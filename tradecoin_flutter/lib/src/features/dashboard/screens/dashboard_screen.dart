import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/api_service.dart' show MarketDataResponse, MarketCoin, TradingSignalsResponse, TradingSignal, PortfolioSummaryResponse, PortfolioSummary, BinanceConnectionResponse, BinanceBalance, apiServiceProvider, marketDataProvider, portfolioSummaryProvider, tradingSignalsProvider;
import '../../../core/services/exchange_rate_service.dart';
import '../../../shared/widgets/cyberpunk_header.dart';
import '../widgets/portfolio_balance_card.dart';
import '../widgets/quick_actions_section.dart';
import '../widgets/recent_activity_section.dart';
import '../widgets/market_overview_card.dart';
import '../widgets/binance_connection_status.dart';
import '../providers/dashboard_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../news/providers/news_provider.dart';
import '../../news/models/news_model.dart';
import '../../signals/providers/signals_provider.dart';
import '../../signals/models/signal_model.dart';
import '../../binance/providers/binance_connection_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _exchangeRateService = ExchangeRateService();

  @override
  void initState() {
    super.initState();
    // 중복 바이낸스 연결 확인 제거 - MainScaffold에서 이미 처리됨
    print('📱 DashboardScreen: 초기화 완료 (바이낸스 연결은 MainScaffold에서 처리)');
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 로컬 세션 기반 인증 상태 확인
    final authState = ref.watch(authStateProvider);

    final marketData = ref.watch(marketDataProvider);
    // portfolioSummaryProvider는 더 이상 사용하지 않음 - 사용자별 포트폴리오로 변경됨
    // final portfolioSummary = ref.watch(portfolioSummaryProvider);
    final tradingSignals = ref.watch(tradingSignalsProvider);
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      appBar: const CyberpunkHeader(),
      body: Container(
        decoration: BoxDecoration(
          gradient: themeState.isDarkMode
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E1B4B),
                  Color(0xFF312E81),
                  Color(0xFF3730A3),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8FAFC),
                  Color(0xFFE2E8F0),
                  Color(0xFFCBD5E1),
                ],
              ),
        ),
        child: _buildDashboardContentWithRealData(
          authState,
          marketData,
          tradingSignals,
        ),
      ),
    );
  }

  Widget _buildDashboardContent(DashboardData data) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(dashboardDataProvider);
      },
      color: AppTheme.accentBlue,
      backgroundColor: AppTheme.surfaceDark,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 포트폴리오 잔고 카드
            PortfolioBalanceCard(
              balance: data.portfolioBalance,
              todayPnL: data.todayPnL,
              todayPnLPercent: data.todayPnLPercent,
            ),

            const SizedBox(height: 24),

            // 마켓 개요
            MarketOverviewCard(marketData: data.marketOverview),

            const SizedBox(height: 24),

            // 빠른 액션
            const QuickActionsSection(),

            const SizedBox(height: 24),

            // 최근 활동
            RecentActivitySection(activities: data.recentActivities),

            const SizedBox(height: 24),

            // 실시간 시그널
            _buildRealtimeSignalsSection(),

            const SizedBox(height: 24),

            // 최신 뉴스
            _buildLatestNewsSection(),

            const SizedBox(height: 100), // 하단 네비게이션 공간
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
          ),
          SizedBox(height: 16),
          Text(
            'Loading dashboard...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
              ),
            ),
            child: const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load dashboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              ref.refresh(dashboardDataProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentBlue,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDashboardContentWithRealData(
    AuthState authState,
    AsyncValue<MarketDataResponse> marketData,
    AsyncValue<TradingSignalsResponse> tradingSignals,
  ) {
    // 모든 데이터가 로딩 중인지 확인
    final isAllLoading = marketData.isLoading &&
                        tradingSignals.isLoading;

    // 초기 로딩 상태에서는 기본 정보 표시 (API 로딩 후 실제 데이터로 교체)
    if (isAllLoading) {
      return _buildInformationalDashboard(authState);
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(marketDataProvider);
        ref.invalidate(tradingSignalsProvider);
      },
      color: AppTheme.accentBlue,
      backgroundColor: AppTheme.surfaceDark,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 사용자 환영 메시지 + 바이낸스 연결 상태
            if (authState.status == AuthStatus.authenticated && authState.userData != null)
              _buildWelcomeSection(authState),

            // 바이낸스 연결 상태 카드
            const BinanceConnectionStatus(),

            const SizedBox(height: 16),

            // 간단한 단일 컬럼 레이아웃으로 변경 (성능 최적화)
            _buildMobileLayout(marketData, tradingSignals),

            const SizedBox(height: 16),

            // 빠른 액션
            const QuickActionsSection(),

            const SizedBox(height: 100), // 하단 네비게이션 공간
          ],
        ),
      ),
    );
  }

  // 와이드 스크린 레이아웃 (3컬럼 그리드)
  Widget _buildWideScreenLayout(
    AsyncValue<PortfolioSummaryResponse> portfolioSummary,
    AsyncValue<MarketDataResponse> marketData,
    AsyncValue<TradingSignalsResponse> tradingSignals,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 첫 번째 컬럼: 포트폴리오
        Expanded(
          flex: 1,
          child: portfolioSummary.when(
            data: (data) => _buildPortfolioSummaryCard(data.data),
            loading: () => _buildLoadingCard('포트폴리오 로딩 중...'),
            error: (error, _) => _buildErrorCard('포트폴리오', error.toString()),
          ),
        ),
        const SizedBox(width: 16),
        // 두 번째 컬럼: 시장 데이터
        Expanded(
          flex: 1,
          child: marketData.when(
            data: (data) => _buildMarketDataCard(data.data),
            loading: () => _buildLoadingCard('시장 데이터 로딩 중...'),
            error: (error, _) => _buildErrorCard('시장 데이터', error.toString()),
          ),
        ),
        const SizedBox(width: 16),
        // 세 번째 컬럼: 트레이딩 시그널
        Expanded(
          flex: 1,
          child: tradingSignals.when(
            data: (data) => _buildTradingSignalsCard(data.data),
            loading: () => _buildLoadingCard('트레이딩 시그널 로딩 중...'),
            error: (error, _) => _buildErrorCard('트레이딩 시그널', error.toString()),
          ),
        ),
      ],
    );
  }

  // 미디엄 스크린 레이아웃 (2컬럼 그리드)
  Widget _buildMediumScreenLayout(
    AsyncValue<PortfolioSummaryResponse> portfolioSummary,
    AsyncValue<MarketDataResponse> marketData,
    AsyncValue<TradingSignalsResponse> tradingSignals,
  ) {
    return Column(
      children: [
        // 첫 번째 행: 포트폴리오와 시장 데이터
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: portfolioSummary.when(
                data: (data) => _buildPortfolioSummaryCard(data.data),
                loading: () => _buildLoadingCard('포트폴리오 로딩 중...'),
                error: (error, _) => _buildErrorCard('포트폴리오', error.toString()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: marketData.when(
                data: (data) => _buildMarketDataCard(data.data),
                loading: () => _buildLoadingCard('시장 데이터 로딩 중...'),
                error: (error, _) => _buildErrorCard('시장 데이터', error.toString()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 두 번째 행: 트레이딩 시그널 (전체 너비)
        tradingSignals.when(
          data: (data) => _buildTradingSignalsCard(data.data),
          loading: () => _buildLoadingCard('트레이딩 시그널 로딩 중...'),
          error: (error, _) => _buildErrorCard('트레이딩 시그널', error.toString()),
        ),
      ],
    );
  }

  // 모바일 레이아웃 (단일 컬럼)
  Widget _buildMobileLayout(
    AsyncValue<MarketDataResponse> marketData,
    AsyncValue<TradingSignalsResponse> tradingSignals,
  ) {
    return Column(
      children: [
        // 실시간 시장 데이터 (애니메이션 제거로 성능 최적화)
        marketData.when(
          data: (data) => _buildMarketDataCard(data.data),
          loading: () => _buildLoadingCard('시장 데이터 로딩 중...'),
          error: (error, _) => _buildErrorCard('시장 데이터', error.toString()),
        ),

        const SizedBox(height: 16),

        // AI 트레이딩 시그널 (애니메이션 제거로 성능 최적화)
        tradingSignals.when(
          data: (data) => _buildTradingSignalsCard(data.data),
          loading: () => _buildLoadingCard('트레이딩 시그널 로딩 중...'),
          error: (error, _) => _buildErrorCard('트레이딩 시그널', error.toString()),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(AuthState authState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.glassmorphism(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '환영합니다, ${authState.userData!.displayName}님!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '구독 상태: ${authState.userData!.subscription.tier.toUpperCase()}',
            style: TextStyle(
              color: AppTheme.accentBlue,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF34D399).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF34D399).withOpacity(0.2),
              ),
            ),
            child: const Text(
              '🟢 실시간 데이터 연결됨',
              style: TextStyle(
                color: Color(0xFF34D399),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioSummaryCard(PortfolioSummary summary) {
    final totalBalanceKRW = _exchangeRateService.convertFromUSD(summary.totalBalance, 'KRW');
    final todayProfitKRW = _exchangeRateService.convertFromUSD(summary.todayProfit, 'KRW');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassmorphism(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: AppTheme.accentBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '포트폴리오 현황',
                style: TextStyle(
                  color: AppTheme.accentBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '총 잔고',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      _exchangeRateService.formatCurrency(totalBalanceKRW, 'KRW'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${summary.totalBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '오늘 수익',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      '${_exchangeRateService.formatCurrency(todayProfitKRW, 'KRW')} (${summary.todayProfitPercent.toStringAsFixed(2)}%)',
                      style: TextStyle(
                        color: summary.todayProfit >= 0
                          ? AppTheme.successGreen
                          : AppTheme.dangerRed,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('총 거래', '${summary.totalTrades}건'),
              _buildStatItem('승률', '${summary.winRate.toStringAsFixed(1)}%'),
              _buildStatItem('총 수익률', '${summary.totalProfitPercent.toStringAsFixed(2)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.accentBlue,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMarketDataCard(List<MarketCoin> coins) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassmorphism(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: AppTheme.accentBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '실시간 시장 현황',
                style: TextStyle(
                  color: AppTheme.accentBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...coins.take(5).map((coin) {
            final priceKRW = _exchangeRateService.convertFromUSD(coin.price, 'KRW');
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coin.symbol,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          coin.name,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _exchangeRateService.formatCurrency(priceKRW, 'KRW'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${coin.changePercent24h > 0 ? '+' : ''}${coin.changePercent24h.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: coin.changePercent24h >= 0
                            ? AppTheme.successGreen
                            : AppTheme.dangerRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTradingSignalsCard(List<TradingSignal> signals) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassmorphism(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: AppTheme.accentBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'AI 트레이딩 시그널',
                style: TextStyle(
                  color: AppTheme.accentBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...signals.take(3).map((signal) => Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getSignalColor(signal.signal).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      signal.symbol,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getSignalColor(signal.signal),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        signal.signal,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '신뢰도: ${(signal.confidence * 100).toInt()}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  signal.reason,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Color _getSignalColor(String signal) {
    switch (signal.toUpperCase()) {
      case 'BUY':
        return AppTheme.successGreen;
      case 'SELL':
        return AppTheme.dangerRed;
      case 'HOLD':
      default:
        return AppTheme.neutralGray;
    }
  }

  Widget _buildLoadingCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassmorphism(),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _buildSkeletonLoader(),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Column(
      children: [
        _buildSkeletonLine(width: double.infinity, height: 16),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildSkeletonLine(width: double.infinity, height: 12)),
            const SizedBox(width: 16),
            Expanded(child: _buildSkeletonLine(width: double.infinity, height: 12)),
          ],
        ),
        const SizedBox(height: 8),
        _buildSkeletonLine(width: 120, height: 12),
      ],
    );
  }

  Widget _buildSkeletonLine({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Colors.white.withOpacity(0.1),
      ),
    );
  }

  Widget _buildErrorCard(String title, String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassmorphism(),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: AppTheme.dangerRed,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            '$title 로딩 실패',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 실제 데이터 로딩 중 상태 표시 (더미 데이터 제거)
  Widget _buildInformationalDashboard(AuthState authState) {
    print('🔄 [대시보드] 실제 데이터 로딩 중 - 더미 데이터 대신 로딩 상태 표시');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 환영 메시지
          if (authState.status == AuthStatus.authenticated && authState.userData != null)
            _buildWelcomeSection(authState),

          const SizedBox(height: 16),

          // 바이낸스 연결 상태 카드
          const BinanceConnectionStatus(),

          const SizedBox(height: 16),

          // 실제 데이터 로딩 중 표시
          _buildRealDataLoadingCard(),

          const SizedBox(height: 16),

          // 빠른 액션 (항상 표시)
          const QuickActionsSection(),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // 실제 데이터 로딩 중 카드 (더미 정보 제거)
  Widget _buildRealDataLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassmorphism(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
                strokeWidth: 2,
              ),
              const SizedBox(width: 12),
              Text(
                '실시간 시장 데이터 로딩 중...',
                style: TextStyle(
                  color: AppTheme.accentBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '바이낸스 API에서 최신 시장 데이터를 가져오고 있습니다.',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            'AI 분석 엔진이 실시간 데이터를 처리하여 정확한 시그널을 생성합니다.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLoadingIndicator('포트폴리오'),
              _buildLoadingIndicator('시장 데이터'),
              _buildLoadingIndicator('AI 시그널'),
            ],
          ),
        ],
      ),
    );
  }

  // 로딩 인디케이터 (작은 컴포넌트)
  Widget _buildLoadingIndicator(String label) {
    return Column(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
            strokeWidth: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }






  Widget _buildRealtimeSignalsSection() {
    final activeSignals = ref.watch(activeSignalsProvider);
    final signalsLoading = ref.watch(signalsLoadingProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassmorphism(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🔥 실시간 시그널',
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.accentBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              if (signalsLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (signalsLoading && activeSignals.isEmpty)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
              ),
            )
          else if (activeSignals.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.signal_cellular_off,
                    size: 48,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '현재 활성 시그널이 없습니다',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: activeSignals
                  .take(3)
                  .map((signal) => _buildSignalPreviewCard(signal))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSignalPreviewCard(SignalModel signal) {
    final color = _getSignalColor(signal.signalType);
    final isPositive = signal.priceChangePercent >= 0;
    final priceKRW = _exchangeRateService.convertFromUSD(signal.currentPrice, 'KRW');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x0A000000),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getSignalIcon(signal.signalType),
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  signal.pair,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${signal.signalTypeKorean} • ${(signal.confidenceScore * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _exchangeRateService.formatCurrency(priceKRW, 'KRW'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                signal.priceChangeFormatted,
                style: TextStyle(
                  color: isPositive ? AppTheme.accentBlue : Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLatestNewsSection() {
    final breakingNews = ref.watch(breakingNewsProvider);
    final newsLoading = ref.watch(newsLoadingProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassmorphism(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📰 주요 뉴스',
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              if (newsLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (newsLoading && breakingNews.isEmpty)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
            )
          else if (breakingNews.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.newspaper,
                    size: 48,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '최신 뉴스를 불러오는 중...',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: breakingNews
                  .take(3)
                  .map((news) => _buildNewsPreviewCard(news))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildNewsPreviewCard(NewsModel news) {
    final sentimentColor = _getSentimentColor(news.sentimentAnalysis.sentiment);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x0A000000),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sentimentColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: sentimentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getSentimentKorean(news.sentimentAnalysis.sentiment),
                  style: TextStyle(
                    color: sentimentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatTimeAgo(news.publishedAt),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            news.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            news.summary,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getSentimentKorean(SentimentType sentiment) {
    switch (sentiment) {
      case SentimentType.veryBullish:
        return '매우 긍정적';
      case SentimentType.bullish:
        return '긍정적';
      case SentimentType.neutral:
        return '중립적';
      case SentimentType.bearish:
        return '부정적';
      case SentimentType.veryBearish:
        return '매우 부정적';
      default:
        return '중립적';
    }
  }

  IconData _getSignalIcon(String signalType) {
    switch (signalType) {
      case 'buy':
        return Icons.trending_up;
      case 'sell':
        return Icons.trending_down;
      case 'hold':
        return Icons.remove;
      default:
        return Icons.help_outline;
    }
  }

  Color _getSentimentColor(SentimentType sentiment) {
    switch (sentiment) {
      case SentimentType.veryBullish:
        return AppTheme.accentBlue;
      case SentimentType.bullish:
        return AppTheme.primaryBlue;
      case SentimentType.neutral:
        return AppTheme.neutralGray;
      case SentimentType.bearish:
        return Colors.orange;
      case SentimentType.veryBearish:
        return AppTheme.dangerRed;
      default:
        return AppTheme.neutralGray;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else {
      return '${difference.inDays}일 전';
    }
  }
}

// 대시보드 데이터 모델
class DashboardData {
  final double portfolioBalance;
  final double todayPnL;
  final double todayPnLPercent;
  final MarketOverviewData marketOverview;
  final List<ActivityItem> recentActivities;

  const DashboardData({
    required this.portfolioBalance,
    required this.todayPnL,
    required this.todayPnLPercent,
    required this.marketOverview,
    required this.recentActivities,
  });
}

class MarketOverviewData {
  final double btcPrice;
  final double btcChange;
  final double ethPrice;
  final double ethChange;
  final String marketStatus;

  const MarketOverviewData({
    required this.btcPrice,
    required this.btcChange,
    required this.ethPrice,
    required this.ethChange,
    required this.marketStatus,
  });
}

class ActivityItem {
  final String id;
  final String type;
  final String coinSymbol;
  final double amount;
  final double price;
  final DateTime timestamp;
  final String status;

  const ActivityItem({
    required this.id,
    required this.type,
    required this.coinSymbol,
    required this.amount,
    required this.price,
    required this.timestamp,
    required this.status,
  });
}