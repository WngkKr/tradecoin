import 'package:flutter/material.dart' as material;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/settings_service.dart';
import '../models/settings_model.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  late NotificationSettings _settings;
  bool _isLoading = true;
  bool _isSaving = false;
  final SettingsService _settingsService = SettingsService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.userData?.uid ?? 'test_user';

      final settings = await _settingsService.getNotificationSettings(userId);
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _settings = NotificationSettings.defaultSettings();
        _isLoading = false;
      });

      if (mounted) {
        material.ScaffoldMessenger.of(context).showSnackBar(
          material.SnackBar(
            content: material.Text('설정 로드 실패: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.userData?.uid ?? 'test_user';

      final success = await _settingsService.updateNotificationSettings(userId, _settings);

      if (success) {
        if (mounted) {
          material.ScaffoldMessenger.of(context).showSnackBar(
            const material.SnackBar(
              content: material.Text('알림 설정이 저장되었습니다.'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      } else {
        throw Exception('설정 저장 실패');
      }
    } catch (e) {
      if (mounted) {
        material.ScaffoldMessenger.of(context).showSnackBar(
          material.SnackBar(
            content: material.Text('설정 저장 실패: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  material.Widget build(material.BuildContext context) {
    return material.Scaffold(
      appBar: material.AppBar(
        title: const material.Text('알림 설정'),
        backgroundColor: const material.Color(0xFF1E1B4B),
        foregroundColor: material.Colors.white,
        actions: [
          if (!_isLoading)
            material.IconButton(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving
                  ? const material.SizedBox(
                      width: 20,
                      height: 20,
                      child: material.CircularProgressIndicator(
                        strokeWidth: 2,
                        color: material.Colors.white,
                      ),
                    )
                  : const material.Icon(material.Icons.save),
              tooltip: '설정 저장',
            ),
        ],
      ),
      body: material.Container(
        decoration: const material.BoxDecoration(
          gradient: material.LinearGradient(
            begin: material.Alignment.topLeft,
            end: material.Alignment.bottomRight,
            colors: [
              material.Color(0xFF1E1B4B),
              material.Color(0xFF312E81),
              material.Color(0xFF3730A3),
            ],
          ),
        ),
        child: _isLoading
            ? const material.Center(
                child: material.CircularProgressIndicator(
                  valueColor: material.AlwaysStoppedAnimation<material.Color>(AppTheme.accentBlue),
                ),
              )
            : material.SingleChildScrollView(
                padding: const material.EdgeInsets.all(16),
                child: material.Column(
                  crossAxisAlignment: material.CrossAxisAlignment.start,
                  children: [
                    // 기본 알림 설정
                    _buildBasicNotifications(),
                    const material.SizedBox(height: 24),

                    // 알림 타입별 설정
                    _buildNotificationTypes(),
                    const material.SizedBox(height: 24),

                    // 신뢰도 임계값 설정
                    _buildConfidenceThreshold(),
                    const material.SizedBox(height: 24),

                    // 방해 금지 시간 설정
                    _buildQuietHours(),
                    const material.SizedBox(height: 100),
                  ],
                ),
              ),
      ),
    );
  }

  material.Widget _buildBasicNotifications() {
    return material.Container(
      padding: const material.EdgeInsets.all(24),
      decoration: AppTheme.glassmorphism(),
      child: material.Column(
        crossAxisAlignment: material.CrossAxisAlignment.start,
        children: [
          material.Text(
            '기본 알림 설정',
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.accentBlue,
            ),
          ),
          const material.SizedBox(height: 16),

          _buildSwitchTile(
            icon: material.Icons.notifications,
            title: '푸시 알림',
            subtitle: '실시간 알림을 휴대폰으로 받습니다',
            value: _settings.pushEnabled,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(pushEnabled: value);
              });
            },
          ),

          _buildSwitchTile(
            icon: material.Icons.email,
            title: '이메일 알림',
            subtitle: '중요한 알림을 이메일로 받습니다',
            value: _settings.emailEnabled,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(emailEnabled: value);
              });
            },
          ),

          _buildSwitchTile(
            icon: material.Icons.sms,
            title: 'SMS 알림',
            subtitle: '긴급 알림을 SMS로 받습니다',
            value: _settings.smsEnabled,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(smsEnabled: value);
              });
            },
          ),
        ],
      ),
    );
  }

  material.Widget _buildNotificationTypes() {
    return material.Container(
      padding: const material.EdgeInsets.all(24),
      decoration: AppTheme.glassmorphism(),
      child: material.Column(
        crossAxisAlignment: material.CrossAxisAlignment.start,
        children: [
          material.Text(
            '알림 타입',
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.primaryBlue,
            ),
          ),
          const material.SizedBox(height: 16),

          _buildSwitchTile(
            icon: material.Icons.price_change,
            title: '가격 알림',
            subtitle: '설정한 가격 도달 시 알림',
            value: _settings.priceAlerts,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(priceAlerts: value);
              });
            },
          ),

          _buildSwitchTile(
            icon: material.Icons.trending_up,
            title: '시그널 알림',
            subtitle: '새로운 거래 시그널 발생 시 알림',
            value: _settings.signalAlerts,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(signalAlerts: value);
              });
            },
          ),

          _buildSwitchTile(
            icon: material.Icons.newspaper,
            title: '뉴스 알림',
            subtitle: '중요한 시장 뉴스 알림',
            value: _settings.newsAlerts,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(newsAlerts: value);
              });
            },
          ),

          _buildSwitchTile(
            icon: material.Icons.account_balance_wallet,
            title: '포트폴리오 알림',
            subtitle: '포트폴리오 변동 사항 알림',
            value: _settings.portfolioAlerts,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(portfolioAlerts: value);
              });
            },
          ),

          _buildSwitchTile(
            icon: material.Icons.swap_horiz,
            title: '거래 알림',
            subtitle: '거래 체결 및 상태 변경 알림',
            value: _settings.tradingAlerts,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(tradingAlerts: value);
              });
            },
          ),
        ],
      ),
    );
  }

  material.Widget _buildConfidenceThreshold() {
    return material.Container(
      padding: const material.EdgeInsets.all(24),
      decoration: AppTheme.glassmorphism(),
      child: material.Column(
        crossAxisAlignment: material.CrossAxisAlignment.start,
        children: [
          material.Text(
            '신뢰도 임계값',
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.accentBlue,
            ),
          ),
          const material.SizedBox(height: 16),
          material.Row(
            mainAxisAlignment: material.MainAxisAlignment.spaceBetween,
            children: [
              material.Text(
                '최소 신뢰도 설정',
                style: AppTheme.bodyMedium.copyWith(
                  color: material.Colors.white.withValues(alpha: 0.8),
                ),
              ),
              material.Container(
                padding: const material.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: material.BoxDecoration(
                  gradient: const material.LinearGradient(
                    colors: [material.Color(0xFF8B5CF6), material.Color(0xFFA855F7)],
                  ),
                  borderRadius: material.BorderRadius.circular(8),
                ),
                child: material.Text(
                  '${_settings.confidenceThreshold.round()}%',
                  style: const material.TextStyle(
                    color: material.Colors.white,
                    fontWeight: material.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const material.SizedBox(height: 8),
          material.Text(
            '${_settings.confidenceThreshold.round()}% 이상의 신뢰도를 가진 시그널만 알림',
            style: AppTheme.bodySmall.copyWith(
              color: material.Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const material.SizedBox(height: 16),
          material.SliderTheme(
            data: material.SliderTheme.of(context).copyWith(
              activeTrackColor: const material.Color(0xFF8B5CF6),
              inactiveTrackColor: material.Colors.white.withValues(alpha: 0.2),
              thumbColor: const material.Color(0xFFA855F7),
              overlayColor: const material.Color(0xFF8B5CF6).withValues(alpha: 0.3),
              trackHeight: 4,
              thumbShape: const material.RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: material.Slider(
              value: _settings.confidenceThreshold,
              min: 50,
              max: 95,
              divisions: 9,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(confidenceThreshold: value);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  material.Widget _buildQuietHours() {
    return material.Container(
      padding: const material.EdgeInsets.all(24),
      decoration: AppTheme.glassmorphism(),
      child: material.Column(
        crossAxisAlignment: material.CrossAxisAlignment.start,
        children: [
          material.Text(
            '방해 금지 시간',
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.primaryBlue,
            ),
          ),
          const material.SizedBox(height: 16),
          _buildSwitchTile(
            icon: material.Icons.nights_stay,
            title: '방해금지 모드',
            subtitle: '설정한 시간 동안 알림 차단',
            value: _settings.quietHoursEnabled,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(quietHoursEnabled: value);
              });
            },
          ),
          if (_settings.quietHoursEnabled) ...[
            const material.SizedBox(height: 16),
            const material.Divider(color: material.Colors.white24),
            const material.SizedBox(height: 16),
            _buildTimeTile(
              title: '시작 시간',
              time: _settings.quietStartTime,
              onTap: () => _selectTime(context, true),
            ),
            const material.SizedBox(height: 8),
            _buildTimeTile(
              title: '종료 시간',
              time: _settings.quietEndTime,
              onTap: () => _selectTime(context, false),
            ),
          ],
        ],
      ),
    );
  }

  material.Widget _buildSwitchTile({
    required material.IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required material.ValueChanged<bool> onChanged,
  }) {
    return material.ListTile(
      leading: material.Icon(icon, color: const material.Color(0xFF8B5CF6)),
      title: material.Text(
        title,
        style: const material.TextStyle(
          color: material.Colors.white,
          fontWeight: material.FontWeight.w600,
        ),
      ),
      subtitle: material.Text(
        subtitle,
        style: material.TextStyle(
          color: material.Colors.white.withValues(alpha: 0.7),
          fontSize: 12,
        ),
      ),
      trailing: material.Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: const material.Color(0xFF8B5CF6),
        activeTrackColor: const material.Color(0xFFA855F7).withValues(alpha: 0.5),
        inactiveThumbColor: material.Colors.grey,
        inactiveTrackColor: material.Colors.grey.withValues(alpha: 0.3),
      ),
    );
  }

  material.Widget _buildTimeTile({
    required String title,
    required TimeOfDay time,
    required material.VoidCallback onTap,
  }) {
    return material.ListTile(
      leading: const material.Icon(material.Icons.access_time, color: material.Color(0xFF8B5CF6)),
      title: material.Text(
        title,
        style: const material.TextStyle(
          color: material.Colors.white,
          fontWeight: material.FontWeight.w600,
        ),
      ),
      trailing: material.Container(
        padding: const material.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: material.BoxDecoration(
          color: material.Colors.white.withValues(alpha: 0.1),
          borderRadius: material.BorderRadius.circular(8),
          border: material.Border.all(color: material.Colors.white.withValues(alpha: 0.2)),
        ),
        child: material.Text(
          time.toString(),
          style: const material.TextStyle(
            color: material.Colors.white,
            fontWeight: material.FontWeight.w600,
          ),
        ),
      ),
      onTap: onTap,
    );
  }

  Future<void> _selectTime(material.BuildContext context, bool isStartTime) async {
    final currentTime = isStartTime ? _settings.quietStartTime : _settings.quietEndTime;
    final material.TimeOfDay? picked = await material.showTimePicker(
      context: context,
      initialTime: material.TimeOfDay(hour: currentTime.hour, minute: currentTime.minute),
      builder: (context, child) {
        return material.Theme(
          data: material.Theme.of(context).copyWith(
            colorScheme: const material.ColorScheme.dark(
              primary: material.Color(0xFF8B5CF6),
              surface: material.Color(0xFF1E1B4B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final newTime = TimeOfDay(hour: picked.hour, minute: picked.minute);
      setState(() {
        if (isStartTime) {
          _settings = _settings.copyWith(quietStartTime: newTime);
        } else {
          _settings = _settings.copyWith(quietEndTime: newTime);
        }
      });
    }
  }
}