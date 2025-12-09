import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum NotificationType {
  signal,
  portfolio,
  trade,
  system,
  news,
}

enum NotificationChannel {
  push,
  email,
  sms,
}

class NotificationData {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  final bool isRead;

  const NotificationData({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.timestamp,
    this.isRead = false,
  });

  NotificationData copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return NotificationData(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
    );
  }
}

class NotificationSettings {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final bool priceAlerts;
  final bool signalAlerts;
  final bool newsAlerts;
  final bool portfolioAlerts;
  final bool tradingAlerts;
  final double confidenceThreshold;
  final bool quietHoursEnabled;
  final Map<String, int> quietStartTime;
  final Map<String, int> quietEndTime;
  final String? fcmToken;
  final String? email;
  final String? phoneNumber;

  const NotificationSettings({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.smsEnabled = false,
    this.priceAlerts = true,
    this.signalAlerts = true,
    this.newsAlerts = false,
    this.portfolioAlerts = true,
    this.tradingAlerts = true,
    this.confidenceThreshold = 75.0,
    this.quietHoursEnabled = false,
    this.quietStartTime = const {'hour': 23, 'minute': 0},
    this.quietEndTime = const {'hour': 8, 'minute': 0},
    this.fcmToken,
    this.email,
    this.phoneNumber,
  });

  NotificationSettings copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    bool? priceAlerts,
    bool? signalAlerts,
    bool? newsAlerts,
    bool? portfolioAlerts,
    bool? tradingAlerts,
    double? confidenceThreshold,
    bool? quietHoursEnabled,
    Map<String, int>? quietStartTime,
    Map<String, int>? quietEndTime,
    String? fcmToken,
    String? email,
    String? phoneNumber,
  }) {
    return NotificationSettings(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      priceAlerts: priceAlerts ?? this.priceAlerts,
      signalAlerts: signalAlerts ?? this.signalAlerts,
      newsAlerts: newsAlerts ?? this.newsAlerts,
      portfolioAlerts: portfolioAlerts ?? this.portfolioAlerts,
      tradingAlerts: tradingAlerts ?? this.tradingAlerts,
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietStartTime: quietStartTime ?? this.quietStartTime,
      quietEndTime: quietEndTime ?? this.quietEndTime,
      fcmToken: fcmToken ?? this.fcmToken,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'push_enabled': pushEnabled,
      'email_enabled': emailEnabled,
      'sms_enabled': smsEnabled,
      'price_alerts': priceAlerts,
      'signal_alerts': signalAlerts,
      'news_alerts': newsAlerts,
      'portfolio_alerts': portfolioAlerts,
      'trading_alerts': tradingAlerts,
      'confidence_threshold': confidenceThreshold,
      'quiet_hours_enabled': quietHoursEnabled,
      'quiet_start_time': quietStartTime,
      'quiet_end_time': quietEndTime,
      if (fcmToken != null) 'fcm_token': fcmToken,
      if (email != null) 'email': email,
      if (phoneNumber != null) 'phone_number': phoneNumber,
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      pushEnabled: json['push_enabled'] ?? true,
      emailEnabled: json['email_enabled'] ?? true,
      smsEnabled: json['sms_enabled'] ?? false,
      priceAlerts: json['price_alerts'] ?? true,
      signalAlerts: json['signal_alerts'] ?? true,
      newsAlerts: json['news_alerts'] ?? false,
      portfolioAlerts: json['portfolio_alerts'] ?? true,
      tradingAlerts: json['trading_alerts'] ?? true,
      confidenceThreshold: (json['confidence_threshold'] ?? 75.0).toDouble(),
      quietHoursEnabled: json['quiet_hours_enabled'] ?? false,
      quietStartTime: json['quiet_start_time'] ?? {'hour': 23, 'minute': 0},
      quietEndTime: json['quiet_end_time'] ?? {'hour': 8, 'minute': 0},
      fcmToken: json['fcm_token'],
      email: json['email'],
      phoneNumber: json['phone_number'],
    );
  }
}

class NotificationService {
  static const String _baseUrl = 'http://10.0.2.2:8001'; // 안드로이드 에뮬레이터에서 localhost 접근

