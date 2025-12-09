import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

// 보안 설정 데이터 모델
class SecuritySettings {
  final bool twoFactorEnabled;
  final bool biometricEnabled;
  final bool autoLockEnabled;
  final int sessionTimeoutMinutes;
  final bool loginAlertsEnabled;
  final bool deviceTrackingEnabled;
  final bool suspiciousActivityAlertsEnabled;
  final bool whitelistEnabled;
  final List<String> trustedDevices;
  final bool apiAccessLoggingEnabled;
  final bool requirePasswordForTransactions;
  final int maxLoginAttempts;
  final int lockoutDurationMinutes;

  const SecuritySettings({
    required this.twoFactorEnabled,
    required this.biometricEnabled,
    required this.autoLockEnabled,
    required this.sessionTimeoutMinutes,
    required this.loginAlertsEnabled,
    required this.deviceTrackingEnabled,
    required this.suspiciousActivityAlertsEnabled,
    required this.whitelistEnabled,
    required this.trustedDevices,
    required this.apiAccessLoggingEnabled,
    required this.requirePasswordForTransactions,
    required this.maxLoginAttempts,
    required this.lockoutDurationMinutes,
  });

  SecuritySettings copyWith({
    bool? twoFactorEnabled,
    bool? biometricEnabled,
    bool? autoLockEnabled,
    int? sessionTimeoutMinutes,
    bool? loginAlertsEnabled,
    bool? deviceTrackingEnabled,
    bool? suspiciousActivityAlertsEnabled,
    bool? whitelistEnabled,
    List<String>? trustedDevices,
    bool? apiAccessLoggingEnabled,
    bool? requirePasswordForTransactions,
    int? maxLoginAttempts,
    int? lockoutDurationMinutes,
  }) {
    return SecuritySettings(
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      autoLockEnabled: autoLockEnabled ?? this.autoLockEnabled,
      sessionTimeoutMinutes: sessionTimeoutMinutes ?? this.sessionTimeoutMinutes,
      loginAlertsEnabled: loginAlertsEnabled ?? this.loginAlertsEnabled,
      deviceTrackingEnabled: deviceTrackingEnabled ?? this.deviceTrackingEnabled,
      suspiciousActivityAlertsEnabled: suspiciousActivityAlertsEnabled ?? this.suspiciousActivityAlertsEnabled,
      whitelistEnabled: whitelistEnabled ?? this.whitelistEnabled,
      trustedDevices: trustedDevices ?? this.trustedDevices,
      apiAccessLoggingEnabled: apiAccessLoggingEnabled ?? this.apiAccessLoggingEnabled,
      requirePasswordForTransactions: requirePasswordForTransactions ?? this.requirePasswordForTransactions,
      maxLoginAttempts: maxLoginAttempts ?? this.maxLoginAttempts,
      lockoutDurationMinutes: lockoutDurationMinutes ?? this.lockoutDurationMinutes,
    );
  }

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'twoFactorEnabled': twoFactorEnabled,
      'biometricEnabled': biometricEnabled,
      'autoLockEnabled': autoLockEnabled,
      'sessionTimeoutMinutes': sessionTimeoutMinutes,
      'loginAlertsEnabled': loginAlertsEnabled,
      'deviceTrackingEnabled': deviceTrackingEnabled,
      'suspiciousActivityAlertsEnabled': suspiciousActivityAlertsEnabled,
      'whitelistEnabled': whitelistEnabled,
      'trustedDevices': trustedDevices,
      'apiAccessLoggingEnabled': apiAccessLoggingEnabled,
      'requirePasswordForTransactions': requirePasswordForTransactions,
      'maxLoginAttempts': maxLoginAttempts,
      'lockoutDurationMinutes': lockoutDurationMinutes,
    };
  }

  // JSON 역직렬화
  factory SecuritySettings.fromJson(Map<String, dynamic> json) {
    return SecuritySettings(
      twoFactorEnabled: json['twoFactorEnabled'] as bool? ?? false,
      biometricEnabled: json['biometricEnabled'] as bool? ?? false,
      autoLockEnabled: json['autoLockEnabled'] as bool? ?? true,
      sessionTimeoutMinutes: json['sessionTimeoutMinutes'] as int? ?? 30,
      loginAlertsEnabled: json['loginAlertsEnabled'] as bool? ?? true,
      deviceTrackingEnabled: json['deviceTrackingEnabled'] as bool? ?? true,
      suspiciousActivityAlertsEnabled: json['suspiciousActivityAlertsEnabled'] as bool? ?? true,
      whitelistEnabled: json['whitelistEnabled'] as bool? ?? false,
      trustedDevices: (json['trustedDevices'] as List<dynamic>?)?.cast<String>() ?? [],
      apiAccessLoggingEnabled: json['apiAccessLoggingEnabled'] as bool? ?? true,
      requirePasswordForTransactions: json['requirePasswordForTransactions'] as bool? ?? true,
      maxLoginAttempts: json['maxLoginAttempts'] as int? ?? 5,
      lockoutDurationMinutes: json['lockoutDurationMinutes'] as int? ?? 15,
    );
  }

  // 기본값
  static const SecuritySettings defaultSettings = SecuritySettings(
    twoFactorEnabled: false,
    biometricEnabled: false,
    autoLockEnabled: true,
    sessionTimeoutMinutes: 30,
    loginAlertsEnabled: true,
    deviceTrackingEnabled: true,
    suspiciousActivityAlertsEnabled: true,
    whitelistEnabled: false,
    trustedDevices: [],
    apiAccessLoggingEnabled: true,
    requirePasswordForTransactions: true,
    maxLoginAttempts: 5,
    lockoutDurationMinutes: 15,
  );
}

