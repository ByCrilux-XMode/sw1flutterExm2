import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiClient {
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> post(
      String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return http.post(
      Uri.parse('${AppConstants.baseUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    return http.get(
      Uri.parse('${AppConstants.baseUrl}$endpoint'),
      headers: headers,
    );
  }

  static Future<http.Response> put(String endpoint,
      [Map<String, dynamic>? body]) async {
    final headers = await _getHeaders();
    return http.put(
      Uri.parse('${AppConstants.baseUrl}$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Future<http.Response> patch(String endpoint,
      [Map<String, dynamic>? body]) async {
    final headers = await _getHeaders();
    return http.patch(
      Uri.parse('${AppConstants.baseUrl}$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }
}
