import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/local_storage_service.dart';

const _settingsFileName = 'app_settings.json';
const _themeModeKey = 'theme_mode';

Future<ThemeMode> loadSavedThemeMode(LocalStorageService storage) async {
  final settings = await storage.readJsonObject(_settingsFileName);
  final raw = settings[_themeModeKey] as String?;
  if (raw == 'dark') {
    return ThemeMode.dark;
  }
  return ThemeMode.light;
}

final initialThemeModeProvider = Provider<ThemeMode>((ref) {
  return ThemeMode.light;
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._storage, {required ThemeMode initialMode})
    : super(initialMode);

  final LocalStorageService _storage;

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final settings = await _storage.readJsonObject(_settingsFileName);
    settings[_themeModeKey] = mode == ThemeMode.dark ? 'dark' : 'light';
    await _storage.writeJsonObject(_settingsFileName, settings);
  }

  Future<void> toggle(bool darkEnabled) async {
    await setMode(darkEnabled ? ThemeMode.dark : ThemeMode.light);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  final storage = ref.watch(localStorageProvider);
  final initialMode = ref.watch(initialThemeModeProvider);
  return ThemeModeNotifier(storage, initialMode: initialMode);
});
