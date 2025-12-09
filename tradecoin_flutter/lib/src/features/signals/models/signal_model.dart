class SignalModel {
  final String id;
  final String symbol;
  final String pair;
  final String signalType; // 'buy', 'sell', 'hold'
  final double confidenceScore; // 0.0 - 1.0
  final String strength; // 'weak', 'medium', 'strong'
  final double currentPrice;
  final double targetPrice;
  final double stopLoss;
  final double takeProfit;
  final String timeframe; // '1m', '5m', '15m', '1h', '4h', '1d'
  final DateTime timestamp;
  final DateTime? expiryTime;
  final bool isActive;
  final List<String> indicators;
  final TechnicalAnalysis technicalAnalysis;
  final SentimentAnalysis sentimentAnalysis;
  final MarketConditions marketConditions;
  final RiskAssessment riskAssessment;
  final String? description;
  final Map<String, dynamic>? metadata;

  // 개인화 관련 필드 추가
  final double personalizedScore;
  final List<String> tags;
  final bool isFavorite;
  final String? userNotes;
  final PersonalizationData? personalization;

  const SignalModel({
    required this.id,
    required this.symbol,
    required this.pair,
    required this.signalType,
    required this.confidenceScore,
    required this.strength,
    required this.currentPrice,
    required this.targetPrice,
    required this.stopLoss,
    required this.takeProfit,
    required this.timeframe,
    required this.timestamp,
    this.expiryTime,
    required this.isActive,
    required this.indicators,
    required this.technicalAnalysis,
    required this.sentimentAnalysis,
    required this.marketConditions,
    required this.riskAssessment,
    this.description,
    this.metadata,
    this.personalizedScore = 0.0,
    this.tags = const [],
    this.isFavorite = false,
    this.userNotes,
    this.personalization,
  });

  factory SignalModel.fromJson(Map<String, dynamic> json) {
    return SignalModel(
      id: json['id'] ?? '',
      symbol: json['symbol'] ?? '',
      pair: json['pair'] ?? '',
      signalType: json['signalType'] ?? 'hold',
      confidenceScore: (json['confidenceScore'] ?? 0.0).toDouble(),
      strength: json['strength'] ?? 'medium',
      currentPrice: (json['currentPrice'] ?? 0.0).toDouble(),
      targetPrice: (json['targetPrice'] ?? 0.0).toDouble(),
      stopLoss: (json['stopLoss'] ?? 0.0).toDouble(),
      takeProfit: (json['takeProfit'] ?? 0.0).toDouble(),
      timeframe: json['timeframe'] ?? '1h',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()).toLocal(),
      expiryTime: json['expiryTime'] != null ? DateTime.parse(json['expiryTime']).toLocal() : null,
      isActive: json['isActive'] ?? true,
      indicators: List<String>.from(json['indicators'] ?? []),
      technicalAnalysis: TechnicalAnalysis.fromJson(json['technicalAnalysis'] ?? {}),
      sentimentAnalysis: SentimentAnalysis.fromJson(json['sentimentAnalysis'] ?? {}),
      marketConditions: MarketConditions.fromJson(json['marketConditions'] ?? {}),
      riskAssessment: RiskAssessment.fromJson(json['riskAssessment'] ?? {}),
      description: json['description'],
      metadata: json['metadata'],
      personalizedScore: (json['personalizedScore'] ?? 0.0).toDouble(),
      tags: List<String>.from(json['tags'] ?? []),
      isFavorite: json['isFavorite'] ?? false,
      userNotes: json['userNotes'],
      personalization: json['personalization'] != null ? PersonalizationData.fromJson(json['personalization']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'pair': pair,
      'signalType': signalType,
      'confidenceScore': confidenceScore,
      'strength': strength,
      'currentPrice': currentPrice,
      'targetPrice': targetPrice,
      'stopLoss': stopLoss,
      'takeProfit': takeProfit,
      'timeframe': timeframe,
      'timestamp': timestamp.toIso8601String(),
      'expiryTime': expiryTime?.toIso8601String(),
      'isActive': isActive,
      'indicators': indicators,
      'technicalAnalysis': technicalAnalysis.toJson(),
      'sentimentAnalysis': sentimentAnalysis.toJson(),
      'marketConditions': marketConditions.toJson(),
      'riskAssessment': riskAssessment.toJson(),
      'description': description,
      'metadata': metadata,
      'personalizedScore': personalizedScore,
      'tags': tags,
      'isFavorite': isFavorite,
      'userNotes': userNotes,
      'personalization': personalization?.toJson(),
    };
  }

  double get priceChangePercent {
    if (currentPrice == 0) return 0.0;
    return ((targetPrice - currentPrice) / currentPrice) * 100;
  }

  String get priceChangeFormatted {
    final change = priceChangePercent;
    final prefix = change >= 0 ? '+' : '';
    return '$prefix${change.toStringAsFixed(2)}%';
  }

  bool get isExpired {
    if (expiryTime == null) return false;
    return DateTime.now().isAfter(expiryTime!);
  }

  String get strengthKorean {
    switch (strength) {
      case 'weak':
        return '약함';
      case 'medium':
        return '중간';
      case 'strong':
        return '강함';
      default:
        return '알 수 없음';
    }
  }

  String get signalTypeKorean {
    switch (signalType) {
      case 'buy':
        return '매수';
      case 'sell':
        return '매도';
      case 'hold':
        return '보유';
      default:
        return '알 수 없음';
    }
  }

  // 개인화 점수 계산
  double calculatePersonalizedScore(UserPreferences userPrefs) {
    double score = confidenceScore * 100; // 기본 신뢰도 점수

    // 선호 코인 가중치
    if (userPrefs.favoriteCoins.contains(symbol)) {
      score *= 1.2;
    }

    // 선호 시간프레임 가중치
    if (userPrefs.preferredTimeframes.contains(timeframe)) {
      score *= 1.1;
    }

    // 리스크 레벨 조정
    final riskScore = _getRiskScore(riskAssessment.riskLevel);
    if (riskScore > userPrefs.maxRiskLevel) {
      score *= 0.8; // 리스크가 높으면 점수 감소
    }

    // 신뢰도 임계값 확인
    if (confidenceScore < userPrefs.minConfidenceThreshold) {
      score *= 0.6;
    }

    return score.clamp(0.0, 100.0);
  }

  int _getRiskScore(String riskLevel) {
    switch (riskLevel) {
      case 'low':
        return 1;
      case 'medium':
        return 2;
      case 'high':
        return 3;
      case 'extreme':
        return 4;
      default:
        return 2;
    }
  }

  // 시그널 액션 이모지
  String get actionEmoji {
    switch (signalType) {
      case 'buy':
        return '📈';
      case 'sell':
        return '📉';
      case 'hold':
        return '⏸️';
      default:
        return '❓';
    }
  }

  // 강도 컬러
  String get strengthColor {
    switch (strength) {
      case 'weak':
        return '#FFA726'; // 오렌지
      case 'medium':
        return '#42A5F5'; // 블루
      case 'strong':
        return '#66BB6A'; // 그린
      default:
        return '#9E9E9E'; // 그레이
    }
  }
}

