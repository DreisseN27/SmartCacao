import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'login_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final storage = const FlutterSecureStorage();

  final List<Map<String, dynamic>> features = const [
    {
      'title': 'Real-time Detection',
      'description': 'Capture and analyze in real-time',
      'icon': Icons.camera_alt,
    },
    {
      'title': 'AI-Powered Analysis',
      'description': 'YOLOv8 with MobileNet+CBAM algorithm',
      'icon': Icons.psychology,
    },
    {
      'title': 'Detailed Reports',
      'description': 'Get comprehensive fermentation analysis',
      'icon': Icons.assessment,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartCacao'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.brown.shade700,
      ),
      body: ListView(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAboutCard(),
                const SizedBox(height: 24),
                const Text(
                  'Features',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // Lazy-load features
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: features.length,
                  itemBuilder: (context, index) {
                    final feature = features[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildFeatureItem(
                        icon: feature['icon'],
                        title: feature['title'],
                        description: feature['description'],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                _buildMainButtons(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 250,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.grain, size: 80, color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Cacao Bean Fermentation',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Detection System',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return const Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'SmartCacao uses advanced machine learning to analyze cacao bean fermentation levels. '
          'Simply capture an image of your cacao beans and the system will determine their '
          'fermentation status: Under-fermented, Properly-fermented, or Over-fermented.',
          style: TextStyle(fontSize: 14, height: 1.6, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.brown.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.brown.shade700, size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 4),
              Text(description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CameraScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown.shade700,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera),
                SizedBox(width: 8),
                Text(
                  'Scan Cacao Beans',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => _showSettings(context),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.settings),
                SizedBox(width: 8),
                Text('Settings'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Model Information',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text('Model: YOLOv8n'),
            const Text('Algorithm: YOLOv8 + MobileNet + CBAM'),
            const Text('Classes: 3 (Under, Proper, Over Fermented)'),
            const Text('Input Size: 640x640'),
            const SizedBox(height: 24),
            const Text(
              'Account',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await storage.delete(key: 'token');
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.shade700),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Close'))
        ],
      ),
    );
  }
}