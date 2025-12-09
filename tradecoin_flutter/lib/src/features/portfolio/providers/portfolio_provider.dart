import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/portfolio_model.dart';
import '../services/portfolio_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../binance/providers/binance_connection_provider.dart';
import '../../../core/services/storage_service.dart';

// 포트폴리오 상태 클래스
class PortfolioState {
  final PortfolioModel? portfolio;
  final List<AssetHolding> holdings;
  final List<Transaction> transactions;
  final Map<String, PortfolioPerformance> performances;
  final Map<String, double> realTimePrices;
  final bool isLoading;
  final bool isSyncing;
  final String? error;
  final DateTime? lastUpdated;
  final DateTime? lastSyncTime;

  const PortfolioState({
    this.portfolio,
    this.holdings = const [],
    this.transactions = const [],
    this.performances = const {},
    this.realTimePrices = const {},
    this.isLoading = false,
    this.isSyncing = false,
    this.error,
    this.lastUpdated,
    this.lastSyncTime,
  });

  PortfolioState copyWith({
    PortfolioModel? portfolio,
    List<AssetHolding>? holdings,
    List<Transaction>? transactions,
    Map<String, PortfolioPerformance>? performances,
    Map<String, double>? realTimePrices,
    bool? isLoading,
    bool? isSyncing,
    String? error,
    DateTime? lastUpdated,
    DateTime? lastSyncTime,
  }) {
    return PortfolioState(
      portfolio: portfolio ?? this.portfolio,
      holdings: holdings ?? this.holdings,
      transactions: transactions ?? this.transactions,
      performances: performances ?? this.performances,
      realTimePrices: realTimePrices ?? this.realTimePrices,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

// 포트폴리오 상태 관리 Notifier
class PortfolioNotifier extends StateNotifier<PortfolioState> {
  final PortfolioService _portfolioService;
  final Ref _ref;

  PortfolioNotifier(this._portfolioService, this._ref) : super(const PortfolioState()) {
    _init();
    // 앱 시작 시 즉시 포트폴리오 데이터 로딩 시도 (안전하게)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        print('🚀 [포트폴리오] 앱 시작 시 자동 데이터 로딩 시작');
        loadPortfolioData().catchError((error) {
          print('❌ [포트폴리오] 초기 로딩 실패: $error');
          state = state.copyWith(
            isLoading: false,
            error: '포트폴리오 초기 로딩 실패: $error',
          );
        });
      } catch (e) {
        print('❌ [포트폴리오] 초기화 중 예외 발생: $e');
        state = state.copyWith(
          isLoading: false,
          error: '포트폴리오 초기화 실패: $e',
        );
      }
    });
  }

