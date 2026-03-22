import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final AuthService authService = AuthService();
  bool loading = false;

  Future<void> checkVerification() async {
    setState(() => loading = true);

    try {
      final verified = await authService.reloadAndCheckVerified();

      if (verified) {
        await authService.syncVerifiedUserToLaravel();

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email is not verified yet')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> resendVerification() async {
    try {
      await authService.sendVerificationAgain();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent again')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resend: $e')),
      );
    }
  }

  Future<void> logout() async {
    await authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'A verification email has been sent to your email address.\n\nPlease verify your email before continuing.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: checkVerification,
                      child: const Text('I have verified my email'),
                    ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: resendVerification,
                child: const Text('Resend verification email'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: logout,
                child: const Text('Back to login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}