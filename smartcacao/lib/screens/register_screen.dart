import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../services/api_service.dart';
import 'email_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
final _middleInitialController = TextEditingController();
final _lastNameController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

 @override
void dispose() {
  _firstNameController.dispose();
  _middleInitialController.dispose();
  _lastNameController.dispose();
  _emailController.dispose();
  _passwordController.dispose();
  _confirmPasswordController.dispose();
  super.dispose();
}

  Future<void> _register() async {

    
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
  await AuthService.register(
    email: _emailController.text.trim(),
    password: _passwordController.text.trim(),
  );

  final user = FirebaseAuth.instance.currentUser;

  if (user == null || user.email == null) {
    throw Exception('Firebase user was not created properly.');
  }

  await ApiService.syncUser(
    firebaseUid: user.uid,
    email: user.email!,
    firstName: _firstNameController.text.trim(),
    middleInitial: _middleInitialController.text.trim().isEmpty
        ? null
        : _middleInitialController.text.trim().toUpperCase(),
    lastName: _lastNameController.text.trim(),
    role: 'farmer',
  );

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Account created. Verification email sent.'),
    ),
  );

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const EmailVerificationScreen(),
    ),
  );
} on FirebaseAuthException catch (e) {
      String message = 'Registration failed. Please try again.';

      if (e.code == 'email-already-in-use') {
        message = 'That email is already registered.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak.';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Something went wrong: $e'),
    ),
  );
} finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildFieldLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  );
}

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Colors.grey,
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: Colors.brown,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(0.95),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.brown.shade200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.brown.shade700,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brown700 = Colors.brown.shade700;
    final brown400 = Colors.brown.shade400;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 260,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [brown700, brown400],
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add_alt_1,
                      size: 80,
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Create SmartCacao Account',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Register to use cacao analysis tools',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
  elevation: 8,
  color: Colors.brown.shade900.withOpacity(0.88),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
  child: Padding(
    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
  'Register',
  style: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  ),
),
const SizedBox(height: 8),
const Text(
  'Fill in your details and verify your email.\nPassword must be at least 6 characters, include 1 capital letter, 1 special character, and contain no spaces.',
  style: TextStyle(
    fontSize: 14,
    color: Colors.white70,
    height: 1.5,
  ),
),
const SizedBox(height: 24),

_buildFieldLabel('First Name'),
TextFormField(
  controller: _firstNameController,
  style: const TextStyle(
    color: Colors.black87,
    fontSize: 15,
  ),
  cursorColor: Colors.brown,
  decoration: _inputDecoration(
    hint: 'Enter your first name',
    icon: Icons.person_outline,
  ),
  validator: (value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'First name is required';
    return null;
  },
),
const SizedBox(height: 16),

_buildFieldLabel('Middle Initial'),
TextFormField(
  controller: _middleInitialController,
  textCapitalization: TextCapitalization.characters,
  maxLength: 1,
  style: const TextStyle(
    color: Colors.black87,
    fontSize: 15,
  ),
  cursorColor: Colors.brown,
  decoration: _inputDecoration(
    hint: 'Enter your middle initial',
    icon: Icons.edit_outlined,
  ).copyWith(
    counterText: '',
  ),
  validator: (value) {
    final text = value?.trim() ?? '';
    if (text.isNotEmpty && text.length > 1) {
      return 'Only 1 character allowed';
    }
    return null;
  },
),
const SizedBox(height: 16),

_buildFieldLabel('Last Name'),
TextFormField(
  controller: _lastNameController,
  style: const TextStyle(
    color: Colors.black87,
    fontSize: 15,
  ),
  cursorColor: Colors.brown,
  decoration: _inputDecoration(
    hint: 'Enter your last name',
    icon: Icons.badge_outlined,
  ),
  validator: (value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Last name is required';
    return null;
  },
),
const SizedBox(height: 16),

_buildFieldLabel('Email'),
TextFormField(
  controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 15,
                            ),
                            cursorColor: Colors.brown,
                            decoration: _inputDecoration(
                              hint: 'Enter your email',
                              icon: Icons.email_outlined,
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) return 'Email is required';
                              if (!text.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          _buildFieldLabel('Password'),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 15,
                            ),
                            cursorColor: Colors.brown,
                            decoration: _inputDecoration(
                              hint: 'Create a password',
                              icon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.brown,
                                ),
                              ),
                            ),
                            validator: (value) {
  final password = value ?? '';

  if (password.isEmpty) {
    return 'Password is required';
  }
  if (password.length < 6) {
    return 'Password must be at least 6 characters';
  }
  if (password.contains(' ')) {
    return 'Password must not contain spaces';
  }
  if (!RegExp(r'[A-Z]').hasMatch(password)) {
    return 'Password must include at least 1 capital letter';
  }
  if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\\/\[\];+=~`]').hasMatch(password)) {
    return 'Password must include at least 1 special character';
  }

  return null;
},
                          ),
                          const SizedBox(height: 16),

                          _buildFieldLabel('Confirm Password'),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 15,
                            ),
                            cursorColor: Colors.brown,
                            decoration: _inputDecoration(
                              hint: 'Re-enter your password',
                              icon: Icons.lock_reset,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.brown,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if ((value ?? '').isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brown700,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Register',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Center(
  child: TextButton(
    onPressed: () => Navigator.pop(context),
    child: const Text(
      'Back to Login',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}