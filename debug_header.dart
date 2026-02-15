import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://api.caroflags.xyz/tiles/14/4508/6488.pbf');
  try {
    final response = await http.get(url);
    print('Content-Encoding: ${response.headers['content-encoding']}');
  } catch (e) {
    print('Error: $e');
  }
}
