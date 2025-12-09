import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 🔔 푸시 알림 서비스
///
/// 기능:
/// - Firebase Cloud Messaging (FCM) 연동
/// - 포그라운드 알림 표시
/// - 백그라운드 알림 처리
/// - 고신뢰도 시그널 알림 (80% 이상)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _fcmToken;

  /// FCM 토큰 가져오기
  String? get fcmToken => _fcmToken;

  /// 알림 서비스 초기화
  Future<void> initialize() async {
    if (_initialized) {
      print('⚠️ NotificationService already initialized');
      return;
    }

    try {
      print('🔔 NotificationService 초기화 시작...');

      // 1. 권한 요청
      final settings = await _requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        print('⚠️ 알림 권한이 거부되었습니다');
        return;
      }

      // 2. FCM 토큰 가져오기
      _fcmToken = await _messaging.getToken();
      print('✅ FCM 토큰: $_fcmToken');

      // 3. 로컬 알림 초기화
      await _initializeLocalNotifications();

      // 4. 포그라운드 메시지 리스너 설정
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 5. 백그라운드 메시지 처리는 main.dart에서 설정
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // 6. 토큰 갱신 리스너
      _messaging.onTokenRefresh.listen((newToken) {
        print('🔄 FCM 토큰 갱신: $newToken');
        _fcmToken = newToken;
        // TODO: 서버에 새 토큰 전송
      });

      _initialized = true;
      print('✅ NotificationService 초기화 완료');
    } catch (e) {
      print('❌ NotificationService 초기화 실패: $e');
    }
  }

  /// 알림 권한 요청
  Future<NotificationSettings> _requestPermission() async {
    print('🔐 알림 권한 요청 중...');

    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('✅ 알림 권한 상태: ${settings.authorizationStatus}');
    return settings;
  }

  /// 로컬 알림 초기화
  Future<void> _initializeLocalNotifications() async {
    print('📱 로컬 알림 초기화 중...');

    // Android 설정
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 설정
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        print('📨 iOS 로컬 알림 수신: $title');
      },
    );

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        print('🖱️ 알림 클릭: ${response.payload}');
        _handleNotificationTap(response.payload);
      },
    );

    // Android 알림 채널 생성
    await _createNotificationChannels();

    print('✅ 로컬 알림 초기화 완료');
  }

  /// Android 알림 채널 생성
  Future<void> _createNotificationChannels() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    // 고신뢰도 시그널 채널 (High Importance)
    const highChannel = AndroidNotificationChannel(
      'high_confidence_signals',
      'High Confidence Signals',
      description: '신뢰도 80% 이상의 고신뢰도 시그널 알림',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFF8B5CF6), // 퍼플
    );

    // 일반 시그널 채널 (Default Importance)
    const defaultChannel = AndroidNotificationChannel(
      'default_signals',
      'Signal Notifications',
      description: '일반 트레이딩 시그널 알림',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(highChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(defaultChannel);

    print('✅ Android 알림 채널 생성 완료');
  }

  /// 포그라운드 메시지 처리
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📨 포그라운드 메시지 수신: ${message.notification?.title}');

    if (message.notification != null) {
      await _showLocalNotification(
        title: message.notification!.title ?? '시그널 알림',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
        isHighPriority: message.data['type'] == 'high_confidence_signal',
      );
    }
  }

  /// 백그라운드에서 앱을 열었을 때 처리
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('🚀 백그라운드 메시지로 앱 열림: ${message.notification?.title}');
    // TODO: 시그널 상세 화면으로 이동
  }

  /// 로컬 알림 표시
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    bool isHighPriority = false,
  }) async {
    final channelId = isHighPriority ? 'high_confidence_signals' : 'default_signals';

    final androidDetails = AndroidNotificationDetails(
      channelId,
      isHighPriority ? 'High Confidence Signals' : 'Signal Notifications',
      importance: isHighPriority ? Importance.max : Importance.defaultImportance,
      priority: isHighPriority ? Priority.high : Priority.defaultPriority,
      ticker: 'TradeCoin Signal',
      color: const Color(0xFF8B5CF6), // 퍼플
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: const Color(0xFF8B5CF6),
      ledOnMs: 1000,
      ledOffMs: 500,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'TradeCoin',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );

    print('✅ 로컬 알림 표시: $title');
  }

  /// 알림 클릭 처리
  void _handleNotificationTap(String? payload) {
    if (payload == null) return;

    print('🖱️ 알림 클릭 처리: $payload');
    // TODO: 시그널 ID 파싱 후 상세 화면으로 이동
  }

  /// 특정 주제 구독
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('✅ 주제 구독 성공: $topic');
    } catch (e) {
      print('❌ 주제 구독 실패: $e');
    }
  }

  /// 특정 주제 구독 해제
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('✅ 주제 구독 해제 성공: $topic');
    } catch (e) {
      print('❌ 주제 구독 해제 실패: $e');
    }
  }

  /// 고신뢰도 시그널 알림 전송 (테스트용)
  Future<void> sendTestNotification() async {
    await _showLocalNotification(
      title: '🔥 TRUMP BUY',
      body: '신뢰도 80% - 지금 확인하세요!',
      isHighPriority: true,
    );
  }
}

/// 백그라운드 메시지 핸들러 (top-level function)
/// main.dart에서 호출
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🌙 백그라운드 메시지 수신: ${message.notification?.title}');
  // 백그라운드에서는 자동으로 시스템 알림이 표시됨
}
