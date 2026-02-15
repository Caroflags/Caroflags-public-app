import 'dart:typed_data';

import 'package:http/http.dart';

import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:archive/archive.dart';
import 'package:vector_tile/vector_tile.dart';

class GzipNetworkVectorTileProvider extends VectorTileProvider {
  final String urlTemplate;
  final Map<String, String>? httpHeaders;
  final _UrlProvider _urlProvider;

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
    final uri = Uri.parse(_urlProvider.url(tile));
    final client = Client();
    try {
      // ignore: avoid_print
      print('Fetching tile: $uri');
      final response = await client.get(uri, headers: httpHeaders);
      // ignore: avoid_print
      print(
        'Response for $tile: ${response.statusCode}, length: ${response.bodyBytes.length}',
      );
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
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
      }
      throw Exception(
        'Cannot retrieve tile: HTTP ${response.statusCode}: $uri ${response.body}',
      );
    } catch (e) {
      // Check for cancellation exception string since we can't easily import the type
      if (e.toString().contains('Cancelled') ||
          e.toString().contains('CancellationException')) {
        // ignore: avoid_print
        print('Tile fetch cancelled: $tile');
        return Uint8List(0);
      }
      // ignore: avoid_print
      print('Error fetching tile $tile: $e');
      rethrow;
    } finally {
      client.close();
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
