import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../models/signal_model.dart';

class SignalService {
  static final String _baseUrl = AppConstants.apiBaseUrl;

  // 시그널 목록 가져오기
  Future<List<SignalModel>> getSignals({
    SignalFilter? filter,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      if (filter != null) {
        if (filter.symbols != null && filter.symbols!.isNotEmpty) {
          queryParams['symbols'] = filter.symbols!.join(',');
        }
        if (filter.signalTypes != null && filter.signalTypes!.isNotEmpty) {
          queryParams['signalTypes'] = filter.signalTypes!.join(',');
        }
        if (filter.timeframes != null && filter.timeframes!.isNotEmpty) {
          queryParams['timeframes'] = filter.timeframes!.join(',');
        }
        if (filter.riskLevels != null && filter.riskLevels!.isNotEmpty) {
          queryParams['riskLevels'] = filter.riskLevels!.join(',');
        }
        if (filter.minConfidence != null) {
          queryParams['minConfidence'] = filter.minConfidence.toString();
        }
        if (filter.maxConfidence != null) {
          queryParams['maxConfidence'] = filter.maxConfidence.toString();
        }
        if (filter.activeOnly != null) {
          queryParams['activeOnly'] = filter.activeOnly.toString();
        }
      }

      final uri = Uri.parse('$_baseUrl/signals').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> signalsData = data['signals'] ?? [];

        return signalsData
            .map((item) => SignalModel.fromJson(item))
            .toList();
      } else {
        throw Exception('Failed to load signals: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching signals: $e');
      return _getMockSignals();
    }
  }

