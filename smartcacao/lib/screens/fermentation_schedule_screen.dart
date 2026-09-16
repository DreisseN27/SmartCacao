import 'package:flutter/material.dart';
import '../services/schedule_repository.dart';

class FermentationScheduleScreen extends StatefulWidget {
  const FermentationScheduleScreen({super.key});

  @override
  State<FermentationScheduleScreen> createState() => _FermentationScheduleScreenState();
}

class _FermentationScheduleScreenState extends State<FermentationScheduleScreen> {
  final _batchController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _batchController.dispose();
    super.dispose();
  }

  String _stageForDay(int day) {
    if (day <= 5) return 'Underfermented';
    if (day == 6) return 'Fermented';
    return 'Overfermented';
  }

  String _actionForDay(int day) {
    if (day <= 5) return 'Continue';
    return day == 6 ? 'Stop' : 'Stop';
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  void _addSchedule() {
    final name = _batchController.text.trim();
    if (name.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a batch name and start date')));
      return;
    }
    ScheduleRepository.instance.addSchedule(name, _selectedDate!);
    _batchController.clear();
    setState(() => _selectedDate = null);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Schedule added')));
  }

  int _daysSinceStart(DateTime start) {
    final now = DateTime.now();
    final diff = now.difference(DateTime(start.year, start.month, start.day));
    return diff.inDays + 1; // day 1 is start date
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fermentation Schedule'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _batchController,
                      decoration: const InputDecoration(labelText: 'Batch name', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _pickStartDate(context),
                            child: Text(_selectedDate == null ? 'Select start date' : 'Start: ${_selectedDate!.toLocal().toString().split(' ')[0]}'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _addSchedule,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.brown.shade700),
                          child: const Text('Add Schedule'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text('Active Schedules', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Expanded(
              child: ValueListenableBuilder<List<FermentationSchedule>>(
                valueListenable: ScheduleRepository.instance.schedules,
                builder: (context, items, _) {
                  if (items.isEmpty) {
                    return const Center(child: Text('No schedules yet.'));
                  }
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final s = items[index];
                      final days = _daysSinceStart(s.startDate);
                      final stage = _stageForDay(days);
                      final action = _actionForDay(days);

                      return Card(
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(backgroundColor: Colors.brown.shade200, child: Text('D$days', style: const TextStyle(color: Colors.white))),
                          title: Text(s.batchName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Start: ${s.startDate.toLocal().toString().split(' ')[0]} • $stage'),
                              const SizedBox(height: 6),
                              Chip(
                                label: Text(action, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                backgroundColor: action == 'Continue' ? Colors.orange : Colors.green,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            iconSize: 20,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            splashRadius: 20,
                            onPressed: () {
                              try {
                                ScheduleRepository.instance.archiveSchedule(s.id);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Schedule moved to history')));
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to archive schedule')));
                              }
                            },
                          ),
                          onTap: () {
                            // Placeholder detail view
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(s.batchName),
                                content: Text('Start date: ${s.startDate.toLocal().toString().split(' ')[0]}\nDays: $days\nStatus: $stage\nAction: $action'),
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
