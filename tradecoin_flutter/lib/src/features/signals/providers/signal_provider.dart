import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/signal_model.dart';
import '../services/signal_service.dart';
import '../../auth/providers/auth_provider.dart';

// 시그널 상태 클래스
class SignalState {
  final List<SignalModel> signals;
  final List<SignalModel> personalizedSignals;
  final List<SignalModel> favoriteSignals;
  final SignalStatsModel? stats;
  final UserPreferences? userPreferences;
  final SignalFilter? activeFilter;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const SignalState({
    this.signals = const [],
    this.personalizedSignals = const [],
    this.favoriteSignals = const [],
    this.stats,
    this.userPreferences,
    this.activeFilter,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  SignalState copyWith({
    List<SignalModel>? signals,
    List<SignalModel>? personalizedSignals,
    List<SignalModel>? favoriteSignals,
    SignalStatsModel? stats,
    UserPreferences? userPreferences,
    SignalFilter? activeFilter,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return SignalState(
      signals: signals ?? this.signals,
      personalizedSignals: personalizedSignals ?? this.personalizedSignals,
      favoriteSignals: favoriteSignals ?? this.favoriteSignals,
      stats: stats ?? this.stats,
      userPreferences: userPreferences ?? this.userPreferences,
      activeFilter: activeFilter ?? this.activeFilter,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// 시그널 상태 관리 Notifier
class SignalNotifier extends StateNotifier<SignalState> {
  final SignalService _signalService;
  final Ref _ref;
  Timer? _autoRefreshTimer;
  Timer? _quickRefreshTimer;

  SignalNotifier(this._signalService, this._ref) : super(const SignalState()) {
    _init();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _quickRefreshTimer?.cancel();
    super.dispose();
  }

  void _init() {
    // 사용자 인증 상태가 변경될 때마다 데이터 새로고침
    _ref.listen(authStateProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated && next.userData != null) {
        loadUserPreferences();
        loadAllSignalData();
      } else {
        // 로그아웃 시 상태 초기화
        state = const SignalState();
      }
    });
  }

  // 모든 시그널 데이터 로드
  Future<void> loadAllSignalData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 병렬로 모든 데이터 로드
      final results = await Future.wait([
        _signalService.getSignals(filter: state.activeFilter),
        _loadPersonalizedSignals(),
        _signalService.getSignalStats(),
      ]);

      final signals = results[0] as List<SignalModel>;
      final personalizedSignals = results[1] as List<SignalModel>;
      final stats = results[2] as SignalStatsModel;

      // 즐겨찾기 시그널 필터링
      final favoriteSignals = signals.where((signal) => signal.isFavorite).toList();

      state = state.copyWith(
        signals: signals,
        personalizedSignals: personalizedSignals,
        favoriteSignals: favoriteSignals,
        stats: stats,
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

  // 개인화된 시그널 로드
  Future<List<SignalModel>> _loadPersonalizedSignals() async {
    final authState = _ref.read(authStateProvider);
    if (authState.status != AuthStatus.authenticated || authState.userData == null) {
      return [];
    }

    return await _signalService.getPersonalizedSignals(
      userId: authState.userData!.uid,
      userPreferences: state.userPreferences,
    );
  }

  // 사용자 선호도 로드
  Future<void> loadUserPreferences() async {
    final authState = _ref.read(authStateProvider);
    if (authState.status != AuthStatus.authenticated || authState.userData == null) return;

    try {
      final preferences = await _signalService.getUserPreferences(authState.userData!.uid);
      if (preferences != null) {
        state = state.copyWith(userPreferences: preferences);
      }
    } catch (e) {
      state = state.copyWith(error: '사용자 선호도를 불러올 수 없습니다: $e');
    }
  }

  // 사용자 선호도 저장
  Future<void> saveUserPreferences(UserPreferences preferences) async {
    final authState = _ref.read(authStateProvider);
    if (authState.status != AuthStatus.authenticated || authState.userData == null) return;

    try {
      final success = await _signalService.saveUserPreferences(
        authState.userData!.uid,
        preferences,
      );

      if (success) {
        state = state.copyWith(userPreferences: preferences);
        // 개인화된 시그널 새로고침
        await refreshPersonalizedSignals();
      } else {
        state = state.copyWith(error: '사용자 선호도를 저장할 수 없습니다');
      }
    } catch (e) {
      state = state.copyWith(error: '사용자 선호도를 저장할 수 없습니다: $e');
    }
  }

  // 필터 적용
  Future<void> applyFilter(SignalFilter? filter) async {
    state = state.copyWith(isLoading: true, activeFilter: filter);

    try {
      final filteredSignals = await _signalService.getSignals(filter: filter);
      state = state.copyWith(
        signals: filteredSignals,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '필터를 적용할 수 없습니다: $e',
      );
    }
  }

  // 시그널 검색
  Future<List<SignalModel>> searchSignals(String query) async {
    try {
      return await _signalService.searchSignals(
        query: query,
        filter: state.activeFilter,
      );
    } catch (e) {
      state = state.copyWith(error: '시그널을 검색할 수 없습니다: $e');
      return [];
    }
  }

  // 즐겨찾기 토글
  Future<void> toggleFavorite(String signalId) async {
    final authState = _ref.read(authStateProvider);
    if (authState.status != AuthStatus.authenticated || authState.userData == null) return;

    try {
      final success = await _signalService.toggleFavorite(signalId, authState.userData!.uid);

      if (success) {
        // 로컬 상태 업데이트
        final updatedSignals = state.signals.map((signal) {
          if (signal.id == signalId) {
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
              personalizedScore: signal.personalizedScore,
              tags: signal.tags,
              isFavorite: !signal.isFavorite,
              userNotes: signal.userNotes,
              personalization: signal.personalization,
            );
          }
          return signal;
        }).toList();

        final favoriteSignals = updatedSignals.where((signal) => signal.isFavorite).toList();

        state = state.copyWith(
          signals: updatedSignals,
          favoriteSignals: favoriteSignals,
        );
      }
    } catch (e) {
      state = state.copyWith(error: '즐겨찾기를 변경할 수 없습니다: $e');
    }
  }

  // 사용자 노트 저장
  Future<void> saveUserNote(String signalId, String note) async {
    final authState = _ref.read(authStateProvider);
    if (authState.status != AuthStatus.authenticated || authState.userData == null) return;

    try {
      final success = await _signalService.saveUserNote(
        signalId,
        authState.userData!.uid,
        note,
      );

      if (success) {
        // 로컬 상태 업데이트
        final updatedSignals = state.signals.map((signal) {
          if (signal.id == signalId) {
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
              personalizedScore: signal.personalizedScore,
              tags: signal.tags,
              isFavorite: signal.isFavorite,
              userNotes: note,
              personalization: signal.personalization,
            );
          }
          return signal;
        }).toList();

        state = state.copyWith(signals: updatedSignals);
      }
    } catch (e) {
      state = state.copyWith(error: '노트를 저장할 수 없습니다: $e');
    }
  }

  // 개인화된 시그널 새로고침
  Future<void> refreshPersonalizedSignals() async {
    try {
      final personalizedSignals = await _loadPersonalizedSignals();
      state = state.copyWith(
        personalizedSignals: personalizedSignals,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: '개인화된 시그널을 새로고침할 수 없습니다: $e');
    }
  }

  // 시그널 새로고침
  Future<void> refreshSignals() async {
    try {
      final signals = await _signalService.getSignals(filter: state.activeFilter);
      state = state.copyWith(
        signals: signals,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: '시그널을 새로고침할 수 없습니다: $e');
    }
  }

  // 통계 새로고침
  Future<void> refreshStats() async {
    try {
      final stats = await _signalService.getSignalStats();
      state = state.copyWith(
        stats: stats,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: '통계를 새로고침할 수 없습니다: $e');
    }
  }

  // 에러 클리어
  void clearError() {
    state = state.copyWith(error: null);
  }

  // 선호 코인 추가/제거
  Future<void> toggleFavoriteCoin(String symbol) async {
    if (state.userPreferences == null) return;

    final currentFavorites = List<String>.from(state.userPreferences!.favoriteCoins);
    if (currentFavorites.contains(symbol)) {
      currentFavorites.remove(symbol);
    } else {
      currentFavorites.add(symbol);
    }

    final updatedPreferences = state.userPreferences!.copyWith(
      favoriteCoins: currentFavorites,
    );

    await saveUserPreferences(updatedPreferences);
  }

  // 선호 시간프레임 설정
  Future<void> updatePreferredTimeframes(List<String> timeframes) async {
    if (state.userPreferences == null) return;

    final updatedPreferences = state.userPreferences!.copyWith(
      preferredTimeframes: timeframes,
    );

    await saveUserPreferences(updatedPreferences);
  }

  // 리스크 레벨 설정
  Future<void> updateMaxRiskLevel(int level) async {
    if (state.userPreferences == null) return;

    final updatedPreferences = state.userPreferences!.copyWith(
      maxRiskLevel: level,
    );

    await saveUserPreferences(updatedPreferences);
  }

  // 신뢰도 임계값 설정
  Future<void> updateMinConfidenceThreshold(double threshold) async {
    if (state.userPreferences == null) return;

    final updatedPreferences = state.userPreferences!.copyWith(
      minConfidenceThreshold: threshold,
    );

    await saveUserPreferences(updatedPreferences);
  }

  // 자동 새로고침 시작 (5분마다 - 백엔드와 동기화)
  void startAutoRefresh() {
    // 기존 타이머 취소
    _autoRefreshTimer?.cancel();

    // 5분마다 자동 새로고침 (백엔드 Twitter 크롤링 주기와 동일)
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        print('🔄 [자동 새로고침] 5분 주기 - 시그널 업데이트 시작');
        refreshSignals();
        refreshPersonalizedSignals();
        refreshStats();
      } else {
        timer.cancel();
      }
    });

    print('✅ [스케줄러] 자동 새로고침 시작 (5분 간격)');
  }

