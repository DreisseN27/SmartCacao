import 'dart:io';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'package:flutter/foundation.dart';

class HistoryDetailScreen extends StatelessWidget {
  final DetectionRecord record;

  const HistoryDetailScreen({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(record.fermentationStatus);
    final statusLabel = _getStatusLabel(record.fermentationStatus);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History Details'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: statusColor.withAlpha((0.12 * 255).toInt()),
                border: Border(
                  bottom: BorderSide(color: statusColor, width: 3),
                ),
              ),
              child: Column(
                children: [
                  Icon(_getStatusIcon(record.fermentationStatus), size: 60, color: statusColor),
                  const SizedBox(height: 14),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(record.timestamp),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
  width: 110,
  height: 110,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: statusColor, width: 2),
    color: statusColor.withAlpha((0.10 * 255).toInt()),
  ),
  child: (!kIsWeb &&
          record.imagePath.isNotEmpty &&
          File(record.imagePath).existsSync())
      ? ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(record.imagePath),
            fit: BoxFit.cover,
          ),
        )
      : Center(
          child: Icon(
            _getStatusIcon(record.fermentationStatus),
            color: statusColor,
            size: 38,
          ),
        ),
),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoLine(
                                  'Average Confidence',
                                  '${(record.averageConfidence * 100).toStringAsFixed(1)}%',
                                ),
                                const SizedBox(height: 10),
                                _buildInfoLine(
                                  'Under-Fermented',
                                  '${record.underFermentedCount}',
                                ),
                                const SizedBox(height: 10),
                                _buildInfoLine(
                                  'Properly-Fermented',
                                  '${record.properlyFermentedCount}',
                                ),
                                const SizedBox(height: 10),
                                _buildInfoLine(
                                  'Over-Fermented',
                                  '${record.overFermentedCount}',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
  'Recommendation',
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.brown.shade800,
  ),
),
                          const SizedBox(height: 12),
                          Text(
                            record.recommendation.isEmpty
                                ? 'No recommendation available.'
                                : record.recommendation,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: Colors.grey,
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
      ),
    );
  }

  Widget _buildInfoLine(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.brown,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'under_fermented':
        return Colors.red.shade600;
      case 'properly_fermented':
        return Colors.green.shade600;
      case 'over_fermented':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getStatusIcon(String status) {
  switch (status) {
    case 'under_fermented':
      return Icons.trending_up;
    case 'properly_fermented':
      return Icons.verified;
    case 'over_fermented':
      return Icons.warning_amber_rounded;
    default:
      return Icons.help_outline;
  }
}

  String _getStatusLabel(String status) {
    switch (status) {
      case 'under_fermented':
        return 'Under-Fermented';
      case 'properly_fermented':
        return 'Properly-Fermented';
      case 'over_fermented':
        return 'Over-Fermented';
      default:
        return 'Unknown';
    }
  }

  String _formatDate(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${_monthName(date.month)} ${date.day}, ${date.year} • $hour:$minute $period';
  }

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
  }
}