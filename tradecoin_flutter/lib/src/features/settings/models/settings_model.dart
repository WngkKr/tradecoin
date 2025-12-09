// 알림 설정 모델
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
  final TimeOfDay quietStartTime;
  final TimeOfDay quietEndTime;

  const NotificationSettings({
    required this.pushEnabled,
    required this.emailEnabled,
    required this.smsEnabled,
    required this.priceAlerts,
    required this.signalAlerts,
    required this.newsAlerts,
    required this.portfolioAlerts,
    required this.tradingAlerts,
    required this.confidenceThreshold,
    required this.quietHoursEnabled,
    required this.quietStartTime,
    required this.quietEndTime,
  });

  factory NotificationSettings.defaultSettings() {
    return NotificationSettings(
      pushEnabled: true,
      emailEnabled: true,
      smsEnabled: false,
      priceAlerts: true,
      signalAlerts: true,
      newsAlerts: false,
      portfolioAlerts: true,
      tradingAlerts: true,
      confidenceThreshold: 75.0,
      quietHoursEnabled: false,
      quietStartTime: const TimeOfDay(hour: 22, minute: 0),
      quietEndTime: const TimeOfDay(hour: 8, minute: 0),
    );
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
      quietStartTime: TimeOfDay(
        hour: json['quiet_start_time']?['hour'] ?? 22,
        minute: json['quiet_start_time']?['minute'] ?? 0,
      ),
      quietEndTime: TimeOfDay(
        hour: json['quiet_end_time']?['hour'] ?? 8,
        minute: json['quiet_end_time']?['minute'] ?? 0,
      ),
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
      'quiet_start_time': {
        'hour': quietStartTime.hour,
        'minute': quietStartTime.minute,
      },
      'quiet_end_time': {
        'hour': quietEndTime.hour,
        'minute': quietEndTime.minute,
      },
    };
  }

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
    TimeOfDay? quietStartTime,
    TimeOfDay? quietEndTime,
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
    );
  }
}

// 시간 클래스 (Flutter의 TimeOfDay와 유사)
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  @override
  String toString() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeOfDay && other.hour == hour && other.minute == minute;
  }

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;
}

// 거래 설정 모델
class TradingSettings {
  final bool autoTradingEnabled;
  final double maxPositionSize;
  final double maxDailyLoss;
  final double maxLeverage;
  final bool stopLossEnabled;
  final double stopLossPercent;
  final bool takeProfitEnabled;
  final double takeProfitPercent;
  final int maxSimultaneousPositions;
  final List<String> allowedCurrencies;
  final List<String> blacklistedCoins;

  const TradingSettings({
    required this.autoTradingEnabled,
    required this.maxPositionSize,
    required this.maxDailyLoss,
    required this.maxLeverage,
    required this.stopLossEnabled,
    required this.stopLossPercent,
    required this.takeProfitEnabled,
    required this.takeProfitPercent,
    required this.maxSimultaneousPositions,
    required this.allowedCurrencies,
    required this.blacklistedCoins,
  });

  factory TradingSettings.defaultSettings() {
    return const TradingSettings(
      autoTradingEnabled: false,
      maxPositionSize: 100.0,
      maxDailyLoss: 50.0,
      maxLeverage: 5.0,
      stopLossEnabled: true,
      stopLossPercent: 3.0,
      takeProfitEnabled: true,
      takeProfitPercent: 10.0,
      maxSimultaneousPositions: 2,
      allowedCurrencies: ['USDT', 'BTC', 'ETH'],
      blacklistedCoins: [],
    );
  }

