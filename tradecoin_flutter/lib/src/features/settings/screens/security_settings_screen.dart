import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../providers/security_settings_provider.dart';

class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeState = ref.watch(localeProvider);
    final securitySettings = ref.watch(securitySettingsProvider);
    final isKorean = localeState.currentLanguage == AppLanguage.korean;

    return Scaffold(
      appBar: AppBar(
        title: Text(isKorean ? '보안 설정' : 'Security Settings'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 보안 레벨 현황
            _buildSecurityLevelOverview(context, ref, securitySettings, isKorean),
            const SizedBox(height: 24),

            // 계정 보안
            _buildAccountSecuritySettings(context, ref, securitySettings, isKorean),
            const SizedBox(height: 24),

            // 세션 관리
            _buildSessionManagementSettings(context, ref, securitySettings, isKorean),
            const SizedBox(height: 24),

            // 활동 모니터링
            _buildActivityMonitoringSettings(context, ref, securitySettings, isKorean),
            const SizedBox(height: 24),

            // 고급 보안
            _buildAdvancedSecuritySettings(context, ref, securitySettings, isKorean),
            const SizedBox(height: 24),

            // 보안 권장사항
            _buildSecurityRecommendations(context, ref, isKorean),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityLevelOverview(BuildContext context, WidgetRef ref, SecuritySettings settings, bool isKorean) {
    final securityLevel = ref.read(securitySettingsProvider.notifier).getSecurityLevel();
    final levelDescription = ref.read(securitySettingsProvider.notifier).getSecurityLevelDescription(isKorean);

    Color levelColor;
    IconData levelIcon;

    switch (securityLevel) {
      case SecurityLevel.maximum:
        levelColor = Colors.green;
        levelIcon = Icons.verified_user;
        break;
      case SecurityLevel.high:
        levelColor = Colors.lightGreen;
        levelIcon = Icons.security;
        break;
      case SecurityLevel.medium:
        levelColor = Colors.orange;
        levelIcon = Icons.warning;
        break;
      case SecurityLevel.low:
        levelColor = Colors.red;
        levelIcon = Icons.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: levelColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                levelIcon,
                color: levelColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                isKorean ? '보안 레벨' : 'Security Level',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 보안 레벨 표시
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      levelDescription,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: levelColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isKorean
                          ? '현재 보안 설정에 따른 보안 수준입니다'
                          : 'Security level based on current settings',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  levelIcon,
                  color: levelColor,
                  size: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSecuritySettings(BuildContext context, WidgetRef ref, SecuritySettings settings, bool isKorean) {
    final biometricStatus = ref.read(securitySettingsProvider.notifier).biometricStatus;

    return _buildSettingsSection(
      context,
      title: isKorean ? '계정 보안' : 'Account Security',
      icon: Icons.account_circle,
      children: [
        _buildToggleSetting(
          context,
          ref,
          title: isKorean ? '2단계 인증 (2FA)' : 'Two-Factor Authentication (2FA)',
          value: settings.twoFactorEnabled,
          onChanged: (value) {
            ref.read(securitySettingsProvider.notifier).toggleTwoFactor(value);
          },
          description: isKorean
              ? '로그인 시 추가 인증 단계를 요구합니다'
              : 'Requires additional authentication step during login',
          icon: Icons.verified_user,
        ),
        const SizedBox(height: 16),
        _buildBiometricSetting(context, ref, settings, biometricStatus, isKorean),
        const SizedBox(height: 16),
        _buildToggleSetting(
          context,
          ref,
          title: isKorean ? '거래 시 비밀번호 확인' : 'Password Required for Transactions',
          value: settings.requirePasswordForTransactions,
          onChanged: (value) {
            ref.read(securitySettingsProvider.notifier).togglePasswordForTransactions(value);
          },
          description: isKorean
              ? '모든 거래 실행 전 비밀번호를 확인합니다'
              : 'Requires password confirmation before executing trades',
          icon: Icons.lock,
        ),
      ],
    );
  }

  Widget _buildBiometricSetting(BuildContext context, WidgetRef ref, SecuritySettings settings, BiometricStatus status, bool isKorean) {
    String statusText;
    Color statusColor;
    bool canToggle = false;

    switch (status) {
      case BiometricStatus.notAvailable:
        statusText = isKorean ? '지원되지 않음' : 'Not Available';
        statusColor = Colors.grey;
        break;
      case BiometricStatus.notEnrolled:
        statusText = isKorean ? '기기에 생체정보 등록 필요' : 'Biometric Not Enrolled';
        statusColor = Colors.orange;
        break;
      case BiometricStatus.available:
        statusText = isKorean ? '사용 가능' : 'Available';
        statusColor = Colors.blue;
        canToggle = true;
        break;
      case BiometricStatus.enabled:
        statusText = isKorean ? '활성화됨' : 'Enabled';
        statusColor = Colors.green;
        canToggle = true;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.fingerprint,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isKorean ? '생체 인증' : 'Biometric Authentication',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: settings.biometricEnabled,
              onChanged: canToggle ? (value) async {
                final success = await ref.read(securitySettingsProvider.notifier).toggleBiometric(value);
                if (!success && value) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isKorean ? '생체 인증 설정에 실패했습니다' : 'Failed to enable biometric authentication',
                        ),
                      ),
                    );
                  }
                }
              } : null,
            ),
          ],
        ),
        if (status != BiometricStatus.notAvailable) ...[
          const SizedBox(height: 8),
          Text(
            isKorean
                ? '지문, 얼굴 인식 등으로 빠르고 안전하게 로그인할 수 있습니다'
                : 'Login quickly and securely using fingerprint, face recognition, etc.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSessionManagementSettings(BuildContext context, WidgetRef ref, SecuritySettings settings, bool isKorean) {
    return _buildSettingsSection(
      context,
      title: isKorean ? '세션 관리' : 'Session Management',
      icon: Icons.access_time,
      children: [
        _buildToggleSetting(
          context,
          ref,
          title: isKorean ? '자동 잠금' : 'Auto Lock',
          value: settings.autoLockEnabled,
          onChanged: (value) {
            ref.read(securitySettingsProvider.notifier).toggleAutoLock(value);
          },
          description: isKorean
              ? '일정 시간 비활성 후 자동으로 잠금 처리합니다'
              : 'Automatically locks after period of inactivity',
          icon: Icons.lock_clock,
        ),
        const SizedBox(height: 16),
        _buildSliderSetting(
          context,
          ref,
          title: isKorean ? '세션 타임아웃' : 'Session Timeout',
          value: settings.sessionTimeoutMinutes.toDouble(),
          min: 5.0,
          max: 120.0,
          divisions: 23,
          suffix: isKorean ? '분' : ' min',
          onChanged: (value) {
            ref.read(securitySettingsProvider.notifier).updateSessionTimeout(value.toInt());
          },
          description: isKorean
              ? '비활성 상태가 지속되면 자동으로 로그아웃됩니다'
              : 'Automatically logs out after inactivity period',
        ),
        const SizedBox(height: 16),
        _buildSliderSetting(
          context,
          ref,
          title: isKorean ? '최대 로그인 시도 횟수' : 'Max Login Attempts',
          value: settings.maxLoginAttempts.toDouble(),
          min: 3.0,
          max: 10.0,
          divisions: 7,
          suffix: isKorean ? '회' : '',
          onChanged: (value) {
            ref.read(securitySettingsProvider.notifier).updateMaxLoginAttempts(value.toInt());
          },
          description: isKorean
              ? '로그인 실패 시 계정이 일시적으로 잠깁니다'
              : 'Account temporarily locked after failed attempts',
        ),
      ],
    );
  }

  Widget _buildActivityMonitoringSettings(BuildContext context, WidgetRef ref, SecuritySettings settings, bool isKorean) {
    return _buildSettingsSection(
      context,
      title: isKorean ? '활동 모니터링' : 'Activity Monitoring',
      icon: Icons.monitor,
      children: [
        _buildToggleSetting(
          context,
          ref,
          title: isKorean ? '로그인 알림' : 'Login Alerts',
          value: settings.loginAlertsEnabled,
          onChanged: (value) {
            ref.read(securitySettingsProvider.notifier).toggleLoginAlerts(value);
          },
          description: isKorean
              ? '새로운 기기에서 로그인 시 알림을 받습니다'
              : 'Get notified when logging in from new devices',
          icon: Icons.notification_important,
        ),
        const SizedBox(height: 16),
        _buildToggleSetting(
          context,
          ref,
          title: isKorean ? '기기 추적' : 'Device Tracking',
          value: settings.deviceTrackingEnabled,
          onChanged: (value) {
            ref.read(securitySettingsProvider.notifier).toggleDeviceTracking(value);
          },
          description: isKorean
              ? '로그인한 기기들을 추적하고 관리합니다'
              : 'Track and manage logged-in devices',
          icon: Icons.devices,
        ),
        const SizedBox(height: 16),
        _buildToggleSetting(
          context,
          ref,
          title: isKorean ? '의심스러운 활동 알림' : 'Suspicious Activity Alerts',
          value: settings.suspiciousActivityAlertsEnabled,
          onChanged: (value) {
            ref.read(securitySettingsProvider.notifier).toggleSuspiciousActivityAlerts(value);
          },
          description: isKorean
              ? '비정상적인 활동 감지 시 즉시 알림을 받습니다'
              : 'Get immediate alerts for suspicious activities',
          icon: Icons.security,
        ),
        const SizedBox(height: 16),
        _buildToggleSetting(
          context,
          ref,
          title: isKorean ? 'API 접근 로깅' : 'API Access Logging',
          value: settings.apiAccessLoggingEnabled,
          onChanged: (value) {
            ref.read(securitySettingsProvider.notifier).toggleApiAccessLogging(value);
          },
          description: isKorean
              ? '모든 API 접근을 기록하고 모니터링합니다'
              : 'Log and monitor all API access',
          icon: Icons.api,
        ),
      ],
    );
  }

  Widget _buildAdvancedSecuritySettings(BuildContext context, WidgetRef ref, SecuritySettings settings, bool isKorean) {
    return _buildSettingsSection(
      context,
      title: isKorean ? '고급 보안' : 'Advanced Security',
      icon: Icons.shield,
      children: [
        _buildToggleSetting(
          context,
          ref,
          title: isKorean ? '화이트리스트 기능' : 'Whitelist Feature',
          value: settings.whitelistEnabled,
          onChanged: (value) {
            ref.read(securitySettingsProvider.notifier).toggleWhitelist(value);
          },
          description: isKorean
              ? '승인된 기기에서만 접근을 허용합니다'
              : 'Only allow access from approved devices',
          icon: Icons.verified,
        ),
        const SizedBox(height: 16),
        _buildTrustedDevicesSection(context, ref, settings, isKorean),
        const SizedBox(height: 16),
        _buildActionButton(
          context,
          title: isKorean ? '모든 기기에서 로그아웃' : 'Logout from All Devices',
          icon: Icons.logout,
          color: Colors.orange,
          onTap: () => _showLogoutAllDialog(context, isKorean),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          title: isKorean ? '보안 설정 초기화' : 'Reset Security Settings',
          icon: Icons.restore,
          color: Colors.red,
          onTap: () => _showResetDialog(context, ref, isKorean),
        ),
      ],
    );
  }

  Widget _buildTrustedDevicesSection(BuildContext context, WidgetRef ref, SecuritySettings settings, bool isKorean) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.devices_other,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isKorean ? '신뢰할 수 있는 기기' : 'Trusted Devices',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${settings.trustedDevices.length}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          isKorean
              ? '현재 기기를 신뢰할 수 있는 기기로 등록하거나 관리할 수 있습니다'
              : 'Register current device as trusted or manage existing ones',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
        if (settings.trustedDevices.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isKorean ? '신뢰할 수 있는 기기 목록을 관리하려면 탭하세요' : 'Tap to manage trusted devices',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSecurityRecommendations(BuildContext context, WidgetRef ref, bool isKorean) {
    final recommendations = ref.read(securitySettingsProvider.notifier).getSecurityRecommendations(isKorean);

    if (recommendations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isKorean ? '모든 보안 권장사항이 적용되었습니다!' : 'All security recommendations are applied!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isKorean ? '보안 권장사항' : 'Security Recommendations',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recommendations.map((recommendation) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: Colors.orange)),
                Expanded(
                  child: Text(
                    recommendation,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildToggleSetting(BuildContext context, WidgetRef ref, {
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? description,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSliderSetting(BuildContext context, WidgetRef ref, {
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String suffix,
    required ValueChanged<double> onChanged,
    String? description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.toStringAsFixed(0)}$suffix',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
        if (description != null) ...[
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  void _showLogoutAllDialog(BuildContext context, bool isKorean) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isKorean ? '모든 기기에서 로그아웃' : 'Logout from All Devices'),
        content: Text(
          isKorean
              ? '모든 기기에서 로그아웃하시겠습니까? 다시 로그인해야 합니다.'
              : 'Logout from all devices? You will need to login again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isKorean ? '취소' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 모든 기기에서 로그아웃 구현
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isKorean ? '모든 기기에서 로그아웃되었습니다' : 'Logged out from all devices',
                  ),
                ),
              );
            },
            child: Text(
              isKorean ? '로그아웃' : 'Logout',
              style: const TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref, bool isKorean) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isKorean ? '보안 설정 초기화' : 'Reset Security Settings'),
        content: Text(
          isKorean
              ? '모든 보안 설정을 기본값으로 초기화하시겠습니까?'
              : 'Reset all security settings to default values?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isKorean ? '취소' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(securitySettingsProvider.notifier).resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isKorean ? '보안 설정이 초기화되었습니다' : 'Security settings have been reset',
                  ),
                ),
              );
            },
            child: Text(
              isKorean ? '초기화' : 'Reset',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}