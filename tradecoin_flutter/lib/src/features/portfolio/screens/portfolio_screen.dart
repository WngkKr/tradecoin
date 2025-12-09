import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/exchange_rate_service.dart';
import '../../../shared/widgets/cyberpunk_header.dart';
import '../../../core/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../binance/screens/binance_onboarding_screen.dart';
import '../../binance/providers/binance_connection_provider.dart';
import '../providers/portfolio_provider.dart';
import '../models/portfolio_model.dart';

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final _exchangeRateService = ExchangeRateService();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();

    // 중복 바이낸스 연결 확인 제거 - MainScaffold에서 이미 처리됨
    print('💰 PortfolioScreen: 초기화 완료 (바이낸스 연결은 MainScaffold에서 처리)');
  }

  // _checkConnectionStatus 메서드 제거됨 (글로벌 상태로 관리)

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Consumer(
            builder: (context, ref, child) {
              try {
                final connectionState = ref.watch(binanceConnectionProvider);
                final portfolioState = ref.watch(portfolioProvider);
                final holdings = ref.watch(holdingsProvider);
                final authState = ref.watch(authStateProvider);

                // 디버그 로그 추가
                print('🔍 [포트폴리오 화면] 상태 확인:');
                print('  📱 인증 상태: ${authState.status}');
                print('  📱 사용자: ${authState.userData?.displayName}');
                print('  🔗 바이낸스 연결: ${connectionState.isConnected}');
                print('  📊 포트폴리오 로딩: ${portfolioState.isLoading}');
                print('  📊 포트폴리오 에러: ${portfolioState.error}');
                print('  📊 보유 자산 개수: ${holdings.length}');
                print('  📊 포트폴리오 데이터: ${portfolioState.portfolio != null ? "있음" : "없음"}');

                // 수동으로 포트폴리오 로딩 트리거 (디버그용)
                if (connectionState.isConnected &&
                    authState.status == AuthStatus.authenticated &&
                    portfolioState.portfolio == null &&
                    !portfolioState.isLoading &&
                    portfolioState.error == null) {
                  print('🚀 [포트폴리오 화면] 수동 포트폴리오 로딩 트리거');
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(portfolioProvider.notifier).loadPortfolioData();
                  });
                }

                // 포트폴리오 에러 상태 확인
                if (portfolioState.error != null) {
                  print('❌ [포트폴리오 화면] 에러 상태 표시: ${portfolioState.error}');
                  return _buildErrorState(portfolioState.error!);
                }

                // 바이낸스 연결 상태 확인
                if (connectionState.isLoading || portfolioState.isLoading) {
                  print('⏳ [포트폴리오 화면] 로딩 상태 표시');
                  return _buildLoadingState();
                } else if (!connectionState.isConnected) {
                  print('🔗 [포트폴리오 화면] 연결 필요 상태 표시');
                  return _buildConnectionRequiredState();
                } else {
                  print('✅ [포트폴리오 화면] 포트폴리오 콘텐츠 표시');
                  return _buildPortfolioContent();
                }
              } catch (e, stackTrace) {
                print('❌ [포트폴리오 화면] Consumer 빌드 에러: $e');
                print('📚 [포트폴리오 화면] 스택 트레이스: $stackTrace');
                return _buildErrorState('포트폴리오 로딩 중 에러가 발생했습니다: $e');
              }
            },
          ),
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
            '포트폴리오 데이터를 불러오고 있습니다...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          // 에러 아이콘
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.dangerRed.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.dangerRed.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.dangerRed,
            ),
          ),

          const SizedBox(height: 32),

          // 제목과 설명
          Text(
            '포트폴리오 로딩 에러',
            style: AppTheme.headingLarge,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            errorMessage,
            style: AppTheme.bodyMedium.copyWith(
              color: Colors.white70,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 48),

          // 재시도 버튼
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.accentBlue, AppTheme.primaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  // 포트폴리오 데이터 재로딩
                  ref.read(portfolioProvider.notifier).loadPortfolioData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.refresh, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      '다시 시도',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 바이낸스 설정 버튼
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BinanceOnboardingScreen(),
                ),
              );
            },
            icon: Icon(Icons.settings, color: AppTheme.accentBlue),
            label: Text(
              '바이낸스 설정',
              style: TextStyle(color: AppTheme.accentBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionRequiredState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          // 연결 필요 아이콘
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.dangerRed.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.dangerRed.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.link_off,
              size: 64,
              color: AppTheme.dangerRed,
            ),
          ),

          const SizedBox(height: 32),

          // 제목과 설명
          Text(
            '바이낸스 연결이 필요합니다',
            style: AppTheme.headingLarge,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            '포트폴리오를 확인하려면 바이낸스 API를 연결해야 합니다.\nAPI 키를 설정하여 실시간 거래 정보를 확인하세요.',
            style: AppTheme.bodyMedium.copyWith(
              color: Colors.white70,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 48),

          // 연결하기 버튼
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.accentBlue, AppTheme.primaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BinanceOnboardingScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.link, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      '바이낸스 연결하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 새로고침 버튼
          TextButton.icon(
            onPressed: () {
              ref.read(binanceConnectionProvider.notifier).checkConnectionStatus();
            },
            icon: Icon(Icons.refresh, color: AppTheme.accentBlue),
            label: Text(
              '연결 상태 새로고침',
              style: TextStyle(color: AppTheme.accentBlue),
            ),
          ),

          const SizedBox(height: 32),

          // 정보 카드
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.glassmorphism(),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: AppTheme.accentBlue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '안전한 연결',
                      style: TextStyle(
                        color: AppTheme.accentBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• 테스트넷으로 안전하게 시작할 수 있습니다\n'
                  '• API 키는 암호화되어 안전하게 저장됩니다\n'
                  '• 언제든지 연결을 해제할 수 있습니다',
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 연결 상태 표시
          _buildConnectionStatus(),
          const SizedBox(height: 16),

          // 포트폴리오 헤더
          _buildPortfolioHeader(),
          const SizedBox(height: 24),

          // 자산 분배 차트
          _buildAssetAllocation(),
          const SizedBox(height: 24),

          // 보유 자산 목록
          _buildHoldings(),
          const SizedBox(height: 24),

          // 거래 히스토리
          _buildTransactionHistory(),

          const SizedBox(height: 100), // 하단 네비게이션 공간
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.successGreen.withOpacity(0.2),
            AppTheme.accentBlue.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.successGreen.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppTheme.successGreen,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '바이낸스 연결됨',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final accountType = ref.watch(binanceAccountTypeProvider);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          accountType == 'demo' ? '테스트넷 환경' : '실거래 환경',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Consumer(
                          builder: (context, ref, child) {
                            final holdings = ref.watch(holdingsProvider);
                            return Text(
                              holdings.isEmpty
                                ? '📭 빈 계좌 (실제 자산 없음)'
                                : '💰 실제 보유 자산 표시 중',
                              style: TextStyle(
                                color: holdings.isEmpty
                                  ? Colors.orange
                                  : AppTheme.successGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BinanceOnboardingScreen(),
                ),
              );
            },
            icon: Icon(Icons.settings, color: AppTheme.accentBlue, size: 16),
            label: Text(
              '설정',
              style: TextStyle(color: AppTheme.accentBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioHeader() {
    return Consumer(
      builder: (context, ref, child) {
        try {
          final portfolio = ref.watch(portfolioDataProvider);
          final isLoading = ref.watch(portfolioLoadingProvider);

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.glassmorphism(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: AppTheme.successGreen,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '포트폴리오 총 가치',
                          style: AppTheme.headingMedium.copyWith(
                            color: AppTheme.successGreen,
                          ),
                        ),
                        const Spacer(),
                        if (isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // KRW 금액 표시 (메인)
                    if (portfolio != null)
                      Text(
                        _exchangeRateService.formatCurrency(
                          _exchangeRateService.convertFromUSD(portfolio.totalValue, 'KRW'),
                          'KRW',
                        ),
                        style: AppTheme.headingLarge.copyWith(fontSize: 36),
                      )
                    else
                      Text(
                        '₩0',
                        style: AppTheme.headingLarge.copyWith(fontSize: 36),
                      ),
                    // USD 금액 표시 (보조)
                    Text(
                      portfolio?.formattedTotalValue ?? '\$0.00',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white60,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          (portfolio?.isProfitable ?? false) ? Icons.trending_up : Icons.trending_down,
                          color: (portfolio?.isProfitable ?? false) ? AppTheme.accentBlue : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          portfolio?.formattedTotalPnl ?? '+\$0.00 (0.0%)',
                          style: TextStyle(
                            color: (portfolio?.isProfitable ?? false) ? AppTheme.accentBlue : Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '지난 24시간',
                          style: AppTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        } catch (e) {
          // 포트폴리오 헤더 빌드 중 에러 발생 시 기본 헤더 표시
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.glassmorphism(),
            child: Column(
              children: [
                Text(
                  '포트폴리오 정보를 불러올 수 없습니다',
                  style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$0.00',
                  style: AppTheme.headingLarge.copyWith(fontSize: 36),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildAssetAllocation() {
    return Consumer(
      builder: (context, ref, child) {
        final holdings = ref.watch(holdingsProvider);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.glassmorphism(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '자산 분배',
                    style: AppTheme.headingMedium.copyWith(
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: holdings.isEmpty
                        ? const Center(
                            child: Text(
                              '보유 자산이 없습니다',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 60,
                              sections: _buildPieChartSections(holdings),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _buildPieChartSections(List<AssetHolding> holdings) {
    final colors = [
      AppTheme.accentBlue,
      AppTheme.primaryBlue,
      AppTheme.dangerRed,
      AppTheme.neutralGray,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];

    return holdings.asMap().entries.map((entry) {
      final index = entry.key;
      final holding = entry.value;
      final color = colors[index % colors.length];

      return PieChartSectionData(
        color: color,
        value: holding.percentageOfPortfolio,
        title: '${holding.symbol}\n${holding.percentageOfPortfolio.toStringAsFixed(0)}%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildHoldings() {
    return Consumer(
      builder: (context, ref, child) {
        final holdings = ref.watch(holdingsProvider);
        final portfolioState = ref.watch(portfolioProvider);

        print('🔍 [_buildHoldings] 보유 자산 상태:');
        print('  📊 보유 자산 개수: ${holdings.length}');
        print('  📊 포트폴리오 상태: ${portfolioState.portfolio != null ? "있음" : "없음"}');
        print('  📊 로딩 중: ${portfolioState.isLoading}');
        print('  📊 에러: ${portfolioState.error}');

        if (holdings.isNotEmpty) {
          print('  📋 자산 목록:');
          for (final holding in holdings) {
            print('    • ${holding.symbol}: ${holding.quantity} (${holding.value})');
          }
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.glassmorphism(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '보유 자산',
                    style: AppTheme.headingMedium.copyWith(
                      color: AppTheme.neutralGray,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (holdings.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 48,
                              color: Colors.white38,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '보유 자산이 없습니다',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '실제 바이낸스 계좌가 비어있습니다.\n거래를 시작하려면 자금을 입금하세요.',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...holdings.map((holding) => _buildHoldingItem(holding)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHoldingItem(AssetHolding holding) {
    final colors = [
      AppTheme.accentBlue,
      AppTheme.primaryBlue,
      AppTheme.dangerRed,
      AppTheme.neutralGray,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];
    final color = colors[holding.symbol.hashCode % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1A1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x331E293B)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                holding.symbol,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holding.symbol,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  holding.name,
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // KRW 금액 (메인)
              Text(
                _exchangeRateService.formatCurrency(
                  _exchangeRateService.convertFromUSD(holding.value, 'KRW'),
                  'KRW',
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              // USD 금액 (보조)
              Text(
                holding.formattedValue,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
              // 수량 및 수익률
              Text(
                '${holding.formattedQuantity} ${holding.symbol} • ${holding.formattedPnl}',
                style: TextStyle(
                  color: holding.isProfitable ? AppTheme.accentBlue : Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory() {
    return Consumer(
      builder: (context, ref, child) {
        final transactions = ref.watch(transactionsProvider);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.glassmorphism(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '최근 거래',
                    style: AppTheme.headingMedium.copyWith(
                      color: AppTheme.dangerRed,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (transactions.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          '거래 내역이 없습니다',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    )
                  else
                    ...transactions.take(5).map((transaction) => _buildTransactionItem(transaction)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1A22D3EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0x3322D3EE),
        ),
      ),
      child: Row(
        children: [
          Icon(
            transaction.isBuy ? Icons.add_circle : Icons.remove_circle,
            color: transaction.isBuy ? AppTheme.accentBlue : Colors.red,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${transaction.sideKorean} ${transaction.symbol}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${transaction.formattedQuantity} ${transaction.symbol}',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                transaction.formattedTotalAmount,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                transaction.formattedDate,
                style: AppTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}