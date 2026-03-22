import 'package:flutter/material.dart';
import 'dart:io';
import '../services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late StorageService storageService;
  String selectedFilter = 'All';

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
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear All'),
              ),
            ],
            onSelected: (value) {
              if (value == 'clear') {
                _showClearConfirmation();
              }
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: storageService.getAllRecords(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data ?? [];

          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.storage_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No detection history yet',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          // Filter records
          final filteredRecords = selectedFilter == 'All'
              ? records
              : records.where((r) => r.fermentationStatus == selectedFilter).toList();
          
          // Sort records by date (newest first)
          filteredRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return Column(
            children: [
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildFilterChip('All'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Under-fermented'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Properly-fermented'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Over-fermented'),
                  ],
                ),
              ),
              // Statistics
              _buildStatisticsPanel(records),
              // Records list
              Expanded(
                child: ListView.builder(
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

  Widget _buildFilterChip(String label) {
    return FilterChip(
      label: Text(label),
      selected: selectedFilter == label,
      onSelected: (selected) {
        setState(() {
          selectedFilter = selected ? label : 'All';
        });
      },
      selectedColor: Colors.brown.shade700,
      labelStyle: TextStyle(
        color: selectedFilter == label ? Colors.white : Colors.black,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatisticsPanel(List<dynamic> records) {
    return FutureBuilder(
      future: storageService.getStatistics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final stats = snapshot.data as Map<String, int>;
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', stats['total'] ?? 0, Colors.blue),
              _buildStatItem('Under', stats['under_fermented'] ?? 0, Colors.red),
              _buildStatItem('Proper', stats['properly_fermented'] ?? 0, Colors.green),
              _buildStatItem('Over', stats['over_fermented'] ?? 0, Colors.orange),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordCard(dynamic record) {
    final statusColor = record.fermentationStatus == 'under_fermented'
        ? Colors.red
        : record.fermentationStatus == 'properly_fermented'
            ? Colors.green
            : Colors.orange;

    final statusLabel = record.fermentationStatus == 'under_fermented'
        ? 'Under-fermented'
        : record.fermentationStatus == 'properly_fermented'
            ? 'Properly-fermented'
            : 'Over-fermented';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor, width: 2),
          ),
          child: File(record.imagePath).existsSync()
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.file(
                    File(record.imagePath),
                    fit: BoxFit.cover,
                  ),
                )
              : Center(
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.grey.shade400,
                  ),
                ),
        ),
        title: Text(
          statusLabel,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confidence: ${(record.averageConfidence * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Date: ${record.timestamp.toString().split('.')[0]}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _showDeleteConfirmation(record.id),
        ),
      ),
    );
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
                setState(() {}); // Refresh list
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
                setState(() {}); // Refresh list
              }
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
