import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

import '../../core/theme/app_theme.dart';

enum NavigationTab {
  home(
    label: '홈',
    icon: Icons.home,
    activeIcon: Icons.home,
    color: AppTheme.accentBlue,
  ),
  portfolio(
    label: '포트폴리오',
    icon: Icons.account_balance_wallet_outlined,
    activeIcon: Icons.account_balance_wallet,
    color: AppTheme.successGreen,
  ),
  signals(
    label: '시그널',
    icon: Icons.flash_on_outlined,
    activeIcon: Icons.flash_on,
    color: AppTheme.warningOrange,
  ),
  news(
    label: '뉴스',
    icon: Icons.article_outlined,
    activeIcon: Icons.article,
    color: AppTheme.primaryBlue,
  ),
  profile(
    label: '프로필',
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    color: AppTheme.neutralGray,
  );

  const NavigationTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Color color;
}

// Current Tab Provider
final currentTabProvider = StateProvider<NavigationTab>((ref) {
  return NavigationTab.signals;
});

class NeonBottomNavigation extends ConsumerStatefulWidget {
  final Function(NavigationTab) onTabChanged;

  const NeonBottomNavigation({
    super.key,
    required this.onTabChanged,
  });

  @override
  ConsumerState<NeonBottomNavigation> createState() => _NeonBottomNavigationState();
}

class _NeonBottomNavigationState extends ConsumerState<NeonBottomNavigation>
    with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;
  late AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    
    // 각 탭별 애니메이션 컨트롤러
    _animationControllers = List.generate(
      NavigationTab.values.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );

    // 스케일 애니메이션
    _scaleAnimations = _animationControllers.map((controller) {
      return Tween<double>(begin: 1.0, end: 1.1).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    // 그라디언트 애니메이션
    _gradientController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    _gradientController.dispose();
    super.dispose();
  }

  void _onTabTapped(NavigationTab tab) {
    final currentTab = ref.read(currentTabProvider);
    if (currentTab != tab) {
      // 이전 탭 애니메이션 리셋
      _animationControllers[currentTab.index].reverse();
      
      // 새로운 탭 애니메이션 시작
      _animationControllers[tab.index].forward();
      
      // 상태 업데이트
      ref.read(currentTabProvider.notifier).state = tab;
      widget.onTabChanged(tab);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(currentTabProvider);

    return Container(
      height: 90,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xF20F172A), // slate-900/95
            Color(0xE61E293B), // slate-800/90
            Colors.transparent,
          ],
        ),
        border: Border(
          top: BorderSide(
            color: AppTheme.borderColor.withOpacity(0.4),
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  AppTheme.accentBlue.withOpacity(0.05),
                  AppTheme.primaryBlue.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: NavigationTab.values.map((tab) {
                    return _buildNavItem(tab, currentTab == tab);
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(NavigationTab tab, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(tab),
        child: AnimatedBuilder(
          animation: _scaleAnimations[tab.index],
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimations[tab.index].value,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 아이콘 컨테이너
                    Stack(
                      children: [
                        // 배경 글로우
                        if (isActive)
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  tab.color.withOpacity(0.1),
                                  tab.color.withOpacity(0.05),
                                  Colors.transparent,
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                        
                        // 메인 아이콘
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: isActive
                                ? RadialGradient(
                                    colors: [
                                      tab.color.withOpacity(0.1),
                                      tab.color.withOpacity(0.05),
                                      Colors.transparent,
                                    ],
                                  )
                                : null,
                            shape: BoxShape.circle,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: tab.color.withOpacity(0.2),
                                        blurRadius: 3,
                                        spreadRadius: 0,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              isActive ? tab.activeIcon : tab.icon,
                              color: isActive 
                                  ? tab.color 
                                  : const Color(0xFF64748B), // slate-500
                              size: 28,
                            ),
                          ),
                        ),
                        
                        // 펄스 효과 (활성화 상태)
                        if (isActive)
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _gradientController,
                              builder: (context, child) {
                                return Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: tab.color.withOpacity(
                                          0.08 * (1 + 0.2 * _gradientController.value),
                                        ),
                                        blurRadius: 2 * (1 + 0.3 * _gradientController.value),
                                        spreadRadius: 0.5 * _gradientController.value,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // 라벨
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive 
                            ? tab.color 
                            : const Color(0xFF64748B),
                      ),
                      child: Text(tab.label),
                    ),
                    
                    const SizedBox(height: 2),
                    
                    // 액티브 인디케이터
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isActive ? 4 : 0,
                      height: isActive ? 4 : 0,
                      decoration: BoxDecoration(
                        color: tab.color,
                        shape: BoxShape.circle,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: tab.color,
                                  blurRadius: 4,
                                  spreadRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// 플로팅 액션 인디케이터
class FloatingActionIndicator extends StatefulWidget {
  const FloatingActionIndicator({super.key});

  @override
  State<FloatingActionIndicator> createState() => _FloatingActionIndicatorState();
}

class _FloatingActionIndicatorState extends State<FloatingActionIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Opacity(
              opacity: _animation.value,
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white30,
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}