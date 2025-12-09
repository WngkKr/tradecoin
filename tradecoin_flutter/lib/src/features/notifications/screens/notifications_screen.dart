import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/cyberpunk_header.dart';
import '../providers/notification_provider.dart';
import '../../../core/services/notification_service.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();

    // 알림 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).loadUserNotifications();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: const CyberpunkHeader(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Consumer(
          builder: (context, ref, child) {
            final notificationState = ref.watch(notificationProvider);

            if (notificationState.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.accentBlue,
                ),
              );
            }

            if (notificationState.error != null) {
              return _buildErrorState(notificationState.error!);
            }

            return CustomScrollView(
              slivers: [
                _buildHeader(ref),
                if (notificationState.notifications.isEmpty)
                  _buildEmptyState()
                else
                  _buildNotificationsList(notificationState.notifications),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final totalCount = ref.watch(notificationsListProvider).length;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.accentBlue.withOpacity(0.1),
              AppTheme.successGreen.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.borderColor.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '알림센터',
                      style: AppTheme.headingLarge.copyWith(
                        color: AppTheme.accentBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '총 $totalCount개 • 미읽음 $unreadCount개',
                      style: AppTheme.bodyMedium.copyWith(
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                  ],
                ),
                if (unreadCount > 0)
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(notificationProvider.notifier).markAllAsRead();
                    },
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text('모두 읽음'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildTestNotificationButton(ref),
                const SizedBox(width: 12),
                _buildSettingsButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestNotificationButton(WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () {
        ref.read(notificationProvider.notifier).sendTestNotification();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('테스트 알림을 발송했습니다'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      },
      icon: const Icon(Icons.notifications_active, size: 18),
      label: const Text('테스트'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accentBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildSettingsButton() {
    return ElevatedButton.icon(
      onPressed: () {
        _showNotificationSettings();
      },
      icon: const Icon(Icons.settings, size: 18),
      label: const Text('설정'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.surfaceDark,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildNotificationsList(List<NotificationData> notifications) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final notification = notifications[index];
          return _buildNotificationCard(notification);
        },
        childCount: notifications.length,
      ),
    );
  }

  Widget _buildNotificationCard(NotificationData notification) {
    final timeAgo = _getTimeAgo(notification.timestamp);
    final isUnread = !notification.isRead;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isUnread
            ? AppTheme.accentBlue.withOpacity(0.05)
            : AppTheme.surfaceDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread
              ? AppTheme.accentBlue.withOpacity(0.2)
              : AppTheme.borderColor.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildNotificationIcon(notification.type, isUnread),
        title: Text(
          notification.title,
          style: AppTheme.bodyLarge.copyWith(
            color: Colors.white,
            fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: AppTheme.bodyMedium.copyWith(
                color: const Color(0xFFE2E8F0),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  timeAgo,
                  style: AppTheme.bodySmall.copyWith(
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const Spacer(),
                if (isUnread)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '새 알림',
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        onTap: () {
          if (isUnread) {
            ref.read(notificationProvider.notifier).markAsRead(notification.id);
          }
          _handleNotificationTap(notification);
        },
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type, bool isUnread) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case NotificationType.signal:
        iconData = Icons.trending_up;
        iconColor = AppTheme.successGreen;
        break;
      case NotificationType.portfolio:
        iconData = Icons.account_balance_wallet;
        iconColor = AppTheme.accentBlue;
        break;
      case NotificationType.trade:
        iconData = Icons.swap_horiz;
        iconColor = AppTheme.warningOrange;
        break;
      case NotificationType.news:
        iconData = Icons.article;
        iconColor = AppTheme.accentBlue;
        break;
      case NotificationType.system:
      default:
        iconData = Icons.info;
        iconColor = const Color(0xFFE2E8F0);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
        border: isUnread
            ? Border.all(color: iconColor.withOpacity(0.3), width: 2)
            : null,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none,
                size: 48,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '알림이 없습니다',
              style: AppTheme.headingMedium.copyWith(
                color: const Color(0xFFE2E8F0),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '새로운 시그널이나 거래 결과를 받으면\n여기에 표시됩니다',
              style: AppTheme.bodyMedium.copyWith(
                color: const Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppTheme.dangerRed,
          ),
          const SizedBox(height: 16),
          Text(
            '오류가 발생했습니다',
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.dangerRed,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTheme.bodyMedium.copyWith(
              color: const Color(0xFFE2E8F0),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.read(notificationProvider.notifier).loadUserNotifications();
            },
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return DateFormat('MM/dd HH:mm').format(timestamp);
    }
  }

  void _handleNotificationTap(NotificationData notification) {
    // 알림 유형에 따라 적절한 화면으로 이동
    switch (notification.type) {
      case NotificationType.signal:
        // 시그널 상세 화면으로 이동
        break;
      case NotificationType.portfolio:
        // 포트폴리오 화면으로 이동
        break;
      case NotificationType.trade:
        // 거래 기록 화면으로 이동
        break;
      case NotificationType.news:
        // 뉴스 화면으로 이동
        break;
      case NotificationType.system:
        // 필요에 따라 처리
        break;
    }
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundDark,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            border: Border.all(
              color: AppTheme.borderColor.withOpacity(0.2),
            ),
          ),
          child: _buildNotificationSettingsSheet(scrollController),
        ),
      ),
    );
  }

  Widget _buildNotificationSettingsSheet(ScrollController scrollController) {
    return Consumer(
      builder: (context, ref, child) {
        final settings = ref.watch(notificationSettingsProvider);

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF94A3B8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '알림 설정',
                    style: AppTheme.headingLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildSettingsSection(
                    '알림 방식',
                    [
                      _buildSwitchTile(
                        '푸시 알림',
                        '앱에서 즉시 알림을 받습니다',
                        settings?.pushEnabled ?? true,
                        (value) => ref
                            .read(notificationProvider.notifier)
                            .togglePushNotifications(value),
                        Icons.notifications_active,
                      ),
                      _buildSwitchTile(
                        '이메일 알림',
                        '이메일로 알림을 받습니다',
                        settings?.emailEnabled ?? true,
                        (value) => ref
                            .read(notificationProvider.notifier)
                            .toggleEmailNotifications(value),
                        Icons.email,
                      ),
                      _buildSwitchTile(
                        'SMS 알림',
                        '문자 메시지로 알림을 받습니다',
                        settings?.smsEnabled ?? false,
                        (value) => ref
                            .read(notificationProvider.notifier)
                            .toggleSmsNotifications(value),
                        Icons.sms,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSettingsSection(
                    '알림 유형',
                    NotificationType.values.map((type) {
                      return _buildSwitchTile(
                        _getNotificationTypeName(type),
                        _getNotificationTypeDescription(type),
                        _getNotificationTypeEnabled(settings, type),
                        (value) => ref
                            .read(notificationProvider.notifier)
                            .toggleNotificationType(type, value),
                        _getNotificationTypeIcon(type),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.headingMedium.copyWith(
            color: AppTheme.accentBlue,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderColor.withOpacity(0.1),
        ),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: AppTheme.bodyLarge.copyWith(
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTheme.bodySmall.copyWith(
            color: const Color(0xFFE2E8F0),
          ),
        ),
        secondary: Icon(
          icon,
          color: AppTheme.accentBlue,
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.accentBlue,
      ),
    );
  }

  String _getNotificationTypeName(NotificationType type) {
    switch (type) {
      case NotificationType.signal:
        return '시그널 알림';
      case NotificationType.portfolio:
        return '포트폴리오 알림';
      case NotificationType.trade:
        return '거래 알림';
      case NotificationType.news:
        return '뉴스 알림';
      case NotificationType.system:
        return '시스템 알림';
    }
  }

  String _getNotificationTypeDescription(NotificationType type) {
    switch (type) {
      case NotificationType.signal:
        return '새로운 거래 시그널이 발생했을 때';
      case NotificationType.portfolio:
        return '포트폴리오 변동사항이 있을 때';
      case NotificationType.trade:
        return '거래가 체결되거나 완료될 때';
      case NotificationType.news:
        return '중요한 암호화폐 뉴스가 있을 때';
      case NotificationType.system:
        return '시스템 점검이나 업데이트가 있을 때';
    }
  }

  bool _getNotificationTypeEnabled(NotificationSettings? settings, NotificationType type) {
    if (settings == null) return true;

    switch (type) {
      case NotificationType.signal:
        return settings.signalAlerts;
      case NotificationType.portfolio:
        return settings.portfolioAlerts;
      case NotificationType.trade:
        return settings.tradingAlerts;
      case NotificationType.news:
        return settings.newsAlerts;
      case NotificationType.system:
        return true; // 시스템 알림은 항상 활성화
    }
  }

  IconData _getNotificationTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.signal:
        return Icons.trending_up;
      case NotificationType.portfolio:
        return Icons.account_balance_wallet;
      case NotificationType.trade:
        return Icons.swap_horiz;
      case NotificationType.news:
        return Icons.article;
      case NotificationType.system:
        return Icons.settings;
    }
  }
}