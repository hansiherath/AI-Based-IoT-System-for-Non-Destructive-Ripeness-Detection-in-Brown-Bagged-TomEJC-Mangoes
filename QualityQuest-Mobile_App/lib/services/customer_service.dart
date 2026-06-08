import 'dart:convert';
import 'package:http/http.dart' as http;

class CustomerService {
  static const String baseUrl = "http://10.162.195.39:3000";

  static Future<void> updateDiabetesStatus({
    required int userId,
    required int isDiabetic,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/customer/diabetes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'isDiabetic': isDiabetic,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update diabetes status");
    }
  }
}