class TechnicalAnalysis {
  final double rsi;
  final double macd;
  final double sma20;
  final double sma50;
  final double sma200;
  final double bollingerUpper;
  final double bollingerLower;
  final double volume;
  final double volumeAvg;
  final String trend; // 'bullish', 'bearish', 'neutral'
  final List<String> patterns;
  final Map<String, double> oscillators;

  const TechnicalAnalysis({
    required this.rsi,
    required this.macd,
    required this.sma20,
    required this.sma50,
    required this.sma200,
    required this.bollingerUpper,
    required this.bollingerLower,
    required this.volume,
    required this.volumeAvg,
    required this.trend,
    required this.patterns,
    required this.oscillators,
  });

  factory TechnicalAnalysis.fromJson(Map<String, dynamic> json) {
    return TechnicalAnalysis(
      rsi: (json['rsi'] ?? 50.0).toDouble(),
      macd: (json['macd'] ?? 0.0).toDouble(),
      sma20: (json['sma20'] ?? 0.0).toDouble(),
      sma50: (json['sma50'] ?? 0.0).toDouble(),
      sma200: (json['sma200'] ?? 0.0).toDouble(),
      bollingerUpper: (json['bollingerUpper'] ?? 0.0).toDouble(),
      bollingerLower: (json['bollingerLower'] ?? 0.0).toDouble(),
      volume: (json['volume'] ?? 0.0).toDouble(),
      volumeAvg: (json['volumeAvg'] ?? 0.0).toDouble(),
      trend: json['trend'] ?? 'neutral',
      patterns: List<String>.from(json['patterns'] ?? []),
      oscillators: Map<String, double>.from((json['oscillators'] ?? {}).map((k, v) => MapEntry(k, v.toDouble()))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rsi': rsi,
      'macd': macd,
      'sma20': sma20,
      'sma50': sma50,
      'sma200': sma200,
      'bollingerUpper': bollingerUpper,
      'bollingerLower': bollingerLower,
      'volume': volume,
      'volumeAvg': volumeAvg,
      'trend': trend,
      'patterns': patterns,
      'oscillators': oscillators,
    };
  }

  String get trendKorean {
    switch (trend) {
      case 'bullish':
        return '상승';
      case 'bearish':
        return '하락';
      case 'neutral':
        return '중립';
      default:
        return '알 수 없음';
    }
  }
}

class SentimentAnalysis {
  final double sentimentScore; // -1.0 to 1.0
  final String sentimentLabel; // 'very_bearish', 'bearish', 'neutral', 'bullish', 'very_bullish'
  final double socialMediaScore;
  final double newsScore;
  final double institutionalFlow;
  final Map<String, double> emotionScores;
  final List<String> keyFactors;

