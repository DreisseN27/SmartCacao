import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'history_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late StorageService storageService;

  String selectedStatus = 'all';
  String selectedSort = 'latest';
  int? selectedMonth;
  int? selectedYear;

  final List<Map<String, String>> statusOptions = const [
    {'label': 'All', 'value': 'all'},
    {'label': 'Under', 'value': 'under_fermented'},
    {'label': 'Properly', 'value': 'properly_fermented'},
    {'label': 'Over', 'value': 'over_fermented'},
  ];

  final List<Map<String, dynamic>> monthOptions = const [
    {'label': 'All Months', 'value': null},
    {'label': 'January', 'value': 1},
    {'label': 'February', 'value': 2},
    {'label': 'March', 'value': 3},
    {'label': 'April', 'value': 4},
    {'label': 'May', 'value': 5},
    {'label': 'June', 'value': 6},
    {'label': 'July', 'value': 7},
    {'label': 'August', 'value': 8},
    {'label': 'September', 'value': 9},
    {'label': 'October', 'value': 10},
    {'label': 'November', 'value': 11},
    {'label': 'December', 'value': 12},
  ];

  @override
  void initState() {
    super.initState();
    storageService = StorageService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection History'),
        elevation: 0,
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton(
            iconColor: Colors.white,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'seed',
                child: Text('Generate Test Data'),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear All'),
              ),
            ],
            onSelected: (value) async {
              if (value == 'seed') {
                await storageService.seedTestRecords();
                if (!mounted) return;
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test history generated successfully.'),
                  ),
                );
              }

              if (value == 'clear') {
                _showClearConfirmation();
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<DetectionRecord>>(
        future: storageService.getAllRecords(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data ?? [];
          final availableYears = _extractYears(records);
          final filteredRecords = _applyFilters(records);

          if (records.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildStatisticsPanel(records),
              _buildFilters(availableYears),
              Expanded(
                child: filteredRecords.isEmpty
                    ? _buildNoResultsState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        itemCount: filteredRecords.length,
                        itemBuilder: (context, index) {
                          final record = filteredRecords[index];
                          return _buildRecordCard(record);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<int> _extractYears(List<DetectionRecord> records) {
    final years = records.map((r) => r.timestamp.year).toSet().toList();
    years.sort((a, b) => b.compareTo(a));
    return years;
  }

  List<DetectionRecord> _applyFilters(List<DetectionRecord> records) {
    List<DetectionRecord> filtered = List<DetectionRecord>.from(records);

    if (selectedStatus != 'all') {
      filtered = filtered
          .where((r) => r.fermentationStatus == selectedStatus)
          .toList();
    }

    if (selectedMonth != null) {
      filtered = filtered.where((r) => r.timestamp.month == selectedMonth).toList();
    }

    if (selectedYear != null) {
      filtered = filtered.where((r) => r.timestamp.year == selectedYear).toList();
    }

    filtered.sort((a, b) {
      if (selectedSort == 'oldest') {
        return a.timestamp.compareTo(b.timestamp);
      }
      return b.timestamp.compareTo(a.timestamp);
    });

    return filtered;
  }

  Widget _buildStatisticsPanel(List<DetectionRecord> records) {
    final total = records.length;
    final under = records.where((r) => r.fermentationStatus == 'under_fermented').length;
    final proper = records.where((r) => r.fermentationStatus == 'properly_fermented').length;
    final over = records.where((r) => r.fermentationStatus == 'over_fermented').length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.brown.shade700,
            Colors.brown.shade500,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', total, Colors.white),
          _buildStatItem('Under', under, Colors.red.shade100),
          _buildStatItem('Proper', proper, Colors.green.shade100),
          _buildStatItem('Over', over, Colors.orange.shade100),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(List<int> availableYears) {
  return Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.brown.shade700,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.brown.withAlpha((0.25 * 255).toInt()),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filter Records',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),

        // STATUS CHIPS
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: statusOptions.map((option) {
            final isSelected = selectedStatus == option['value'];

            return ChoiceChip(
              label: Text(
                option['label']!,
                style: TextStyle(
                  color: isSelected ? Colors.brown : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  selectedStatus = option['value']!;
                });
              },
              selectedColor: Colors.white,
              backgroundColor: Colors.white.withAlpha((0.15 * 255).toInt()),
              side: BorderSide(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withAlpha((0.35 * 255).toInt()),
              ),
              showCheckmark: false,
            );
          }).toList(),
        ),

        const SizedBox(height: 14),

        // SORT + MONTH
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: selectedSort,
                decoration: _dropdownDecoration('Sort'),
                items: const [
                  DropdownMenuItem(
                    value: 'latest',
                    child: Text('Latest first'),
                  ),
                  DropdownMenuItem(
                    value: 'oldest',
                    child: Text('Oldest first'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedSort = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<int?>(
                value: selectedMonth,
                decoration: _dropdownDecoration('Month'),
                items: monthOptions.map((month) {
                  return DropdownMenuItem<int?>(
                    value: month['value'] as int?,
                    child: Text(month['label'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedMonth = value;
                  });
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // YEAR
        DropdownButtonFormField<int?>(
          value: selectedYear,
          decoration: _dropdownDecoration('Year'),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('All Years'),
            ),
            ...availableYears.map(
              (year) => DropdownMenuItem<int?>(
                value: year,
                child: Text(year.toString()),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              selectedYear = value;
            });
          },
        ),
      ],
    ),
  );
}

  InputDecoration _dropdownDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white),
    filled: true,
    fillColor: Colors.white.withAlpha((0.12 * 255).toInt()),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Colors.white.withAlpha((0.35 * 255).toInt()),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Colors.white.withAlpha((0.35 * 255).toInt()),
      ),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(
        color: Colors.white,
        width: 1.5,
      ),
    ),
  );
}

  Widget _buildRecordCard(DetectionRecord record) {
  final statusColor = _getStatusColor(record.fermentationStatus);
  final statusLabel = _getStatusLabel(record.fermentationStatus);

  return Card(
    margin: const EdgeInsets.only(bottom: 14),
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: statusColor.withAlpha((0.35 * 255).toInt()),
        width: 1.5,
      ),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HistoryDetailScreen(record: record),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withAlpha((0.10 * 255).toInt()),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(record.fermentationStatus),
                  color: statusColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: statusColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withAlpha((0.35 * 255).toInt()),
                    ),
                  ),
                  child: Text(
                    '${(record.averageConfidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRecordThumbnail(record, statusColor),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(record.timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildMiniCountRow(
                        label: 'Under',
                        value: record.underFermentedCount,
                        color: Colors.red.shade600,
                      ),
                      const SizedBox(height: 6),
                      _buildMiniCountRow(
                        label: 'Proper',
                        value: record.properlyFermentedCount,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(height: 6),
                      _buildMiniCountRow(
                        label: 'Over',
                        value: record.overFermentedCount,
                        color: Colors.orange.shade700,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  children: [
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 18,
                      color: statusColor,
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(record.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildMiniCountRow({
  required String label,
  required int value,
  required Color color,
}) {
  return Row(
    children: [
      SizedBox(
        width: 50,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value == 0 ? 0 : (value / 12).clamp(0, 1).toDouble(),
            minHeight: 8,
            backgroundColor: color.withAlpha((0.15 * 255).toInt()),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Text(
        '$value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    ],
  );
}



  Widget _buildRecordThumbnail(DetectionRecord record, Color statusColor) {
    final canUseFileImage = !kIsWeb && record.imagePath.isNotEmpty;

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 2),
        color: statusColor.withAlpha((0.10 * 255).toInt()),
      ),
      child: canUseFileImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: File(record.imagePath).existsSync()
                  ? Image.file(
                      File(record.imagePath),
                      fit: BoxFit.cover,
                    )
                  : Icon(
                      _getStatusIcon(record.fermentationStatus),
                      color: statusColor,
                      size: 32,
                    ),
            )
          : Icon(
              _getStatusIcon(record.fermentationStatus),
              color: statusColor,
              size: 32,
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storage_outlined,
            size: 70,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No detection history yet',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your previous cacao scan results will appear here.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No records match the selected filters.',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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

  void _showDeleteConfirmation(String recordId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await storageService.deleteRecord(recordId);
              if (mounted) {
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Records?'),
        content: const Text('This will delete all detection history and images. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await storageService.clearAllRecords();
              if (mounted) {
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}