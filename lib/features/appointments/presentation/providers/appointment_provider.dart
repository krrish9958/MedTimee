import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/local_storage_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/appointment.dart';

class AppointmentNotifier extends StateNotifier<List<Appointment>> {
  AppointmentNotifier(this._storage, this._userId) : super(const []) {
    Future.microtask(_load);
  }

  final LocalStorageService _storage;
  final String _userId;
  static const _baseFileName = 'appointments';
  static const _legacyFileName = 'appointments.json';

  String get _fileName => '${_baseFileName}_${_safeUserKey(_userId)}.json';

  static String _safeUserKey(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  Future<void> addVisit({
    required String doctorName,
    required DateTime visitAt,
    required String reason,
  }) async {
    final updated = [
      ...state,
      Appointment(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        doctorName: doctorName,
        visitAt: visitAt,
        reason: reason,
      ),
    ];
    state = updated;
    await _persist(updated);
  }

  Future<void> updateVisit({
    required String id,
    required String doctorName,
    required DateTime visitAt,
    required String reason,
  }) async {
    final updated = state
        .map(
          (visit) => visit.id == id
              ? Appointment(
                  id: visit.id,
                  doctorName: doctorName,
                  visitAt: visitAt,
                  reason: reason,
                )
              : visit,
        )
        .toList();

    state = updated;
    await _persist(updated);
  }

  Future<void> deleteVisit(String id) async {
    final updated = state.where((visit) => visit.id != id).toList();
    state = updated;
    await _persist(updated);
  }

  Future<void> restoreVisit(Appointment visit) async {
    final updated = [...state, visit];
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
          final id = row['id'] as String?;
          final doctorName = row['doctorName'] as String?;
          final reason = row['reason'] as String?;
          final visitAtRaw = row['visitAt'] as String?;
          final visitAt = visitAtRaw == null
              ? null
              : DateTime.tryParse(visitAtRaw);

          if (id == null ||
              doctorName == null ||
              reason == null ||
              visitAt == null) {
            return null;
          }

          return Appointment(
            id: id,
            doctorName: doctorName,
            visitAt: visitAt,
            reason: reason,
          );
        })
        .whereType<Appointment>()
        .toList();
  }

  Future<void> _persist(List<Appointment> visits) async {
    await _storage.writeJsonList(
      _fileName,
      visits
          .map(
            (visit) => {
              'id': visit.id,
              'doctorName': visit.doctorName,
              'visitAt': visit.visitAt.toIso8601String(),
              'reason': visit.reason,
            },
          )
          .toList(),
    );
  }
}

final appointmentProvider =
    StateNotifierProvider.autoDispose<AppointmentNotifier, List<Appointment>>((ref) {
      final storage = ref.watch(localStorageProvider);
      final userId = ref.watch(authProvider.select((state) => state.userId));
      return AppointmentNotifier(storage, userId ?? 'guest');
    });
