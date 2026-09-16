import 'package:flutter/material.dart';

class TimeStatusScreen extends StatelessWidget {
  const TimeStatusScreen({super.key});

  String _stageForDay(int day) {
    if (day <= 5) return 'Underfermented';
    if (day == 6) return 'Fermented';
    return 'Overfermented';
  }

  String _guideForDay(int day) {
    if (day <= 5) return 'Continue: Yes';
    if (day == 6) return 'Continue: No — Fermented';
    return 'Action: Stop — Overfermented';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Status'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fermentation Schedule',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Shows fermentation day and guidance whether to continue the process.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Static schedule list (placeholder)
            Expanded(
              child: Card(
                elevation: 4,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    final day = index + 1;
                    final stage = _stageForDay(day);
                    final guide = _guideForDay(day);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.brown.shade200,
                        child: Text('D$day', style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text('Day $day — $stage', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(guide),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Placeholder - no function yet
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Day $day details'),
                            content: Text('Stage: $stage\n$guide\n\n(Integration with actual schedule coming soon.)'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Text('Guide', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('• Day 1-5: Underfermented — Continue fermentation.\n• Day 6: Fermented — Stop and inspect.\n• Day 7+: Overfermented — Avoid continuing.'),
          ],
        ),
      ),
    );
  }
}
