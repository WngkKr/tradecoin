import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/simple_header.dart';
import '../../../core/providers/theme_provider.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: themeState.isDarkMode
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E1B4B),
                  Color(0xFF312E81),
                  Color(0xFF3730A3),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8FAFC),
                  Color(0xFFE2E8F0),
                  Color(0xFFCBD5E1),
                ],
              ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SimpleHeader(title: '테마 설정'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildThemeModeSection(themeState, themeNotifier),
                    const SizedBox(height: 24),
                    _buildPreviewSection(themeState),
                    const SizedBox(height: 24),
                    _buildCustomizationSection(themeState),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeModeSection(ThemeState themeState, ThemeNotifier themeNotifier) {
    return _buildGlassSection(
      title: '🎨 테마 모드',
      isDark: themeState.isDarkMode,
      children: [
        _buildThemeOption(
          title: '라이트 모드',
          subtitle: '밝은 배경과 어두운 텍스트',
          icon: Icons.light_mode,
          selected: themeState.themeMode == AppThemeMode.light,
          onTap: () => themeNotifier.setThemeMode(AppThemeMode.light),
          isDark: themeState.isDarkMode,
        ),
        _buildThemeOption(
          title: '다크 모드',
          subtitle: '어두운 배경과 밝은 텍스트',
          icon: Icons.dark_mode,
          selected: themeState.themeMode == AppThemeMode.dark,
          onTap: () => themeNotifier.setThemeMode(AppThemeMode.dark),
          isDark: themeState.isDarkMode,
        ),
        _buildThemeOption(
          title: '시스템 설정',
          subtitle: '기기 설정에 따라 자동 변경',
          icon: Icons.settings_system_daydream,
          selected: themeState.themeMode == AppThemeMode.system,
          onTap: () => themeNotifier.setThemeMode(AppThemeMode.system),
          isDark: themeState.isDarkMode,
        ),
      ],
    );
  }

  Widget _buildPreviewSection(ThemeState themeState) {
    return _buildGlassSection(
      title: '👀 미리보기',
      isDark: themeState.isDarkMode,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeState.isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: themeState.isDarkMode
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: themeState.isDarkMode
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BTC/USDT',
                      style: TextStyle(
                        color: themeState.isDarkMode ? Colors.white : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$67,234.56',
                          style: TextStyle(
                            color: themeState.isDarkMode
                              ? Colors.white.withValues(alpha: 0.8)
                              : Colors.grey[700],
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '+2.45%',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('매수'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: themeState.isDarkMode
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '매도',
                        style: TextStyle(
                          color: themeState.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomizationSection(ThemeState themeState) {
    return _buildGlassSection(
      title: '🎯 커스터마이징',
      isDark: themeState.isDarkMode,
      children: [
        ListTile(
          leading: Icon(
            Icons.palette,
            color: themeState.isDarkMode ? const Color(0xFF8B5CF6) : const Color(0xFF8B5CF6),
          ),
          title: Text(
            '강조색',
            style: TextStyle(
              color: themeState.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '퍼플 (기본)',
            style: TextStyle(
              color: themeState.isDarkMode
                ? Colors.white.withValues(alpha: 0.7)
                : Colors.grey[600],
              fontSize: 12,
            ),
          ),
          trailing: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
        ListTile(
          leading: Icon(
            Icons.format_size,
            color: themeState.isDarkMode ? const Color(0xFF8B5CF6) : const Color(0xFF8B5CF6),
          ),
          title: Text(
            '글꼴 크기',
            style: TextStyle(
              color: themeState.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '보통',
            style: TextStyle(
              color: themeState.isDarkMode
                ? Colors.white.withValues(alpha: 0.7)
                : Colors.grey[600],
              fontSize: 12,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: themeState.isDarkMode
              ? Colors.white.withValues(alpha: 0.5)
              : Colors.grey[400],
          ),
        ),
        ListTile(
          leading: Icon(
            Icons.opacity,
            color: themeState.isDarkMode ? const Color(0xFF8B5CF6) : const Color(0xFF8B5CF6),
          ),
          title: Text(
            '투명도 효과',
            style: TextStyle(
              color: themeState.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            themeState.isDarkMode ? '활성화됨' : '비활성화됨',
            style: TextStyle(
              color: themeState.isDarkMode
                ? Colors.white.withValues(alpha: 0.7)
                : Colors.grey[600],
              fontSize: 12,
            ),
          ),
          trailing: Switch(
            value: themeState.isDarkMode,
            onChanged: null,
            activeColor: const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected
          ? const Color(0xFF8B5CF6).withValues(alpha: 0.1)
          : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
            ? const Color(0xFF8B5CF6).withValues(alpha: 0.3)
            : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: selected
            ? const Color(0xFF8B5CF6)
            : isDark ? Colors.white.withValues(alpha: 0.7) : Colors.grey[600],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDark
              ? Colors.white.withValues(alpha: 0.7)
              : Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: selected
          ? const Icon(
              Icons.check_circle,
              color: Color(0xFF8B5CF6),
            )
          : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildGlassSection({
    required String title,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.grey.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}