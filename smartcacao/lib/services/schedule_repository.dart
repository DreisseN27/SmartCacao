import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class FermentationSchedule {
  final String id;
  final String batchName;
  final DateTime startDate;
  final DateTime createdAt;

  FermentationSchedule({
    required this.id,
    required this.batchName,
    required this.startDate,
    required this.createdAt,
  });
}

class ScheduleRepository {
  ScheduleRepository._privateConstructor();
  static final ScheduleRepository instance = ScheduleRepository._privateConstructor();

  final ValueNotifier<List<FermentationSchedule>> schedules = ValueNotifier<List<FermentationSchedule>>([]);
  final ValueNotifier<List<FermentationSchedule>> history = ValueNotifier<List<FermentationSchedule>>([]);
  final _uuid = Uuid();

  void addSchedule(String batchName, DateTime startDate) {
    final schedule = FermentationSchedule(
      id: _uuid.v4(),
      batchName: batchName,
      startDate: startDate,
      createdAt: DateTime.now(),
    );
    schedules.value = List.from(schedules.value)..insert(0, schedule);
  }

  /// Moves an active schedule into history (archive) instead of permanently deleting.
  void archiveSchedule(String id) {
    final found = schedules.value.firstWhere((s) => s.id == id, orElse: () => throw StateError('Schedule not found'));
    schedules.value = List.from(schedules.value)..removeWhere((s) => s.id == id);
    history.value = List.from(history.value)..insert(0, found);
  }

  /// Permanently remove from history.
  void deleteFromHistory(String id) {
    history.value = List.from(history.value)..removeWhere((s) => s.id == id);
  }

  List<FermentationSchedule> getAll() => schedules.value;
  List<FermentationSchedule> getHistory() => history.value;
}