  void _init() {
    // 사용자 인증 상태가 변경될 때마다 포트폴리오 데이터 새로고침
    _ref.listen(authStateProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated && next.userData != null) {
        loadPortfolioData();
      } else {
        // 로그아웃 시 상태 초기화
        state = const PortfolioState();
      }
    });

    // 바이낸스 연결 상태 리스너 제거 - 무한 루프 방지
    // 대신 loadPortfolioData() 내에서 직접 바이낸스 연결 상태를 확인하도록 변경
    print('🔄 [포트폴리오] 초기화 완료 - 바이낸스 연결 상태 리스너 제거됨');
  }

  // 포트폴리오 데이터 로드 (안전한 버전)
  Future<void> loadPortfolioData() async {
    try {
      // 현재 상태가 mounted인지 확인
      if (!mounted) {
        print('⚠️ [포트폴리오] Provider가 disposed 상태 - 로딩 중단');
        return;
      }

      if (mounted) {
        state = state.copyWith(isLoading: true, error: null);
      }

      print('🔄 [포트폴리오] 데이터 로딩 시작...');

      // 바이낸스 연결 상태 확인 (안전하게)
      BinanceConnectionState? binanceState;
      try {
        binanceState = _ref.read(binanceConnectionProvider);
        print('🔍 [포트폴리오] 바이낸스 연결 상태: ${binanceState?.isConnected ?? false}');
        print('🔍 [포트폴리오] 바이낸스 계정 타입: ${binanceState?.accountType ?? "unknown"}');
      } catch (e) {
        print('⚠️ [포트폴리오] 바이낸스 상태 확인 실패: $e - 연결 안됨으로 처리');
        binanceState = null;
      }

      if (binanceState?.isConnected == true) {
        print('✅ [포트폴리오] 바이낸스 연결됨 - 실제 계정 정보 로딩');
        // 실제 바이낸스 API에서 계좌 정보 가져오기
        await _loadRealPortfolioData();
        return;
      }

      // 바이낸스 연결이 안되어 있으면 빈 상태로 설정
      final authState = _ref.read(authStateProvider);
      final isAuthenticated = authState.status == AuthStatus.authenticated && authState.userData != null;

      print('⚠️ [포트폴리오] 바이낸스 미연결 - 빈 상태로 설정 (인증: $isAuthenticated)');

      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: null,
          portfolio: null,
          holdings: [],
          transactions: [],
          realTimePrices: {},
        );
      }

    } catch (e, stackTrace) {
      print('❌ [포트폴리오] 데이터 로딩 실패: $e');
      print('📚 [포트폴리오] 스택 트레이스: $stackTrace');
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: '포트폴리오 로딩 실패: ${e.toString()}',
        );
      }
    }
  }

  // 실제 바이낸스 API 포트폴리오 데이터 로딩
  Future<void> _loadRealPortfolioData() async {
    try {
      if (!mounted) {
        print('⚠️ [포트폴리오] Provider가 disposed 상태 - 실제 데이터 로딩 중단');
        return;
      }

      print('🔄 [포트폴리오] 실제 바이낸스 API에서 계좌 정보 로딩 중...');

      // 실제 바이낸스 API에서 계좌 정보 가져오기
      final portfolioData = await _portfolioService.getPortfolio(
        _ref.read(authStateProvider).userData?.uid ?? 'unknown_user'
      );

      // 실제 계좌가 빈 경우 빈 포트폴리오 상태로 설정
      if (portfolioData.holdings.isEmpty) {
        print('📭 [포트폴리오] 실제 계좌에 보유 자산 없음 - 빈 포트폴리오 표시');

        // 빈 포트폴리오 모델 생성
        final userId = _ref.read(authStateProvider).userData?.uid ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
        final emptyPortfolio = PortfolioModel(
          userId: userId,
          totalValue: 0.0,
          totalBalance: 0.0,
          totalPnl: 0.0,
          totalPnlPercent: 0.0,
          holdings: [],
          transactions: [],
          allocation: {},
          stats: PortfolioStats(
            totalInvested: 0.0,
            totalWithdrawn: 0.0,
            realizedPnl: 0.0,
            unrealizedPnl: 0.0,
            totalFees: 0.0,
            totalTrades: 0,
            winningTrades: 0,
            losingTrades: 0,
            winRate: 0.0,
            averageWin: 0.0,
            averageLoss: 0.0,
            largestWin: 0.0,
            largestLoss: 0.0,
            sharpeRatio: 0.0,
            maxDrawdown: 0.0,
            monthlyReturns: {},
            firstTradeDate: DateTime.now(),
          ),
          lastUpdated: DateTime.now(),
        );

        if (mounted) {
          state = state.copyWith(
            portfolio: emptyPortfolio,
            holdings: [],
            transactions: [],
            realTimePrices: {},
            isLoading: false,
            error: null,
            lastUpdated: DateTime.now(),
          );
          print('✅ [포트폴리오] 빈 포트폴리오 상태 설정 완료');
        }
      } else {
        // 실제 보유 자산이 있는 경우
        print('💰 [포트폴리오] 실제 보유 자산 발견: ${portfolioData.holdings.length}개');

        if (mounted) {
          state = state.copyWith(
            portfolio: portfolioData,
            holdings: portfolioData.holdings,
            transactions: portfolioData.transactions,
            realTimePrices: {},
            isLoading: false,
            error: null,
            lastUpdated: DateTime.now(),
          );
          print('✅ [포트폴리오] 실제 포트폴리오 데이터 로딩 완료');
        }
      }
    } catch (e, stackTrace) {
      print('❌ [포트폴리오] 실제 데이터 로딩 실패: $e');
      print('📚 [포트폴리오] 스택 트레이스: $stackTrace');

      // 실패 시 빈 포트폴리오로 fallback
      if (mounted) {
        final userId = _ref.read(authStateProvider).userData?.uid ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
        final emptyPortfolio = PortfolioModel(
          userId: userId,
          totalValue: 0.0,
          totalBalance: 0.0,
          totalPnl: 0.0,
          totalPnlPercent: 0.0,
          holdings: [],
          transactions: [],
          allocation: {},
          stats: PortfolioStats(
            totalInvested: 0.0,
            totalWithdrawn: 0.0,
            realizedPnl: 0.0,
            unrealizedPnl: 0.0,
            totalFees: 0.0,
            totalTrades: 0,
            winningTrades: 0,
            losingTrades: 0,
            winRate: 0.0,
            averageWin: 0.0,
            averageLoss: 0.0,
            largestWin: 0.0,
            largestLoss: 0.0,
            sharpeRatio: 0.0,
            maxDrawdown: 0.0,
            monthlyReturns: {},
            firstTradeDate: DateTime.now(),
          ),
          lastUpdated: DateTime.now(),
        );

        state = state.copyWith(
          portfolio: emptyPortfolio,
          holdings: [],
          transactions: [],
          realTimePrices: {},
          isLoading: false,
          error: null,
          lastUpdated: DateTime.now(),
        );
        print('🔄 [포트폴리오] 빈 포트폴리오로 fallback 설정 완료');
      }
    }
  }

  // 바이낸스와 동기화
  Future<void> syncWithBinance() async {
    final authState = _ref.read(authStateProvider);
    if (authState.status != AuthStatus.authenticated || authState.userData == null) return;

    final binanceState = _ref.read(binanceConnectionProvider);
    if (!binanceState.isConnected) return;

    state = state.copyWith(isSyncing: true, error: null);

    try {
      // StorageService에서 실제 API 키 가져오기
      final storage = StorageService.instance;
      final binanceKeyData = await storage.loadBinanceApiKeys();

      if (binanceKeyData == null || binanceKeyData['hasApiKey'] != true) {
        throw Exception('바이낸스 API 키가 설정되지 않았습니다');
      }

      final syncedPortfolio = await _portfolioService.syncPortfolioWithBinance(
        authState.userData!.uid,
        apiKey: binanceKeyData['apiKey'] as String,
        secretKey: binanceKeyData['secretKey'] as String,
        isTestnet: binanceKeyData['isTestnet'] as bool? ?? false,
      );

      state = state.copyWith(
        portfolio: syncedPortfolio,
        holdings: syncedPortfolio.holdings,
        isSyncing: false,
        lastSyncTime: DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      // 동기화 후 거래 내역도 새로고침
      await refreshTransactions();
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: '바이낸스 동기화 실패: $e',
      );
    }
  }

  // 성과 데이터 로드
  Future<void> loadPerformanceData(String period) async {
    final authState = _ref.read(authStateProvider);
    if (authState.status != AuthStatus.authenticated || authState.userData == null) return;

    try {
      final performance = await _portfolioService.getPortfolioPerformance(
        authState.userData!.uid,
        period,
      );

      final updatedPerformances = Map<String, PortfolioPerformance>.from(state.performances);
      updatedPerformances[period] = performance;

      state = state.copyWith(performances: updatedPerformances);
    } catch (e) {
      state = state.copyWith(error: '성과 데이터 로드 실패: $e');
    }
  }

  // 거래 내역 새로고침
  Future<void> refreshTransactions({
    int limit = 50,
    String? symbol,
    TransactionSide? side,
  }) async {
    final authState = _ref.read(authStateProvider);
    if (authState.status != AuthStatus.authenticated || authState.userData == null) return;

    try {
      final transactions = await _portfolioService.getTransactions(
        authState.userData!.uid,
        limit: limit,
        symbol: symbol,
        side: side,
      );

      state = state.copyWith(
        transactions: transactions,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: '거래 내역 새로고침 실패: $e');
    }
  }

  // 실시간 가격 업데이트
  Future<void> updateRealTimePrices() async {
    if (state.holdings.isEmpty) return;

    try {
      final symbols = state.holdings.map((h) => h.symbol).toList();
      final prices = await _portfolioService.getRealTimePrices(symbols);

      // 실시간 가격으로 보유 자산 업데이트
      final updatedHoldings = state.holdings.map((holding) {
        final currentPrice = prices[holding.symbol] ?? holding.currentPrice;
        final value = holding.quantity * currentPrice;
        final pnl = value - (holding.quantity * holding.averagePrice);
        final pnlPercent = holding.averagePrice > 0 ? (pnl / (holding.quantity * holding.averagePrice)) * 100 : 0;

        return holding.copyWith(
          currentPrice: currentPrice.toDouble(),
          value: value,
          pnl: pnl,
          pnlPercent: pnlPercent.toDouble(),
          lastUpdated: DateTime.now(),
        );
      }).toList();

      // 포트폴리오 총 가치 재계산
      if (state.portfolio != null) {
        final totalValue = updatedHoldings.fold<double>(0, (sum, h) => sum + h.value);
        final totalInvested = updatedHoldings.fold<double>(0, (sum, h) => sum + (h.quantity * h.averagePrice));
        final totalPnl = totalValue - totalInvested;
        final totalPnlPercent = totalInvested > 0 ? (totalPnl / totalInvested) * 100 : 0;

        final updatedPortfolio = state.portfolio!.copyWith(
          totalValue: totalValue.toDouble(),
          totalPnl: totalPnl,
          totalPnlPercent: totalPnlPercent.toDouble(),
          holdings: updatedHoldings,
          lastUpdated: DateTime.now(),
        );

        state = state.copyWith(
          portfolio: updatedPortfolio,
          holdings: updatedHoldings,
          realTimePrices: prices,
          lastUpdated: DateTime.now(),
        );
      } else {
        state = state.copyWith(
          holdings: updatedHoldings,
          realTimePrices: prices,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      state = state.copyWith(error: '실시간 가격 업데이트 실패: $e');
    }
  }

  // 자산 분석 데이터 가져오기
  Future<Map<String, dynamic>?> getAssetAnalysis(String symbol) async {
    final authState = _ref.read(authStateProvider);
    if (authState.status != AuthStatus.authenticated || authState.userData == null) return null;

    try {
      return await _portfolioService.getAssetAnalysis(authState.userData!.uid, symbol);
    } catch (e) {
      state = state.copyWith(error: '자산 분석 데이터 로드 실패: $e');
      return null;
    }
  }

  // 리밸런싱 제안 가져오기
  Future<Map<String, dynamic>?> getRebalancingSuggestions() async {
    final authState = _ref.read(authStateProvider);
    if (authState.status != AuthStatus.authenticated || authState.userData == null) return null;

    try {
      return await _portfolioService.getRebalancingSuggestions(authState.userData!.uid);
    } catch (e) {
      state = state.copyWith(error: '리밸런싱 제안 로드 실패: $e');
      return null;
    }
  }

  // 백테스팅 실행
  Future<Map<String, dynamic>?> runBacktest(Map<String, dynamic> strategy) async {
    final authState = _ref.read(authStateProvider);
    if (authState.status != AuthStatus.authenticated || authState.userData == null) return null;

    try {
      return await _portfolioService.runBacktest(authState.userData!.uid, strategy);
    } catch (e) {
      state = state.copyWith(error: '백테스팅 실행 실패: $e');
      return null;
    }
  }

  // 에러 클리어
  void clearError() {
    state = state.copyWith(error: null);
  }

  // 특정 자산으로 필터링된 거래 내역
  Future<void> filterTransactionsBySymbol(String symbol) async {
    await refreshTransactions(symbol: symbol);
  }

  // 매수/매도별 거래 내역 필터링
  Future<void> filterTransactionsBySide(TransactionSide side) async {
    await refreshTransactions(side: side);
  }

  // 자동 새로고침 시작 (30초마다 실시간 가격 업데이트)
  void startAutoRefresh() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        updateRealTimePrices();
        startAutoRefresh(); // 재귀 호출로 지속적 새로고침
      }
    });
  }

  // 포트폴리오 전체 새로고침
  Future<void> refreshAll() async {
    await loadPortfolioData();
    await loadPerformanceData('1D');
    await loadPerformanceData('1W');
    await loadPerformanceData('1M');
  }
}

