import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/portfolio/screens/portfolio_screen.dart';
import '../../features/signals/screens/signals_screen.dart';
import '../../features/news/screens/news_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/theme_settings_screen.dart';
import '../../features/settings/screens/language_settings_screen.dart';
import '../../features/settings/screens/enhanced_trading_settings_screen.dart';
import '../../features/settings/screens/security_settings_screen.dart';
import '../../features/profile/screens/profile_edit_screen.dart';
import '../../features/security/screens/security_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/debug/screens/api_test_screen.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../../features/auth/providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(ref.watch(authStateProvider.notifier).stream),
    redirect: (context, state) {
      // ProviderContainer를 사용해서 현재 인증 상태 가져오기
      final container = ProviderScope.containerOf(context);
      final authState = container.read(authStateProvider);

      final isLoading = authState.status == AuthStatus.loading;
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isLoginPage = state.matchedLocation == '/login' || state.matchedLocation == '/';
      final isSignupPage = state.matchedLocation == '/signup';

      // 로딩 중이면 로그인 화면 유지
      if (isLoading) {
        return '/login';
      }

      // 인증되었으면
      if (isAuthenticated) {
        // 로그인/회원가입 페이지에 있다면 시그널 화면으로 이동
        if (isLoginPage || isSignupPage) {
          print('✅ [라우터] 세션 유지됨 → 시그널 화면으로 자동 이동');
          return '/signals';
        }
        // 이미 다른 페이지면 그대로 유지
        return null;
      }

      // 인증되지 않았으면
      // 로그인/회원가입 페이지가 아니면 로그인으로 이동
      if (!isLoginPage && !isSignupPage) {
        print('⚠️ [라우터] 세션 없음 → 로그인 화면으로 이동');
        return '/login';
      }

      return null;
    },
    routes: [
      // 로그인 라우트
      GoRoute(
        path: '/',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // 회원가입 라우트
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      
      // 메인 앱 라우트 (하단 네비게이션 포함)
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/portfolio',
            builder: (context, state) => const PortfolioScreen(),
          ),
          GoRoute(
            path: '/signals',
            builder: (context, state) => const SignalsScreen(),
          ),
          GoRoute(
            path: '/news',
            builder: (context, state) => const NewsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // 전체 화면 라우트 (설정, 보안, 알림)
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/security',
        builder: (context, state) => const SecuritySettingsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/theme-settings',
        builder: (context, state) => const ThemeSettingsScreen(),
      ),
      GoRoute(
        path: '/language-settings',
        builder: (context, state) => const LanguageSettingsScreen(),
      ),
      GoRoute(
        path: '/trading-settings',
        builder: (context, state) => const EnhancedTradingSettingsScreen(),
      ),
      GoRoute(
        path: '/profile-edit',
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: '/api-test',
        builder: (context, state) => const ApiTestScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.uri.toString()}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});

// GoRouter용 Stream 리스너 헬퍼 클래스
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (_) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}