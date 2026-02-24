import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart';
import 'app/theme_mode_provider.dart';
import 'core/services/app_database.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final appDatabase = await AppDatabase.create();
  final localStorage = LocalStorageService();
  final initialThemeMode = await loadSavedThemeMode(localStorage);
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(appDatabase),
        localStorageProvider.overrideWithValue(localStorage),
        notificationServiceProvider.overrideWithValue(notificationService),
        initialThemeModeProvider.overrideWithValue(initialThemeMode),
      ],
      child: const HealthCompanionApp(),
    ),
  );
}
