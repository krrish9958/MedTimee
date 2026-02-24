import 'package:isar/isar.dart';

import '../../../../core/services/app_database.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/medicine_intake.dart';
import '../../domain/repositories/medicine_repository.dart';
import '../models/medicine_intake_record.dart';
import '../models/medicine_record.dart';

class IsarMedicineRepository implements MedicineRepository {
  IsarMedicineRepository(this._db, this._notifications, {required String userId})
    : _userId = userId;

  final AppDatabase _db;
  final NotificationService _notifications;
  final String _userId;
  bool _legacyMigrationAttempted = false;
  bool _demoCleanupAttempted = false;

  String get _userPrefix => '$_userId::';

  String _scopeMedicineId(String id) {
    if (id.startsWith(_userPrefix)) return id;
    return '$_userPrefix$id';
  }

  bool _belongsToUser(String medicineId) {
    return medicineId.startsWith(_userPrefix);
  }

  bool _isScoped(String medicineId) {
    return medicineId.contains('::');
  }

  @override
  Future<void> addMedicine(Medicine medicine) async {
    final scopedMedicine = Medicine(
      id: _scopeMedicineId(medicine.id),
      name: medicine.name,
      dosage: medicine.dosage,
      startDate: medicine.startDate,
      frequency: medicine.frequency,
      instructions: medicine.instructions,
    );

    await _db.isar.writeTxn(() async {
      await _db.isar.medicineRecords.put(MedicineRecord.fromEntity(scopedMedicine));
    });

    await _ensureIntakesForMedicineOn(DateTime.now(), scopedMedicine);
  }

  @override
  Future<List<Medicine>> getMedicines() async {
    await _migrateLegacyRecordsIfNeeded();
    await _cleanupSeededDemoMedicinesIfNeeded();

    final records = await _db.isar.medicineRecords
        .where()
        .sortByName()
        .findAll();
    return records
        .where((record) => _belongsToUser(record.id))
        .map((record) => record.toEntity())
        .toList();
  }

  @override
  Future<List<MedicineIntake>> getTodaySchedule() async {
    await _ensureTodayIntakes();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    final intakeRecords = await _db.isar.medicineIntakeRecords
        .filter()
        .scheduledAtBetween(start, end)
        .findAll();
    intakeRecords.removeWhere((record) => !_belongsToUser(record.medicineId));
    intakeRecords.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return intakeRecords.map((record) => record.toEntity()).toList();
  }

  @override
  Future<void> markSkipped(String medicineId, DateTime scheduledAt) async {
    final key = MedicineIntakeRecord.buildKey(
      _scopeMedicineId(medicineId),
      scheduledAt,
    );
    final record = await _db.isar.medicineIntakeRecords
        .filter()
        .keyEqualTo(key)
        .findFirst();
    if (record == null) return;

    record.skipped = true;
    record.takenAt = null;
    await _db.isar.writeTxn(() async {
      await _db.isar.medicineIntakeRecords.put(record);
    });

    await _notifications.cancelReminder(
      _notificationId(record.medicineId, scheduledAt),
    );
  }

  @override
  Future<void> markTaken(String medicineId, DateTime scheduledAt) async {
    final key = MedicineIntakeRecord.buildKey(
      _scopeMedicineId(medicineId),
      scheduledAt,
    );
    final record = await _db.isar.medicineIntakeRecords
        .filter()
        .keyEqualTo(key)
        .findFirst();
    if (record == null) return;

    record.skipped = false;
    record.takenAt = DateTime.now();
    await _db.isar.writeTxn(() async {
      await _db.isar.medicineIntakeRecords.put(record);
    });

    await _notifications.cancelReminder(
      _notificationId(record.medicineId, scheduledAt),
    );
  }

  Future<void> _ensureTodayIntakes() async {
    final medicines = await getMedicines();
    for (final medicine in medicines) {
      await _ensureIntakesForMedicineOn(DateTime.now(), medicine);
    }
  }

