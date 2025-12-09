import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final String language;
  final String theme;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool dataLiveUpdate;
  final double maxLeverage;
  final double stopLossPercentage;
  final double takeProfitPercentage;
  final bool autoBackup;
  final String backupFrequency;

  const AppSettings({
    this.language = 'ko',
    this.theme = 'dark',
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.dataLiveUpdate = true,
    this.maxLeverage = 5.0,
    this.stopLossPercentage = 3.0,
    this.takeProfitPercentage = 10.0,
    this.autoBackup = true,
    this.backupFrequency = 'daily',
  });

  AppSettings copyWith({
    String? language,
    String? theme,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? dataLiveUpdate,
    double? maxLeverage,
    double? stopLossPercentage,
    double? takeProfitPercentage,
    bool? autoBackup,
    String? backupFrequency,
  }) {
    return AppSettings(
      language: language ?? this.language,
      theme: theme ?? this.theme,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      dataLiveUpdate: dataLiveUpdate ?? this.dataLiveUpdate,
      maxLeverage: maxLeverage ?? this.maxLeverage,
      stopLossPercentage: stopLossPercentage ?? this.stopLossPercentage,
      takeProfitPercentage: takeProfitPercentage ?? this.takeProfitPercentage,
      autoBackup: autoBackup ?? this.autoBackup,
      backupFrequency: backupFrequency ?? this.backupFrequency,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'theme': theme,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'dataLiveUpdate': dataLiveUpdate,
      'maxLeverage': maxLeverage,
      'stopLossPercentage': stopLossPercentage,
      'takeProfitPercentage': takeProfitPercentage,
      'autoBackup': autoBackup,
      'backupFrequency': backupFrequency,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      language: json['language'] ?? 'ko',
      theme: json['theme'] ?? 'dark',
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      dataLiveUpdate: json['dataLiveUpdate'] ?? true,
      maxLeverage: (json['maxLeverage'] ?? 5.0).toDouble(),
      stopLossPercentage: (json['stopLossPercentage'] ?? 3.0).toDouble(),
      takeProfitPercentage: (json['takeProfitPercentage'] ?? 10.0).toDouble(),
      autoBackup: json['autoBackup'] ?? true,
      backupFrequency: json['backupFrequency'] ?? 'daily',
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  static const String _settingsKey = 'app_settings';

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null) {
        final settingsMap = Map<String, dynamic>.from(
          // JSON 파싱 시뮬레이션 (실제로는 json.decode 사용)
          <String, dynamic>{},
        );
        state = AppSettings.fromJson(settingsMap);
      }
    } catch (e) {
      // 기본값 유지
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, state.toJson().toString());
    } catch (e) {
      // 에러 처리
    }
  }

  Future<void> updateLanguage(String language) async {
    state = state.copyWith(language: language);
    await _saveSettings();
  }

  Future<void> updateTheme(String theme) async {
    state = state.copyWith(theme: theme);
    await _saveSettings();
  }

  Future<void> toggleSound(bool enabled) async {
    state = state.copyWith(soundEnabled: enabled);
    await _saveSettings();
  }

  Future<void> toggleVibration(bool enabled) async {
    state = state.copyWith(vibrationEnabled: enabled);
    await _saveSettings();
  }

  Future<void> toggleDataLiveUpdate(bool enabled) async {
    state = state.copyWith(dataLiveUpdate: enabled);
    await _saveSettings();
  }

  Future<void> updateMaxLeverage(double leverage) async {
    state = state.copyWith(maxLeverage: leverage);
    await _saveSettings();
  }

  Future<void> updateStopLoss(double percentage) async {
    state = state.copyWith(stopLossPercentage: percentage);
    await _saveSettings();
  }

  Future<void> updateTakeProfit(double percentage) async {
    state = state.copyWith(takeProfitPercentage: percentage);
    await _saveSettings();
  }

  Future<void> toggleAutoBackup(bool enabled) async {
    state = state.copyWith(autoBackup: enabled);
    await _saveSettings();
  }

  Future<void> updateBackupFrequency(String frequency) async {
    state = state.copyWith(backupFrequency: frequency);
    await _saveSettings();
  }

  Future<void> resetToDefaults() async {
    state = const AppSettings();
    await _saveSettings();
  }

  Future<void> exportSettings() async {
    // 설정 내보내기 구현
  }

  Future<void> importSettings(Map<String, dynamic> settings) async {
    state = AppSettings.fromJson(settings);
    await _saveSettings();
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});