import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  ApiService._();

  // For Android emulator
  static const String baseUrl = 'http://localhost:8000/api';

  // For real phone later, change this to your PC's local IP:
  // static const String baseUrl = 'http://192.168.1.12:8000/api';

  static Future<void> syncUser({
    required String firebaseUid,
    required String email,
    required String firstName,
    required String? middleInitial,
    required String lastName,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/sync'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'firebase_uid': firebaseUid,
        'email': email,
        'first_name': firstName,
        'middle_initial': middleInitial,
        'last_name': lastName,
        'role': role,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to sync user to backend: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>?> fetchUserProfile({
    required String firebaseUid,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile/$firebaseUid'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to fetch user profile: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final user = data['user'];

    if (user is Map<String, dynamic>) {
      return user;
    }

    return null;
  }
}