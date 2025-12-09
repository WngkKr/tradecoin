import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/notification_provider.dart';
import '../../../core/services/notification_service.dart';

class NotificationDropdown extends ConsumerWidget {
  final VoidCallback onClose;

  const NotificationDropdown({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsListProvider);

    return Container(
      width: 320,
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, ref),
          const Divider(height: 1),
          _buildNotificationList(context, ref, notifications),
          if (notifications.isNotEmpty) ...[
            const Divider(height: 1),
            _buildFooter(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.notifications_outlined,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '알림',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                ref.read(notificationProvider.notifier).markAllAsRead();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '모두 읽음',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 12,
                ),
              ),
            ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 18),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(BuildContext context, WidgetRef ref, List<NotificationData> notifications) {
    if (notifications.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.notifications_none,
              size: 48,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              '새로운 알림이 없습니다',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
      );
    }

    return Flexible(
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: notifications.length > 5 ? 5 : notifications.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationItem(context, ref, notification);
        },
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, WidgetRef ref, NotificationData notification) {
    return ListTile(
      leading: _buildNotificationIcon(notification),
      title: Text(
        notification.title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
          color: notification.isRead
            ? Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)
            : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            notification.body,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: notification.isRead
                ? Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)
                : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(notification.timestamp),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).disabledColor,
              fontSize: 11,
            ),
          ),
        ],
      ),
      trailing: !notification.isRead
        ? Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
          )
        : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () {
        if (!notification.isRead) {
          ref.read(notificationProvider.notifier).markAsRead(notification.id);
        }
        _handleNotificationTap(context, notification);
      },
    );
  }

  Widget _buildNotificationIcon(NotificationData notification) {
    IconData iconData;
    Color color;

    switch (notification.type) {
      case NotificationType.signal:
        iconData = Icons.trending_up;
        color = Colors.green;
        break;
      case NotificationType.portfolio:
        iconData = Icons.pie_chart;
        color = Colors.blue;
        break;
      case NotificationType.trade:
        iconData = Icons.swap_horiz;
        color = Colors.purple;
        break;
      case NotificationType.system:
        iconData = Icons.info;
        color = Colors.orange;
        break;
      case NotificationType.news:
        iconData = Icons.article;
        color = Colors.cyan;
        break;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: color,
        size: 18,
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: () {
            onClose();
            context.go('/notifications');
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            '모든 알림 보기',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }

  void _handleNotificationTap(BuildContext context, NotificationData notification) {
    switch (notification.type) {
      case NotificationType.signal:
        if (notification.data != null && notification.data!['signalId'] != null) {
          context.go('/signals/${notification.data!['signalId']}');
        } else {
          context.go('/signals');
        }
        break;
      case NotificationType.portfolio:
        context.go('/portfolio');
        break;
      case NotificationType.trade:
        context.go('/portfolio');
        break;
      case NotificationType.system:
        context.go('/settings');
        break;
      case NotificationType.news:
        context.go('/news');
        break;
    }
  }
}