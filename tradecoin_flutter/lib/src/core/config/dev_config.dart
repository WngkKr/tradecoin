/// 🔧 개발 모드 전용 설정
/// 프로덕션 빌드 시 이 값들은 무시됩니다.
class DevConfig {
  // 🚨 경고: 절대 프로덕션에 배포하지 마세요!
  static const bool isDevelopmentMode = true;

  // 🔑 개발 모드 전용 바이낸스 API 키
  // 테스트용으로만 사용하며, 실제 사용자는 프로필에서 직접 입력해야 합니다.
  static const String devBinanceApiKey =
      'jhoeFXEYEzkkDZrRViFvlbkAmBM70KCnSn1zxQVv9ytI2iAo00qeanW2DB4Yv2Yx';
  static const String devBinanceSecretKey =
      'rQmNdhZKzOalGuArsdY5foUkhCS8LnkvCwd4gTaIDDRgK0RL2dvuWpJ9HnemMRIg';
  static const bool devIsTestnet = false; // false = 실거래 모드

  // 🧪 자동 입력 활성화 여부
  static const bool autoFillApiKeys = true;
}