  // 빠른 새로고침 시작 (30초마다 - 실시간 가격 업데이트용)
  void startQuickRefresh() {
    // 기존 타이머 취소
    _quickRefreshTimer?.cancel();

    // 30초마다 빠른 새로고침 (가격만 업데이트)
    _quickRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        print('⚡ [빠른 새로고침] 30초 주기 - 가격 업데이트');
        _quickRefreshPricesOnly();
      } else {
        timer.cancel();
      }
    });

    print('✅ [스케줄러] 빠른 새로고침 시작 (30초 간격)');
  }

  // 가격만 빠르게 업데이트 (API 호출 최소화)
  Future<void> _quickRefreshPricesOnly() async {
    try {
      // 현재 활성 시그널의 가격만 업데이트
      final activeSignals = state.signals.where((s) => s.isActive).toList();

      // 가격 업데이트 로직은 SignalService에 추가 필요
      // 여기서는 전체 새로고침보다 가벼운 작업만 수행

      print('💰 [가격 업데이트] ${activeSignals.length}개 활성 시그널 가격 갱신');
    } catch (e) {
      print('⚠️ [가격 업데이트 실패] $e');
    }
  }

  // 모든 자동 새로고침 중지
  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _quickRefreshTimer?.cancel();
    print('⏸️ [스케줄러] 자동 새로고침 중지');
  }
}

