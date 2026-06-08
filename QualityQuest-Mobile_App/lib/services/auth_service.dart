import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthService {
  // ---------- REGISTER ----------
  static Future<String?> register({
    required String email,
    required String password,
    required String fname,
    required String lname,
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/register");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "fname": fname,
          "lname": lname,
        }),
      );

      if (response.statusCode == 200) {
        return null;
      } else {
        return jsonDecode(response.body)["message"];
      }
    } catch (_) {
      return "Cannot connect to server";
    }
  }

  // ---------- LOGIN ----------
  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/login");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );
      final body = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
           "error": body["message"] ?? "Login failed"
        };
      }
    } catch (e) {
      return {
        "error": "Cannot connect to server"
      };
    }
  }


  static Future<void> updateDiabetesStatus(
    int userId, bool isDiabetic) async {

  final url = Uri.parse("${ApiConfig.baseUrl}/customer/diabetes");

  await http.put(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "userId": userId,
      "isDiabetic": isDiabetic ? 1 : 0,
    }),
  );
}

}
