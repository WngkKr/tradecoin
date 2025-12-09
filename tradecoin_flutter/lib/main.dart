import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'src/core/theme/app_theme.dart';
import 'src/core/router/app_router.dart';
import 'src/core/constants/app_constants.dart';
import 'src/core/providers/theme_provider.dart';
import 'src/core/providers/locale_provider.dart';
import 'src/features/auth/providers/auth_provider.dart';
import 'src/features/binance/providers/binance_connection_provider.dart';
import 'src/core/services/storage_service.dart';
import 'src/core/services/exchange_rate_service.dart';
// import 'src/services/notification_service.dart'; // Android API 29 호환성 문제로 임시 비활성화
import 'firebase_options.dart';

/// 백그라운드 메시지 핸들러 (top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('🌙 백그라운드 메시지: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화 임시 비활성화 (timeout 문제 해결)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');

    // 백그라운드 메시지 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 알림 서비스 초기화 (Android API 29 호환성 문제로 임시 비활성화)
    // await NotificationService().initialize();
  } catch (e) {
    print('⚠️ Firebase initialization failed: $e');
    print('📱 Running without Firebase (offline mode)');
  }

  // Hive 초기화 (로컬 데이터베이스)
  await Hive.initFlutter();

  // 🔑 바이낸스 API 키 및 환율 데이터를 백그라운드에서 초기화 (비동기)
  _initializeBackgroundServices();

  runApp(
    const ProviderScope(
      child: TradeCoinApp(),
    ),
  );
}

/// 백그라운드 서비스 초기화 (논블로킹)
void _initializeBackgroundServices() {
  // 바이낸스 API 키 및 환율 데이터를 비동기로 초기화
  Future.wait([
    _initializeBinanceApiKeys(),
    _initializeExchangeRates(),
  ]).catchError((error) {
    print('⚠️ 백그라운드 서비스 초기화 중 일부 오류 발생: $error');
    return [];
  });
}

/// 바이낸스 API 키 초기화 함수
Future<void> _initializeBinanceApiKeys() async {
  try {
    final storage = StorageService.instance;

    // 기존 저장된 API 키 확인
    final keyData = await storage.loadBinanceApiKeys();

    if (keyData != null && keyData['hasApiKey'] == true) {
      final apiKey = keyData['apiKey'] as String;
      final isTestnet = keyData['isTestnet'] as bool;
      print('✅ 저장된 바이낸스 API 키 발견');
      print('   API: ${apiKey.length > 8 ? '${apiKey.substring(0, 4)}***${apiKey.substring(apiKey.length - 4)}' : '****'}');
      print('   모드: ${isTestnet ? 'TESTNET' : 'MAINNET'}');
    } else {
      print('⚠️ 저장된 API 키가 없습니다. 프로필에서 설정해주세요.');
    }
  } catch (e) {
    print('❌ API 키 초기화 오류: $e');
  }
}

/// 환율 데이터 초기화 함수
Future<void> _initializeExchangeRates() async {
  try {
    print('💱 환율 데이터 초기화 중...');
    final exchangeRateService = ExchangeRateService();
    await exchangeRateService.fetchExchangeRates();
    print('✅ 환율 데이터 초기화 완료!');
  } catch (e) {
    print('❌ 환율 초기화 오류: $e');
  }
}

class TradeCoinApp extends ConsumerStatefulWidget {
  const TradeCoinApp({super.key});

  @override
  ConsumerState<TradeCoinApp> createState() => _TradeCoinAppState();
}

class _TradeCoinAppState extends ConsumerState<TradeCoinApp> {
  @override
  void initState() {
    super.initState();
    print('🚀 TradeCoinApp: 앱 초기화 시작...');
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeState = ref.watch(themeProvider);
    final localeState = ref.watch(localeProvider);

    // 인증 상태 변화 로깅만 수행 (바이낸스 연결은 MainScaffold에서 처리)
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      final userData = next.userData;
      print('👤 인증 상태 변화 감지: ${userData?.email ?? "로그아웃"}');

      if (userData == null) {
        print('⚠️ 사용자 로그아웃 상태 - 바이낸스 연결 해제');
        ref.read(binanceConnectionProvider.notifier).disconnect();
      }
    });

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // 다국어 설정
      locale: localeState.locale,

      // 테마 설정 - 새로운 theme provider 사용
      theme: themeState.lightTheme,
      darkTheme: themeState.darkTheme,
      themeMode: _getThemeMode(themeState.themeMode),

      // 라우팅
      routerConfig: router,
    );
  }

  ThemeMode _getThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}