  // 알림 발송
  Future<bool> sendNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    required Set<NotificationChannel> channels,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/notifications/send'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': userId,
          'title': title,
          'body': body,
          'type': type.name,
          'channels': channels.map((c) => c.name).toList(),
          'data': data,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Failed to send notification: $e');
      return false;
    }
  }

  // 시그널 알림 발송
  Future<bool> sendSignalNotification({
    required String userId,
    required String coinSymbol,
    required String action,
    required double confidence,
    Map<String, dynamic>? additionalData,
  }) async {
    return sendNotification(
      userId: userId,
      title: '🚀 $coinSymbol 시그널 발생!',
      body: '신뢰도 ${confidence.toStringAsFixed(0)}% - ${action.toUpperCase()}',
      type: NotificationType.signal,
      channels: {NotificationChannel.push, NotificationChannel.email},
      data: {
        'coinSymbol': coinSymbol,
        'action': action,
        'confidence': confidence,
        if (additionalData != null) ...additionalData,
      },
    );
  }

  // 포트폴리오 알림 발송
  Future<bool> sendPortfolioNotification({
    required String userId,
    required String title,
    required String message,
    required double pnl,
    required double pnlPercent,
  }) async {
    String emoji = pnl >= 0 ? '📈' : '📉';
    String sign = pnl >= 0 ? '+' : '';

    return sendNotification(
      userId: userId,
      title: '$emoji $title',
      body: '${sign}\$${pnl.toStringAsFixed(2)} ($sign${pnlPercent.toStringAsFixed(1)}%)',
      type: NotificationType.portfolio,
      channels: {NotificationChannel.push},
      data: {
        'pnl': pnl,
        'pnlPercent': pnlPercent,
        'message': message,
      },
    );
  }

  // 거래 완료 알림 발송
  Future<bool> sendTradeNotification({
    required String userId,
    required String coinSymbol,
    required String action,
    required double amount,
    required double price,
    required double pnl,
  }) async {
    String emoji = action.toLowerCase() == 'buy' ? '💰' : '💸';
    String pnlEmoji = pnl >= 0 ? '📈' : '📉';
    String pnlSign = pnl >= 0 ? '+' : '';

    return sendNotification(
      userId: userId,
      title: '$emoji $coinSymbol ${action.toUpperCase()} 거래 완료',
      body: '${amount.toStringAsFixed(4)} $coinSymbol @ \$${price.toStringAsFixed(2)} $pnlEmoji $pnlSign\$${pnl.toStringAsFixed(2)}',
      type: NotificationType.trade,
      channels: {NotificationChannel.push, NotificationChannel.email},
      data: {
        'coinSymbol': coinSymbol,
        'action': action,
        'amount': amount,
        'price': price,
        'pnl': pnl,
      },
    );
  }

  // 사용자별 알림 목록 가져오기
  Future<List<NotificationData>> getUserNotifications(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/notifications/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['notifications'] as List)
            .map((json) => NotificationData.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('Failed to fetch notifications: $e');
      return [];
    }
  }

  // 알림 읽음 상태 업데이트
  Future<bool> markAsRead(String userId, String notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'userId': userId}),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
      return false;
    }
  }

  // 알림 설정 저장
  Future<bool> saveNotificationSettings(String userId, NotificationSettings settings) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/settings/notifications/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(settings.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to save notification settings: $e');
      return false;
    }
  }

  // 알림 설정 가져오기
  Future<NotificationSettings?> getNotificationSettings(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/settings/notifications/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return NotificationSettings.fromJson(data['data']);
        }
      }

      return null;
    } catch (e) {
      debugPrint('Failed to fetch notification settings: $e');
      return null;
    }
  }

  // FCM 토큰 업데이트
  Future<bool> updateFcmToken(String userId, String token) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/notifications/fcm-token/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'fcmToken': token}),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Failed to update FCM token: $e');
      return false;
    }
  }

  // 알림 테스트 발송
  Future<bool> sendTestNotification(String userId) async {
    return sendNotification(
      userId: userId,
      title: '🔔 알림 테스트',
      body: 'TradeCoin 알림이 정상적으로 작동합니다!',
      type: NotificationType.system,
      channels: {NotificationChannel.push},
      data: {'test': true},
    );
  }
}