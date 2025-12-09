import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecuritySettings {
  final bool twoFactorEnabled;
  final bool biometricEnabled;
  final bool sessionTimeout;
  final int sessionTimeoutMinutes;
  final List<LoginRecord> loginHistory;
  final List<ConnectedDevice> connectedDevices;

  const SecuritySettings({
    this.twoFactorEnabled = false,
    this.biometricEnabled = false,
    this.sessionTimeout = true,
    this.sessionTimeoutMinutes = 30,
    this.loginHistory = const [],
    this.connectedDevices = const [],
  });

  SecuritySettings copyWith({
    bool? twoFactorEnabled,
    bool? biometricEnabled,
    bool? sessionTimeout,
    int? sessionTimeoutMinutes,
    List<LoginRecord>? loginHistory,
    List<ConnectedDevice>? connectedDevices,
  }) {
    return SecuritySettings(
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      sessionTimeout: sessionTimeout ?? this.sessionTimeout,
      sessionTimeoutMinutes: sessionTimeoutMinutes ?? this.sessionTimeoutMinutes,
      loginHistory: loginHistory ?? this.loginHistory,
      connectedDevices: connectedDevices ?? this.connectedDevices,
    );
  }
}

class LoginRecord {
  final String id;
  final DateTime timestamp;
  final String ipAddress;
  final String deviceInfo;
  final String location;
  final bool successful;

  const LoginRecord({
    required this.id,
    required this.timestamp,
    required this.ipAddress,
    required this.deviceInfo,
    required this.location,
    required this.successful,
  });
}

class ConnectedDevice {
  final String id;
  final String deviceName;
  final String deviceType;
  final DateTime lastAccess;
  final bool isCurrentDevice;
  final String ipAddress;

  const ConnectedDevice({
    required this.id,
    required this.deviceName,
    required this.deviceType,
    required this.lastAccess,
    required this.isCurrentDevice,
    required this.ipAddress,
  });
}

class SecurityNotifier extends StateNotifier<SecuritySettings> {
  SecurityNotifier() : super(const SecuritySettings()) {
    _loadSecuritySettings();
  }

  void _loadSecuritySettings() {
    // Mock 데이터 로드
    final mockLoginHistory = [
      LoginRecord(
        id: '1',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ipAddress: '192.168.1.100',
        deviceInfo: 'Chrome on macOS',
        location: '서울, 대한민국',
        successful: true,
      ),
      LoginRecord(
        id: '2',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ipAddress: '192.168.1.105',
        deviceInfo: 'Safari on iPhone',
        location: '서울, 대한민국',
        successful: true,
      ),
      LoginRecord(
        id: '3',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        ipAddress: '203.123.45.67',
        deviceInfo: 'Chrome on Windows',
        location: '부산, 대한민국',
        successful: false,
      ),
    ];

    final mockConnectedDevices = [
      ConnectedDevice(
        id: '1',
        deviceName: 'MacBook Pro',
        deviceType: 'Desktop',
        lastAccess: DateTime.now(),
        isCurrentDevice: true,
        ipAddress: '192.168.1.100',
      ),
      ConnectedDevice(
        id: '2',
        deviceName: 'iPhone 15 Pro',
        deviceType: 'Mobile',
        lastAccess: DateTime.now().subtract(const Duration(hours: 5)),
        isCurrentDevice: false,
        ipAddress: '192.168.1.105',
      ),
    ];

    state = state.copyWith(
      loginHistory: mockLoginHistory,
      connectedDevices: mockConnectedDevices,
    );
  }

  Future<void> toggleTwoFactor(bool enabled) async {
    state = state.copyWith(twoFactorEnabled: enabled);
  }

  Future<void> toggleBiometric(bool enabled) async {
    state = state.copyWith(biometricEnabled: enabled);
  }

  Future<void> toggleSessionTimeout(bool enabled) async {
    state = state.copyWith(sessionTimeout: enabled);
  }

  Future<void> updateSessionTimeout(int minutes) async {
    state = state.copyWith(sessionTimeoutMinutes: minutes);
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    // 비밀번호 변경 로직
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }

  Future<void> setupTwoFactor() async {
    // 2단계 인증 설정
    await Future.delayed(const Duration(seconds: 2));
    state = state.copyWith(twoFactorEnabled: true);
  }

  Future<void> disableTwoFactor() async {
    // 2단계 인증 해제
    await Future.delayed(const Duration(seconds: 1));
    state = state.copyWith(twoFactorEnabled: false);
  }

  Future<void> setupBiometric() async {
    // 생체 인증 설정
    await Future.delayed(const Duration(seconds: 1));
    state = state.copyWith(biometricEnabled: true);
  }

  Future<void> revokeDevice(String deviceId) async {
    final updatedDevices = state.connectedDevices
        .where((device) => device.id != deviceId)
        .toList();
    state = state.copyWith(connectedDevices: updatedDevices);
  }

  Future<void> revokeAllDevices() async {
    final currentDevice = state.connectedDevices
        .where((device) => device.isCurrentDevice)
        .toList();
    state = state.copyWith(connectedDevices: currentDevice);
  }
}

final securityProvider = StateNotifierProvider<SecurityNotifier, SecuritySettings>((ref) {
  return SecurityNotifier();
});