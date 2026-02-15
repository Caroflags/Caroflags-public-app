import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:archive/archive.dart';

void main() async {
  final url = Uri.parse('https://api.caroflags.xyz/tiles/14/4508/6488.pbf');
  print('Requesting: $url');

  try {
    final response = await http.get(url);
    final bytes = response.bodyBytes;
    print('Raw Body Length: ${bytes.length}');

    // Check if gzipped
    if (bytes.length > 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
      print('Confirmed GZIP magic bytes.');
      try {
        final decoded = GZipDecoder().decodeBytes(bytes);
        print('Successfully unzipped! Decoded length: ${decoded.length}');
        print('First few unzipped bytes: ${decoded.take(10).toList()}');
      } catch (e) {
        print('Unzip failed: $e');
      }
    } else {
      print('Not gzipped.');
    }
  } catch (e) {
    print('Error: $e');
  }
}