// 포트폴리오 서비스 인스턴스 제공
final portfolioServiceProvider = Provider<PortfolioService>((ref) {
  return PortfolioService();
});

// 포트폴리오 상태 제공
final portfolioProvider = StateNotifierProvider<PortfolioNotifier, PortfolioState>((ref) {
  final portfolioService = ref.read(portfolioServiceProvider);
  final notifier = PortfolioNotifier(portfolioService, ref);

  // 자동 새로고침 시작
  notifier.startAutoRefresh();

  return notifier;
});

// 개별 데이터 접근을 위한 편의 Provider들
final portfolioDataProvider = Provider<PortfolioModel?>((ref) {
  return ref.watch(portfolioProvider).portfolio;
});

final holdingsProvider = Provider<List<AssetHolding>>((ref) {
  return ref.watch(portfolioProvider).holdings;
});

final transactionsProvider = Provider<List<Transaction>>((ref) {
  return ref.watch(portfolioProvider).transactions;
});

final realTimePricesProvider = Provider<Map<String, double>>((ref) {
  return ref.watch(portfolioProvider).realTimePrices;
});

final portfolioLoadingProvider = Provider<bool>((ref) {
  return ref.watch(portfolioProvider).isLoading;
});

final portfolioSyncingProvider = Provider<bool>((ref) {
  return ref.watch(portfolioProvider).isSyncing;
});

