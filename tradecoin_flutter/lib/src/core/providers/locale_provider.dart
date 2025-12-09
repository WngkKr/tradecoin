import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 지원하는 언어 enum
enum AppLanguage {
  korean('ko', 'KR', '한국어', 'KRW'),
  english('en', 'US', 'English', 'USD'),
  japanese('ja', 'JP', '日本語', 'JPY'),
  chinese('zh', 'CN', '中文', 'CNY');

  const AppLanguage(this.languageCode, this.countryCode, this.displayName, this.defaultCurrency);

  final String languageCode;
  final String countryCode;
  final String displayName;
  final String defaultCurrency;

  Locale get locale => Locale(languageCode, countryCode);
}

// 언어 상태 클래스
class LocaleState {
  final AppLanguage currentLanguage;
  final Locale locale;
  final String currency;

  const LocaleState({
    required this.currentLanguage,
    required this.locale,
    required this.currency,
  });

  LocaleState copyWith({
    AppLanguage? currentLanguage,
    Locale? locale,
    String? currency,
  }) {
    return LocaleState(
      currentLanguage: currentLanguage ?? this.currentLanguage,
      locale: locale ?? this.locale,
      currency: currency ?? this.currency,
    );
  }
}

// 언어 프로바이더
class LocaleNotifier extends StateNotifier<LocaleState> {
  LocaleNotifier() : super(const LocaleState(
    currentLanguage: AppLanguage.korean,
    locale: Locale('ko', 'KR'),
    currency: 'KRW',
  )) {
    _loadLocalePreference();
  }

  // 언어 설정 로드
  Future<void> _loadLocalePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString('app_language') ?? 'ko';
      final savedCurrency = prefs.getString('app_currency');

      AppLanguage language;
      switch (savedLanguageCode) {
        case 'en':
          language = AppLanguage.english;
          break;
        case 'ja':
          language = AppLanguage.japanese;
          break;
        case 'zh':
          language = AppLanguage.chinese;
          break;
        case 'ko':
        default:
          language = AppLanguage.korean;
          break;
      }

      String currency = savedCurrency ?? language.defaultCurrency;

      state = LocaleState(
        currentLanguage: language,
        locale: language.locale,
        currency: currency,
      );
    } catch (e) {
      print('언어 설정 로드 실패: $e');
    }
  }

  // 언어 변경
  Future<void> setLanguage(AppLanguage language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', language.languageCode);

      // 언어 변경 시 기본 통화도 함께 변경
      String newCurrency = state.currency;
      if (state.currency == state.currentLanguage.defaultCurrency) {
        newCurrency = language.defaultCurrency;
        await prefs.setString('app_currency', newCurrency);
      }

      state = LocaleState(
        currentLanguage: language,
        locale: language.locale,
        currency: newCurrency,
      );
    } catch (e) {
      print('언어 설정 저장 실패: $e');
    }
  }

  // 통화 변경
  Future<void> setCurrency(String currency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_currency', currency);

      state = state.copyWith(currency: currency);
    } catch (e) {
      print('통화 설정 저장 실패: $e');
    }
  }

  // 시스템 언어 감지 및 설정
  Future<void> setSystemLanguage() async {
    try {
      final systemLocale = PlatformDispatcher.instance.locale;
      AppLanguage language;

      switch (systemLocale.languageCode) {
        case 'ko':
          language = AppLanguage.korean;
          break;
        case 'ja':
          language = AppLanguage.japanese;
          break;
        case 'zh':
          language = AppLanguage.chinese;
          break;
        case 'en':
        default:
          language = AppLanguage.english;
          break;
      }

      await setLanguage(language);
    } catch (e) {
      print('시스템 언어 설정 실패: $e');
    }
  }
}

// Provider 정의
final localeProvider = StateNotifierProvider<LocaleNotifier, LocaleState>((ref) {
  return LocaleNotifier();
});

// 현재 언어만 간단히 접근하는 Provider
final currentLanguageProvider = Provider<AppLanguage>((ref) {
  return ref.watch(localeProvider).currentLanguage;
});

