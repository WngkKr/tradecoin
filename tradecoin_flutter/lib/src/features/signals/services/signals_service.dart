import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../models/signal_model.dart';

class SignalsService {
  static final String _baseUrl = AppConstants.apiBaseUrl;

  Future<List<SignalModel>> getActiveSignals({
    int limit = 20,
    List<String>? symbols,
    String? signalType,
    double? minConfidence,
  }) async {
    try {
      print('🔄 [시그널] 실제 백엔드에서 활성 시그널 조회 시작...');

      final queryParams = <String, String>{
        'limit': limit.toString(),
      };

      if (symbols != null && symbols.isNotEmpty) {
        queryParams['symbols'] = symbols.join(',');
      }

      if (signalType != null) {
        queryParams['signalType'] = signalType;
      }

      if (minConfidence != null) {
        queryParams['minConfidence'] = minConfidence.toString();
      }

      final uri = Uri.parse('$_baseUrl/api/signals/active').replace(
        queryParameters: queryParams,
      );

      print('🌐 [시그널] API 요청 URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📡 [시그널] 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        final dataStr = responseData.toString();
        print('📊 [시그널] 받은 데이터: ${dataStr.substring(0, dataStr.length > 200 ? 200 : dataStr.length)}${dataStr.length > 200 ? '...' : ''}');

        List<dynamic> signalsData;

        // 응답 데이터 형식에 따라 처리
        if (responseData is List) {
          signalsData = responseData;
        } else if (responseData is Map && responseData['signals'] != null) {
          signalsData = responseData['signals'];
        } else {
          print('⚠️ [시그널] 예상치 못한 응답 형식, 빈 리스트 반환');
          signalsData = [];
        }

        final signals = signalsData
            .map((item) => SignalModel.fromJson(item))
            .toList();

        print('✅ [시그널] 성공적으로 ${signals.length}개의 실제 시그널 로드됨');
        return signals;
      } else {
        print('❌ [시그널] API 오류: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load active signals: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [시그널] 실제 API 호출 실패, 빈 리스트 반환: $e');
      // 더미 데이터 대신 빈 리스트 반환
      return [];
    }
  }

  Future<List<SignalHistoryModel>> getSignalHistory({
    int limit = 50,
    String? status,
    String? result,
    String? symbol,
  }) async {
    try {
      print('🔄 [시그널히스토리] 실제 백엔드에서 시그널 히스토리 조회 시작...');

      final queryParams = <String, String>{
        'limit': limit.toString(),
      };

      if (status != null) {
        queryParams['status'] = status;
      }

      if (result != null) {
        queryParams['result'] = result;
      }

      if (symbol != null) {
        queryParams['symbol'] = symbol;
      }

      final uri = Uri.parse('$_baseUrl/signal-history').replace(
        queryParameters: queryParams,
      );

      print('🌐 [시그널히스토리] API 요청 URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📡 [시그널히스토리] 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        final dataStr = responseData.toString();
        print('📊 [시그널히스토리] 받은 데이터: ${dataStr.substring(0, dataStr.length > 200 ? 200 : dataStr.length)}${dataStr.length > 200 ? '...' : ''}');

        List<dynamic> historyData;

        // 응답 데이터 형식에 따라 처리
        if (responseData is List) {
          historyData = responseData;
        } else if (responseData is Map && responseData['history'] != null) {
          historyData = responseData['history'];
        } else {
          print('⚠️ [시그널히스토리] 예상치 못한 응답 형식, 빈 리스트 반환');
          historyData = [];
        }

        final history = historyData
            .map((item) => SignalHistoryModel.fromJson(item))
            .toList();

        print('✅ [시그널히스토리] 성공적으로 ${history.length}개의 실제 히스토리 로드됨');
        return history;
      } else {
        print('❌ [시그널히스토리] API 오류: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load signal history: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [시그널히스토리] 실제 API 호출 실패, 빈 리스트 반환: $e');
      // 더미 데이터 대신 빈 리스트 반환
      return [];
    }
  }

  Future<SignalStatsModel> getSignalStats() async {
    try {
      print('🔄 [시그널통계] 실제 백엔드에서 시그널 통계 조회 시작...');

      final response = await http.get(
        Uri.parse('$_baseUrl/signal-stats'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📡 [시그널통계] 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('📊 [시그널통계] 받은 데이터: ${data.toString()}');

        final stats = SignalStatsModel.fromJson(data);
        print('✅ [시그널통계] 성공적으로 실제 통계 로드됨');
        return stats;
      } else {
        print('❌ [시그널통계] API 오류: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load signal stats: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [시그널통계] 실제 API 호출 실패, 기본 통계 반환: $e');
      // 더미 데이터 대신 기본 빈 통계 반환
      return SignalStatsModel(
        totalSignals: 0,
        activeSignals: 0,
        closedSignals: 0,
        winRate: 0.0,
        avgProfit: 0.0,
        totalProfitLoss: 0.0,
        bestTrade: 0.0,
        worstTrade: 0.0,
        consecutiveWins: 0,
        consecutiveLosses: 0,
        signalTypeStats: {},
        symbolStats: {},
        lastUpdated: DateTime.now(),
      );
    }
  }

  Future<SignalModel?> getSignalById(String signalId) async {
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
        throw Exception('Failed to load signal: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching signal: $e');
      return null;
    }
  }

  Future<List<SignalModel>> getRecommendedSignals({
    int limit = 5,
    String? userRiskProfile,
  }) async {
    try {
      print('🔄 [추천시그널] 실제 백엔드에서 추천 시그널 조회 시작...');

      final queryParams = <String, String>{
        'limit': limit.toString(),
      };

      if (userRiskProfile != null) {
        queryParams['riskProfile'] = userRiskProfile;
      }

      final uri = Uri.parse('$_baseUrl/recommended-signals').replace(
        queryParameters: queryParams,
      );

      print('🌐 [추천시그널] API 요청 URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📡 [추천시그널] 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        final dataStr = responseData.toString();
        print('📊 [추천시그널] 받은 데이터: ${dataStr.substring(0, dataStr.length > 200 ? 200 : dataStr.length)}${dataStr.length > 200 ? '...' : ''}');

        List<dynamic> signalsData;

        // 응답 데이터 형식에 따라 처리
        if (responseData is List) {
          signalsData = responseData;
        } else if (responseData is Map && responseData['recommendations'] != null) {
          signalsData = responseData['recommendations'];
        } else {
          print('⚠️ [추천시그널] 예상치 못한 응답 형식, 빈 리스트 반환');
          signalsData = [];
        }

        final signals = signalsData
            .map((item) => SignalModel.fromJson(item))
            .toList();

        print('✅ [추천시그널] 성공적으로 ${signals.length}개의 실제 추천 시그널 로드됨');
        return signals;
      } else {
        print('❌ [추천시그널] API 오류: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load recommendations: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [추천시그널] 실제 API 호출 실패, 빈 리스트 반환: $e');
      // 더미 데이터 대신 빈 리스트 반환
      return [];
    }
  }

  Future<bool> executeSignal(String signalId, {
    double? positionSize,
    Map<String, dynamic>? customParams,
  }) async {
    try {
      final body = <String, dynamic>{
        'signalId': signalId,
      };

      if (positionSize != null) {
        body['positionSize'] = positionSize;
      }

      if (customParams != null) {
        body.addAll(customParams);
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/signals/execute'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error executing signal: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getMarketAnalysis() async {
    try {
      print('🔄 [마켓분석] 실제 백엔드에서 시장 분석 조회 시작...');

      final response = await http.get(
        Uri.parse('$_baseUrl/market-analysis'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📡 [마켓분석] 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final analysis = json.decode(response.body);
        final dataStr = analysis.toString();
        print('📊 [마켓분석] 받은 데이터: ${dataStr.substring(0, dataStr.length > 200 ? 200 : dataStr.length)}${dataStr.length > 200 ? '...' : ''}');
        print('✅ [마켓분석] 성공적으로 실제 분석 로드됨');
        return analysis;
      } else {
        print('❌ [마켓분석] API 오류: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load market analysis: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [마켓분석] 실제 API 호출 실패, 기본 분석 반환: $e');
      // 더미 데이터 대신 기본 중립 분석 반환
      return {
        'marketTrend': 'neutral',
        'confidence': 0.5,
        'keyLevels': {},
        'marketPhase': 'neutral',
        'recommendedActions': ['시장 분석 중입니다. 잠시 후 다시 확인해 주세요.'],
        'riskFactors': ['데이터 수집 중'],
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }

  // Mock data methods
  List<SignalModel> _getMockActiveSignals() {
    return [
      SignalModel(
        id: 'sig_001',
        symbol: 'BTC',
        pair: 'BTC/USDT',
        signalType: 'buy',
        confidenceScore: 0.85,
        strength: 'strong',
        currentPrice: 67234.50,
        targetPrice: 69500.00,
        stopLoss: 65200.00,
        takeProfit: 70000.00,
        timeframe: '4h',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        expiryTime: DateTime.now().add(const Duration(hours: 4)),
        isActive: true,
        indicators: ['MACD', 'RSI', 'Bollinger Bands'],
        technicalAnalysis: const TechnicalAnalysis(
          rsi: 65.2,
          macd: 850.5,
          sma20: 66800.0,
          sma50: 65200.0,
          sma200: 62000.0,
          bollingerUpper: 68500.0,
          bollingerLower: 65500.0,
          volume: 1250000000.0,
          volumeAvg: 980000000.0,
          trend: 'bullish',
          patterns: ['Golden Cross', 'Bull Flag'],
          oscillators: {'stochastic': 68.5, 'williams_r': -25.8},
        ),
        sentimentAnalysis: const SentimentAnalysis(
          sentimentScore: 0.7,
          sentimentLabel: 'bullish',
          socialMediaScore: 0.65,
          newsScore: 0.8,
          institutionalFlow: 2500000000.0,
          emotionScores: {'greed': 0.75, 'fear': 0.25, 'optimism': 0.85},
          keyFactors: ['ETF inflows', 'Institutional adoption', 'Positive news'],
        ),
        marketConditions: const MarketConditions(
          volatility: 0.28,
          liquidity: 0.85,
          marketPhase: 'markup',
          fearGreedIndex: 75.0,
          dominanceIndex: 45.2,
          correlations: {'ETH': 0.85, 'SPY': 0.65},
        ),
        riskAssessment: const RiskAssessment(
          riskLevel: 'medium',
          maxLoss: 3.2,
          riskReward: 2.8,
          riskFactors: ['Market volatility', 'Regulatory uncertainty'],
          positionSize: 2.5,
          riskManagement: 'Use stop loss at \$65,200',
        ),
        description: 'Strong bullish signal with high institutional flow and positive sentiment',
      ),
      SignalModel(
        id: 'sig_002',
        symbol: 'ETH',
        pair: 'ETH/USDT',
        signalType: 'buy',
        confidenceScore: 0.72,
        strength: 'medium',
        currentPrice: 3890.25,
        targetPrice: 4050.00,
        stopLoss: 3750.00,
        takeProfit: 4100.00,
        timeframe: '2h',
        timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
        expiryTime: DateTime.now().add(const Duration(hours: 2)),
        isActive: true,
        indicators: ['EMA', 'MACD', 'Volume'],
        technicalAnalysis: const TechnicalAnalysis(
          rsi: 58.7,
          macd: 45.2,
          sma20: 3850.0,
          sma50: 3800.0,
          sma200: 3600.0,
          bollingerUpper: 3950.0,
          bollingerLower: 3750.0,
          volume: 850000000.0,
          volumeAvg: 720000000.0,
          trend: 'bullish',
          patterns: ['Ascending Triangle'],
          oscillators: {'stochastic': 62.3, 'williams_r': -35.2},
        ),
        sentimentAnalysis: const SentimentAnalysis(
          sentimentScore: 0.6,
          sentimentLabel: 'bullish',
          socialMediaScore: 0.58,
          newsScore: 0.65,
          institutionalFlow: 1800000000.0,
          emotionScores: {'greed': 0.65, 'fear': 0.35, 'optimism': 0.72},
          keyFactors: ['DeFi growth', 'Layer 2 adoption'],
        ),
        marketConditions: const MarketConditions(
          volatility: 0.32,
          liquidity: 0.78,
          marketPhase: 'accumulation',
          fearGreedIndex: 68.0,
          dominanceIndex: 18.7,
          correlations: {'BTC': 0.85, 'DeFi': 0.92},
        ),
        riskAssessment: const RiskAssessment(
          riskLevel: 'medium',
          maxLoss: 3.6,
          riskReward: 2.1,
          riskFactors: ['Gas fee concerns', 'Competition from L1s'],
          positionSize: 3.0,
          riskManagement: 'Monitor gas fees and DeFi TVL',
        ),
        description: 'Ethereum showing strength with DeFi momentum',
      ),
    ];
  }

  List<SignalHistoryModel> _getMockSignalHistory() {
    return [
      SignalHistoryModel(
        id: 'hist_001',
        signalId: 'sig_999',
        symbol: 'BTC',
        pair: 'BTC/USDT',
        signalType: 'buy',
        entryPrice: 65420.00,
        exitPrice: 68800.00,
        profitLoss: 3380.00,
        profitLossPercent: 5.2,
        status: 'closed',
        result: 'win',
        entryTime: DateTime.now().subtract(const Duration(days: 1)),
        exitTime: DateTime.now().subtract(const Duration(hours: 18)),
        notes: 'Successful breakout trade',
      ),
      SignalHistoryModel(
        id: 'hist_002',
        signalId: 'sig_998',
        symbol: 'ETH',
        pair: 'ETH/USDT',
        signalType: 'sell',
        entryPrice: 3750.00,
        exitPrice: 3892.50,
        profitLoss: 142.50,
        profitLossPercent: 3.8,
        status: 'closed',
        result: 'win',
        entryTime: DateTime.now().subtract(const Duration(days: 2)),
        exitTime: DateTime.now().subtract(const Duration(hours: 30)),
        notes: 'Good timing on resistance level',
      ),
    ];
  }

  SignalStatsModel _getMockSignalStats() {
    return SignalStatsModel(
      totalSignals: 145,
      activeSignals: 12,
      closedSignals: 133,
      winRate: 72.5,
      avgProfit: 4.8,
      totalProfitLoss: 24750.00,
      bestTrade: 12.8,
      worstTrade: -8.2,
      consecutiveWins: 7,
      consecutiveLosses: 2,
      signalTypeStats: {
        'buy': 78,
        'sell': 45,
        'hold': 22,
      },
      symbolStats: {
        'BTC': 58.2,
        'ETH': 35.8,
        'Others': 6.0,
      },
      lastUpdated: DateTime.now(),
    );
  }

  List<SignalModel> _getMockRecommendedSignals() {
    return _getMockActiveSignals().take(3).toList();
  }

  Map<String, dynamic> _getMockMarketAnalysis() {
    return {
      'marketTrend': 'bullish',
      'confidence': 0.75,
      'keyLevels': {
        'BTC': {
          'support': 65000,
          'resistance': 70000,
        },
        'ETH': {
          'support': 3750,
          'resistance': 4100,
        },
      },
      'marketPhase': 'accumulation',
      'recommendedActions': [
        'Consider accumulating on dips',
        'Monitor institutional flows',
        'Watch for breakout above resistance',
      ],
      'riskFactors': [
        'Regulatory uncertainty',
        'Macro economic headwinds',
        'Technical overbought levels',
      ],
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }
}