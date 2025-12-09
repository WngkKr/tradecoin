import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 환율 정보를 관리하는 서비스
/// USD를 기준으로 각국 통화로 변환
class ExchangeRateService {
  static final ExchangeRateService _instance = ExchangeRateService._internal();
  factory ExchangeRateService() => _instance;
  ExchangeRateService._internal();

  // 환율 캐시
  Map<String, double> _rates = {};
  DateTime? _lastUpdate;

  // 캐시 유효 시간 (1시간)
  static const Duration _cacheValidDuration = Duration(hours: 1);

  // 기본 환율 (API 실패 시 fallback)
  static const Map<String, double> _fallbackRates = {
    'KRW': 1350.0,  // 1 USD = 1,350 KRW
    'JPY': 150.0,   // 1 USD = 150 JPY
    'CNY': 7.2,     // 1 USD = 7.2 CNY
    'EUR': 0.92,    // 1 USD = 0.92 EUR
    'GBP': 0.79,    // 1 USD = 0.79 GBP
  };

  /// 환율 데이터 가져오기 (무료 API 사용)
  Future<void> fetchExchangeRates() async {
    try {
      // 캐시가 유효하면 재사용
      if (_lastUpdate != null &&
          DateTime.now().difference(_lastUpdate!) < _cacheValidDuration) {
        print('✅ [환율] 캐시된 환율 사용 (마지막 업데이트: $_lastUpdate)');
        return;
      }

      print('🔄 [환율] 최신 환율 데이터 가져오는 중...');

      // 무료 환율 API 사용 (exchangerate-api.com)
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;

        _rates = {
          'USD': 1.0,
          'KRW': rates['KRW']?.toDouble() ?? _fallbackRates['KRW']!,
          'JPY': rates['JPY']?.toDouble() ?? _fallbackRates['JPY']!,
          'CNY': rates['CNY']?.toDouble() ?? _fallbackRates['CNY']!,
          'EUR': rates['EUR']?.toDouble() ?? _fallbackRates['EUR']!,
          'GBP': rates['GBP']?.toDouble() ?? _fallbackRates['GBP']!,
        };

        _lastUpdate = DateTime.now();

        // SharedPreferences에 저장
        await _saveToCache();

        print('✅ [환율] 환율 데이터 업데이트 완료');
        print('   💵 1 USD = ${_rates['KRW']!.toStringAsFixed(2)} KRW');
      } else {
        print('⚠️ [환율] API 응답 실패 (${response.statusCode}) - fallback 환율 사용');
        _useFallbackRates();
      }
    } catch (e) {
      print('❌ [환율] 환율 데이터 가져오기 실패: $e');

      // 캐시된 데이터 로드 시도
      final loaded = await _loadFromCache();
      if (!loaded) {
        _useFallbackRates();
      }
    }
  }

  /// Fallback 환율 사용
  void _useFallbackRates() {
    _rates = Map.from(_fallbackRates);
    _rates['USD'] = 1.0;
    _lastUpdate = DateTime.now();
    print('⚠️ [환율] Fallback 환율 사용 중');
  }

  /// 캐시에서 환율 데이터 로드
  Future<bool> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('exchange_rates');
      final lastUpdateStr = prefs.getString('exchange_rates_update');

      if (cachedData != null && lastUpdateStr != null) {
        final data = json.decode(cachedData) as Map<String, dynamic>;
        _rates = data.map((key, value) => MapEntry(key, value.toDouble()));
        _lastUpdate = DateTime.parse(lastUpdateStr);

        print('✅ [환율] 캐시된 환율 데이터 로드 성공');
        return true;
      }
    } catch (e) {
      print('❌ [환율] 캐시 로드 실패: $e');
    }
    return false;
  }

  /// 환율 데이터 캐시에 저장
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('exchange_rates', json.encode(_rates));
      await prefs.setString('exchange_rates_update', _lastUpdate!.toIso8601String());
    } catch (e) {
      print('❌ [환율] 캐시 저장 실패: $e');
    }
  }

  /// USD 금액을 지정된 통화로 변환
  double convertFromUSD(double usdAmount, String targetCurrency) {
    if (targetCurrency == 'USD') return usdAmount;

    final rate = _rates[targetCurrency];
    if (rate == null) {
      print('⚠️ [환율] $targetCurrency 환율 없음 - USD 반환');
      return usdAmount;
    }

    return usdAmount * rate;
  }

  /// 지정된 통화 금액을 USD로 변환
  double convertToUSD(double amount, String sourceCurrency) {
    if (sourceCurrency == 'USD') return amount;

    final rate = _rates[sourceCurrency];
    if (rate == null) {
      print('⚠️ [환율] $sourceCurrency 환율 없음 - 원본 금액 반환');
      return amount;
    }

    return amount / rate;
  }

  /// USD 금액을 포맷된 문자열로 변환 (USD + 원화 병기)
  String formatUSDWithKRW(double usdAmount, {bool showSymbol = true}) {
    final krwAmount = convertFromUSD(usdAmount, 'KRW');

    final usdFormatted = showSymbol
        ? '\$${usdAmount.toStringAsFixed(2)}'
        : usdAmount.toStringAsFixed(2);

    final krwFormatted = _formatNumber(krwAmount);

    return '$usdFormatted (₩$krwFormatted)';
  }

  /// 금액을 통화 형식으로 포맷 (쉼표 포함)
  String formatCurrency(double amount, String currency) {
    // KRW, JPY, CNY는 소수점 없이 정수로 표시
    final formattedNumber = (currency == 'KRW' || currency == 'JPY' || currency == 'CNY')
        ? _formatNumberInteger(amount)
        : _formatNumber(amount);

    switch (currency) {
      case 'USD':
        return '\$$formattedNumber';
      case 'KRW':
        return '₩$formattedNumber';
      case 'JPY':
        return '¥$formattedNumber';
      case 'EUR':
        return '€$formattedNumber';
      case 'GBP':
        return '£$formattedNumber';
      case 'CNY':
        return '¥$formattedNumber';
      default:
        return '$currency $formattedNumber';
    }
  }

  /// 숫자를 정수로 포맷 (소수점 없음, 쉼표 포함)
  String _formatNumberInteger(double number) {
    final integerPart = number.round().toString();

    // 정수 부분에 쉼표 추가
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedInteger = integerPart.replaceAllMapped(
      regex,
      (Match m) => '${m[1]},',
    );

    return formattedInteger;
  }

  /// 숫자를 쉼표로 포맷 (1,234,567.89)
  String _formatNumber(double number) {
    // 소수점 2자리까지 표시
    final parts = number.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    // 정수 부분에 쉼표 추가
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedInteger = integerPart.replaceAllMapped(
      regex,
      (Match m) => '${m[1]},',
    );

    return '$formattedInteger.$decimalPart';
  }

  /// 현재 환율 정보 가져오기
  Map<String, double> get rates => Map.unmodifiable(_rates);

  /// 마지막 업데이트 시간
  DateTime? get lastUpdate => _lastUpdate;

  /// KRW 환율 가져오기
  double get krwRate => _rates['KRW'] ?? _fallbackRates['KRW']!;

  /// 환율이 로드되었는지 확인
  bool get isLoaded => _rates.isNotEmpty;
}