  // 트윗 번역 관련 필드 추가
  final String? tweetTextEn; // 원문 (영어)
  final String? tweetTextKo; // 번역문 (한국어)
  final String? tweetAuthor; // 작성자
  final String? tweetUrl; // 트윗 URL

  const SentimentAnalysis({
    required this.sentimentScore,
    required this.sentimentLabel,
    required this.socialMediaScore,
    required this.newsScore,
    required this.institutionalFlow,
    required this.emotionScores,
    required this.keyFactors,
    this.tweetTextEn,
    this.tweetTextKo,
    this.tweetAuthor,
    this.tweetUrl,
  });

  factory SentimentAnalysis.fromJson(Map<String, dynamic> json) {
    return SentimentAnalysis(
      sentimentScore: (json['sentimentScore'] ?? 0.0).toDouble(),
      sentimentLabel: json['sentimentLabel'] ?? 'neutral',
      socialMediaScore: (json['socialMediaScore'] ?? 0.0).toDouble(),
      newsScore: (json['newsScore'] ?? 0.0).toDouble(),
      institutionalFlow: (json['institutionalFlow'] ?? 0.0).toDouble(),
      emotionScores: Map<String, double>.from((json['emotionScores'] ?? {}).map((k, v) => MapEntry(k, v.toDouble()))),
      keyFactors: List<String>.from(json['keyFactors'] ?? []),
      tweetTextEn: json['tweetTextEn'],
      tweetTextKo: json['tweetTextKo'],
      tweetAuthor: json['tweetAuthor'],
      tweetUrl: json['tweetUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sentimentScore': sentimentScore,
      'sentimentLabel': sentimentLabel,
      'socialMediaScore': socialMediaScore,
      'newsScore': newsScore,
      'institutionalFlow': institutionalFlow,
      'emotionScores': emotionScores,
      'keyFactors': keyFactors,
      'tweetTextEn': tweetTextEn,
      'tweetTextKo': tweetTextKo,
      'tweetAuthor': tweetAuthor,
      'tweetUrl': tweetUrl,
    };
  }

  String get sentimentLabelKorean {
    switch (sentimentLabel) {
      case 'very_bearish':
        return '매우 약세';
      case 'bearish':
        return '약세';
      case 'neutral':
        return '중립';
      case 'bullish':
        return '강세';
      case 'very_bullish':
        return '매우 강세';
      default:
        return '알 수 없음';
    }
  }
}

class MarketConditions {
  final double volatility;
  final double liquidity;
  final String marketPhase; // 'accumulation', 'markup', 'distribution', 'markdown'
  final double fearGreedIndex;
  final double dominanceIndex;
  final Map<String, double> correlations;

