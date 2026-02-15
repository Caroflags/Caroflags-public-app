import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final url = Uri.parse('https://api.caroflags.xyz/tiles/14/4508/6488.pbf');
  print('Requesting: $url');
  final response = await http.get(url);

  print('Status Code: ${response.statusCode}');
  print('Headers:');
  response.headers.forEach((k, v) => print('  $k: $v'));

  final bytes = response.bodyBytes;
  if (bytes.length > 2) {
    print(
      'First 2 bytes (hex): ${bytes[0].toRadixString(16).padLeft(2, "0")} ${bytes[1].toRadixString(16).padLeft(2, "0")}',
    );
    if (bytes[0] == 0x1f && bytes[1] == 0x8b) {
      print('RESULT: Body is GZIPPED.');
    } else {
      print('RESULT: Body is NOT gzipped.');
    }
  }
}
