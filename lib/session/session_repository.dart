import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'session_model.dart';

class SessionRepository {
  static const _key = 'sessions';

  static Future<void> save(SessionSummary session) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await loadAll();
    sessions.add(session);
    final json = sessions.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_key, json);
  }

  static Future<List<SessionSummary>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getStringList(_key) ?? [];
    return json.map((s) => SessionSummary.fromJson(jsonDecode(s))).toList();
  }

  static Future<void> deleteAt(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await loadAll();
    if (index >= 0 && index < sessions.length) {
      sessions.removeAt(index);
      final json = sessions.map((s) => jsonEncode(s.toJson())).toList();
      await prefs.setStringList(_key, json);
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
