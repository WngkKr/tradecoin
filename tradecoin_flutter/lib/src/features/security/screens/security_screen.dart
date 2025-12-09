import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/cyberpunk_header.dart';
import '../providers/security_provider.dart';

class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final security = ref.watch(securityProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: const CyberpunkHeader(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              '보안 설정',
              Icons.security,
              [
                _buildSwitchTile('2단계 인증 (2FA)', security.twoFactorEnabled, (value) {
                  if (value) {
                    ref.read(securityProvider.notifier).setupTwoFactor();
                  } else {
                    ref.read(securityProvider.notifier).disableTwoFactor();
                  }
                }),
                _buildSwitchTile('생체 인증 (지문/Face ID)', security.biometricEnabled, (value) {
                  if (value) {
                    ref.read(securityProvider.notifier).setupBiometric();
                  } else {
                    ref.read(securityProvider.notifier).toggleBiometric(false);
                  }
                }),
                _buildSwitchTile('세션 타임아웃', security.sessionTimeout, (value) {
                  ref.read(securityProvider.notifier).toggleSessionTimeout(value);
                }),
                if (security.sessionTimeout)
                  _buildSessionTimeoutSelector(ref, security),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              '비밀번호',
              Icons.lock,
              [
                _buildActionTile('비밀번호 변경', Icons.edit, () {
                  _showPasswordChangeDialog(context, ref);
                }),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              '로그인 기록',
              Icons.history,
              [
                ...security.loginHistory.map((record) => _buildLoginRecord(record)).toList(),
                if (security.loginHistory.isEmpty)
                  _buildEmptyState('로그인 기록이 없습니다'),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              '연결된 기기',
              Icons.devices,
              [
                ...security.connectedDevices.map((device) => _buildDeviceCard(context, device, ref)),
                if (security.connectedDevices.isNotEmpty)
                  _buildActionTile('모든 기기 연결 해제', Icons.logout, () {
                    _showRevokeAllDevicesDialog(context, ref);
                  }),
                if (security.connectedDevices.isEmpty)
                  _buildEmptyState('연결된 기기가 없습니다'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassmorphism(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.accentBlue, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.accentBlue,
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

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTheme.bodyLarge.copyWith(color: Colors.white),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.accentBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTimeoutSelector(WidgetRef ref, SecuritySettings security) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.timer, color: AppTheme.accentBlue),
          const SizedBox(width: 16),
          Expanded(
            child: Text('세션 타임아웃 시간', style: AppTheme.bodyLarge.copyWith(color: Colors.white)),
          ),
          DropdownButton<int>(
            value: security.sessionTimeoutMinutes,
            dropdownColor: AppTheme.surfaceDark,
            items: const [
              DropdownMenuItem(value: 15, child: Text('15분', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 30, child: Text('30분', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 60, child: Text('1시간', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 120, child: Text('2시간', style: TextStyle(color: Colors.white))),
            ],
            onChanged: (value) {
              if (value != null) {
                ref.read(securityProvider.notifier).updateSessionTimeout(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.accentBlue),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title, style: AppTheme.bodyLarge.copyWith(color: Colors.white)),
              ),
              Icon(Icons.arrow_forward_ios, color: AppTheme.accentBlue, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginRecord(LoginRecord record) {
    final dateFormatter = DateFormat('yyyy년 MM월 dd일 HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: record.successful
            ? null
            : Border.all(color: AppTheme.dangerRed.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                record.successful ? Icons.check_circle : Icons.error,
                color: record.successful ? AppTheme.successGreen : AppTheme.dangerRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  record.successful ? '로그인 성공' : '로그인 실패',
                  style: AppTheme.bodyMedium.copyWith(
                    color: record.successful ? AppTheme.successGreen : AppTheme.dangerRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                dateFormatter.format(record.timestamp),
                style: AppTheme.bodySmall.copyWith(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.computer, color: AppTheme.accentBlue, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  record.deviceInfo,
                  style: AppTheme.bodySmall.copyWith(color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, color: AppTheme.accentBlue, size: 16),
              const SizedBox(width: 8),
              Text(
                '${record.location} (${record.ipAddress})',
                style: AppTheme.bodySmall.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(BuildContext context, ConnectedDevice device, WidgetRef ref) {
    final dateFormatter = DateFormat('yyyy년 MM월 dd일 HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: device.isCurrentDevice
            ? Border.all(color: AppTheme.accentBlue.withOpacity(0.5))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getDeviceIcon(device.deviceType),
                color: AppTheme.accentBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          device.deviceName,
                          style: AppTheme.bodyLarge.copyWith(color: Colors.white),
                        ),
                        if (device.isCurrentDevice) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accentBlue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.accentBlue.withOpacity(0.5)),
                            ),
                            child: Text(
                              '현재 기기',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.accentBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      device.deviceType,
                      style: AppTheme.bodySmall.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              if (!device.isCurrentDevice)
                IconButton(
                  onPressed: () {
                    SecurityScreen._showRevokeDeviceDialog(context, ref, device);
                  },
                  icon: Icon(Icons.logout, color: AppTheme.dangerRed),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, color: AppTheme.accentBlue, size: 16),
              const SizedBox(width: 8),
              Text(
                '마지막 접근: ${dateFormatter.format(device.lastAccess)}',
                style: AppTheme.bodySmall.copyWith(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, color: AppTheme.accentBlue, size: 16),
              const SizedBox(width: 8),
              Text(
                'IP: ${device.ipAddress}',
                style: AppTheme.bodySmall.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.info_outline, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTheme.bodyMedium.copyWith(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDeviceIcon(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'mobile':
        return Icons.smartphone;
      case 'tablet':
        return Icons.tablet;
      case 'desktop':
        return Icons.computer;
      default:
        return Icons.devices;
    }
  }

  void _showPasswordChangeDialog(BuildContext context, WidgetRef ref) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('비밀번호 변경', style: AppTheme.headingMedium.copyWith(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: '현재 비밀번호',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.accentBlue),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.accentBlue),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: '새 비밀번호',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.accentBlue),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.accentBlue),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: '새 비밀번호 확인',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.accentBlue),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.accentBlue),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: TextStyle(color: AppTheme.accentBlue)),
          ),
          TextButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('새 비밀번호가 일치하지 않습니다')),
                );
                return;
              }

              final success = await ref.read(securityProvider.notifier).changePassword(
                currentPasswordController.text,
                newPasswordController.text,
              );

              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('비밀번호가 성공적으로 변경되었습니다')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('비밀번호 변경에 실패했습니다')),
                );
              }
            },
            child: Text('변경', style: TextStyle(color: AppTheme.successGreen)),
          ),
        ],
      ),
    );
  }

  static void _showRevokeDeviceDialog(BuildContext context, WidgetRef ref, ConnectedDevice device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('기기 연결 해제', style: AppTheme.headingMedium.copyWith(color: Colors.white)),
        content: Text(
          '${device.deviceName} 기기의 연결을 해제하시겠습니까?\n해당 기기에서 다시 로그인해야 합니다.',
          style: AppTheme.bodyMedium.copyWith(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: TextStyle(color: AppTheme.accentBlue)),
          ),
          TextButton(
            onPressed: () {
              ref.read(securityProvider.notifier).revokeDevice(device.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${device.deviceName} 연결이 해제되었습니다')),
              );
            },
            child: Text('해제', style: TextStyle(color: AppTheme.dangerRed)),
          ),
        ],
      ),
    );
  }

  void _showRevokeAllDevicesDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('모든 기기 연결 해제', style: AppTheme.headingMedium.copyWith(color: Colors.white)),
        content: Text(
          '현재 기기를 제외한 모든 기기의 연결을 해제하시겠습니까?\n다른 기기에서 다시 로그인해야 합니다.',
          style: AppTheme.bodyMedium.copyWith(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: TextStyle(color: AppTheme.accentBlue)),
          ),
          TextButton(
            onPressed: () {
              ref.read(securityProvider.notifier).revokeAllDevices();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('모든 기기 연결이 해제되었습니다')),
              );
            },
            child: Text('해제', style: TextStyle(color: AppTheme.dangerRed)),
          ),
        ],
      ),
    );
  }
}