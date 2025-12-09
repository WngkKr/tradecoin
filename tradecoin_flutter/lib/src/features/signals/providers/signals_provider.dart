import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/signal_model.dart';
import '../services/signals_service.dart';

class SignalsState {
  final List<SignalModel> activeSignals;
  final List<SignalHistoryModel> signalHistory;
  final SignalStatsModel? signalStats;
  final List<SignalModel> recommendedSignals;
  final Map<String, dynamic>? marketAnalysis;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const SignalsState({
    this.activeSignals = const [],
    this.signalHistory = const [],
    this.signalStats,
    this.recommendedSignals = const [],
    this.marketAnalysis,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  SignalsState copyWith({
    List<SignalModel>? activeSignals,
    List<SignalHistoryModel>? signalHistory,
    SignalStatsModel? signalStats,
    List<SignalModel>? recommendedSignals,
    Map<String, dynamic>? marketAnalysis,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return SignalsState(
      activeSignals: activeSignals ?? this.activeSignals,
      signalHistory: signalHistory ?? this.signalHistory,
      signalStats: signalStats ?? this.signalStats,
      recommendedSignals: recommendedSignals ?? this.recommendedSignals,
      marketAnalysis: marketAnalysis ?? this.marketAnalysis,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class SignalsNotifier extends StateNotifier<SignalsState> {
  final SignalsService _signalsService;

  SignalsNotifier(this._signalsService) : super(const SignalsState()) {
    loadAllSignalsData();
  }

  Future<void> loadAllSignalsData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await Future.wait([
        _signalsService.getActiveSignals(),
        _signalsService.getSignalHistory(),
        _signalsService.getSignalStats(),
        _signalsService.getRecommendedSignals(),
        _signalsService.getMarketAnalysis(),
      ]);

      state = state.copyWith(
        activeSignals: results[0] as List<SignalModel>,
        signalHistory: results[1] as List<SignalHistoryModel>,
        signalStats: results[2] as SignalStatsModel,
        recommendedSignals: results[3] as List<SignalModel>,
        marketAnalysis: results[4] as Map<String, dynamic>,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshActiveSignals() async {
    try {
      final activeSignals = await _signalsService.getActiveSignals();
      state = state.copyWith(
        activeSignals: activeSignals,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refreshSignalHistory() async {
    try {
      final signalHistory = await _signalsService.getSignalHistory();
      state = state.copyWith(
        signalHistory: signalHistory,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refreshSignalStats() async {
    try {
      final signalStats = await _signalsService.getSignalStats();
      state = state.copyWith(
        signalStats: signalStats,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refreshRecommendedSignals() async {
    try {
      final recommendedSignals = await _signalsService.getRecommendedSignals();
      state = state.copyWith(
        recommendedSignals: recommendedSignals,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refreshMarketAnalysis() async {
    try {
      final marketAnalysis = await _signalsService.getMarketAnalysis();
      state = state.copyWith(
        marketAnalysis: marketAnalysis,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> executeSignal(String signalId, {
    double? positionSize,
    Map<String, dynamic>? customParams,
  }) async {
    try {
      final success = await _signalsService.executeSignal(
        signalId,
        positionSize: positionSize,
        customParams: customParams,
      );

      if (success) {
        // Refresh active signals after execution
        await refreshActiveSignals();
        await refreshSignalHistory();
      }

      return success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  List<SignalModel> getSignalsByType(String signalType) {
    return state.activeSignals
        .where((signal) => signal.signalType == signalType)
        .toList();
  }

  List<SignalModel> getSignalsBySymbol(String symbol) {
    return state.activeSignals
        .where((signal) => signal.symbol == symbol)
        .toList();
  }

  List<SignalModel> getHighConfidenceSignals({double threshold = 0.75}) {
    return state.activeSignals
        .where((signal) => signal.confidenceScore >= threshold)
        .toList();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void startAutoRefresh() {
    Future.delayed(const Duration(minutes: 2), () {
      if (mounted) {
        refreshActiveSignals();
        refreshRecommendedSignals();
        startAutoRefresh();
      }
    });
  }
}

// Service provider
final signalsServiceProvider = Provider<SignalsService>((ref) {
  return SignalsService();
});

// Main signals provider
final signalsProvider = StateNotifierProvider<SignalsNotifier, SignalsState>((ref) {
  final signalsService = ref.read(signalsServiceProvider);
  final notifier = SignalsNotifier(signalsService);

  // Start auto-refresh
  notifier.startAutoRefresh();

  return notifier;
});

// Individual data access providers
final activeSignalsProvider = Provider<List<SignalModel>>((ref) {
  return ref.watch(signalsProvider).activeSignals;
});

final signalHistoryProvider = Provider<List<SignalHistoryModel>>((ref) {
  return ref.watch(signalsProvider).signalHistory;
});

final signalStatsProvider = Provider<SignalStatsModel?>((ref) {
  return ref.watch(signalsProvider).signalStats;
});

final recommendedSignalsProvider = Provider<List<SignalModel>>((ref) {
  return ref.watch(signalsProvider).recommendedSignals;
});

final marketAnalysisProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(signalsProvider).marketAnalysis;
});

final signalsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(signalsProvider).isLoading;
});

final signalsErrorProvider = Provider<String?>((ref) {
  return ref.watch(signalsProvider).error;
});

// Filtered providers
final buySignalsProvider = Provider<List<SignalModel>>((ref) {
  final signalsNotifier = ref.watch(signalsProvider.notifier);
  return signalsNotifier.getSignalsByType('buy');
});

final sellSignalsProvider = Provider<List<SignalModel>>((ref) {
  final signalsNotifier = ref.watch(signalsProvider.notifier);
  return signalsNotifier.getSignalsByType('sell');
});

final highConfidenceSignalsProvider = Provider<List<SignalModel>>((ref) {
  final signalsNotifier = ref.watch(signalsProvider.notifier);
  return signalsNotifier.getHighConfidenceSignals();
});

// Signal stats summary provider
final signalStatsSummaryProvider = Provider<Map<String, dynamic>>((ref) {
  final stats = ref.watch(signalStatsProvider);
  if (stats == null) return {};

  return {
    'activeSignals': stats.activeSignals,
    'winRate': stats.winRate,
    'totalProfitLoss': stats.totalProfitLoss,
    'avgProfit': stats.avgProfit,
    'bestTrade': stats.bestTrade,
    'consecutiveWins': stats.consecutiveWins,
  };
});

// Market analysis summary provider
final marketAnalysisSummaryProvider = Provider<Map<String, dynamic>>((ref) {
  final analysis = ref.watch(marketAnalysisProvider);
  if (analysis == null) return {};

  return {
    'marketTrend': analysis['marketTrend'] ?? 'neutral',
    'confidence': analysis['confidence'] ?? 0.5,
    'marketPhase': analysis['marketPhase'] ?? 'neutral',
    'keyLevels': analysis['keyLevels'] ?? {},
    'recommendedActions': analysis['recommendedActions'] ?? [],
    'riskFactors': analysis['riskFactors'] ?? [],
  };
});

// Performance metrics provider
final performanceMetricsProvider = Provider<Map<String, dynamic>>((ref) {
  final stats = ref.watch(signalStatsProvider);
  final activeSignals = ref.watch(activeSignalsProvider);

  if (stats == null) return {};

  // Calculate additional metrics
  final totalSignals = stats.totalSignals;
  final winRate = stats.winRate;
  final avgProfit = stats.avgProfit;

  // Risk-adjusted returns (simplified Sharpe-like ratio)
  final riskAdjustedReturn = avgProfit > 0 ? avgProfit / 10.0 : 0.0; // Assuming 10% volatility

  // Signal distribution
  final signalDistribution = <String, int>{};
  for (final signal in activeSignals) {
    signalDistribution[signal.signalType] = (signalDistribution[signal.signalType] ?? 0) + 1;
  }

  return {
    'totalSignals': totalSignals,
    'winRate': winRate,
    'avgProfit': avgProfit,
    'riskAdjustedReturn': riskAdjustedReturn,
    'signalDistribution': signalDistribution,
    'profitFactor': _calculateProfitFactor(stats),
    'maxDrawdown': _calculateMaxDrawdown(stats),
    'consistency': _calculateConsistency(stats),
  };
});

// Helper functions for performance metrics
double _calculateProfitFactor(SignalStatsModel stats) {
  // Simplified profit factor calculation
  final totalProfit = stats.totalProfitLoss > 0 ? stats.totalProfitLoss : 0.0;
  final totalLoss = stats.worstTrade.abs();

  if (totalLoss == 0) return double.infinity;
  return totalProfit / totalLoss;
}

double _calculateMaxDrawdown(SignalStatsModel stats) {
  // Simplified max drawdown (using worst trade as proxy)
  return stats.worstTrade.abs();
}

double _calculateConsistency(SignalStatsModel stats) {
  // Consistency based on win rate and consecutive wins/losses
  final winRate = stats.winRate / 100;
  final maxConsecutiveWins = stats.consecutiveWins.toDouble();
  final maxConsecutiveLosses = stats.consecutiveLosses.toDouble();

  // Higher win rate and lower consecutive losses = higher consistency
  final lossImpact = maxConsecutiveLosses > 0 ? 1.0 / maxConsecutiveLosses : 1.0;
  return (winRate * lossImpact * 100).clamp(0.0, 100.0);
}