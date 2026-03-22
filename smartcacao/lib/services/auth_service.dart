import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user?.updateDisplayName(name);
    await credential.user?.sendEmailVerification();

    return credential;
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> sendVerificationAgain() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<bool> reloadAndCheckVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    await user.reload();
    return FirebaseAuth.instance.currentUser?.emailVerified ?? false;
  }

  Future<void> syncVerifiedUserToLaravel() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated Firebase user');
    }

    final idToken = await user.getIdToken();

    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/firebase/sync-user'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'name': user.displayName ?? '',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to sync user to backend: ${response.body}');
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}