  const MarketConditions({
    required this.volatility,
    required this.liquidity,
    required this.marketPhase,
    required this.fearGreedIndex,
    required this.dominanceIndex,
    required this.correlations,
  });

  factory MarketConditions.fromJson(Map<String, dynamic> json) {
    return MarketConditions(
      volatility: (json['volatility'] ?? 0.0).toDouble(),
      liquidity: (json['liquidity'] ?? 0.0).toDouble(),
      marketPhase: json['marketPhase'] ?? 'neutral',
      fearGreedIndex: (json['fearGreedIndex'] ?? 50.0).toDouble(),
      dominanceIndex: (json['dominanceIndex'] ?? 0.0).toDouble(),
      correlations: Map<String, double>.from((json['correlations'] ?? {}).map((k, v) => MapEntry(k, v.toDouble()))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'volatility': volatility,
      'liquidity': liquidity,
      'marketPhase': marketPhase,
      'fearGreedIndex': fearGreedIndex,
      'dominanceIndex': dominanceIndex,
      'correlations': correlations,
    };
  }

  String get marketPhaseKorean {
    switch (marketPhase) {
      case 'accumulation':
        return '축적';
      case 'markup':
        return '상승';
      case 'distribution':
        return '분산';
      case 'markdown':
        return '하락';
      default:
        return '알 수 없음';
    }
  }
}

class RiskAssessment {
  final String riskLevel; // 'low', 'medium', 'high', 'extreme'
  final double maxLoss; // Maximum potential loss percentage
  final double riskReward; // Risk to reward ratio
  final List<String> riskFactors;
  final double positionSize; // Recommended position size percentage
  final String riskManagement; // Risk management strategy

  const RiskAssessment({
    required this.riskLevel,
    required this.maxLoss,
    required this.riskReward,
    required this.riskFactors,
    required this.positionSize,
    required this.riskManagement,
  });

  factory RiskAssessment.fromJson(Map<String, dynamic> json) {
    return RiskAssessment(
      riskLevel: json['riskLevel'] ?? 'medium',
      maxLoss: (json['maxLoss'] ?? 0.0).toDouble(),
      riskReward: (json['riskReward'] ?? 1.0).toDouble(),
      riskFactors: List<String>.from(json['riskFactors'] ?? []),
      positionSize: (json['positionSize'] ?? 1.0).toDouble(),
      riskManagement: json['riskManagement'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riskLevel': riskLevel,
      'maxLoss': maxLoss,
      'riskReward': riskReward,
      'riskFactors': riskFactors,
      'positionSize': positionSize,
      'riskManagement': riskManagement,
    };
  }

  String get riskLevelKorean {
    switch (riskLevel) {
      case 'low':
        return '낮음';
      case 'medium':
        return '보통';
      case 'high':
        return '높음';
      case 'extreme':
        return '매우 높음';
      default:
        return '알 수 없음';
    }
  }
}

class SignalHistoryModel {
  final String id;
  final String signalId;
  final String symbol;
  final String pair;
  final String signalType;
  final double entryPrice;
  final double exitPrice;
  final double profitLoss;
  final double profitLossPercent;
  final String status; // 'open', 'closed', 'expired'
  final String result; // 'win', 'loss', 'breakeven'
  final DateTime entryTime;
  final DateTime? exitTime;
  final String? notes;

  const SignalHistoryModel({
    required this.id,
    required this.signalId,
    required this.symbol,
    required this.pair,
    required this.signalType,
    required this.entryPrice,
    required this.exitPrice,
    required this.profitLoss,
    required this.profitLossPercent,
    required this.status,
    required this.result,
    required this.entryTime,
    this.exitTime,
    this.notes,
  });

