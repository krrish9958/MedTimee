import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_application_1/features/medicines/domain/entities/medicine.dart';
import 'package:flutter_application_1/features/medicines/domain/entities/medicine_intake.dart';
import 'package:flutter_application_1/features/medicines/domain/repositories/medicine_repository.dart';
import 'package:flutter_application_1/features/medicines/presentation/providers/medicines_provider.dart';

class FakeMedicineRepository implements MedicineRepository {
  @override
  Future<void> addMedicine(Medicine medicine) async {}

  @override
  Future<List<Medicine>> getMedicines() async => const [];

  @override
  Future<List<MedicineIntake>> getTodaySchedule() async => const [];

  @override
  Future<void> markSkipped(String medicineId, DateTime scheduledAt) async {}

  @override
  Future<void> markTaken(String medicineId, DateTime scheduledAt) async {}
}

void main() {
  testWidgets('App renders tabs', (WidgetTester tester) async {
    final mockAuth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(email: 'test@example.com'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          medicineRepositoryProvider.overrideWithValue(
            FakeMedicineRepository(),
          ),
          firebaseAuthProvider.overrideWithValue(mockAuth),
        ],
        child: const HealthCompanionApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Medicines'), findsOneWidget);
    expect(find.text('Health Logs'), findsOneWidget);
    expect(find.text('Visits'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
  });
}