// 현재 로케일만 간단히 접근하는 Provider
final currentLocaleProvider = Provider<Locale>((ref) {
  return ref.watch(localeProvider).locale;
});

// 현재 통화만 간단히 접근하는 Provider
final currentCurrencyProvider = Provider<String>((ref) {
  return ref.watch(localeProvider).currency;
});

// 지원 통화 목록
class CurrencyInfo {
  final String code;
  final String symbol;
  final String name;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
  });
}

const List<CurrencyInfo> supportedCurrencies = [
  CurrencyInfo(code: 'KRW', symbol: '₩', name: '한국 원'),
  CurrencyInfo(code: 'USD', symbol: '\$', name: 'US Dollar'),
  CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro'),
  CurrencyInfo(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
  CurrencyInfo(code: 'GBP', symbol: '£', name: 'British Pound'),
  CurrencyInfo(code: 'CNY', symbol: '¥', name: 'Chinese Yuan'),
  CurrencyInfo(code: 'HKD', symbol: 'HK\$', name: 'Hong Kong Dollar'),
  CurrencyInfo(code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar'),
  CurrencyInfo(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar'),
];

// 통화 정보 가져오기 함수
CurrencyInfo getCurrencyInfo(String currencyCode) {
  return supportedCurrencies.firstWhere(
    (currency) => currency.code == currencyCode,
    orElse: () => supportedCurrencies.first,
  );
}

// 통화 포맷팅 함수
String formatCurrency(double amount, String currencyCode, {int? decimalPlaces}) {
  final currencyInfo = getCurrencyInfo(currencyCode);
  final decimals = decimalPlaces ?? (currencyCode == 'JPY' ? 0 : 2);

  switch (currencyCode) {
    case 'KRW':
      return '₩${amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match match) => '${match[1]},'
      )}';
    case 'JPY':
      return '¥${amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match match) => '${match[1]},'
      )}';
    case 'CNY':
      return '¥${amount.toStringAsFixed(decimals).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match match) => '${match[1]},'
      )}';
    case 'USD':
    case 'EUR':
    case 'GBP':
    default:
      final formattedAmount = amount.toStringAsFixed(decimals).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match match) => '${match[1]},'
      );
      return '${currencyInfo.symbol}$formattedAmount';
  }
}

// 언어 변경 시 추천 통화 가져오기
List<String> getRecommendedCurrencies(AppLanguage language) {
  switch (language) {
    case AppLanguage.korean:
      return ['KRW', 'USD', 'EUR'];
    case AppLanguage.english:
      return ['USD', 'EUR', 'GBP'];
    case AppLanguage.japanese:
      return ['JPY', 'USD', 'KRW'];
    case AppLanguage.chinese:
      return ['CNY', 'HKD', 'USD'];
  }
}

// 언어별 기본 통화 추천 (fallback 함수)
List<String> getDefaultCurrenciesForLanguage(AppLanguage language) {
  final recommended = getRecommendedCurrencies(language);
  return recommended.isNotEmpty ? recommended : ['USD', 'EUR', 'KRW'];
}

// 통화 변환율 (실제로는 API에서 가져와야 함)
Map<String, double> getExchangeRates(String baseCurrency) {
  // 실제 앱에서는 실시간 환율 API를 사용해야 합니다
  // 여기서는 예시 데이터를 사용합니다
  const exchangeRates = {
    'USD': {
      'KRW': 1300.0,
      'EUR': 0.85,
      'JPY': 110.0,
      'GBP': 0.73,
      'CNY': 6.45,
    },
    'KRW': {
      'USD': 0.000769,
      'EUR': 0.000654,
      'JPY': 0.0846,
      'GBP': 0.000561,
      'CNY': 0.00496,
    },
    'EUR': {
      'USD': 1.18,
      'KRW': 1529.41,
      'JPY': 129.41,
      'GBP': 0.86,
      'CNY': 7.59,
    },
  };

  return Map<String, double>.from(exchangeRates[baseCurrency] ?? {});
}