import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class AuthService {
  final storage = FlutterSecureStorage();

  // Register user
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Save token securely
      await storage.write(key: 'token', value: data['token']);
    }

    return data;
  }

  // Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await storage.write(key: 'token', value: data['token']);
    }

    return data;
  }

  // Logout
  Future<void> logout() async {
    await storage.delete(key: 'token');
  }

  // Get token
  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }
}