final portfolioErrorProvider = Provider<String?>((ref) {
  return ref.watch(portfolioProvider).error;
});

// 포트폴리오 성과 Provider들
final portfolioPerformanceProvider = Provider.family<PortfolioPerformance?, String>((ref, period) {
  return ref.watch(portfolioProvider).performances[period];
});

// 자산별 Provider들
final assetHoldingProvider = Provider.family<AssetHolding?, String>((ref, symbol) {
  final holdings = ref.watch(holdingsProvider);
  return holdings.cast<AssetHolding?>().firstWhere(
    (holding) => holding?.symbol == symbol,
    orElse: () => null,
  );
});

final assetTransactionsProvider = Provider.family<List<Transaction>, String>((ref, symbol) {
  final transactions = ref.watch(transactionsProvider);
  return transactions.where((tx) => tx.symbol == symbol).toList();
});

// 포트폴리오 통계 Provider들
final totalPortfolioValueProvider = Provider<double>((ref) {
  final portfolio = ref.watch(portfolioDataProvider);
  return portfolio?.totalValue ?? 0.0;
});

final totalPortfolioPnlProvider = Provider<double>((ref) {
  final portfolio = ref.watch(portfolioDataProvider);
  return portfolio?.totalPnl ?? 0.0;
});

final totalPortfolioPnlPercentProvider = Provider<double>((ref) {
  final portfolio = ref.watch(portfolioDataProvider);
  return portfolio?.totalPnlPercent ?? 0.0;
});

