import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/app_database.dart';
import '../../../../core/services/notification_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/isar_medicine_repository.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/medicine_intake.dart';
import '../../domain/repositories/medicine_repository.dart';

final medicineRepositoryProvider = Provider<MedicineRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final notifications = ref.watch(notificationServiceProvider);
  final userId = ref.watch(authProvider.select((state) => state.userId));
  return IsarMedicineRepository(db, notifications, userId: userId ?? 'guest');
});

class MedicinesState {
  const MedicinesState({
    required this.medicines,
    required this.today,
    this.loading = false,
  });

  final List<Medicine> medicines;
  final List<MedicineIntake> today;
  final bool loading;

  MedicinesState copyWith({
    List<Medicine>? medicines,
    List<MedicineIntake>? today,
    bool? loading,
  }) {
    return MedicinesState(
      medicines: medicines ?? this.medicines,
      today: today ?? this.today,
      loading: loading ?? this.loading,
    );
  }

  factory MedicinesState.initial() =>
      const MedicinesState(medicines: [], today: [], loading: false);
}

class MedicinesNotifier extends StateNotifier<MedicinesState> {
  MedicinesNotifier(this._repo) : super(MedicinesState.initial()) {
    Future.microtask(refresh);
  }

  final MedicineRepository _repo;

  Future<void> refresh({bool showLoading = true}) async {
    if (showLoading) {
      state = state.copyWith(loading: true);
    }
    final medicines = await _repo.getMedicines();
    final today = await _repo.getTodaySchedule();
    state = state.copyWith(
      medicines: medicines,
      today: today,
      loading: false,
    );
  }

  Future<void> addMedicine({
    required String name,
    required String dosage,
    required MedicineFrequency frequency,
    String? instructions,
  }) async {
    final medicine = Medicine(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      dosage: dosage,
      startDate: DateTime.now(),
      frequency: frequency,
      instructions: instructions,
    );
    await _repo.addMedicine(medicine);
    await refresh(showLoading: false);
  }

  Future<void> markTaken(MedicineIntake intake) async {
    final previousToday = state.today;
    state = state.copyWith(
      today: previousToday.map((item) {
        final isTarget =
            item.medicineId == intake.medicineId &&
            item.scheduledAt == intake.scheduledAt;
        if (!isTarget) return item;
        return item.copyWith(takenAt: DateTime.now(), skipped: false);
      }).toList(),
    );

    try {
      await _repo.markTaken(intake.medicineId, intake.scheduledAt);
      final today = await _repo.getTodaySchedule();
      state = state.copyWith(today: today);
    } catch (_) {
      state = state.copyWith(today: previousToday);
    }
  }

  Future<void> markSkipped(MedicineIntake intake) async {
    final previousToday = state.today;
    state = state.copyWith(
      today: previousToday.map((item) {
        final isTarget =
            item.medicineId == intake.medicineId &&
            item.scheduledAt == intake.scheduledAt;
        if (!isTarget) return item;
        return item.copyWith(takenAt: null, skipped: true);
      }).toList(),
    );

    try {
      await _repo.markSkipped(intake.medicineId, intake.scheduledAt);
      final today = await _repo.getTodaySchedule();
      state = state.copyWith(today: today);
    } catch (_) {
      state = state.copyWith(today: previousToday);
    }
  }

}

final medicinesProvider =
    StateNotifierProvider.autoDispose<MedicinesNotifier, MedicinesState>((ref) {
      final repo = ref.watch(medicineRepositoryProvider);
      return MedicinesNotifier(repo);
    });
