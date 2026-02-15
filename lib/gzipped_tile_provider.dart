import 'dart:typed_data';

import 'package:http/http.dart'
    as http; // Keeping http for type reference if needed, though Client usage removed
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:archive/archive.dart';
import 'package:vector_tile/vector_tile.dart';

class GzipNetworkVectorTileProvider extends VectorTileProvider {
  final String urlTemplate;
  final Map<String, String>? httpHeaders;
  final _UrlProvider _urlProvider;

  static final _cacheManager = CacheManager(
    Config(
      'map_tiles_cache',
      stalePeriod: const Duration(days: 120),
      maxNrOfCacheObjects: 10000,
      repo: JsonCacheInfoRepository(databaseName: 'map_tiles_cache'),
      fileService: HttpFileService(),
    ),
  );

  @override
  final int maximumZoom;
  @override
  final int minimumZoom;
  @override
  TileOffset tileOffset;

  GzipNetworkVectorTileProvider({
    required this.urlTemplate,
    this.httpHeaders = const {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
      'Accept-Encoding': 'gzip',
    },
    this.maximumZoom = 16,
    this.minimumZoom = 1,
    TileOffset? tileOffset,
  }) : tileOffset = tileOffset ?? TileOffset.mapbox,
       _urlProvider = _UrlProvider(urlTemplate);

  @override
  Future<Uint8List> provide(TileIdentity tile) async {
    _checkTile(tile);
    final url = _urlProvider.url(tile);
    final uri = Uri.parse(url);

    try {
      // ignore: avoid_print
      print('Fetching tile from cache/network: $uri');

      final file = await _cacheManager.getSingleFile(url, headers: httpHeaders);
      final bytes = await file.readAsBytes();

      if (bytes.length > 4) {
        final prefix = bytes
            .sublist(0, 4)
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join(' ');
        // ignore: avoid_print
        print('Bytes prefix: $prefix');
      }

      final decoded = _decode(bytes);
      if (decoded.isEmpty) {
        // ignore: avoid_print
        print('WARNING: Decoded tile is empty!');
        return Uint8List(0);
      }

      try {
        // Attempt to parse the tile to ensure it's valid protobuf.
        // This prevents vector_map_tiles from crashing later.
        VectorTile.fromBytes(bytes: decoded);
      } catch (e) {
        // ignore: avoid_print
        print('WARNING: Invalid tile data (wire type or protobuf error): $e');
        // Return empty tile to suppress crash
        return Uint8List(0);
      }

      return decoded;
    } catch (e) {
      // Check for cancellation exception string
      if (e.toString().contains('Cancelled') ||
          e.toString().contains('CancellationException')) {
        // ignore: avoid_print
        print('Tile fetch cancelled: $tile');
        return Uint8List(0);
      }
      // ignore: avoid_print
      print('Error fetching tile $tile: $e');
      rethrow;
    }
  }

  Uint8List _decode(Uint8List bytes) {
    if (bytes.length > 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
      return Uint8List.fromList(GZipDecoder().decodeBytes(bytes));
    }
    return bytes;
  }

  void _checkTile(TileIdentity tile) {
    if (tile.z > maximumZoom || tile.z < minimumZoom || !tile.isValid()) {
      throw Exception('Invalid tile coordinates $tile');
    }
  }
}

class _UrlProvider {
  final String urlTemplate;

  _UrlProvider(this.urlTemplate);

  String url(TileIdentity identity) {
    return urlTemplate.replaceAllMapped(RegExp(r'\{(x|y|z)\}'), (match) {
      switch (match.group(1)) {
        case 'x':
          return identity.x.toInt().toString();
        case 'y':
          return identity.y.toInt().toString();
        case 'z':
          return identity.z.toInt().toString();
        default:
          throw Exception(
            'unexpected url template: $urlTemplate - token ${match.group(1)} is not supported',
          );
      }
    });
  }
}
