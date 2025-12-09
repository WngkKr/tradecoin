import 'package:flutter/material.dart';

import '../../../core/services/notification_service.dart';

class NotificationToast extends StatefulWidget {
  final NotificationData notification;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;
  final Duration duration;

  const NotificationToast({
    super.key,
    required this.notification,
    this.onDismiss,
    this.onTap,
    this.duration = const Duration(seconds: 4),
  });

  @override
  State<NotificationToast> createState() => _NotificationToastState();
}

class _NotificationToastState extends State<NotificationToast>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeController);

    // 애니메이션 시작
    _slideController.forward();
    _fadeController.forward();

    // 자동 dismiss
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismissToast();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _dismissToast() async {
    await _slideController.reverse();
    await _fadeController.reverse();
    if (mounted) {
      widget.onDismiss?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getTypeColor().withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                widget.onTap?.call();
                _dismissToast();
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _buildIcon(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.notification.title,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.notification.body,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _dismissToast,
                      icon: const Icon(Icons.close, size: 18),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final color = _getTypeColor();
    final iconData = _getTypeIcon();

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: color,
        size: 16,
      ),
    );
  }

  Color _getTypeColor() {
    switch (widget.notification.type) {
      case NotificationType.signal:
        return Colors.green;
      case NotificationType.portfolio:
        return Colors.blue;
      case NotificationType.trade:
        return Colors.purple;
      case NotificationType.system:
        return Colors.orange;
      case NotificationType.news:
        return Colors.cyan;
    }
  }

  IconData _getTypeIcon() {
    switch (widget.notification.type) {
      case NotificationType.signal:
        return Icons.trending_up;
      case NotificationType.portfolio:
        return Icons.pie_chart;
      case NotificationType.trade:
        return Icons.swap_horiz;
      case NotificationType.system:
        return Icons.info;
      case NotificationType.news:
        return Icons.article;
    }
  }
}

// Toast 관리를 위한 overlay 서비스
class NotificationToastService {
  static final List<OverlayEntry> _activeToasts = [];
  static const int _maxToasts = 3;

  static void show(
    BuildContext context,
    NotificationData notification, {
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (_activeToasts.length >= _maxToasts) {
      // 가장 오래된 토스트 제거
      _activeToasts.first.remove();
      _activeToasts.removeAt(0);
    }

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + (50.0 * _activeToasts.length),
        left: 0,
        right: 0,
        child: NotificationToast(
          notification: notification,
          duration: duration,
          onDismiss: () {
            overlayEntry.remove();
            _activeToasts.remove(overlayEntry);
          },
          onTap: onTap,
        ),
      ),
    );

    _activeToasts.add(overlayEntry);
    overlay.insert(overlayEntry);
  }

  static void showSignal(
    BuildContext context, {
    required String coinSymbol,
    required String action,
    required double confidence,
    VoidCallback? onTap,
  }) {
    final notification = NotificationData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '🚀 $coinSymbol 시그널!',
      body: '신뢰도 ${confidence.toStringAsFixed(0)}% - ${action.toUpperCase()}',
      type: NotificationType.signal,
      timestamp: DateTime.now(),
      data: {
        'coinSymbol': coinSymbol,
        'action': action,
        'confidence': confidence,
      },
    );

    show(context, notification, onTap: onTap);
  }

  static void showPortfolio(
    BuildContext context, {
    required String title,
    required double pnl,
    required double pnlPercent,
    VoidCallback? onTap,
  }) {
    final emoji = pnl >= 0 ? '📈' : '📉';
    final sign = pnl >= 0 ? '+' : '';

    final notification = NotificationData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '$emoji $title',
      body: '$sign\$${pnl.toStringAsFixed(2)} ($sign${pnlPercent.toStringAsFixed(1)}%)',
      type: NotificationType.portfolio,
      timestamp: DateTime.now(),
      data: {
        'pnl': pnl,
        'pnlPercent': pnlPercent,
      },
    );

    show(context, notification, onTap: onTap);
  }

  static void clearAll() {
    for (final entry in _activeToasts) {
      entry.remove();
    }
    _activeToasts.clear();
  }
}