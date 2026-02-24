import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final localStorageProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError('localStorageProvider must be overridden in main');
});

class LocalStorageService {
  Future<List<Map<String, dynamic>>> readJsonList(String fileName) async {
    final file = await _fileFor(fileName);
    if (!await file.exists()) return const [];

    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return const [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> writeJsonList(
    String fileName,
    List<Map<String, dynamic>> data,
  ) async {
    final file = await _fileFor(fileName);
    await file.writeAsString(jsonEncode(data));
  }

  Future<void> deleteFile(String fileName) async {
    final file = await _fileFor(fileName);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Map<String, dynamic>> readJsonObject(String fileName) async {
    final file = await _fileFor(fileName);
    if (!await file.exists()) return <String, dynamic>{};

    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return <String, dynamic>{};

    final decoded = jsonDecode(raw);
    if (decoded is! Map) return <String, dynamic>{};
    return Map<String, dynamic>.from(decoded);
  }

  Future<void> writeJsonObject(String fileName, Map<String, dynamic> data) async {
    final file = await _fileFor(fileName);
    await file.writeAsString(jsonEncode(data));
  }

  Future<File> _fileFor(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$fileName');
  }
}
