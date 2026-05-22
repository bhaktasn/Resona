import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'breathing_engine.dart';
import 'breathing_settings.dart';

final breathingSettingsProvider =
    StateNotifierProvider<BreathingSettingsNotifier, BreathingSettings>((ref) {
  return BreathingSettingsNotifier();
});

class BreathingSettingsNotifier extends StateNotifier<BreathingSettings> {
  BreathingSettingsNotifier() : super(const BreathingSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('breathing_settings');
    if (json != null) {
      state = BreathingSettings.fromJson(jsonDecode(json));
    }
  }

  Future<void> update(BreathingSettings settings) async {
    state = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('breathing_settings', jsonEncode(settings.toJson()));
  }
}

final breathingEngineProvider = Provider<BreathingEngine>((ref) {
  final settings = ref.read(breathingSettingsProvider);
  final engine = BreathingEngine(settings);

  // Push user settings changes to the engine without recreating it
  ref.listen(breathingSettingsProvider, (prev, next) {
    engine.updateSettings(next);
  });

  ref.onDispose(() => engine.dispose());
  return engine;
});