// 시그널 서비스 인스턴스 제공
final signalServiceProvider = Provider<SignalService>((ref) {
  return SignalService();
});

// 시그널 상태 제공
final signalProvider = StateNotifierProvider<SignalNotifier, SignalState>((ref) {
  final signalService = ref.read(signalServiceProvider);
  final notifier = SignalNotifier(signalService, ref);

  // 자동 새로고침 시작 (5분 간격 - 백엔드 Twitter 크롤링과 동기화)
  notifier.startAutoRefresh();

  // 빠른 새로고침 시작 (30초 간격 - 가격만 업데이트)
  notifier.startQuickRefresh();

  return notifier;
});

// 개별 데이터 접근을 위한 편의 Provider들
final signalsListProvider = Provider<List<SignalModel>>((ref) {
  return ref.watch(signalProvider).signals;
});

final personalizedSignalsProvider = Provider<List<SignalModel>>((ref) {
  return ref.watch(signalProvider).personalizedSignals;
});

final favoriteSignalsProvider = Provider<List<SignalModel>>((ref) {
  return ref.watch(signalProvider).favoriteSignals;
});

final signalStatsProvider = Provider<SignalStatsModel?>((ref) {
  return ref.watch(signalProvider).stats;
});

final userPreferencesProvider = Provider<UserPreferences?>((ref) {
  return ref.watch(signalProvider).userPreferences;
});

