import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/cyberpunk_header.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/trading_settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: const CyberpunkHeader(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              '언어 및 지역 설정',
              Icons.language,
              [
                _buildLanguageNavigationTile(context, ref),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              '테마 설정',
              Icons.palette,
              [
                _buildThemeNavigationTile(context, ref),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              '알림 설정',
              Icons.notifications,
              [
                _buildSwitchTile('소리 알림', settings.soundEnabled, (value) {
                  ref.read(settingsProvider.notifier).toggleSound(value);
                }),
                _buildSwitchTile('진동 알림', settings.vibrationEnabled, (value) {
                  ref.read(settingsProvider.notifier).toggleVibration(value);
                }),
                _buildSwitchTile('실시간 데이터 업데이트', settings.dataLiveUpdate, (value) {
                  ref.read(settingsProvider.notifier).toggleDataLiveUpdate(value);
                }),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              '거래 설정',
              Icons.show_chart,
              [
                _buildTradingNavigationTile(context, ref),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              '백업 및 복원',
              Icons.backup,
              [
                _buildSwitchTile('자동 백업', settings.autoBackup, (value) {
                  ref.read(settingsProvider.notifier).toggleAutoBackup(value);
                }),
                _buildBackupFrequencySelector(ref, settings),
                _buildActionTile('설정 내보내기', Icons.file_upload, () {
                  ref.read(settingsProvider.notifier).exportSettings();
                }),
                _buildActionTile('설정 가져오기', Icons.file_download, () async {
                  // 파일 선택 구현
                }),
                _buildActionTile('초기화', Icons.restore, () {
                  _showResetDialog(context, ref);
                }),
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

  Widget _buildLanguageSelector(WidgetRef ref, AppSettings settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.translate, color: AppTheme.accentBlue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('언어', style: AppTheme.bodyLarge.copyWith(color: Colors.white)),
                Text('Language', style: AppTheme.bodySmall),
              ],
            ),
          ),
          DropdownButton<String>(
            value: settings.language,
            dropdownColor: AppTheme.surfaceDark,
            items: const [
              DropdownMenuItem(value: 'ko', child: Text('한국어', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 'ja', child: Text('日本語', style: TextStyle(color: Colors.white))),
            ],
            onChanged: (value) {
              if (value != null) {
                ref.read(settingsProvider.notifier).updateLanguage(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeNavigationTile(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final currentThemeName = _getThemeName(themeState.themeMode);

    return InkWell(
      onTap: () => context.push('/theme-settings'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              themeState.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: AppTheme.accentBlue,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '테마 설정',
                    style: AppTheme.bodyLarge.copyWith(color: Colors.white),
                  ),
                  Text(
                    '현재: $currentThemeName',
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.accentBlue.withValues(alpha: 0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return '라이트 모드';
      case AppThemeMode.dark:
        return '다크 모드';
      case AppThemeMode.system:
        return '시스템 설정';
    }
  }

  Widget _buildLanguageNavigationTile(BuildContext context, WidgetRef ref) {
    final localeState = ref.watch(localeProvider);
    final currencyInfo = getCurrencyInfo(localeState.currency);
    final currentLanguageName = localeState.currentLanguage.displayName;

    return InkWell(
      onTap: () => context.push('/language-settings'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.translate,
              color: AppTheme.accentBlue,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '언어 및 지역',
                    style: AppTheme.bodyLarge.copyWith(color: Colors.white),
                  ),
                  Text(
                    '현재: $currentLanguageName, ${currencyInfo.symbol} ${currencyInfo.code}',
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.accentBlue.withValues(alpha: 0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradingNavigationTile(BuildContext context, WidgetRef ref) {
    final tradingSettings = ref.watch(tradingSettingsProvider);
    final riskLevel = ref.read(tradingSettingsProvider.notifier).getRiskLevel();

    return InkWell(
      onTap: () => context.push('/trading-settings'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.show_chart,
              color: AppTheme.accentBlue,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '거래 설정',
                    style: AppTheme.bodyLarge.copyWith(color: Colors.white),
                  ),
                  Text(
                    '레버리지: ${tradingSettings.maxLeverage.toInt()}x, 리스크: $riskLevel',
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.accentBlue.withValues(alpha: 0.7),
              size: 16,
            ),
          ],
        ),
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

  Widget _buildSliderTile(String title, double value, double min, double max, Function(double) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTheme.bodyLarge.copyWith(color: Colors.white)),
              Text('${value.toStringAsFixed(1)}', style: AppTheme.bodyLarge.copyWith(color: AppTheme.accentBlue)),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) * 2).round(),
            activeColor: AppTheme.accentBlue,
            inactiveColor: AppTheme.surfaceDark,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildBackupFrequencySelector(WidgetRef ref, AppSettings settings) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: AppTheme.accentBlue),
          const SizedBox(width: 16),
          Expanded(
            child: Text('백업 주기', style: AppTheme.bodyLarge.copyWith(color: Colors.white)),
          ),
          DropdownButton<String>(
            value: settings.backupFrequency,
            dropdownColor: AppTheme.surfaceDark,
            items: const [
              DropdownMenuItem(value: 'daily', child: Text('매일', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 'weekly', child: Text('매주', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 'monthly', child: Text('매월', style: TextStyle(color: Colors.white))),
            ],
            onChanged: (value) {
              if (value != null) {
                ref.read(settingsProvider.notifier).updateBackupFrequency(value);
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

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('설정 초기화', style: AppTheme.headingMedium.copyWith(color: Colors.white)),
        content: Text(
          '모든 설정을 기본값으로 초기화하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
          style: AppTheme.bodyMedium.copyWith(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: TextStyle(color: AppTheme.accentBlue)),
          ),
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).resetToDefaults();
              Navigator.pop(context);
            },
            child: Text('초기화', style: TextStyle(color: AppTheme.dangerRed)),
          ),
        ],
      ),
    );
  }
}