  // 개인화된 시그널 가져오기
  Future<List<SignalModel>> getPersonalizedSignals({
    required String userId,
    UserPreferences? userPreferences,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'userId': userId,
        'limit': limit.toString(),
      };

      if (userPreferences != null) {
        queryParams['preferences'] = json.encode(userPreferences.toJson());
      }

      final uri = Uri.parse('$_baseUrl/signals/personalized').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> signalsData = data['signals'] ?? [];

        return signalsData
            .map((item) => SignalModel.fromJson(item))
            .toList();
      } else {
        throw Exception('Failed to load personalized signals: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching personalized signals: $e');
      // 목업 데이터로 개인화 적용
      final mockSignals = _getMockSignals();
      if (userPreferences != null) {
        return _applyPersonalization(mockSignals, userPreferences);
      }
      return mockSignals;
    }
  }

  // 시그널 상세 정보 가져오기
  Future<SignalModel?> getSignalDetail(String signalId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/signals/$signalId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return SignalModel.fromJson(data);
      } else {
        throw Exception('Failed to load signal detail: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching signal detail: $e');
      return _getMockSignals().firstWhere(
        (signal) => signal.id == signalId,
        orElse: () => _getMockSignals().first,
      );
    }
  }

  // 시그널 즐겨찾기 토글
  Future<bool> toggleFavorite(String signalId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/signals/$signalId/favorite'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'userId': userId}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error toggling favorite: $e');
      return true; // 목업 환경에서는 항상 성공
    }
  }

  // 사용자 노트 저장
  Future<bool> saveUserNote(String signalId, String userId, String note) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/signals/$signalId/note'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': userId,
          'note': note,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error saving user note: $e');
      return true; // 목업 환경에서는 항상 성공
    }
  }

  // 사용자 선호도 저장
  Future<bool> saveUserPreferences(String userId, UserPreferences preferences) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/$userId/preferences'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(preferences.toJson()),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error saving user preferences: $e');
      return true; // 목업 환경에서는 항상 성공
    }
  }

  // 사용자 선호도 불러오기
  Future<UserPreferences?> getUserPreferences(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId/preferences'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return UserPreferences.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching user preferences: $e');
      return _getDefaultUserPreferences();
    }
  }

  // 시그널 통계 가져오기
  Future<SignalStatsModel> getSignalStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/signals/stats'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return SignalStatsModel.fromJson(data);
      } else {
        throw Exception('Failed to load signal stats: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching signal stats: $e');
      return _getMockSignalStats();
    }
  }

  // 시그널 검색
  Future<List<SignalModel>> searchSignals({
    required String query,
    SignalFilter? filter,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'q': query,
        'limit': limit.toString(),
      };

      if (filter != null) {
        queryParams['filter'] = json.encode(filter.toJson());
      }

      final uri = Uri.parse('$_baseUrl/signals/search').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> signalsData = data['signals'] ?? [];

        return signalsData
            .map((item) => SignalModel.fromJson(item))
            .toList();
      } else {
        throw Exception('Failed to search signals: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching signals: $e');
      return _getMockSignals()
          .where((signal) =>
            signal.symbol.toLowerCase().contains(query.toLowerCase()) ||
            signal.description?.toLowerCase().contains(query.toLowerCase()) == true)
          .toList();
    }
  }

  // 개인화 적용 로직
  List<SignalModel> _applyPersonalization(List<SignalModel> signals, UserPreferences preferences) {
    return signals.map((signal) {
      final personalizedScore = signal.calculatePersonalizedScore(preferences);
      return SignalModel(
        id: signal.id,
        symbol: signal.symbol,
        pair: signal.pair,
        signalType: signal.signalType,
        confidenceScore: signal.confidenceScore,
        strength: signal.strength,
        currentPrice: signal.currentPrice,
        targetPrice: signal.targetPrice,
        stopLoss: signal.stopLoss,
        takeProfit: signal.takeProfit,
        timeframe: signal.timeframe,
        timestamp: signal.timestamp,
        expiryTime: signal.expiryTime,
        isActive: signal.isActive,
        indicators: signal.indicators,
        technicalAnalysis: signal.technicalAnalysis,
        sentimentAnalysis: signal.sentimentAnalysis,
        marketConditions: signal.marketConditions,
        riskAssessment: signal.riskAssessment,
        description: signal.description,
        metadata: signal.metadata,
        personalizedScore: personalizedScore,
        tags: signal.tags,
        isFavorite: preferences.favoriteCoins.contains(signal.symbol),
        userNotes: signal.userNotes,
        personalization: signal.personalization,
      );
    }).toList()..sort((a, b) => b.personalizedScore.compareTo(a.personalizedScore));
  }

  // 목업 데이터 생성
  List<SignalModel> _getMockSignals() {
    return [
      SignalModel(
        id: '1',
        symbol: 'BTC',
        pair: 'BTCUSDT',
        signalType: 'buy',
        confidenceScore: 0.85,
        strength: 'strong',
        currentPrice: 67234.50,
        targetPrice: 71500.00,
        stopLoss: 65000.00,
        takeProfit: 73000.00,
        timeframe: '4h',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        expiryTime: DateTime.now().add(const Duration(hours: 24)),
        isActive: true,
        indicators: ['MACD', 'RSI', 'Bollinger Bands'],
        technicalAnalysis: const TechnicalAnalysis(
          rsi: 32.5,
          macd: 0.85,
          sma20: 66800.0,
          sma50: 65200.0,
          sma200: 62800.0,
          bollingerUpper: 68500.0,
          bollingerLower: 65200.0,
          volume: 1250000.0,
          volumeAvg: 980000.0,
          trend: 'bullish',
          patterns: ['Falling Wedge', 'Golden Cross'],
          oscillators: {'RSI': 32.5, 'Stoch': 28.7},
        ),
        sentimentAnalysis: const SentimentAnalysis(
          sentimentScore: 0.7,
          sentimentLabel: 'bullish',
          socialMediaScore: 0.75,
          newsScore: 0.68,
          institutionalFlow: 2340000000.0,
          emotionScores: {'greed': 0.8, 'fear': 0.2},
          keyFactors: ['ETF 승인 기대', '기관 투자 증가'],
        ),
        marketConditions: const MarketConditions(
          volatility: 0.25,
          liquidity: 0.95,
          marketPhase: 'accumulation',
          fearGreedIndex: 75.0,
          dominanceIndex: 45.2,
          correlations: {'ETH': 0.8, 'Gold': -0.3},
        ),
        riskAssessment: const RiskAssessment(
          riskLevel: 'medium',
          maxLoss: 3.5,
          riskReward: 2.8,
          riskFactors: ['Market volatility', 'Regulatory uncertainty'],
          positionSize: 5.0,
          riskManagement: 'Tight stop-loss with trailing',
        ),
        description: '비트코인 ETF 승인 기대와 기관 투자 유입으로 인한 강력한 매수 시그널',
        personalizedScore: 85.0,
        tags: ['Breakout', 'ETF', 'Institutional'],
        isFavorite: false,
      ),
      SignalModel(
        id: '2',
        symbol: 'ETH',
        pair: 'ETHUSDT',
        signalType: 'buy',
        confidenceScore: 0.78,
        strength: 'medium',
        currentPrice: 2876.30,
        targetPrice: 3150.00,
        stopLoss: 2750.00,
        takeProfit: 3200.00,
        timeframe: '1h',
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
        expiryTime: DateTime.now().add(const Duration(hours: 12)),
        isActive: true,
        indicators: ['EMA', 'Volume', 'Support/Resistance'],
        technicalAnalysis: const TechnicalAnalysis(
          rsi: 58.2,
          macd: 0.45,
          sma20: 2850.0,
          sma50: 2820.0,
          sma200: 2780.0,
          bollingerUpper: 2920.0,
          bollingerLower: 2780.0,
          volume: 890000.0,
          volumeAvg: 750000.0,
          trend: 'bullish',
          patterns: ['Bull Flag'],
          oscillators: {'RSI': 58.2, 'Williams': -25.4},
        ),
        sentimentAnalysis: const SentimentAnalysis(
          sentimentScore: 0.65,
          sentimentLabel: 'bullish',
          socialMediaScore: 0.62,
          newsScore: 0.70,
          institutionalFlow: 1200000000.0,
          emotionScores: {'optimism': 0.7, 'confidence': 0.6},
          keyFactors: ['ETH 2.0 스테이킹', 'DeFi 활성화'],
        ),
        marketConditions: const MarketConditions(
          volatility: 0.30,
          liquidity: 0.88,
          marketPhase: 'markup',
          fearGreedIndex: 68.0,
          dominanceIndex: 18.7,
          correlations: {'BTC': 0.8, 'DeFi': 0.9},
        ),
        riskAssessment: const RiskAssessment(
          riskLevel: 'medium',
          maxLoss: 4.2,
          riskReward: 2.5,
          riskFactors: ['Gas fee impact', 'DeFi competition'],
          positionSize: 4.5,
          riskManagement: 'Volume-based stop loss',
        ),
        description: 'ETH 2.0 업그레이드와 DeFi 생태계 성장으로 인한 상승 모멘텀',
        personalizedScore: 78.0,
        tags: ['DeFi', 'ETH2.0', 'Staking'],
        isFavorite: false,
      ),
      SignalModel(
        id: '3',
        symbol: 'DOGE',
        pair: 'DOGEUSDT',
        signalType: 'sell',
        confidenceScore: 0.72,
        strength: 'medium',
        currentPrice: 0.285,
        targetPrice: 0.245,
        stopLoss: 0.295,
        takeProfit: 0.235,
        timeframe: '15m',
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        expiryTime: DateTime.now().add(const Duration(hours: 6)),
        isActive: true,
        indicators: ['RSI', 'MACD', 'Volume'],
        technicalAnalysis: const TechnicalAnalysis(
          rsi: 78.5,
          macd: -0.02,
          sma20: 0.290,
          sma50: 0.275,
          sma200: 0.268,
          bollingerUpper: 0.295,
          bollingerLower: 0.265,
          volume: 2500000.0,
          volumeAvg: 1800000.0,
          trend: 'bearish',
          patterns: ['Double Top'],
          oscillators: {'RSI': 78.5, 'CCI': 185.2},
        ),
        sentimentAnalysis: const SentimentAnalysis(
          sentimentScore: -0.3,
          sentimentLabel: 'bearish',
          socialMediaScore: 0.45,
          newsScore: -0.2,
          institutionalFlow: -450000000.0,
          emotionScores: {'fear': 0.6, 'uncertainty': 0.7},
          keyFactors: ['Elon Musk 트윗 감소', '밈코인 열풍 진정'],
        ),
        marketConditions: const MarketConditions(
          volatility: 0.45,
          liquidity: 0.72,
          marketPhase: 'distribution',
          fearGreedIndex: 42.0,
          dominanceIndex: 1.2,
          correlations: {'SHIB': 0.7, 'BTC': 0.4},
        ),
        riskAssessment: const RiskAssessment(
          riskLevel: 'high',
          maxLoss: 3.8,
          riskReward: 1.8,
          riskFactors: ['High volatility', 'Meme coin risk'],
          positionSize: 2.5,
          riskManagement: 'Quick scalp with tight stops',
        ),
        description: '과매수 구간에서 모멘텀 약화, 단기 조정 예상',
        personalizedScore: 72.0,
        tags: ['Meme', 'Overbought', 'Scalping'],
        isFavorite: false,
      ),
    ];
  }

  UserPreferences _getDefaultUserPreferences() {
    return const UserPreferences(
      favoriteCoins: ['BTC', 'ETH'],
      preferredTimeframes: ['1h', '4h'],
      preferredSignalTypes: ['buy', 'sell'],
      maxRiskLevel: 2,
      minConfidenceThreshold: 0.7,
      minExpectedReturn: 5.0,
      enablePushNotifications: true,
      enableEmailAlerts: false,
    );
  }

  SignalStatsModel _getMockSignalStats() {
    return SignalStatsModel(
      totalSignals: 847,
      activeSignals: 23,
      closedSignals: 824,
      winRate: 73.5,
      avgProfit: 8.2,
      totalProfitLoss: 2456.78,
      bestTrade: 45.6,
      worstTrade: -12.3,
      consecutiveWins: 8,
      consecutiveLosses: 2,
      signalTypeStats: {
        'buy': 456,
        'sell': 298,
        'hold': 93,
      },
      symbolStats: {
        'BTC': 234.5,
        'ETH': 189.2,
        'DOGE': 67.8,
        'ADA': 45.3,
      },
      lastUpdated: DateTime.now(),
    );
  }
}