import '../../core/providers/locale_provider.dart';

class CurrencyUtils {
  static String formatAmount(
    double amount,
    String currencyCode, {
    int? decimalPlaces,
    bool compact = false,
  }) {
    // 통화별 소수점 자릿수 설정
    final decimals = decimalPlaces ?? _getDefaultDecimalPlaces(currencyCode);

    // 큰 숫자의 경우 압축 형식 사용
    if (compact && amount >= 1000000) {
      return _formatCompactAmount(amount, currencyCode);
    }

    return formatCurrency(amount, currencyCode, decimalPlaces: decimals);
  }

  static int _getDefaultDecimalPlaces(String currencyCode) {
    switch (currencyCode) {
      case 'JPY':
      case 'KRW':
        return 0; // 원, 엔은 소수점 없음
      case 'BTC':
      case 'ETH':
        return 6; // 암호화폐는 소수점 6자리
      default:
        return 2; // 일반 통화는 소수점 2자리
    }
  }

  static String _formatCompactAmount(double amount, String currencyCode) {
    final currencyInfo = getCurrencyInfo(currencyCode);

    String compactValue;
    if (amount >= 1000000000) {
      compactValue = '${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      compactValue = '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      compactValue = '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      compactValue = amount.toStringAsFixed(_getDefaultDecimalPlaces(currencyCode));
    }

    return '${currencyInfo.symbol}$compactValue';
  }

  // 퍼센트 변화율 포매팅
  static String formatPercentage(double percentage, {int decimalPlaces = 2}) {
    final sign = percentage >= 0 ? '+' : '';
    return '$sign${percentage.toStringAsFixed(decimalPlaces)}%';
  }

  // 24시간 변화율 색상 결정
  static String get24HourChangeColor(double changePercent) {
    if (changePercent > 0) return 'success';
    if (changePercent < 0) return 'danger';
    return 'neutral';
  }

  // 통화 변환 (실제로는 API를 통해 실시간 환율 적용해야 함)
  static double convertCurrency(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) {
    if (fromCurrency == toCurrency) return amount;

    // 실제 앱에서는 실시간 환율 API를 사용해야 합니다
    final exchangeRates = getExchangeRates(fromCurrency);
    final rate = exchangeRates[toCurrency] ?? 1.0;

    return amount * rate;
  }

  // 통화별 입력 검증
  static bool isValidAmount(String input, String currencyCode) {
    if (input.isEmpty) return false;

    final double? amount = double.tryParse(input);
    if (amount == null || amount < 0) return false;

    // 통화별 최소/최대 금액 검증
    switch (currencyCode) {
      case 'KRW':
        return amount >= 1000 && amount <= 1000000000; // 1천원 ~ 10억원
      case 'USD':
      case 'EUR':
      case 'GBP':
        return amount >= 1 && amount <= 1000000; // $1 ~ $1M
      case 'JPY':
        return amount >= 100 && amount <= 100000000; // ¥100 ~ ¥100M
      default:
        return amount >= 0.01 && amount <= 1000000;
    }
  }

  // 통화별 최소 주문 금액
  static double getMinimumOrderAmount(String currencyCode) {
    switch (currencyCode) {
      case 'KRW':
        return 5000; // 5천원
      case 'USD':
      case 'EUR':
      case 'GBP':
        return 10; // $10, €10, £10
      case 'JPY':
        return 1000; // ¥1000
      case 'CNY':
        return 50; // ¥50
      default:
        return 10;
    }
  }

  // 통화 입력 필드 힌트 텍스트
  static String getAmountHintText(String currencyCode, String languageCode) {
    final minAmount = getMinimumOrderAmount(currencyCode);
    final formattedMin = formatAmount(minAmount, currencyCode);

    switch (languageCode) {
      case 'ko':
        return '최소 주문 금액: $formattedMin';
      case 'ja':
        return '最小注文金額: $formattedMin';
      case 'zh':
        return '最小订单金额: $formattedMin';
      default:
        return 'Minimum order: $formattedMin';
    }
  }

  // 수수료 계산
  static Map<String, double> calculateFees(
    double amount,
    String currencyCode, {
    double tradingFeeRate = 0.001, // 0.1% 기본 수수료
    double withdrawalFeeRate = 0.0005, // 0.05% 출금 수수료
  }) {
    final tradingFee = amount * tradingFeeRate;
    final withdrawalFee = amount * withdrawalFeeRate;
    final totalFees = tradingFee + withdrawalFee;
    final netAmount = amount - totalFees;

    return {
      'amount': amount,
      'tradingFee': tradingFee,
      'withdrawalFee': withdrawalFee,
      'totalFees': totalFees,
      'netAmount': netAmount,
    };
  }

  // 리스크 레벨별 권장 포지션 크기
  static double getRecommendedPositionSize(
    double totalBalance,
    String riskLevel,
    double leverage,
  ) {
    late double riskPercentage;

    switch (riskLevel.toLowerCase()) {
      case 'low':
      case '낮음':
        riskPercentage = 0.02; // 2%
        break;
      case 'medium':
      case '보통':
        riskPercentage = 0.05; // 5%
        break;
      case 'high':
      case '높음':
        riskPercentage = 0.10; // 10%
        break;
      default:
        riskPercentage = 0.05;
    }

    final basePosition = totalBalance * riskPercentage;
    return basePosition * leverage;
  }
}