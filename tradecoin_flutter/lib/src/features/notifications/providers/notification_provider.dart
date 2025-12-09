import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/providers/auth_provider.dart';

class NotificationState {
  final List<NotificationData> notifications;
  final NotificationSettings? settings;
  final bool isLoading;
  final String? error;
  final int unreadCount;

  const NotificationState({
    this.notifications = const [],
    this.settings,
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
  });

  NotificationState copyWith({
    List<NotificationData>? notifications,
    NotificationSettings? settings,
    bool? isLoading,
    String? error,
    int? unreadCount,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier(this._ref) : super(const NotificationState()) {
    _init();
  }

  final Ref _ref;
  final NotificationService _notificationService = NotificationService();

  void _init() {
    // 사용자 인증 상태가 변경될 때마다 알림 데이터 새로고침
    _ref.listen(authStateProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated && next.userData != null) {
        loadUserNotifications();
        loadNotificationSettings();
      } else {
        // 로그아웃 시 상태 초기화
        state = const NotificationState();
      }
    });
  }

  // 사용자 알림 목록 로드
  Future<void> loadUserNotifications() async {
    final authState = _ref.read(authStateProvider);
    if (authState.status != AuthStatus.authenticated || authState.userData == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final notifications = await _notificationService.getUserNotifications(
        authState.userData!.uid,
      );

      final unreadCount = notifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '알림을 불러올 수 없습니다: $e',
      );
    }
  }

  // 알림 설정 로드
  Future<void> loadNotificationSettings() async {
    final authState = _ref.read(authStateProvider);
    if (authState.status != AuthStatus.authenticated || authState.userData == null) return;

    try {
      final settings = await _notificationService.getNotificationSettings(
        authState.userData!.uid,
      );

      if (settings != null) {
        state = state.copyWith(settings: settings);
      } else {
        // 기본 설정 생성
        final defaultSettings = NotificationSettings(
          signalAlerts: true,
          portfolioAlerts: true,
          tradingAlerts: true,
          priceAlerts: true,
          newsAlerts: false,
          email: authState.userData!.email,
        );
        await saveNotificationSettings(defaultSettings);
      }
    } catch (e) {
      state = state.copyWith(
        error: '알림 설정을 불러올 수 없습니다: $e',
      );
    }
  }

  // 알림 읽음 표시
  Future<void> markAsRead(String notificationId) async {
    final authState = _ref.read(authStateProvider);
    if (authState.status != AuthStatus.authenticated || authState.userData == null) return;

    try {
      final success = await _notificationService.markAsRead(
        authState.userData!.uid,
        notificationId,
      );

      if (success) {
        final updatedNotifications = state.notifications.map((notification) {
          if (notification.id == notificationId) {
            return notification.copyWith(isRead: true);
          }
          return notification;
        }).toList();

        final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: unreadCount,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: '알림 상태를 업데이트할 수 없습니다: $e',
      );
    }
  }

  // 모든 알림 읽음 표시
  Future<void> markAllAsRead() async {
    for (final notification in state.notifications.where((n) => !n.isRead)) {
      await markAsRead(notification.id);
    }
  }

  // 알림 설정 저장
  Future<void> saveNotificationSettings(NotificationSettings settings) async {
    final authState = _ref.read(authStateProvider);
    if (authState.status != AuthStatus.authenticated || authState.userData == null) return;

    try {
      final success = await _notificationService.saveNotificationSettings(
        authState.userData!.uid,
        settings,
      );

      if (success) {
        state = state.copyWith(settings: settings);
      } else {
        state = state.copyWith(
          error: '알림 설정을 저장할 수 없습니다',
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: '알림 설정을 저장할 수 없습니다: $e',
      );
    }
  }

  // FCM 토큰 업데이트
  Future<void> updateFcmToken(String token) async {
    final authState = _ref.read(authStateProvider);
    if (authState.status != AuthStatus.authenticated || authState.userData == null) return;

    try {
      final success = await _notificationService.updateFcmToken(
        authState.userData!.uid,
        token,
      );

      if (success && state.settings != null) {
        final updatedSettings = state.settings!.copyWith(fcmToken: token);
        state = state.copyWith(settings: updatedSettings);
      }
    } catch (e) {
      state = state.copyWith(
        error: 'FCM 토큰을 업데이트할 수 없습니다: $e',
      );
    }
  }

  // 시그널 알림 발송
  Future<void> sendSignalNotification({
    required String coinSymbol,
    required String action,
    required double confidence,
    Map<String, dynamic>? additionalData,
  }) async {
    final authState = _ref.read(authStateProvider);
    if (authState.status != AuthStatus.authenticated || authState.userData == null) return;

    // 시그널 알림이 활성화되어 있는지 확인
    if (state.settings?.signalAlerts != true) {
      return;
    }

    try {
      await _notificationService.sendSignalNotification(
        userId: authState.userData!.uid,
        coinSymbol: coinSymbol,
        action: action,
        confidence: confidence,
        additionalData: additionalData,
      );

      // 알림 목록 새로고침
      await loadUserNotifications();
    } catch (e) {
      state = state.copyWith(
        error: '시그널 알림을 발송할 수 없습니다: $e',
      );
    }
  }

  // 포트폴리오 알림 발송
  Future<void> sendPortfolioNotification({
    required String title,
    required String message,
    required double pnl,
    required double pnlPercent,
  }) async {
    final authState = _ref.read(authStateProvider);
    if (authState.status != AuthStatus.authenticated || authState.userData == null) return;

    // 포트폴리오 알림이 활성화되어 있는지 확인
    if (state.settings?.portfolioAlerts != true) {
      return;
    }

    try {
      await _notificationService.sendPortfolioNotification(
        userId: authState.userData!.uid,
        title: title,
        message: message,
        pnl: pnl,
        pnlPercent: pnlPercent,
      );

      // 알림 목록 새로고침
      await loadUserNotifications();
    } catch (e) {
      state = state.copyWith(
        error: '포트폴리오 알림을 발송할 수 없습니다: $e',
      );
    }
  }

  // 테스트 알림 발송
  Future<void> sendTestNotification() async {
    final authState = _ref.read(authStateProvider);
    if (authState.status != AuthStatus.authenticated || authState.userData == null) return;

    try {
      final success = await _notificationService.sendTestNotification(
        authState.userData!.uid,
      );

      if (success) {
        // 알림 목록 새로고침
        await loadUserNotifications();
      } else {
        state = state.copyWith(
          error: '테스트 알림을 발송할 수 없습니다',
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: '테스트 알림을 발송할 수 없습니다: $e',
      );
    }
  }

  // 에러 상태 클리어
  void clearError() {
    state = state.copyWith(error: null);
  }

  // 알림 추가 (실시간으로 받은 알림)
  void addNotification(NotificationData notification) {
    final updatedNotifications = [notification, ...state.notifications];
    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    );
  }

  // 특정 유형의 알림 설정 토글
  Future<void> toggleSignalAlerts(bool enabled) async {
    if (state.settings == null) return;
    final updatedSettings = state.settings!.copyWith(signalAlerts: enabled);
    await saveNotificationSettings(updatedSettings);
  }

  Future<void> togglePortfolioAlerts(bool enabled) async {
    if (state.settings == null) return;
    final updatedSettings = state.settings!.copyWith(portfolioAlerts: enabled);
    await saveNotificationSettings(updatedSettings);
  }

  Future<void> toggleTradingAlerts(bool enabled) async {
    if (state.settings == null) return;
    final updatedSettings = state.settings!.copyWith(tradingAlerts: enabled);
    await saveNotificationSettings(updatedSettings);
  }

  Future<void> toggleNewsAlerts(bool enabled) async {
    if (state.settings == null) return;
    final updatedSettings = state.settings!.copyWith(newsAlerts: enabled);
    await saveNotificationSettings(updatedSettings);
  }

  // 푸시 알림 설정 토글
  Future<void> togglePushNotifications(bool enabled) async {
    if (state.settings == null) return;

    final updatedSettings = state.settings!.copyWith(pushEnabled: enabled);
    await saveNotificationSettings(updatedSettings);
  }

  // 이메일 알림 설정 토글
  Future<void> toggleEmailNotifications(bool enabled) async {
    if (state.settings == null) return;

    final updatedSettings = state.settings!.copyWith(emailEnabled: enabled);
    await saveNotificationSettings(updatedSettings);
  }

  // SMS 알림 설정 토글
  Future<void> toggleSmsNotifications(bool enabled) async {
    if (state.settings == null) return;

    final updatedSettings = state.settings!.copyWith(smsEnabled: enabled);
    await saveNotificationSettings(updatedSettings);
  }

  // 알림 타입별 토글
  Future<void> toggleNotificationType(NotificationType type, bool enabled) async {
    if (state.settings == null) return;

    NotificationSettings updatedSettings;
    switch (type) {
      case NotificationType.signal:
        updatedSettings = state.settings!.copyWith(signalAlerts: enabled);
        break;
      case NotificationType.portfolio:
        updatedSettings = state.settings!.copyWith(portfolioAlerts: enabled);
        break;
      case NotificationType.trade:
        updatedSettings = state.settings!.copyWith(tradingAlerts: enabled);
        break;
      case NotificationType.news:
        updatedSettings = state.settings!.copyWith(newsAlerts: enabled);
        break;
      case NotificationType.system:
        // 시스템 알림은 변경 불가
        return;
    }

    await saveNotificationSettings(updatedSettings);
  }
}

// Provider 정의
final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref);
});

// 편의 Provider들
final notificationsListProvider = Provider<List<NotificationData>>((ref) {
  return ref.watch(notificationProvider).notifications;
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});

final notificationSettingsProvider = Provider<NotificationSettings?>((ref) {
  return ref.watch(notificationProvider).settings;
});

final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  return ref.watch(notificationProvider).unreadCount > 0;
});