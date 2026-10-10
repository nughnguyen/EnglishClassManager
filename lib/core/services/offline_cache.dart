import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Small per-user JSON cache used to show the last loaded data without a network.
class OfflineCache {
  static Future<File> _file(String userId, String key) async {
    final directory = await getApplicationDocumentsDirectory();
    final safeUserId = userId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final safeKey = key.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return File('${directory.path}/cache_${safeUserId}_$safeKey.json');
  }

  static Future<void> save(
    String userId,
    String key,
    List<Map<String, dynamic>> rows,
  ) async {
    final file = await _file(userId, key);
    await file.writeAsString(jsonEncode(rows), flush: true);
  }

  static Future<List<Map<String, dynamic>>?> read(
    String userId,
    String key,
  ) async {
    try {
      final file = await _file(userId, key);
      if (!await file.exists()) return null;
      final value = jsonDecode(await file.readAsString()) as List;
      return value
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}
