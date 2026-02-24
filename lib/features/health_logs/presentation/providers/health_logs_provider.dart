import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/local_storage_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/health_log.dart';

class HealthLogsNotifier extends StateNotifier<List<HealthLog>> {
  HealthLogsNotifier(this._storage, this._userId) : super(const []) {
    Future.microtask(_load);
  }

  final LocalStorageService _storage;
  final String _userId;
  static const _baseFileName = 'health_logs';
  static const _legacyFileName = 'health_logs.json';

  String get _fileName => '${_baseFileName}_${_safeUserKey(_userId)}.json';

  static String _safeUserKey(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  Future<void> addLog({
    required HealthMetricType type,
    required String value,
    String? note,
  }) async {
    final updated = [
      ...state,
      HealthLog(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: type,
        value: value,
        recordedAt: DateTime.now(),
        note: note,
      ),
    ];
    state = updated;
    await _persist(updated);
  }

  Future<void> updateLog({
    required String id,
    required HealthMetricType type,
    required String value,
    String? note,
  }) async {
    final updated = state
        .map(
          (log) => log.id == id
              ? HealthLog(
                  id: log.id,
                  type: type,
                  value: value,
                  recordedAt: log.recordedAt,
                  note: note,
                )
              : log,
        )
        .toList();

    state = updated;
    await _persist(updated);
  }

  Future<void> deleteLog(String id) async {
    final updated = state.where((log) => log.id != id).toList();
    state = updated;
    await _persist(updated);
  }

  Future<void> restoreLog(HealthLog log) async {
    final updated = [...state, log];
    state = updated;
    await _persist(updated);
  }

  Future<void> _load() async {
    var rows = await _storage.readJsonList(_fileName);
    if (rows.isEmpty) {
      rows = await _storage.readJsonList(_legacyFileName);
      if (rows.isNotEmpty) {
        await _storage.writeJsonList(_fileName, rows);
        await _storage.deleteFile(_legacyFileName);
      }
    }

    state = rows
        .map((row) {
          final typeIndex = row['type'] as int?;
          if (typeIndex == null ||
              typeIndex < 0 ||
              typeIndex >= HealthMetricType.values.length) {
            return null;
          }

          final recordedAtRaw = row['recordedAt'] as String?;
          final recordedAt = recordedAtRaw == null
              ? null
              : DateTime.tryParse(recordedAtRaw);
          if (recordedAt == null) return null;

          final id = row['id'] as String?;
          final value = row['value'] as String?;
          if (id == null || value == null) return null;

          return HealthLog(
            id: id,
            type: HealthMetricType.values[typeIndex],
            value: value,
            recordedAt: recordedAt,
            note: row['note'] as String?,
          );
        })
        .whereType<HealthLog>()
        .toList();
  }

  Future<void> _persist(List<HealthLog> logs) async {
    await _storage.writeJsonList(
      _fileName,
      logs
          .map(
            (log) => {
              'id': log.id,
              'type': log.type.index,
              'value': log.value,
              'recordedAt': log.recordedAt.toIso8601String(),
              'note': log.note,
            },
          )
          .toList(),
    );
  }
}

final healthLogsProvider =
    StateNotifierProvider.autoDispose<HealthLogsNotifier, List<HealthLog>>((ref) {
      final storage = ref.watch(localStorageProvider);
      final userId = ref.watch(authProvider.select((state) => state.userId));
      return HealthLogsNotifier(storage, userId ?? 'guest');
    });