  Future<void> _migrateLegacyRecordsIfNeeded() async {
    if (_legacyMigrationAttempted) {
      return;
    }
    _legacyMigrationAttempted = true;

    final legacyMedicines = (await _db.isar.medicineRecords.where().findAll())
        .where((record) => !_isScoped(record.id))
        .toList();
    if (legacyMedicines.isEmpty) {
      return;
    }

    await _db.isar.writeTxn(() async {
      for (final medicineRecord in legacyMedicines) {
        final oldMedicineId = medicineRecord.id;
        final newMedicineId = _scopeMedicineId(oldMedicineId);

        medicineRecord.id = newMedicineId;
        await _db.isar.medicineRecords.put(medicineRecord);

        final intakeRecords = await _db.isar.medicineIntakeRecords
            .filter()
            .medicineIdEqualTo(oldMedicineId)
            .findAll();

        for (final intake in intakeRecords) {
          final scopedKey = MedicineIntakeRecord.buildKey(
            newMedicineId,
            intake.scheduledAt,
          );

          final existingScoped = await _db.isar.medicineIntakeRecords
              .filter()
              .keyEqualTo(scopedKey)
              .findFirst();
          if (existingScoped != null && existingScoped.isarId != intake.isarId) {
            await _db.isar.medicineIntakeRecords.delete(intake.isarId);
            continue;
          }

          intake.medicineId = newMedicineId;
          intake.key = scopedKey;
          await _db.isar.medicineIntakeRecords.put(intake);
        }
      }
    });
  }

  Future<void> _cleanupSeededDemoMedicinesIfNeeded() async {
    if (_demoCleanupAttempted) {
      return;
    }
    _demoCleanupAttempted = true;

    const demoIds = {'demo_omega3', 'demo_vitamin_a'};
    final userMedicines = (await _db.isar.medicineRecords.where().findAll())
        .where((record) => _belongsToUser(record.id))
        .toList();

    final demoMedicines = userMedicines.where((record) {
      final baseId = record.id.substring(_userPrefix.length);
      return demoIds.contains(baseId);
    }).toList();

    if (demoMedicines.isEmpty) {
      return;
    }

    final remindersToCancel = <MedicineIntakeRecord>[];
    await _db.isar.writeTxn(() async {
      for (final medicine in demoMedicines) {
        final intakeRecords = await _db.isar.medicineIntakeRecords
            .filter()
            .medicineIdEqualTo(medicine.id)
            .findAll();
        remindersToCancel.addAll(intakeRecords);
        if (intakeRecords.isNotEmpty) {
          await _db.isar.medicineIntakeRecords.deleteAll(
            intakeRecords.map((e) => e.isarId).toList(),
          );
        }

        await _db.isar.medicineRecords.delete(medicine.isarId);
      }
    });

    for (final intake in remindersToCancel) {
      await _notifications.cancelReminder(
        _notificationId(intake.medicineId, intake.scheduledAt),
      );
    }
  }

  Future<void> _ensureIntakesForMedicineOn(
    DateTime day,
    Medicine medicine,
  ) async {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final slots = medicine.scheduleForDate(dayStart);
    final expectedKeys = slots
        .map((slot) => MedicineIntakeRecord.buildKey(medicine.id, slot))
        .toSet();

    final existingForDay = await _db.isar.medicineIntakeRecords
        .filter()
        .medicineIdEqualTo(medicine.id)
        .scheduledAtBetween(dayStart, dayEnd)
        .findAll();

    final staleRecords = existingForDay
        .where((record) => !expectedKeys.contains(record.key))
        .toList();
    if (staleRecords.isNotEmpty) {
      await _db.isar.writeTxn(() async {
        await _db.isar.medicineIntakeRecords.deleteAll(
          staleRecords.map((e) => e.isarId).toList(),
        );
      });
      for (final stale in staleRecords) {
        await _notifications.cancelReminder(
          _notificationId(stale.medicineId, stale.scheduledAt),
        );
      }
    }

    final toInsert = <MedicineIntakeRecord>[];

    for (final slot in slots) {
      final key = MedicineIntakeRecord.buildKey(medicine.id, slot);
      final exists = existingForDay.any((record) => record.key == key);
      if (exists) continue;

      toInsert.add(
        MedicineIntakeRecord.create(medicineId: medicine.id, scheduledAt: slot),
      );

      await _notifications.scheduleMedicineReminder(
        id: _notificationId(medicine.id, slot),
        medicineName: medicine.name,
        scheduledAt: slot,
      );
    }

    if (toInsert.isEmpty) return;
    await _db.isar.writeTxn(() async {
      await _db.isar.medicineIntakeRecords.putAll(toInsert);
    });
  }

  int _notificationId(String medicineId, DateTime scheduledAt) {
    return (medicineId.hashCode ^ scheduledAt.millisecondsSinceEpoch) &
        0x7fffffff;
  }
}