// 생체 인증 상태
enum BiometricStatus {
  notAvailable,
  notEnrolled,
  available,
  enabled,
}

// 보안 레벨 enum
enum SecurityLevel {
  low,
  medium,
  high,
  maximum,
}

// 보안 설정 관리 클래스
class SecuritySettingsNotifier extends StateNotifier<SecuritySettings> {
  SecuritySettingsNotifier() : super(SecuritySettings.defaultSettings) {
    _loadSettings();
    _checkBiometricAvailability();
  }

  static const String _storageKey = 'security_settings';
  final LocalAuthentication _localAuth = LocalAuthentication();

  BiometricStatus _biometricStatus = BiometricStatus.notAvailable;
  BiometricStatus get biometricStatus => _biometricStatus;

  // 설정 로드
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsString = prefs.getString(_storageKey);

      if (settingsString != null) {
        final Map<String, dynamic> settingsMap = {};
        final pairs = settingsString.split('|');

        for (final pair in pairs) {
          final keyValue = pair.split(':');
          if (keyValue.length == 2) {
            final key = keyValue[0];
            final value = keyValue[1];

            if (key == 'trustedDevices') {
              settingsMap[key] = value.split(',').where((s) => s.isNotEmpty).toList();
            } else if (key == 'sessionTimeoutMinutes' || key == 'maxLoginAttempts' || key == 'lockoutDurationMinutes') {
              settingsMap[key] = int.tryParse(value) ?? 0;
            } else {
              settingsMap[key] = value.toLowerCase() == 'true';
            }
          }
        }

        state = SecuritySettings.fromJson(settingsMap);
      }
    } catch (e) {
      print('보안 설정 로드 실패: $e');
      state = SecuritySettings.defaultSettings;
    }
  }

  // 설정 저장
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsMap = state.toJson();
      final settingsString = settingsMap.entries
          .map((entry) => '${entry.key}:${entry.value is List ? (entry.value as List).join(',') : entry.value}')
          .join('|');
      await prefs.setString(_storageKey, settingsString);
    } catch (e) {
      print('보안 설정 저장 실패: $e');
    }
  }

  // 생체 인증 가용성 확인
  Future<void> _checkBiometricAvailability() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!isAvailable || !isDeviceSupported) {
        _biometricStatus = BiometricStatus.notAvailable;
        return;
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        _biometricStatus = BiometricStatus.notEnrolled;
        return;
      }

      _biometricStatus = state.biometricEnabled
          ? BiometricStatus.enabled
          : BiometricStatus.available;
    } catch (e) {
      print('생체 인증 확인 실패: $e');
      _biometricStatus = BiometricStatus.notAvailable;
    }
  }

  // 2FA 토글
  Future<void> toggleTwoFactor(bool enabled) async {
    state = state.copyWith(twoFactorEnabled: enabled);
    await _saveSettings();
  }

  // 생체 인증 토글
  Future<bool> toggleBiometric(bool enabled) async {
    if (!enabled) {
      state = state.copyWith(biometricEnabled: false);
      _biometricStatus = BiometricStatus.available;
      await _saveSettings();
      return true;
    }

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: '생체 인증을 활성화하려면 인증이 필요합니다',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        state = state.copyWith(biometricEnabled: true);
        _biometricStatus = BiometricStatus.enabled;
        await _saveSettings();
        return true;
      }
      return false;
    } catch (e) {
      print('생체 인증 설정 실패: $e');
      return false;
    }
  }

  // 자동 잠금 토글
  Future<void> toggleAutoLock(bool enabled) async {
    state = state.copyWith(autoLockEnabled: enabled);
    await _saveSettings();
  }

  // 세션 타임아웃 설정
  Future<void> updateSessionTimeout(int minutes) async {
    state = state.copyWith(sessionTimeoutMinutes: minutes);
    await _saveSettings();
  }

  // 로그인 알림 토글
  Future<void> toggleLoginAlerts(bool enabled) async {
    state = state.copyWith(loginAlertsEnabled: enabled);
    await _saveSettings();
  }

  // 기기 추적 토글
  Future<void> toggleDeviceTracking(bool enabled) async {
    state = state.copyWith(deviceTrackingEnabled: enabled);
    await _saveSettings();
  }

  // 의심스러운 활동 알림 토글
  Future<void> toggleSuspiciousActivityAlerts(bool enabled) async {
    state = state.copyWith(suspiciousActivityAlertsEnabled: enabled);
    await _saveSettings();
  }

  // 화이트리스트 토글
  Future<void> toggleWhitelist(bool enabled) async {
    state = state.copyWith(whitelistEnabled: enabled);
    await _saveSettings();
  }

  // 신뢰할 수 있는 기기 추가
  Future<void> addTrustedDevice(String deviceId) async {
    final updatedDevices = [...state.trustedDevices, deviceId];
    state = state.copyWith(trustedDevices: updatedDevices);
    await _saveSettings();
  }

  // 신뢰할 수 있는 기기 제거
  Future<void> removeTrustedDevice(String deviceId) async {
    final updatedDevices = state.trustedDevices.where((id) => id != deviceId).toList();
    state = state.copyWith(trustedDevices: updatedDevices);
    await _saveSettings();
  }

  // API 접근 로깅 토글
  Future<void> toggleApiAccessLogging(bool enabled) async {
    state = state.copyWith(apiAccessLoggingEnabled: enabled);
    await _saveSettings();
  }

  // 거래 비밀번호 요구 토글
  Future<void> togglePasswordForTransactions(bool enabled) async {
    state = state.copyWith(requirePasswordForTransactions: enabled);
    await _saveSettings();
  }

  // 최대 로그인 시도 횟수 설정
  Future<void> updateMaxLoginAttempts(int attempts) async {
    state = state.copyWith(maxLoginAttempts: attempts);
    await _saveSettings();
  }

  // 잠금 해제 대기 시간 설정
  Future<void> updateLockoutDuration(int minutes) async {
    state = state.copyWith(lockoutDurationMinutes: minutes);
    await _saveSettings();
  }

  // 모든 설정을 기본값으로 리셋
  Future<void> resetToDefaults() async {
    state = SecuritySettings.defaultSettings;
    await _saveSettings();
    await _checkBiometricAvailability();
  }

  // 보안 레벨 계산
  SecurityLevel getSecurityLevel() {
    int score = 0;

    // 2FA (25점)
    if (state.twoFactorEnabled) score += 25;

    // 생체 인증 (20점)
    if (state.biometricEnabled) score += 20;

    // 자동 잠금 (15점)
    if (state.autoLockEnabled) score += 15;

    // 세션 타임아웃 (10점)
    if (state.sessionTimeoutMinutes <= 15) {
      score += 10;
    } else if (state.sessionTimeoutMinutes <= 30) {
      score += 7;
    } else if (state.sessionTimeoutMinutes <= 60) {
      score += 5;
    }

    // 알림 설정 (10점)
    if (state.loginAlertsEnabled) score += 5;
    if (state.suspiciousActivityAlertsEnabled) score += 5;

    // 기기 추적 (10점)
    if (state.deviceTrackingEnabled) score += 10;

    // 거래 비밀번호 (10점)
    if (state.requirePasswordForTransactions) score += 10;

    // 점수에 따른 보안 레벨 결정 (100점 만점)
    if (score >= 80) return SecurityLevel.maximum;
    if (score >= 60) return SecurityLevel.high;
    if (score >= 40) return SecurityLevel.medium;
    return SecurityLevel.low;
  }

  // 보안 레벨 설명 가져오기
  String getSecurityLevelDescription(bool isKorean) {
    final level = getSecurityLevel();
    switch (level) {
      case SecurityLevel.maximum:
        return isKorean ? '매우 안전' : 'Maximum Security';
      case SecurityLevel.high:
        return isKorean ? '안전' : 'High Security';
      case SecurityLevel.medium:
        return isKorean ? '보통' : 'Medium Security';
      case SecurityLevel.low:
        return isKorean ? '위험' : 'Low Security';
    }
  }

  // 보안 권장사항 가져오기
  List<String> getSecurityRecommendations(bool isKorean) {
    final recommendations = <String>[];

    if (!state.twoFactorEnabled) {
      recommendations.add(isKorean
          ? '2단계 인증을 활성화하세요'
          : 'Enable two-factor authentication');
    }

    if (!state.biometricEnabled && _biometricStatus == BiometricStatus.available) {
      recommendations.add(isKorean
          ? '생체 인증을 설정하세요'
          : 'Set up biometric authentication');
    }

    if (state.sessionTimeoutMinutes > 60) {
      recommendations.add(isKorean
          ? '세션 타임아웃을 줄이세요'
          : 'Reduce session timeout');
    }

    if (!state.loginAlertsEnabled) {
      recommendations.add(isKorean
          ? '로그인 알림을 활성화하세요'
          : 'Enable login alerts');
    }

    if (!state.requirePasswordForTransactions) {
      recommendations.add(isKorean
          ? '거래 시 비밀번호 확인을 활성화하세요'
          : 'Require password for transactions');
    }

    return recommendations;
  }
}

// Provider 정의
final securitySettingsProvider = StateNotifierProvider<SecuritySettingsNotifier, SecuritySettings>((ref) {
  return SecuritySettingsNotifier();
});

// 개별 설정값에 쉽게 접근할 수 있는 Provider들
final twoFactorEnabledProvider = Provider<bool>((ref) {
  return ref.watch(securitySettingsProvider).twoFactorEnabled;
});

final biometricEnabledProvider = Provider<bool>((ref) {
  return ref.watch(securitySettingsProvider).biometricEnabled;
});

final sessionTimeoutProvider = Provider<int>((ref) {
  return ref.watch(securitySettingsProvider).sessionTimeoutMinutes;
});

final securityLevelProvider = Provider<SecurityLevel>((ref) {
  return ref.read(securitySettingsProvider.notifier).getSecurityLevel();
});

final biometricStatusProvider = Provider<BiometricStatus>((ref) {
  return ref.read(securitySettingsProvider.notifier).biometricStatus;
});