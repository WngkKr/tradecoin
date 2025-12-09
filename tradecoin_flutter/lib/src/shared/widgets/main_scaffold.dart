import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../features/binance/providers/binance_connection_provider.dart';
import 'neon_bottom_navigation.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const MainScaffold({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  @override
  void initState() {
    super.initState();
    // 앱 시작 시 바이낸스 연결 상태 즉시 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔄 MainScaffold: 바이낸스 연결 상태 초기화 중...');
      ref.read(binanceConnectionProvider.notifier).checkConnectionStatus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateCurrentTab();
  }

  void _updateCurrentTab() {
    final location = GoRouterState.of(context).uri.path;
    NavigationTab currentTab;
    
    switch (location) {
      case '/dashboard':
        currentTab = NavigationTab.home;
        break;
      case '/portfolio':
        currentTab = NavigationTab.portfolio;
        break;
      case '/signals':
        currentTab = NavigationTab.signals;
        break;
      case '/news':
        currentTab = NavigationTab.news;
        break;
      case '/profile':
        currentTab = NavigationTab.profile;
        break;
      default:
        currentTab = NavigationTab.home;
    }

    // Provider 업데이트
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(currentTabProvider.notifier).state = currentTab;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: widget.child,
      ),
      bottomNavigationBar: NeonBottomNavigation(
        onTabChanged: (tab) {
          switch (tab) {
            case NavigationTab.home:
              context.go('/dashboard');
              break;
            case NavigationTab.portfolio:
              context.go('/portfolio');
              break;
            case NavigationTab.signals:
              context.go('/signals');
              break;
            case NavigationTab.news:
              context.go('/news');
              break;
            case NavigationTab.profile:
              context.go('/profile');
              break;
          }
        },
      ),
    );
  }
}