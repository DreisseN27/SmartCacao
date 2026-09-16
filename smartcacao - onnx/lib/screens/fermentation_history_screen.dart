import 'package:flutter/material.dart';
import '../services/schedule_repository.dart';

class FermentationHistoryScreen extends StatelessWidget {
  const FermentationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fermentation History'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Saved Schedules', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: ValueListenableBuilder<List<FermentationSchedule>>(
                valueListenable: ScheduleRepository.instance.history,
                builder: (context, items, _) {
                  if (items.isEmpty) return const Center(child: Text('No saved schedules yet.'));
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final s = items[index];
                      return Card(
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          title: Text(s.batchName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Start: ${s.startDate.toLocal().toString().split(' ')[0]} • Created: ${s.createdAt.toLocal().toString().split(' ')[0]}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () {
                              ScheduleRepository.instance.deleteFromHistory(s.id);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Schedule permanently deleted from history')));
                            },
                          ),
                          onTap: () {
                            // Show details even after archived
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(s.batchName),
                                content: Text('Start date: ${s.startDate.toLocal().toString().split(' ')[0]}\nCreated: ${s.createdAt.toLocal().toString().split(' ')[0]}'),
                                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
