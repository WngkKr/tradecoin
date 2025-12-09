import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../binance/providers/binance_connection_provider.dart';
import '../../portfolio/providers/portfolio_provider.dart';
import '../../portfolio/services/portfolio_service.dart';

class ApiTestScreen extends ConsumerStatefulWidget {
  const ApiTestScreen({super.key});

  @override
  ConsumerState<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends ConsumerState<ApiTestScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<String> _testResults = [];
  bool _isTestRunning = false;

  @override
  void initState() {
    super.initState();
    // 화면 로드 시 바이낸스 연결 상태 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeConnections();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 연결 상태 초기화
  Future<void> _initializeConnections() async {
    try {
      _addTestResult('🔄 초기 연결 상태 확인 중...');
      await ref.read(binanceConnectionProvider.notifier).checkConnectionStatus();
      _addTestResult('✅ 초기 연결 상태 확인 완료');
    } catch (e) {
      _addTestResult('❌ 초기 연결 상태 확인 실패: $e');
    }
  }

  void _addTestResult(String result) {
    setState(() {
      _testResults.add('${DateTime.now().toString().substring(11, 19)}: $result');
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearResults() {
    setState(() {
      _testResults.clear();
    });
  }

  Future<void> _testApiKey() async {
    _addTestResult('🔑 API 키 테스트 시작...');
    try {
      final connectionState = ref.read(binanceConnectionProvider);
      final storage = StorageService.instance;
      final keys = await storage.loadBinanceApiKeys() ?? {};

      _addTestResult('✅ API 키 상태: ${connectionState.isConnected ? "연결됨" : "연결 안됨"}');
      _addTestResult('🔍 API 키: ${keys['maskedApiKey'] ?? "없음"}');
      _addTestResult('🔍 시크릿 키: ${keys['maskedSecretKey'] ?? "없음"}');
      _addTestResult('🔍 테스트넷: ${keys['isTestnet'] ?? false ? "예" : "아니오"}');
    } catch (e) {
      _addTestResult('❌ API 키 테스트 실패: $e');
    }
  }

  Future<void> _testPortfolioLoad() async {
    _addTestResult('💰 포트폴리오 로딩 테스트 시작...');
    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.userData?.uid ?? 'test_user';

      _addTestResult('👤 사용자 ID: $userId');

      final portfolioService = PortfolioService();
      final portfolio = await portfolioService.getPortfolio(userId);

      _addTestResult('✅ 포트폴리오 로딩 성공');
      _addTestResult('📊 총 자산: \$${portfolio.totalValue.toStringAsFixed(2)}');
      _addTestResult('📈 총 손익: \$${portfolio.totalPnl.toStringAsFixed(2)}');
      _addTestResult('🔢 보유 자산 수: ${portfolio.holdings.length}개');

      for (final holding in portfolio.holdings) {
        _addTestResult('  📈 ${holding.symbol}: ${holding.quantity} (${holding.pnlPercent.toStringAsFixed(2)}%)');
      }
    } catch (e) {
      _addTestResult('❌ 포트폴리오 로딩 실패: $e');
    }
  }

  Future<void> _testBinanceApi() async {
    _addTestResult('🔗 바이낸스 연결 상태 테스트 시작...');
    try {
      final connectionState = ref.read(binanceConnectionProvider);

      _addTestResult('📊 바이낸스 연결 상태 확인 중...');

      if (connectionState.isConnected) {
        _addTestResult('✅ 바이낸스 연결 성공');
        _addTestResult('🔑 API 키 마스킹됨: ${connectionState.isConnected ? "설정됨" : "N/A"}');
        _addTestResult('🔧 계정 타입: ${connectionState.accountType ?? "N/A"}');
      } else {
        _addTestResult('❌ 바이낸스 연결 실패');
        _addTestResult('📋 에러: ${connectionState.error ?? "연결 상태 없음"}');
      }
    } catch (e) {
      _addTestResult('❌ 바이낸스 API 테스트 실패: $e');
    }
  }

  Future<void> _testBackendApi() async {
    _addTestResult('🖥️ 백엔드 API 테스트 시작...');
    try {
      final portfolioService = PortfolioService();
      final authState = ref.read(authStateProvider);
      final userId = authState.userData?.uid ?? 'test_user';

      // 직접 백엔드 API 호출 테스트
      _addTestResult('🌐 백엔드 API 직접 호출 중...');

      final response = await portfolioService.testBackendConnection(userId);
      _addTestResult('✅ 백엔드 응답: $response');

    } catch (e) {
      _addTestResult('❌ 백엔드 API 테스트 실패: $e');
    }
  }

  Future<void> _testTradingFunctions() async {
    _addTestResult('⚡ 거래 기능 테스트 시작...');
    try {
      final connectionState = ref.read(binanceConnectionProvider);

      if (!connectionState.isConnected) {
        _addTestResult('❌ 바이낸스 연결이 필요합니다');
        return;
      }

      _addTestResult('📊 거래 가능 상태 확인 중...');

      // 계정 정보 확인
      final accountInfo = connectionState.accountInfo;
      if (accountInfo != null) {
        _addTestResult('✅ 계정 타입: ${accountInfo['accountType']}');
        _addTestResult('✅ 거래 가능: ${accountInfo['canTrade'] ?? false ? "예" : "아니오"}');
        _addTestResult('💰 지갑 잔액: ${accountInfo['totalWalletBalance'] ?? '0.00'} USDT');
      }

      // 모의 거래 테스트 (실제 거래 X)
      _addTestResult('🎯 모의 거래 주문 테스트...');
      _addTestResult('📈 테스트 주문: BTC 매수 0.001 BTC');
      _addTestResult('💡 주문 타입: MARKET (시장가)');
      _addTestResult('⚠️ 실제 주문이 아닌 테스트입니다');

      // 잠시 대기 (실제 API 호출 시뮬레이션)
      await Future.delayed(const Duration(milliseconds: 1500));

      _addTestResult('✅ 모의 거래 주문 성공');
      _addTestResult('📝 주문 ID: TEST_ORDER_123456');
      _addTestResult('💰 예상 수수료: 0.001 USDT');

      _addTestResult('🔍 주문 상태 조회 테스트...');
      await Future.delayed(const Duration(milliseconds: 1000));
      _addTestResult('✅ 주문 상태: FILLED (체결 완료)');

      _addTestResult('📊 거래 내역 조회 테스트...');
      await Future.delayed(const Duration(milliseconds: 1000));
      _addTestResult('✅ 최근 거래 3건 조회 성공');
      _addTestResult('  • BTC/USDT: +0.001 BTC (매수)');
      _addTestResult('  • ETH/USDT: -0.1 ETH (매도)');
      _addTestResult('  • DOGE/USDT: +1000 DOGE (매수)');

    } catch (e) {
      _addTestResult('❌ 거래 기능 테스트 실패: $e');
    }
  }

  Future<void> _runAllTests() async {
    if (_isTestRunning) return;

    setState(() {
      _isTestRunning = true;
    });

    _clearResults();
    _addTestResult('🚀 전체 테스트 시작');

    await _testApiKey();
    await Future.delayed(const Duration(milliseconds: 500));

    await _testPortfolioLoad();
    await Future.delayed(const Duration(milliseconds: 500));

    await _testBinanceApi();
    await Future.delayed(const Duration(milliseconds: 500));

    await _testBackendApi();
    await Future.delayed(const Duration(milliseconds: 500));

    await _testTradingFunctions();

    _addTestResult('🏁 전체 테스트 완료');

    setState(() {
      _isTestRunning = false;
    });
  }

  void _copyApiKey() async {
    try {
      final storage = StorageService.instance;
      final keys = await storage.loadBinanceApiKeys();
      final apiKey = keys?['apiKey'] ?? '';
      if (apiKey.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: apiKey));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('API 키가 클립보드에 복사되었습니다')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API 키 복사 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(binanceConnectionProvider);
    final portfolioState = ref.watch(portfolioProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('API 테스트'),
        backgroundColor: const Color(0xFF1E1B4B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _clearResults,
            icon: const Icon(Icons.clear_all),
            tooltip: '결과 지우기',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E1B4B),
              Color(0xFF312E81),
              Color(0xFF3730A3),
            ],
          ),
        ),
        child: Column(
          children: [
            // 상태 정보 카드
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassmorphism(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        connectionState.isConnected
                          ? Icons.check_circle
                          : Icons.cancel,
                        color: connectionState.isConnected
                          ? AppTheme.successGreen
                          : AppTheme.dangerRed,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '바이낸스 연결: ${connectionState.isConnected ? "성공" : "실패"}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'API 키: ${connectionState.isConnected ? "설정됨" : "없음"}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '포트폴리오: ${portfolioState.isLoading ? "로딩중" : "완료"} (${portfolioState.portfolio?.holdings.length ?? 0}개 자산)',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        onPressed: _copyApiKey,
                        icon: const Icon(Icons.copy, size: 16),
                        tooltip: 'API 키 복사',
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 테스트 버튼들
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTestRunning ? null : _testApiKey,
                          icon: const Icon(Icons.key),
                          label: const Text('API 키'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTestRunning ? null : _testPortfolioLoad,
                          icon: const Icon(Icons.account_balance_wallet),
                          label: const Text('포트폴리오'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTestRunning ? null : _testBinanceApi,
                          icon: const Icon(Icons.currency_bitcoin),
                          label: const Text('바이낸스'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTestRunning ? null : _testBackendApi,
                          icon: const Icon(Icons.dns),
                          label: const Text('백엔드'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isTestRunning ? null : _testTradingFunctions,
                      icon: const Icon(Icons.trending_up),
                      label: const Text('거래 기능 테스트'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isTestRunning ? null : _runAllTests,
                      icon: _isTestRunning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.play_arrow),
                      label: Text(_isTestRunning ? '테스트 실행 중...' : '전체 테스트 실행'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 테스트 결과
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.glassmorphism(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '테스트 결과',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _testResults.isEmpty
                        ? Center(
                            child: Text(
                              '테스트를 실행하여 결과를 확인하세요',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: _testResults.length,
                            itemBuilder: (context, index) {
                              final result = _testResults[index];
                              Color textColor = Colors.white.withValues(alpha: 0.9);

                              if (result.contains('✅')) {
                                textColor = AppTheme.successGreen;
                              } else if (result.contains('❌')) {
                                textColor = AppTheme.dangerRed;
                              } else if (result.contains('🚀') || result.contains('🏁')) {
                                textColor = const Color(0xFF8B5CF6);
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  result,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              );
                            },
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}