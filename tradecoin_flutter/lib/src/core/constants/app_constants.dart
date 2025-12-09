import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'TradeCoin';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'AI Trading Platform';

  // API 엔드포인트 - 환경별 자동 선택
  // 개발 환경
  static const String _devBaseUrl = 'http://10.0.2.2:8080'; // Android Emulator
  static const String _devBaseUrlIOS = 'http://127.0.0.1:8080'; // iOS Simulator
  static const String _devBaseUrlRealDevice = 'http://192.168.68.108:8080'; // Real Device (Mac IP)

  // 프로덕션 환경 (Render 배포 후 여기에 실제 URL 입력)
  static const String _prodBaseUrl = 'https://tradecoin-api.onrender.com';

  // 실기기 여부 판단 (에뮬레이터가 아닌 경우)
  static bool get _isRealDevice {
    // 에뮬레이터/시뮬레이터가 아닌 실제 기기인지 확인
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android: 10.0.2.2가 아닌 다른 IP 사용 시 실기기
      return true; // 일단 true로 설정 (실기기 우선)
    }
    return false;
  }

  // 현재 환경에 맞는 URL 자동 선택
  static String get apiBaseUrl {
    if (kDebugMode) {
      // 디버그 모드: 로컬 서버 사용
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return _devBaseUrlIOS;
      }
      // Android: 실기기면 Mac IP, 에뮬레이터면 10.0.2.2
      return _devBaseUrlRealDevice; // 실기기 테스트를 위해 Mac IP 사용
    } else {
      // 릴리즈 모드: 프로덕션 서버 사용
      return _prodBaseUrl;
    }
  }

  // 하위 호환성을 위한 baseUrl (deprecated)
  @Deprecated('Use apiBaseUrl instead')
  static const String baseUrl = 'https://api.tradecoin.app';

  // Firebase 컬렉션명
  static const String usersCollection = 'users';
  static const String signalsCollection = 'signals';
  static const String portfolioCollection = 'userPortfolios';

  // 페이지 사이즈
  static const int defaultPageSize = 20;

  // 애니메이션 지속시간
  static const int animationDurationMs = 300;
}