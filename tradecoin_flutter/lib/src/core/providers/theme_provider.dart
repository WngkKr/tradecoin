import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 테마 모드 enum
enum AppThemeMode {
  light,
  dark,
  system,
}

// 테마 상태 클래스
class ThemeState {
  final AppThemeMode themeMode;
  final bool isDarkMode;
  final ThemeData lightTheme;
  final ThemeData darkTheme;

  const ThemeState({
    required this.themeMode,
    required this.isDarkMode,
    required this.lightTheme,
    required this.darkTheme,
  });

  ThemeState copyWith({
    AppThemeMode? themeMode,
    bool? isDarkMode,
    ThemeData? lightTheme,
    ThemeData? darkTheme,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      lightTheme: lightTheme ?? this.lightTheme,
      darkTheme: darkTheme ?? this.darkTheme,
    );
  }
}

// 테마 프로바이더
class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(ThemeState(
    themeMode: AppThemeMode.dark,
    isDarkMode: true,
    lightTheme: _createLightTheme(),
    darkTheme: _createDarkTheme(),
  )) {
    _loadThemePreference();
  }

  // 테마 설정 로드
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeIndex = prefs.getInt('theme_mode') ?? 1; // 기본값: dark
      final themeMode = AppThemeMode.values[savedThemeIndex];

      await setThemeMode(themeMode);
    } catch (e) {
      print('테마 설정 로드 실패: $e');
    }
  }

  // 테마 모드 변경
  Future<void> setThemeMode(AppThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme_mode', mode.index);

      bool isDark;
      switch (mode) {
        case AppThemeMode.light:
          isDark = false;
          break;
        case AppThemeMode.dark:
          isDark = true;
          break;
        case AppThemeMode.system:
          // 시스템 테마 감지 (기본적으로 다크 모드 선호)
          isDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
          break;
      }

      state = state.copyWith(
        themeMode: mode,
        isDarkMode: isDark,
      );
    } catch (e) {
      print('테마 설정 저장 실패: $e');
    }
  }

  // 라이트 테마 생성
  static ThemeData _createLightTheme() {
    const primaryColor = Color(0xFF8B5CF6);
    const surfaceColor = Color(0xFFF8FAFC);
    const backgroundColor = Color(0xFFFFFFFF);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: MaterialColor(0xFF8B5CF6, {
        50: Color(0xFFF5F3FF),
        100: Color(0xFFEDE9FE),
        200: Color(0xFFDDD6FE),
        300: Color(0xFFC4B5FD),
        400: Color(0xFFA78BFA),
        500: Color(0xFF8B5CF6),
        600: Color(0xFF7C3AED),
        700: Color(0xFF6D28D9),
        800: Color(0xFF5B21B6),
        900: Color(0xFF4C1D95),
      }),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: surfaceColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: Color(0xFF1F2937),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF6B7280)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: Color(0xFF6B7280),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: const CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: Color(0xFF1F2937),
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: Color(0xFF1F2937),
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: Color(0xFF1F2937),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFF374151),
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 14,
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: Color(0xFFA855F7),
        surface: surfaceColor,
        error: Color(0xFFEF4444),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1F2937),
        onError: Colors.white,
      ),
    );
  }

  // 다크 테마 생성 (기존 글래스모피즘 스타일 유지)
  static ThemeData _createDarkTheme() {
    const primaryColor = Color(0xFF8B5CF6);
    const surfaceColor = Color(0xFF1E293B);
    const backgroundColor = Color(0xFF0F172A);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: MaterialColor(0xFF8B5CF6, {
        50: Color(0xFF4C1D95),
        100: Color(0xFF5B21B6),
        200: Color(0xFF6D28D9),
        300: Color(0xFF7C3AED),
        400: Color(0xFF8B5CF6),
        500: Color(0xFFA78BFA),
        600: Color(0xFFC4B5FD),
        700: Color(0xFFDDD6FE),
        800: Color(0xFFEDE9FE),
        900: Color(0xFFF5F3FF),
      }),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: surfaceColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFFE2E8F0)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E293B),
        selectedItemColor: primaryColor,
        unselectedItemColor: Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryColor.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF334155),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 14,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: Color(0xFFA855F7),
        surface: surfaceColor,
        error: Color(0xFFEF4444),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
    );
  }
}

// 테마 프로바이더 정의
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

// 현재 테마 모드만 접근하는 프로바이더
final currentThemeModeProvider = Provider<AppThemeMode>((ref) {
  return ref.watch(themeProvider).themeMode;
});

// 다크 모드 여부만 접근하는 프로바이더
final isDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(themeProvider).isDarkMode;
});