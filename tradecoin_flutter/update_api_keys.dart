import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  print('🔄 바이낸스 API 키 업데이트 시작...');

  final prefs = await SharedPreferences.getInstance();

  // 새로운 API 키
  const newApiKey = 'jhoeFXEYEzkkDZrRViFvlbkAmBM70KCnSn1zxQVv9ytI2iAo00qeanW2DB4Yv2Yx';
  const newSecretKey = 'rQmNdhZKzOalGuArsdY5foUkhCS8LnkvCwd4gTaIDDRgK0RL2dvuWpJ9HnemMRIg';

  // API 키 저장
  await prefs.setBool('binance_api_connected', true);
  await prefs.setBool('binance_is_testnet', false);  // 실거래 모드
  await prefs.setString('binance_api_key', newApiKey);
  await prefs.setString('binance_secret_key', newSecretKey);

  // 마스킹된 키 생성
  String maskedApiKey = '${newApiKey.substring(0, 4)}${'*' * (newApiKey.length - 8)}${newApiKey.substring(newApiKey.length - 4)}';
  String maskedSecretKey = '${newSecretKey.substring(0, 4)}${'*' * (newSecretKey.length - 8)}${newSecretKey.substring(newSecretKey.length - 4)}';

  await prefs.setString('binance_api_key_mask', maskedApiKey);
  await prefs.setString('binance_secret_key_mask', maskedSecretKey);

  print('✅ API 키 업데이트 완료!');
  print('   API Key: $maskedApiKey');
  print('   Secret: $maskedSecretKey');
  print('   모드: MAINNET (실거래)');
  print('\n앱을 재시작하면 새 API 키가 적용됩니다.');
}
