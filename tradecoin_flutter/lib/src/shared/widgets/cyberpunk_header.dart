import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

import '../../core/theme/app_theme.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/binance/providers/binance_connection_provider.dart';
import '../../features/notifications/providers/notification_provider.dart';
import '../../features/notifications/widgets/notification_dropdown.dart';

class CyberpunkHeader extends ConsumerStatefulWidget implements PreferredSizeWidget {
  const CyberpunkHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(120);

  @override
  ConsumerState<CyberpunkHeader> createState() => _CyberpunkHeaderState();
}

class _CyberpunkHeaderState extends ConsumerState<CyberpunkHeader>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _hideNotificationDropdown();
    super.dispose();
  }

  void _showNotificationDropdown() {
    if (_overlayEntry != null) return;

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: offset.dy + size.height + 8,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: NotificationDropdown(
            onClose: _hideNotificationDropdown,
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _hideNotificationDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x1A1B365D), // Professional blue/10
            Color(0x0F3B82F6), // Accent blue/6  
            Color(0x051A202C), // Surface dark/3
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderColor.withOpacity(0.3),
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
                  AppTheme.accentBlue.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    // 미래형 로고 - Expanded로 감싸서 오버플로우 방지
                    Expanded(
                      flex: 4,
                      child: _buildFuturisticLogo(),
                    ),
                    const SizedBox(width: 6),
                    // 마켓 상태 및 사용자 프로필 - 축소
                    _buildRightSection(authState),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticLogo() {
    return Row(
      children: [
        // 로고 컨테이너 - 크기 축소
        Stack(
          children: [
            // 메인 로고
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.accentBlue, Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentBlue.withOpacity(0.25),
                    blurRadius: 6,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFE0F2FE)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 배경 원형 그라디언트
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              Color(0xFF60A5FA).withValues(alpha: 0.3),
                              Color(0xFF3B82F6).withValues(alpha: 0.6),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      // 중앙 다이아몬드 모양 (AI/crypto 느낌)
                      Transform.rotate(
                        angle: 0.785398, // 45도
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1E40AF),
                                Color(0xFF3B82F6),
                                Color(0xFF60A5FA),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF3B82F6).withValues(alpha: 0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 상단 작은 점들 (데이터/신호 표현)
                      Positioned(
                        top: 6,
                        child: Row(
                          children: [
                            Container(
                              width: 2,
                              height: 2,
                              decoration: BoxDecoration(
                                color: Color(0xFF60A5FA),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 1),
                            Container(
                              width: 1.5,
                              height: 1.5,
                              decoration: BoxDecoration(
                                color: Color(0xFF3B82F6),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 1),
                            Container(
                              width: 2,
                              height: 2,
                              decoration: BoxDecoration(
                                color: Color(0xFF60A5FA),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 온라인 상태 표시
            Positioned(
              top: -2,
              right: -2,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.successGreen.withOpacity(0.6),
                          blurRadius: 3,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        // 텍스트 - Expanded로 감싸서 오버플로우 방지
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppTheme.accentBlue, Color(0xFF60A5FA)],
                ).createShader(bounds),
                child: Text(
                  'TradeCoin',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'AI TRADING PLATFORM',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.accentBlue,
                  letterSpacing: 0.8,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightSection(AuthState authState) {
    return Consumer(
      builder: (context, ref, child) {
        final connectionState = ref.watch(binanceConnectionProvider);
        final screenWidth = MediaQuery.of(context).size.width;

        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Binance 연결 상태에 따른 마켓 상태 표시 - 화면 크기에 따라 조절
            if (screenWidth > 400) ...[
              _buildCompactMarketStatus(connectionState.isConnected),
              const SizedBox(width: 6),
            ],

            // 알림 버튼
            _buildNotificationButton(),
          ],
        );
      },
    );
  }

  Widget _buildMarketStatus(bool isConnected) {
    if (isConnected) {
      // 바이낸스 연결 시 - LIVE 상태
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF34D399).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF34D399).withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF34D399),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF34D399).withOpacity(
                          (0.4 + 0.4 * _pulseController.value).clamp(0.0, 1.0),
                        ),
                        blurRadius: 2 * (1 + _pulseController.value),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 4),
            const Text(
              'LIVE',
              style: TextStyle(
                color: Color(0xFF34D399),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else {
      // 바이낸스 연결 안됨 - 일반 마켓 상태
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.accentBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.accentBlue.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppTheme.accentBlue,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'Market',
              style: TextStyle(
                color: AppTheme.accentBlue,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildCompactMarketStatus(bool isConnected) {
    if (isConnected) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: const Color(0xFF34D399),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF34D399).withOpacity(0.4),
              blurRadius: 3,
              spreadRadius: 0,
            ),
          ],
        ),
      );
    } else {
      return Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppTheme.accentBlue,
          shape: BoxShape.circle,
        ),
      );
    }
  }

  Widget _buildNotificationButton() {
    return Consumer(
      builder: (context, ref, child) {
        final unreadCount = ref.watch(unreadNotificationCountProvider);

        return GestureDetector(
          onTap: () {
            if (_overlayEntry != null) {
              _hideNotificationDropdown();
            } else {
              _showNotificationDropdown();
            }
          },
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Icon(
                      Icons.notifications_outlined,
                      color: AppTheme.accentBlue.withValues(
                        alpha: 0.7 + 0.3 * _glowController.value,
                      ),
                      size: 18,
                    );
                  },
                ),
              ),
              // 미읽은 알림 배지
              if (unreadCount > 0)
                Positioned(
                  top: -1,
                  right: -1,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + 0.1 * _pulseController.value,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                                blurRadius: 3,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

}