  factory TradingSettings.fromJson(Map<String, dynamic> json) {
    return TradingSettings(
      autoTradingEnabled: json['auto_trading_enabled'] ?? false,
      maxPositionSize: (json['max_position_size'] ?? 100.0).toDouble(),
      maxDailyLoss: (json['max_daily_loss'] ?? 50.0).toDouble(),
      maxLeverage: (json['max_leverage'] ?? 5.0).toDouble(),
      stopLossEnabled: json['stop_loss_enabled'] ?? true,
      stopLossPercent: (json['stop_loss_percent'] ?? 3.0).toDouble(),
      takeProfitEnabled: json['take_profit_enabled'] ?? true,
      takeProfitPercent: (json['take_profit_percent'] ?? 10.0).toDouble(),
      maxSimultaneousPositions: json['max_simultaneous_positions'] ?? 2,
      allowedCurrencies: List<String>.from(json['allowed_currencies'] ?? ['USDT', 'BTC', 'ETH']),
      blacklistedCoins: List<String>.from(json['blacklisted_coins'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'auto_trading_enabled': autoTradingEnabled,
      'max_position_size': maxPositionSize,
      'max_daily_loss': maxDailyLoss,
      'max_leverage': maxLeverage,
      'stop_loss_enabled': stopLossEnabled,
      'stop_loss_percent': stopLossPercent,
      'take_profit_enabled': takeProfitEnabled,
      'take_profit_percent': takeProfitPercent,
      'max_simultaneous_positions': maxSimultaneousPositions,
      'allowed_currencies': allowedCurrencies,
      'blacklisted_coins': blacklistedCoins,
    };
  }

  TradingSettings copyWith({
    bool? autoTradingEnabled,
    double? maxPositionSize,
    double? maxDailyLoss,
    double? maxLeverage,
    bool? stopLossEnabled,
    double? stopLossPercent,
    bool? takeProfitEnabled,
    double? takeProfitPercent,
    int? maxSimultaneousPositions,
    List<String>? allowedCurrencies,
    List<String>? blacklistedCoins,
  }) {
    return TradingSettings(
      autoTradingEnabled: autoTradingEnabled ?? this.autoTradingEnabled,
      maxPositionSize: maxPositionSize ?? this.maxPositionSize,
      maxDailyLoss: maxDailyLoss ?? this.maxDailyLoss,
      maxLeverage: maxLeverage ?? this.maxLeverage,
      stopLossEnabled: stopLossEnabled ?? this.stopLossEnabled,
      stopLossPercent: stopLossPercent ?? this.stopLossPercent,
      takeProfitEnabled: takeProfitEnabled ?? this.takeProfitEnabled,
      takeProfitPercent: takeProfitPercent ?? this.takeProfitPercent,
      maxSimultaneousPositions: maxSimultaneousPositions ?? this.maxSimultaneousPositions,
      allowedCurrencies: allowedCurrencies ?? this.allowedCurrencies,
      blacklistedCoins: blacklistedCoins ?? this.blacklistedCoins,
    );
  }
}

// 리스크 관리 설정 모델
class RiskManagementSettings {
  final double portfolioRiskPercent;
  final double singleTradeRiskPercent;
  final double maxDrawdownPercent;
  final bool emergencyStopEnabled;
  final double emergencyStopPercent;
  final bool volatilityFilterEnabled;
  final double maxVolatilityPercent;
  final bool correlationFilterEnabled;
  final double maxCorrelationPercent;

  const RiskManagementSettings({
    required this.portfolioRiskPercent,
    required this.singleTradeRiskPercent,
    required this.maxDrawdownPercent,
    required this.emergencyStopEnabled,
    required this.emergencyStopPercent,
    required this.volatilityFilterEnabled,
    required this.maxVolatilityPercent,
    required this.correlationFilterEnabled,
    required this.maxCorrelationPercent,
  });

  factory RiskManagementSettings.defaultSettings() {
    return const RiskManagementSettings(
      portfolioRiskPercent: 10.0,
      singleTradeRiskPercent: 2.0,
      maxDrawdownPercent: 15.0,
      emergencyStopEnabled: true,
      emergencyStopPercent: 20.0,
      volatilityFilterEnabled: false,
      maxVolatilityPercent: 50.0,
      correlationFilterEnabled: false,
      maxCorrelationPercent: 70.0,
    );
  }

  factory RiskManagementSettings.fromJson(Map<String, dynamic> json) {
    return RiskManagementSettings(
      portfolioRiskPercent: (json['portfolio_risk_percent'] ?? 10.0).toDouble(),
      singleTradeRiskPercent: (json['single_trade_risk_percent'] ?? 2.0).toDouble(),
      maxDrawdownPercent: (json['max_drawdown_percent'] ?? 15.0).toDouble(),
      emergencyStopEnabled: json['emergency_stop_enabled'] ?? true,
      emergencyStopPercent: (json['emergency_stop_percent'] ?? 20.0).toDouble(),
      volatilityFilterEnabled: json['volatility_filter_enabled'] ?? false,
      maxVolatilityPercent: (json['max_volatility_percent'] ?? 50.0).toDouble(),
      correlationFilterEnabled: json['correlation_filter_enabled'] ?? false,
      maxCorrelationPercent: (json['max_correlation_percent'] ?? 70.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'portfolio_risk_percent': portfolioRiskPercent,
      'single_trade_risk_percent': singleTradeRiskPercent,
      'max_drawdown_percent': maxDrawdownPercent,
      'emergency_stop_enabled': emergencyStopEnabled,
      'emergency_stop_percent': emergencyStopPercent,
      'volatility_filter_enabled': volatilityFilterEnabled,
      'max_volatility_percent': maxVolatilityPercent,
      'correlation_filter_enabled': correlationFilterEnabled,
      'max_correlation_percent': maxCorrelationPercent,
    };
  }

  RiskManagementSettings copyWith({
    double? portfolioRiskPercent,
    double? singleTradeRiskPercent,
    double? maxDrawdownPercent,
    bool? emergencyStopEnabled,
    double? emergencyStopPercent,
    bool? volatilityFilterEnabled,
    double? maxVolatilityPercent,
    bool? correlationFilterEnabled,
    double? maxCorrelationPercent,
  }) {
    return RiskManagementSettings(
      portfolioRiskPercent: portfolioRiskPercent ?? this.portfolioRiskPercent,
      singleTradeRiskPercent: singleTradeRiskPercent ?? this.singleTradeRiskPercent,
      maxDrawdownPercent: maxDrawdownPercent ?? this.maxDrawdownPercent,
      emergencyStopEnabled: emergencyStopEnabled ?? this.emergencyStopEnabled,
      emergencyStopPercent: emergencyStopPercent ?? this.emergencyStopPercent,
      volatilityFilterEnabled: volatilityFilterEnabled ?? this.volatilityFilterEnabled,
      maxVolatilityPercent: maxVolatilityPercent ?? this.maxVolatilityPercent,
      correlationFilterEnabled: correlationFilterEnabled ?? this.correlationFilterEnabled,
      maxCorrelationPercent: maxCorrelationPercent ?? this.maxCorrelationPercent,
    );
  }
}