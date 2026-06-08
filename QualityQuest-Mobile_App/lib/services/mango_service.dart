import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mango_result.dart';
import '../config/api_config.dart';

class MangoService {
  static Future<MangoResult> fetchLatestResult(int userId) async {
    final url =
        Uri.parse('${ApiConfig.baseUrl}/latest-mango-result/$userId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return MangoResult.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load mango result');
    }
  }
}
