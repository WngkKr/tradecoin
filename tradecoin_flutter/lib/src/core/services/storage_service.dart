import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 🔐 플랫폼별 저장소 서비스
/// - SharedPreferences: 일반 데이터 (연결 상태, 설정 등)
/// - FlutterSecureStorage: 민감한 데이터 (API 키, 시크릿 키) - 암호화됨
class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();

  StorageService._();

  /// 🔒 암호화된 저장소 (API 키 전용)
  final _secureStorage = const FlutterSecureStorage();

  /// 문자열 값 저장
  Future<bool> setString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(key, value);
    } catch (e) {
      print('❌ Storage setString 실패: $e');
      return false;
    }
  }

  /// 문자열 값 가져오기
  Future<String?> getString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      print('❌ Storage getString 실패: $e');
      return null;
    }
  }

  /// 불리언 값 저장
  Future<bool> setBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(key, value);
    } catch (e) {
      print('❌ Storage setBool 실패: $e');
      return false;
    }
  }

  /// 불리언 값 가져오기
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? defaultValue;
    } catch (e) {
      print('❌ Storage getBool 실패: $e');
      return defaultValue;
    }
  }

  /// 정수 값 저장
  Future<bool> setInt(String key, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setInt(key, value);
    } catch (e) {
      print('❌ Storage setInt 실패: $e');
      return false;
    }
  }

  /// 정수 값 가져오기
  Future<int> getInt(String key, {int defaultValue = 0}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(key) ?? defaultValue;
    } catch (e) {
      print('❌ Storage getInt 실패: $e');
      return defaultValue;
    }
  }

  /// JSON 객체 저장
  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    try {
      final jsonString = json.encode(value);
      return await setString(key, jsonString);
    } catch (e) {
      print('❌ Storage setJson 실패: $e');
      return false;
    }
  }

  /// JSON 객체 가져오기
  Future<Map<String, dynamic>?> getJson(String key) async {
    try {
      final jsonString = await getString(key);
      if (jsonString == null) return null;
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('❌ Storage getJson 실패: $e');
      return null;
    }
  }

  /// 값 삭제
  Future<bool> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(key);
    } catch (e) {
      print('❌ Storage remove 실패: $e');
      return false;
    }
  }

  /// 모든 값 삭제
  Future<bool> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.clear();
    } catch (e) {
      print('❌ Storage clear 실패: $e');
      return false;
    }
  }

  /// 특정 키가 존재하는지 확인
  Future<bool> containsKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(key);
    } catch (e) {
      print('❌ Storage containsKey 실패: $e');
      return false;
    }
  }

  /// 🔒 바이낸스 API 키 저장 (암호화된 저장소 사용)
  Future<bool> saveBinanceApiKeys({
    required String apiKey,
    required String secretKey,
    required bool isTestnet,
  }) async {
    try {
      print('🔄 StorageService: API 키 저장 시작...');
      print('🔄 StorageService: API 키 길이: ${apiKey.length}, 시크릿 키 길이: ${secretKey.length}');
      print('🔄 StorageService: 테스트넷 모드: $isTestnet');

      // 연결 상태 저장 (SharedPreferences - 일반 데이터)
      print('🔄 StorageService: 연결 상태 저장 중...');
      final connected = await setBool('binance_api_connected', true);
      print('🔄 StorageService: 연결 상태 저장 결과: $connected');

      final testnet = await setBool('binance_is_testnet', isTestnet);
      print('🔄 StorageService: 테스트넷 상태 저장 결과: $testnet');

      // 🔒 실제 API 키 저장 (FlutterSecureStorage - 암호화됨)
      print('🔄 StorageService: 암호화된 저장소에 API 키 저장 중...');
      await _secureStorage.write(key: 'binance_api_key', value: apiKey);
      print('✅ StorageService: API 키 암호화 저장 완료');

      await _secureStorage.write(key: 'binance_secret_key', value: secretKey);
      print('✅ StorageService: 시크릿 키 암호화 저장 완료');

      // 마스킹된 키 저장 (표시용 - SharedPreferences)
      String maskedApiKey = '';
      String maskedSecretKey = '';

      if (apiKey.length > 8) {
        maskedApiKey = '${apiKey.substring(0, 4)}${'*' * (apiKey.length - 8)}${apiKey.substring(apiKey.length - 4)}';
      }

      if (secretKey.length > 8) {
        maskedSecretKey = '${secretKey.substring(0, 4)}${'*' * (secretKey.length - 8)}${secretKey.substring(secretKey.length - 4)}';
      }

      print('🔄 StorageService: 마스킹된 키 저장 중...');
      final maskedApiResult = await setString('binance_api_key_mask', maskedApiKey);
      print('🔄 StorageService: 마스킹된 API 키 저장 결과: $maskedApiResult');

      final maskedSecretResult = await setString('binance_secret_key_mask', maskedSecretKey);
      print('🔄 StorageService: 마스킹된 시크릿 키 저장 결과: $maskedSecretResult');

      // 모든 저장 결과 확인
      final allSuccess = connected && testnet && maskedApiResult && maskedSecretResult;

      if (allSuccess) {
        print('✅ 바이낸스 API 키가 암호화되어 안전하게 저장되었습니다');
      } else {
        print('❌ 일부 데이터 저장 실패 - connected: $connected, testnet: $testnet, maskedApi: $maskedApiResult, maskedSecret: $maskedSecretResult');
      }

      return allSuccess;
    } catch (e, stackTrace) {
      print('❌ 바이낸스 API 키 저장 실패: $e');
      print('❌ 스택 트레이스: $stackTrace');
      return false;
    }
  }

  /// 🔒 바이낸스 API 키 불러오기 (암호화된 저장소에서)
  Future<Map<String, dynamic>?> loadBinanceApiKeys() async {
    try {
      final hasApiKey = await getBool('binance_api_connected');
      if (!hasApiKey) return null;

      final isTestnet = await getBool('binance_is_testnet', defaultValue: true);

      // 🔒 암호화된 저장소에서 실제 키 불러오기
      final apiKey = await _secureStorage.read(key: 'binance_api_key');
      final secretKey = await _secureStorage.read(key: 'binance_secret_key');

      // SharedPreferences에서 마스킹된 키 불러오기 (표시용)
      final maskedApiKey = await getString('binance_api_key_mask');
      final maskedSecretKey = await getString('binance_secret_key_mask');

      return {
        'hasApiKey': hasApiKey,
        'isTestnet': isTestnet,
        'apiKey': apiKey ?? '',
        'secretKey': secretKey ?? '',
        'maskedApiKey': maskedApiKey ?? '',
        'maskedSecretKey': maskedSecretKey ?? '',
      };
    } catch (e) {
      print('❌ 바이낸스 API 키 불러오기 실패: $e');
      return null;
    }
  }

  /// 🔒 바이낸스 API 키 삭제 (암호화된 저장소 포함)
  Future<bool> clearBinanceApiKeys() async {
    try {
      // SharedPreferences에서 일반 데이터 삭제
      await remove('binance_api_connected');
      await remove('binance_is_testnet');
      await remove('binance_api_key_mask');
      await remove('binance_secret_key_mask');

      // 🔒 암호화된 저장소에서 API 키 삭제
      await _secureStorage.delete(key: 'binance_api_key');
      await _secureStorage.delete(key: 'binance_secret_key');

      print('✅ 바이낸스 API 키가 완전히 삭제되었습니다 (암호화된 저장소 포함)');
      return true;
    } catch (e) {
      print('❌ 바이낸스 API 키 삭제 실패: $e');
      return false;
    }
  }
}