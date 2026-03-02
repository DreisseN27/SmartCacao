import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final success = result['success'] ?? false;
    final fermentationStatus = result['fermentationStatus'] ?? 'unknown';
    final statistics = result['statistics'] as Map<String, dynamic>? ?? {};
    final confidence = result['confidence'] as Map<String, dynamic>? ?? {};
    final recommendation = result['recommendation'] ?? '';
    final detections = result['detections'] as List<dynamic>? ?? [];

    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help_outline;

    if (fermentationStatus == 'under_fermented') {
      statusColor = Colors.red;
      statusIcon = Icons.schedule;
    } else if (fermentationStatus == 'properly_fermented') {
      statusColor = Colors.green;
      statusIcon = Icons.verified;
    } else if (fermentationStatus == 'over_fermented') {
      statusColor = Colors.amber;
      statusIcon = Icons.warning;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Result'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: success
            ? _buildSuccessView(
                context,
                fermentationStatus,
                statusColor,
                statusIcon,
                statistics,
                confidence,
                recommendation,
                detections,
              )
            : _buildFailureView(context, result['message'] ?? 'Unknown error'),
      ),
    );
  }

  Widget _buildSuccessView(
    BuildContext context,
    String fermentationStatus,
    Color statusColor,
    IconData statusIcon,
    Map<String, dynamic> statistics,
    Map<String, dynamic> confidence,
    String recommendation,
    List<dynamic> detections,
  ) {
    return Column(
      children: [
        // Status header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: statusColor.withAlpha((0.1 * 255).toInt()),
            border: Border(
              bottom: BorderSide(color: statusColor, width: 3),
            ),
          ),
          child: Column(
            children: [
              Icon(statusIcon, size: 64, color: statusColor),
              const SizedBox(height: 16),
              Text(
                _getStatusTitle(fermentationStatus),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getStatusDescription(fermentationStatus),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),

        // Statistics section
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Analysis Statistics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Beans detected
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.grain,
                          color: Colors.blue,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Beans Detected',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${statistics['totalBeansDetected'] ?? 0}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Fermentation breakdown
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Under-Fermented',
                      count: statistics['underFermented'] ?? 0,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Properly-Fermented',
                      count: statistics['properlyFermented'] ?? 0,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Over-Fermented',
                      count: statistics['overFermented'] ?? 0,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Confidence scores
              const Text(
                'Confidence Scores',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildConfidenceRow(
                        'Average Confidence',
                        '${((confidence['average'] ?? 0) * 100).toStringAsFixed(1)}%',
                      ),
                      const Divider(height: 24),
                      _buildConfidenceRow(
                        'Highest Confidence',
                        '${((confidence['highest'] ?? 0) * 100).toStringAsFixed(1)}%',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Recommendation
              const Text(
                'Recommendation',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Card(
                color: statusColor.withAlpha((0.1 * 255).toInt()),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: statusColor,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          recommendation,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil(
                    (route) => route.isFirst,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home),
                      SizedBox(width: 8),
                      Text(
                        'Back to Home',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt),
                      SizedBox(width: 8),
                      Text(
                        'Scan Again',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha((0.1 * 255).toInt()),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.grain, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.brown,
          ),
        ),
      ],
    );
  }

  Widget _buildFailureView(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 24),
          const Text(
            'Analysis Failed',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
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
                  Icon(Icons.camera_alt),
                  SizedBox(width: 8),
                  Text(
                    'Try Again',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'under_fermented':
        return 'Under-Fermented';
      case 'properly_fermented':
        return 'Properly Fermented';
      case 'over_fermented':
        return 'Over-Fermented';
      default:
        return 'Unknown Status';
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'under_fermented':
        return 'Beans need more fermentation time to develop proper flavor';
      case 'properly_fermented':
        return 'Beans have reached optimal fermentation. Ready for processing!';
      case 'over_fermented':
        return 'Fermentation has exceeded optimal time. Reduce next cycle.';
      default:
        return 'Unable to determine fermentation status';
    }
  }
}