  factory SignalHistoryModel.fromJson(Map<String, dynamic> json) {
    return SignalHistoryModel(
      id: json['id'] ?? '',
      signalId: json['signalId'] ?? '',
      symbol: json['symbol'] ?? '',
      pair: json['pair'] ?? '',
      signalType: json['signalType'] ?? 'hold',
      entryPrice: (json['entryPrice'] ?? 0.0).toDouble(),
      exitPrice: (json['exitPrice'] ?? 0.0).toDouble(),
      profitLoss: (json['profitLoss'] ?? 0.0).toDouble(),
      profitLossPercent: (json['profitLossPercent'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'open',
      result: json['result'] ?? 'pending',
      entryTime: DateTime.parse(json['entryTime'] ?? DateTime.now().toIso8601String()),
      exitTime: json['exitTime'] != null ? DateTime.parse(json['exitTime']) : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'signalId': signalId,
      'symbol': symbol,
      'pair': pair,
      'signalType': signalType,
      'entryPrice': entryPrice,
      'exitPrice': exitPrice,
      'profitLoss': profitLoss,
      'profitLossPercent': profitLossPercent,
      'status': status,
      'result': result,
      'entryTime': entryTime.toIso8601String(),
      'exitTime': exitTime?.toIso8601String(),
      'notes': notes,
    };
  }

  String get statusKorean {
    switch (status) {
      case 'open':
        return '진행중';
      case 'closed':
        return '완료';
      case 'expired':
        return '만료';
      default:
        return '알 수 없음';
    }
  }

  String get resultKorean {
    switch (result) {
      case 'win':
        return '성공';
      case 'loss':
        return '실패';
      case 'breakeven':
        return '무승부';
      default:
        return '진행중';
    }
  }
}

class SignalStatsModel {
  final int totalSignals;
  final int activeSignals;
  final int closedSignals;
  final double winRate;
  final double avgProfit;
  final double totalProfitLoss;
  final double bestTrade;
  final double worstTrade;
  final int consecutiveWins;
  final int consecutiveLosses;
  final Map<String, int> signalTypeStats;
  final Map<String, double> symbolStats;
  final DateTime lastUpdated;

  const SignalStatsModel({
    required this.totalSignals,
    required this.activeSignals,
    required this.closedSignals,
    required this.winRate,
    required this.avgProfit,
    required this.totalProfitLoss,
    required this.bestTrade,
    required this.worstTrade,
    required this.consecutiveWins,
    required this.consecutiveLosses,
    required this.signalTypeStats,
    required this.symbolStats,
    required this.lastUpdated,
  });

  factory SignalStatsModel.fromJson(Map<String, dynamic> json) {
    return SignalStatsModel(
      totalSignals: json['totalSignals'] ?? 0,
      activeSignals: json['activeSignals'] ?? 0,
      closedSignals: json['closedSignals'] ?? 0,
      winRate: (json['winRate'] ?? 0.0).toDouble(),
      avgProfit: (json['avgProfit'] ?? 0.0).toDouble(),
      totalProfitLoss: (json['totalProfitLoss'] ?? 0.0).toDouble(),
      bestTrade: (json['bestTrade'] ?? 0.0).toDouble(),
      worstTrade: (json['worstTrade'] ?? 0.0).toDouble(),
      consecutiveWins: json['consecutiveWins'] ?? 0,
      consecutiveLosses: json['consecutiveLosses'] ?? 0,
      signalTypeStats: Map<String, int>.from(json['signalTypeStats'] ?? {}),
      symbolStats: Map<String, double>.from((json['symbolStats'] ?? {}).map((k, v) => MapEntry(k, v.toDouble()))),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSignals': totalSignals,
      'activeSignals': activeSignals,
      'closedSignals': closedSignals,
      'winRate': winRate,
      'avgProfit': avgProfit,
      'totalProfitLoss': totalProfitLoss,
      'bestTrade': bestTrade,
      'worstTrade': worstTrade,
      'consecutiveWins': consecutiveWins,
      'consecutiveLosses': consecutiveLosses,
      'signalTypeStats': signalTypeStats,
      'symbolStats': symbolStats,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

// 개인화 데이터 클래스
class PersonalizationData {
  final double userScore;
  final Map<String, double> weights;
  final List<String> appliedFilters;
  final DateTime lastUpdated;

  const PersonalizationData({
    required this.userScore,
    required this.weights,
    required this.appliedFilters,
    required this.lastUpdated,
  });

  factory PersonalizationData.fromJson(Map<String, dynamic> json) {
    return PersonalizationData(
      userScore: (json['userScore'] ?? 0.0).toDouble(),
      weights: Map<String, double>.from((json['weights'] ?? {}).map((k, v) => MapEntry(k, v.toDouble()))),
      appliedFilters: List<String>.from(json['appliedFilters'] ?? []),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userScore': userScore,
      'weights': weights,
      'appliedFilters': appliedFilters,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

// 사용자 선호도 클래스
class UserPreferences {
  final List<String> favoriteCoins;
  final List<String> preferredTimeframes;
  final List<String> preferredSignalTypes;
  final int maxRiskLevel; // 1: low, 2: medium, 3: high, 4: extreme
  final double minConfidenceThreshold; // 0.0 - 1.0
  final double minExpectedReturn;
  final bool enablePushNotifications;
  final bool enableEmailAlerts;
  final Map<String, double> coinWeights;
  final Map<String, bool> notificationSettings;

  const UserPreferences({
    this.favoriteCoins = const [],
    this.preferredTimeframes = const [],
    this.preferredSignalTypes = const [],
    this.maxRiskLevel = 2, // medium
    this.minConfidenceThreshold = 0.7,
    this.minExpectedReturn = 5.0,
    this.enablePushNotifications = true,
    this.enableEmailAlerts = false,
    this.coinWeights = const {},
    this.notificationSettings = const {},
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      favoriteCoins: List<String>.from(json['favoriteCoins'] ?? []),
      preferredTimeframes: List<String>.from(json['preferredTimeframes'] ?? []),
      preferredSignalTypes: List<String>.from(json['preferredSignalTypes'] ?? []),
      maxRiskLevel: json['maxRiskLevel'] ?? 2,
      minConfidenceThreshold: (json['minConfidenceThreshold'] ?? 0.7).toDouble(),
      minExpectedReturn: (json['minExpectedReturn'] ?? 5.0).toDouble(),
      enablePushNotifications: json['enablePushNotifications'] ?? true,
      enableEmailAlerts: json['enableEmailAlerts'] ?? false,
      coinWeights: Map<String, double>.from((json['coinWeights'] ?? {}).map((k, v) => MapEntry(k, v.toDouble()))),
      notificationSettings: Map<String, bool>.from(json['notificationSettings'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'favoriteCoins': favoriteCoins,
      'preferredTimeframes': preferredTimeframes,
      'preferredSignalTypes': preferredSignalTypes,
      'maxRiskLevel': maxRiskLevel,
      'minConfidenceThreshold': minConfidenceThreshold,
      'minExpectedReturn': minExpectedReturn,
      'enablePushNotifications': enablePushNotifications,
      'enableEmailAlerts': enableEmailAlerts,
      'coinWeights': coinWeights,
      'notificationSettings': notificationSettings,
    };
  }

  UserPreferences copyWith({
    List<String>? favoriteCoins,
    List<String>? preferredTimeframes,
    List<String>? preferredSignalTypes,
    int? maxRiskLevel,
    double? minConfidenceThreshold,
    double? minExpectedReturn,
    bool? enablePushNotifications,
    bool? enableEmailAlerts,
    Map<String, double>? coinWeights,
    Map<String, bool>? notificationSettings,
  }) {
    return UserPreferences(
      favoriteCoins: favoriteCoins ?? this.favoriteCoins,
      preferredTimeframes: preferredTimeframes ?? this.preferredTimeframes,
      preferredSignalTypes: preferredSignalTypes ?? this.preferredSignalTypes,
      maxRiskLevel: maxRiskLevel ?? this.maxRiskLevel,
      minConfidenceThreshold: minConfidenceThreshold ?? this.minConfidenceThreshold,
      minExpectedReturn: minExpectedReturn ?? this.minExpectedReturn,
      enablePushNotifications: enablePushNotifications ?? this.enablePushNotifications,
      enableEmailAlerts: enableEmailAlerts ?? this.enableEmailAlerts,
      coinWeights: coinWeights ?? this.coinWeights,
      notificationSettings: notificationSettings ?? this.notificationSettings,
    );
  }

  String get riskLevelKorean {
    switch (maxRiskLevel) {
      case 1:
        return '낮음';
      case 2:
        return '보통';
      case 3:
        return '높음';
      case 4:
        return '매우 높음';
      default:
        return '보통';
    }
  }
}

// 시그널 필터 클래스
class SignalFilter {
  final List<String>? symbols;
  final List<String>? signalTypes;
  final List<String>? timeframes;
  final List<String>? riskLevels;
  final double? minConfidence;
  final double? maxConfidence;
  final double? minExpectedReturn;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? activeOnly;
  final bool? favoritesOnly;

  const SignalFilter({
    this.symbols,
    this.signalTypes,
    this.timeframes,
    this.riskLevels,
    this.minConfidence,
    this.maxConfidence,
    this.minExpectedReturn,
    this.startDate,
    this.endDate,
    this.activeOnly,
    this.favoritesOnly,
  });

  factory SignalFilter.fromJson(Map<String, dynamic> json) {
    return SignalFilter(
      symbols: json['symbols'] != null ? List<String>.from(json['symbols']) : null,
      signalTypes: json['signalTypes'] != null ? List<String>.from(json['signalTypes']) : null,
      timeframes: json['timeframes'] != null ? List<String>.from(json['timeframes']) : null,
      riskLevels: json['riskLevels'] != null ? List<String>.from(json['riskLevels']) : null,
      minConfidence: json['minConfidence']?.toDouble(),
      maxConfidence: json['maxConfidence']?.toDouble(),
      minExpectedReturn: json['minExpectedReturn']?.toDouble(),
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      activeOnly: json['activeOnly'],
      favoritesOnly: json['favoritesOnly'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbols': symbols,
      'signalTypes': signalTypes,
      'timeframes': timeframes,
      'riskLevels': riskLevels,
      'minConfidence': minConfidence,
      'maxConfidence': maxConfidence,
      'minExpectedReturn': minExpectedReturn,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'activeOnly': activeOnly,
      'favoritesOnly': favoritesOnly,
    };
  }

  bool matches(SignalModel signal) {
    if (symbols != null && !symbols!.contains(signal.symbol)) {
      return false;
    }

    if (signalTypes != null && !signalTypes!.contains(signal.signalType)) {
      return false;
    }

    if (timeframes != null && !timeframes!.contains(signal.timeframe)) {
      return false;
    }

    if (riskLevels != null && !riskLevels!.contains(signal.riskAssessment.riskLevel)) {
      return false;
    }

    if (minConfidence != null && signal.confidenceScore < minConfidence!) {
      return false;
    }

    if (maxConfidence != null && signal.confidenceScore > maxConfidence!) {
      return false;
    }

    if (minExpectedReturn != null && signal.priceChangePercent < minExpectedReturn!) {
      return false;
    }

    if (startDate != null && signal.timestamp.isBefore(startDate!)) {
      return false;
    }

    if (endDate != null && signal.timestamp.isAfter(endDate!)) {
      return false;
    }

    if (activeOnly == true && !signal.isActive) {
      return false;
    }

    if (favoritesOnly == true && !signal.isFavorite) {
      return false;
    }

    return true;
  }

  SignalFilter copyWith({
    List<String>? symbols,
    List<String>? signalTypes,
    List<String>? timeframes,
    List<String>? riskLevels,
    double? minConfidence,
    double? maxConfidence,
    double? minExpectedReturn,
    DateTime? startDate,
    DateTime? endDate,
    bool? activeOnly,
    bool? favoritesOnly,
  }) {
    return SignalFilter(
      symbols: symbols ?? this.symbols,
      signalTypes: signalTypes ?? this.signalTypes,
      timeframes: timeframes ?? this.timeframes,
      riskLevels: riskLevels ?? this.riskLevels,
      minConfidence: minConfidence ?? this.minConfidence,
      maxConfidence: maxConfidence ?? this.maxConfidence,
      minExpectedReturn: minExpectedReturn ?? this.minExpectedReturn,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      activeOnly: activeOnly ?? this.activeOnly,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    );
  }
}