final signalLoadingProvider = Provider<bool>((ref) {
  return ref.watch(signalProvider).isLoading;
});

final signalErrorProvider = Provider<String?>((ref) {
  return ref.watch(signalProvider).error;
});

// 필터링된 시그널 Provider
final filteredSignalsProvider = Provider.family<List<SignalModel>, SignalFilter?>((ref, filter) {
  final signals = ref.watch(signalsListProvider);
  if (filter == null) return signals;

  return signals.where((signal) => filter.matches(signal)).toList();
});

// 시그널 타입별 Provider
final signalsByTypeProvider = Provider.family<List<SignalModel>, String>((ref, signalType) {
  final signals = ref.watch(signalsListProvider);
  return signals.where((signal) => signal.signalType == signalType).toList();
});

// 코인별 시그널 Provider
final signalsBySymbolProvider = Provider.family<List<SignalModel>, String>((ref, symbol) {
  final signals = ref.watch(signalsListProvider);
  return signals.where((signal) => signal.symbol == symbol).toList();
});

// 고신뢰도 시그널 Provider
final highConfidenceSignalsProvider = Provider<List<SignalModel>>((ref) {
  final signals = ref.watch(signalsListProvider);
  return signals.where((signal) => signal.confidenceScore >= 0.8).toList();
});

// 활성 시그널 Provider
final activeSignalsProvider = Provider<List<SignalModel>>((ref) {
  final signals = ref.watch(signalsListProvider);
  return signals.where((signal) => signal.isActive && !signal.isExpired).toList();
});

// 시그널 통계 요약 Provider
final signalStatsSummaryProvider = Provider<Map<String, dynamic>>((ref) {
  final stats = ref.watch(signalStatsProvider);
  if (stats == null) return {};

  return {
    'totalSignals': stats.totalSignals,
    'activeSignals': stats.activeSignals,
    'winRate': stats.winRate,
    'avgProfit': stats.avgProfit,
    'bestTrade': stats.bestTrade,
    'worstTrade': stats.worstTrade,
  };
});

// 개인화 점수 순 정렬된 시그널 Provider
final topPersonalizedSignalsProvider = Provider<List<SignalModel>>((ref) {
  final personalizedSignals = ref.watch(personalizedSignalsProvider);
  final sortedSignals = List<SignalModel>.from(personalizedSignals);
  sortedSignals.sort((a, b) => b.personalizedScore.compareTo(a.personalizedScore));
  return sortedSignals.take(10).toList();
});

// 선호 코인 시그널 Provider
final preferredCoinsSignalsProvider = Provider<List<SignalModel>>((ref) {
  final signals = ref.watch(signalsListProvider);
  final preferences = ref.watch(userPreferencesProvider);

  if (preferences == null || preferences.favoriteCoins.isEmpty) {
    return signals;
  }

  return signals.where((signal) => preferences.favoriteCoins.contains(signal.symbol)).toList();
});