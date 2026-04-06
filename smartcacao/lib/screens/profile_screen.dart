import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _buildFullName(Map<String, dynamic> userData) {
    final firstName = (userData['first_name'] ?? '').toString().trim();
    final middleInitial = (userData['middle_initial'] ?? '').toString().trim();
    final lastName = (userData['last_name'] ?? '').toString().trim();

    final middlePart = middleInitial.isNotEmpty ? ' ${middleInitial.toUpperCase()}.' : '';
    final fullName = '$firstName$middlePart $lastName'.trim();

    return fullName.isEmpty ? 'SmartCacao User' : fullName;
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final email = firebaseUser?.email ?? 'No email available';
    final isVerified = firebaseUser?.emailVerified ?? false;
    final uid = firebaseUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: uid.isEmpty
            ? Future.value(null)
            : ApiService.fetchUserProfile(firebaseUid: uid),
        builder: (context, snapshot) {
          final userData = snapshot.data;

          final displayName = userData != null
              ? _buildFullName(userData)
              : 'SmartCacao User';

          final displayRole = userData != null
              ? (userData['role'] ?? 'Farmer').toString()
              : 'Farmer';

          final displayFirstName = userData != null
              ? (userData['first_name'] ?? 'Unavailable').toString()
              : 'Unavailable';

          final displayMiddleInitial = userData != null
              ? ((userData['middle_initial'] ?? '').toString().trim().isEmpty
                  ? 'N/A'
                  : (userData['middle_initial']).toString().toUpperCase())
              : 'N/A';

          final displayLastName = userData != null
              ? (userData['last_name'] ?? 'Unavailable').toString()
              : 'Unavailable';

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.brown.shade700,
                        Colors.brown.shade400,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: Colors.white.withOpacity(0.18),
                        child: const Icon(
                          Icons.account_circle,
                          size: 72,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            children: [
                              _buildProfileRow(
                                icon: Icons.person_outline,
                                label: 'First Name',
                                value: displayFirstName,
                              ),
                              const Divider(height: 24),
                              _buildProfileRow(
                                icon: Icons.edit_outlined,
                                label: 'Middle Initial',
                                value: displayMiddleInitial,
                              ),
                              const Divider(height: 24),
                              _buildProfileRow(
                                icon: Icons.badge_outlined,
                                label: 'Last Name',
                                value: displayLastName,
                              ),
                              const Divider(height: 24),
                              _buildProfileRow(
                                icon: Icons.work_outline,
                                label: 'Role',
                                value: displayRole,
                              ),
                              const Divider(height: 24),
                              _buildProfileRow(
                                icon: Icons.email_outlined,
                                label: 'Email Address',
                                value: email,
                              ),
                              const Divider(height: 24),
                              _buildProfileRow(
                                icon: isVerified
                                    ? Icons.verified
                                    : Icons.error_outline,
                                label: 'Email Verification',
                                value: isVerified ? 'Verified' : 'Not Verified',
                                valueColor: isVerified
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                              const Divider(height: 24),
                              _buildProfileRow(
                                icon: Icons.fingerprint,
                                label: 'Firebase UID',
                                value: uid.isEmpty ? 'Unavailable' : uid,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: CircularProgressIndicator(),
                        ),
                      if (snapshot.hasError)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Using available account info while profile data loads.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_back),
                              SizedBox(width: 8),
                              Text(
                                'Back to Home',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.brown.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Colors.brown.shade700,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}