final portfolioAllocationProvider = Provider<Map<String, double>>((ref) {
  final portfolio = ref.watch(portfolioDataProvider);
  return portfolio?.allocation ?? {};
});

final topHoldingsProvider = Provider<List<AssetHolding>>((ref) {
  final portfolio = ref.watch(portfolioDataProvider);
  return portfolio?.topHoldings ?? [];
});

final recentTransactionsProvider = Provider<List<Transaction>>((ref) {
  final portfolio = ref.watch(portfolioDataProvider);
  return portfolio?.recentTransactions ?? [];
});

// 상태 체크 Provider들
final hasPortfolioDataProvider = Provider<bool>((ref) {
  final portfolio = ref.watch(portfolioDataProvider);
  return portfolio != null;
});

final hasHoldingsProvider = Provider<bool>((ref) {
  final holdings = ref.watch(holdingsProvider);
  return holdings.isNotEmpty;
});

final isPortfolioProfitableProvider = Provider<bool>((ref) {
  final portfolio = ref.watch(portfolioDataProvider);
  return portfolio?.isProfitable ?? false;
});

// 마지막 업데이트 시간 Provider
final lastPortfolioUpdateProvider = Provider<DateTime?>((ref) {
  return ref.watch(portfolioProvider).lastUpdated;
});

final lastSyncTimeProvider = Provider<DateTime?>((ref) {
  return ref.watch(portfolioProvider).lastSyncTime;
});