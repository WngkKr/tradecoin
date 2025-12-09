import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/exchange_rate_service.dart';
import '../../../shared/widgets/cyberpunk_header.dart';
import '../models/signal_model.dart';
import '../providers/signals_provider.dart';
import '../widgets/candlestick_chart.dart';

class SignalsScreen extends ConsumerStatefulWidget {
  const SignalsScreen({super.key});

  @override
  ConsumerState<SignalsScreen> createState() => _SignalsScreenState();
}

class _SignalsScreenState extends ConsumerState<SignalsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  Timer? _autoRefreshTimer;
  final _exchangeService = ExchangeRateService();
  String _selectedCoin = 'BTC'; // 선택된 코인
  List<FlSpot> _chartData = []; // 라인 차트 데이터
  List<CandleData> _candleData = []; // 캔들스틱 차트 데이터
  bool _isLoadingChart = false;
  bool _showCandlestick = true; // true: 캔들스틱, false: 라인 차트

  // 🧪 차트 업데이트 테스트 추적 변수
  final List<Map<String, dynamic>> _chartUpdateLog = [];
  int _totalChartUpdates = 0;
  String? _lastChartUpdateTime;
  bool _showDebugPanel = true; // 디버그 패널 표시 여부

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

    // 차트 데이터 로드
    _loadChartData();

    // 3분마다 자동 갱신
    _autoRefreshTimer = Timer.periodic(
      const Duration(minutes: 3),
      (timer) {
        if (mounted) {
          ref.read(signalsProvider.notifier).refreshActiveSignals();
          _loadChartData(); // 차트도 갱신
        }
      },
    );
  }

  // 실제 가격 히스토리 데이터 로드
  Future<void> _loadChartData() async {
    if (!mounted) return;

    // 🧪 차트 업데이트 로깅
    final updateTime = DateTime.now();
    setState(() {
      _isLoadingChart = true;
      _totalChartUpdates++;
      _lastChartUpdateTime = '${updateTime.hour.toString().padLeft(2, '0')}:${updateTime.minute.toString().padLeft(2, '0')}:${updateTime.second.toString().padLeft(2, '0')}';
    });

    // 로그 추가
    _chartUpdateLog.add({
      'coin': _selectedCoin,
      'time': updateTime,
      'updateNumber': _totalChartUpdates,
    });

    // 최대 10개까지만 유지
    if (_chartUpdateLog.length > 10) {
      _chartUpdateLog.removeAt(0);
    }

    try {
      print('🔄 [차트] 데이터 로딩 시작: $_selectedCoin (5분봉) [업데이트 #$_totalChartUpdates]');
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/price/history?symbol=$_selectedCoin&interval=5m&limit=24'),
      ).timeout(const Duration(seconds: 10));

      print('📡 [차트] 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 [차트] 받은 데이터: ${data.toString().substring(0, data.toString().length > 200 ? 200 : data.toString().length)}');

        // API 응답은 {"data": [...]} 형식
        final priceData = data['data'] as List;

        if (mounted) {
          setState(() {
            // 라인 차트 데이터 생성
            _chartData = priceData.asMap().entries.map((entry) {
              final price = entry.value['close'] as num;
              return FlSpot(entry.key.toDouble(), price.toDouble());
            }).toList();

            // 캔들스틱 차트 데이터 생성
            _candleData = priceData.asMap().entries.map((entry) {
              final index = entry.key;
              final candle = entry.value;

              // timestamp를 milliseconds로 변환 (epoch time)
              int timestampMs = candle['timestamp'] as int;
              DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(timestampMs);

              return CandleData(
                open: (candle['open'] as num?)?.toDouble() ?? (candle['close'] as num).toDouble(),
                high: (candle['high'] as num?)?.toDouble() ?? (candle['close'] as num).toDouble(),
                low: (candle['low'] as num?)?.toDouble() ?? (candle['close'] as num).toDouble(),
                close: (candle['close'] as num).toDouble(),
                volume: (candle['volume'] as num?)?.toDouble() ?? 0.0,
                timestamp: timestamp,
                index: index,
              );
            }).toList();

            _isLoadingChart = false;
            print('✅ [차트] 데이터 로드 완료: ${_chartData.length}개 포인트, ${_candleData.length}개 캔들');
          });
        }
      } else {
        print('❌ [차트] API 오류: ${response.statusCode} - ${response.body}');
        if (mounted) {
          setState(() {
            _isLoadingChart = false;
          });
        }
      }
    } catch (e) {
      print('❌ 차트 데이터 로드 실패: $e');
      if (mounted) {
        setState(() {
          _isLoadingChart = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _autoRefreshTimer?.cancel();
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI 신호 헤더
                _buildSignalsHeader(),
                const SizedBox(height: 16),

                // 코인 선택 및 차트
                _buildCoinChart(),
                const SizedBox(height: 24),

                // 실시간 신호들
                _buildActiveSignals(),
                const SizedBox(height: 24),
                
                // AI 추천
                _buildAIRecommendations(),
                const SizedBox(height: 24),
                
                // 신호 히스토리
                _buildSignalHistory(),
                const SizedBox(height: 24),

                // 🧪 차트 업데이트 디버그 패널
                if (_showDebugPanel) _buildChartDebugPanel(),

                const SizedBox(height: 100), // 하단 네비게이션 공간
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignalsHeader() {
    final signalStats = ref.watch(signalStatsProvider);
    final isLoading = ref.watch(signalsLoadingProvider);
    final lastUpdated = ref.watch(signalsProvider).lastUpdated;

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
                  const Icon(
                    Icons.trending_up,
                    color: AppTheme.accentBlue,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI 트레이딩 시그널',
                          style: AppTheme.headingMedium.copyWith(
                            color: AppTheme.accentBlue,
                          ),
                        ),
                        if (lastUpdated != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '마지막 업데이트: ${_formatLastUpdate(lastUpdated)}',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: Colors.grey[400],
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentBlue.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.accentBlue.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.autorenew,
                                        size: 10,
                                        color: AppTheme.accentBlue.withOpacity(0.8),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '5분 자동',
                                        style: AppTheme.bodySmall.copyWith(
                                          color: AppTheme.accentBlue.withOpacity(0.8),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
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
              Row(
                children: [
                  _buildStatCard(
                    '활성 신호',
                    signalStats?.activeSignals.toString() ?? '-',
                    AppTheme.accentBlue
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    '성공률',
                    signalStats != null ? '${signalStats.winRate.toStringAsFixed(1)}%' : '-',
                    AppTheme.successGreen
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    '수익률',
                    signalStats != null ? '${signalStats.avgProfit >= 0 ? '+' : ''}${signalStats.avgProfit.toStringAsFixed(1)}%' : '-',
                    signalStats != null && signalStats.avgProfit >= 0 ? AppTheme.primaryBlue : Colors.red
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x1A1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSignals() {
    final activeSignals = ref.watch(activeSignalsProvider);
    final isLoading = ref.watch(signalsLoadingProvider);

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '실시간 신호',
                              style: AppTheme.headingMedium.copyWith(
                                color: AppTheme.successGreen,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 활성 신호 개수 표시
                            if (activeSignals.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.successGreen.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.successGreen.withOpacity(0.4)),
                                ),
                                child: Text(
                                  '${activeSignals.length}개',
                                  style: const TextStyle(
                                    color: AppTheme.successGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // 코인별 신호 요약 표시
                        if (activeSignals.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: _getUniqueCoinSignals(activeSignals).take(5).map((coin) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0x1A10B981),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.successGreen.withOpacity(0.3)),
                                ),
                                child: Text(
                                  coin,
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          )
                        else
                          Text(
                            DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppTheme.successGreen, size: 20),
                    onPressed: () {
                      ref.read(signalsProvider.notifier).refreshActiveSignals();
                      // 수동 갱신 표시
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('시그널 갱신 중...'),
                          duration: Duration(seconds: 1),
                          backgroundColor: AppTheme.successGreen,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (isLoading)
                _buildLoadingBox()
              else if (activeSignals.isEmpty)
                _buildEmptySignalsState()
              else
                ...activeSignals.take(4).map((signal) => _buildSignalItemFromModel(signal)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignalItem(String pair, String signal, String strength, String price, String change, bool isPositive, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1A1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
            child: Icon(
              signal == '매수' ? Icons.trending_up : 
              signal == '매도' ? Icons.trending_down : Icons.remove,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pair,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '$signal • $strength',
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
                price,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              Text(
                change,
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

  Widget _buildAIRecommendations() {
    final marketAnalysis = ref.watch(marketAnalysisProvider);
    final recommendedSignals = ref.watch(recommendedSignalsProvider);

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
                  const Icon(
                    Icons.psychology,
                    color: AppTheme.primaryBlue,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI 분석 및 추천',
                    style: AppTheme.headingMedium.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (marketAnalysis != null) ...[
                _buildRecommendationCard(
                  '시장 동향',
                  '현재 시장은 ${_getMarketTrendKorean(marketAnalysis['marketTrend'] ?? 'neutral')} 상태입니다. ${_getMarketPhaseKorean(marketAnalysis['marketPhase'] ?? 'neutral')} 단계로 분석됩니다.',
                  Icons.analytics,
                  AppTheme.accentBlue,
                ),
                if ((marketAnalysis['recommendedActions'] as List?)?.isNotEmpty == true)
                  _buildRecommendationCard(
                    '추천 행동',
                    (marketAnalysis['recommendedActions'] as List).first,
                    Icons.lightbulb,
                    AppTheme.successGreen,
                  ),
                if ((marketAnalysis['riskFactors'] as List?)?.isNotEmpty == true)
                  _buildRecommendationCard(
                    '위험 요소',
                    (marketAnalysis['riskFactors'] as List).first,
                    Icons.warning,
                    AppTheme.neutralGray,
                  ),
              ] else ...[
                _buildRecommendationCard(
                  '시장 분석',
                  '시장 데이터를 분석 중입니다. 잠시 후 다시 확인해 주세요.',
                  Icons.analytics,
                  AppTheme.accentBlue,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1A1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: AppTheme.bodySmall.copyWith(
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalHistory() {
    final signalHistory = ref.watch(signalHistoryProvider);

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
                  Text(
                    '신호 히스토리',
                    style: AppTheme.headingMedium.copyWith(
                      color: AppTheme.dangerRed,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.history, color: AppTheme.dangerRed, size: 20),
                    onPressed: () => ref.read(signalsProvider.notifier).refreshSignalHistory(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (signalHistory.isEmpty)
                const Center(
                  child: Text(
                    '히스토리가 없습니다',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...signalHistory.take(4).map((history) => _buildHistoryItemFromModel(history)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String pair, String signal, String result, String price, String profit, String date, bool isSuccess) {
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
            isSuccess ? Icons.check_circle : Icons.cancel,
            color: isSuccess ? AppTheme.accentBlue : Colors.red,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$signal $pair',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  result,
                  style: TextStyle(
                    color: isSuccess ? AppTheme.accentBlue : Colors.red,
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
                profit,
                style: TextStyle(
                  color: isSuccess ? AppTheme.accentBlue : Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                date,
                style: AppTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBox() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0x1A8B5CF6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '실시간 시그널 분석 중...',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x0AFFFFFF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLoadingStep('인플루언서 트윗 수집', true),
                _buildLoadingStep('감정 분석 진행', true),
                _buildLoadingStep('기술적 지표 계산', true),
                _buildLoadingStep('AI 시그널 생성', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStep(String text, bool isComplete) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.hourglass_empty,
            color: isComplete ? AppTheme.successGreen : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isComplete ? Colors.white70 : Colors.grey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySignalsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.signal_cellular_off,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            '활성 신호가 없습니다',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '새로운 신호가 생성되면 알림을 받게 됩니다',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 마지막 업데이트 시간 포맷
  String _formatLastUpdate(DateTime lastUpdated) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else {
      return '${difference.inDays}일 전';
    }
  }

  Widget _buildSignalItemFromModel(SignalModel signal) {
    final color = _getSignalColor(signal.signalType, signal.strength);
    final isPositive = signal.priceChangePercent >= 0;

    // 고신뢰도 시그널 확인 (85% 이상)
    final isHighConfidence = signal.confidenceScore >= 0.85;

    // 소셜 시그널인지 확인 (metadata에 source가 있으면)
    final isSocialSignal = signal.metadata?['source'] == 'social_media';
    final influencer = signal.metadata?['influencer'] as String?;
    final keyFactors = signal.sentimentAnalysis?.keyFactors ?? [];

    // 시간 계산
    final now = DateTime.now();
    final signalTime = signal.timestamp;
    final timeDiff = now.difference(signalTime);
    final minutesAgo = timeDiff.inMinutes;

    // 🔍 타임스탬프 디버그 로그
    print('🔍 [시간 디버그] ${signal.pair}');
    print('   현재 시간: $now');
    print('   시그널 시간: $signalTime');
    print('   시간 차이: ${timeDiff.inMinutes}분 (${timeDiff.inHours}시간)');

    // 음수 시간 차이 처리 (미래 시간인 경우 절대값 사용)
    final absoluteMinutes = minutesAgo.abs();

    final timeAgoText = absoluteMinutes < 1
        ? '방금 전'
        : absoluteMinutes < 60
            ? '$absoluteMinutes분 전'
            : '${timeDiff.inHours.abs()}시간 전';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // 고신뢰도 시그널은 어두운 그라디언트 배경
        gradient: isHighConfidence
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0x40334155), // 다크 슬레이트
                  Color(0x40475569), // 더 진한 슬레이트
                ],
              )
            : null,
        color: !isHighConfidence ? const Color(0x1A1E293B) : null,
        borderRadius: BorderRadius.circular(12),
        // 고신뢰도 시그널은 은은한 화이트 테두리
        border: Border.all(
          color: isHighConfidence
              ? Colors.white.withValues(alpha: 0.3)
              : color.withOpacity(0.3),
          width: isHighConfidence ? 2 : 1,
        ),
        // 고신뢰도 시그널에 은은한 글로우 효과
        boxShadow: isHighConfidence ? [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 아이콘 제거 - 공간 확보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // 코인 심볼 강조 표시
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6B46C1), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withOpacity(0.3),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.currency_bitcoin,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                signal.symbol,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 고신뢰도 시그널 "⭐ HIGH" 배지 (85% 이상)
                        if (isHighConfidence)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              '⭐ HIGH',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (isHighConfidence) const SizedBox(width: 4),
                        // 신뢰도 배지
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isHighConfidence
                                ? Colors.white.withValues(alpha: 0.15)
                                : color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: isHighConfidence
                                ? Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1)
                                : null,
                          ),
                          child: Text(
                            '${(signal.confidenceScore * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: isHighConfidence ? Colors.white : color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          '${signal.signalTypeKorean} • ${signal.strengthKorean}',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 10,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                timeAgoText,
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _exchangeService.formatCurrency(
                      _exchangeService.convertFromUSD(signal.currentPrice, 'KRW'),
                      'KRW'
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    signal.priceChangeFormatted,
                    style: TextStyle(
                      color: isPositive ? AppTheme.accentBlue : Colors.red,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 소셜 시그널 근거 표시
          if (isSocialSignal && keyFactors.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x00000000), // 투명 배경
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 인플루언서 및 트윗 시간
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        influencer != null ? '@$influencer' : '인플루언서',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        timeAgoText,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      // 실시간 표시
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          '실시간',
                          style: TextStyle(
                            color: AppTheme.successGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 트윗 내용 전체 표시 (한/영 번역)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0x0A000000),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.format_quote,
                              size: 12,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '최신 트윗 내용',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // 한국어 번역문 (크게 표시)
                        if (signal.sentimentAnalysis?.tweetTextKo != null) ...[
                          Text(
                            signal.sentimentAnalysis!.tweetTextKo!,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 원문 (작게 표시)
                          if (signal.sentimentAnalysis?.tweetTextEn != null)
                            Text(
                              signal.sentimentAnalysis!.tweetTextEn!,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 11,
                                height: 1.5,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ] else ...[
                          // 번역 데이터가 없으면 기존 방식 사용
                          Text(
                            keyFactors.isNotEmpty ? keyFactors.first : '트윗 내용 없음',
                            style: TextStyle(
                              color: Colors.grey[200],
                              fontSize: 12,
                              height: 1.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 고신뢰도 근거 (85% 이상일 경우에만 표시)
                  if (isHighConfidence)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.verified,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                '⭐ HIGH 시그널 근거 (85% 이상)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // 근거 항목들
                          _buildEvidenceItem('인플루언서 영향력', '높음', Colors.white),
                          _buildEvidenceItem('키워드 매칭', '강함', Colors.white),
                          _buildEvidenceItem('감정 분석 점수', '${(signal.confidenceScore * 100).toStringAsFixed(0)}%', Colors.white),
                        ],
                      ),
                    ),

                  const SizedBox(height: 8),
                  // 과거 성과 데이터
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0x1A10B981),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.successGreen.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.history,
                          size: 12,
                          color: AppTheme.successGreen,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '과거 이 시그널 후 평균: +${_getHistoricalPerformance(signal.symbol, influencer, signal)}% (15분 내)',
                            style: const TextStyle(
                              color: AppTheme.successGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getSignalColor(String signalType, String strength) {
    switch (signalType) {
      case 'buy':
        return strength == 'strong' ? AppTheme.accentBlue : AppTheme.primaryBlue;
      case 'sell':
        return strength == 'strong' ? AppTheme.dangerRed : Colors.red[400]!;
      case 'hold':
        return AppTheme.neutralGray;
      default:
        return AppTheme.neutralGray;
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

  String _getMarketTrendKorean(String trend) {
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

  String _getMarketPhaseKorean(String phase) {
    switch (phase) {
      case 'accumulation':
        return '축적';
      case 'markup':
        return '상승';
      case 'distribution':
        return '분산';
      case 'markdown':
        return '하락';
      default:
        return '중립';
    }
  }

  // USD 가격 포맷
  String _formatUSDPrice(double usdPrice) {
    if (usdPrice >= 1000) {
      return '\$${(usdPrice / 1000).toStringAsFixed(1)}K';
    } else if (usdPrice >= 1) {
      return '\$${usdPrice.toStringAsFixed(0)}';
    } else {
      return '\$${usdPrice.toStringAsFixed(4)}';
    }
  }

  // 이동평균 계산 함수
  List<FlSpot> _calculateMovingAverage(List<FlSpot> spots, int period) {
    if (spots.isEmpty || spots.length < period) return [];

    List<FlSpot> maSpots = [];
    for (int i = period - 1; i < spots.length; i++) {
      double sum = 0;
      for (int j = 0; j < period; j++) {
        sum += spots[i - j].y;
      }
      double average = sum / period;
      maSpots.add(FlSpot(spots[i].x, average));
    }
    return maSpots;
  }

  // 차트 범례 위젯
  Widget _buildChartLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 2,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // 고유 코인 목록 추출
  List<String> _getUniqueCoinSignals(List<SignalModel> signals) {
    final uniqueCoins = <String>{};
    for (final signal in signals) {
      uniqueCoins.add(signal.symbol);
    }
    return uniqueCoins.toList();
  }

  // 과거 성과 데이터 가져오기 (API에서 제공하는 실제 데이터 사용)
  String _getHistoricalPerformance(String symbol, String? influencer, SignalModel signal) {
    // API에서 받은 historicalPerformance 필드 사용 (실제 15분 가격 변동 추적 데이터)
    final historicalPerformance = signal.metadata?['historicalPerformance'];

    if (historicalPerformance != null) {
      if (historicalPerformance is double) {
        return historicalPerformance.toStringAsFixed(1);
      } else if (historicalPerformance is int) {
        return historicalPerformance.toDouble().toStringAsFixed(1);
      } else if (historicalPerformance is String) {
        try {
          return double.parse(historicalPerformance).toStringAsFixed(1);
        } catch (e) {
          // 파싱 실패 시 기본값
        }
      }
    }

    // API에서 데이터가 없으면 기본값 (데이터 수집 중)
    return '5.0';
  }

  Widget _buildHistoryItemFromModel(SignalHistoryModel history) {
    final isSuccess = history.result == 'win';
    final dateFormatter = DateFormat('MM-dd');

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
            isSuccess ? Icons.check_circle : Icons.cancel,
            color: isSuccess ? AppTheme.accentBlue : Colors.red,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${history.signalType == 'buy' ? '매수' : history.signalType == 'sell' ? '매도' : '보유'} ${history.pair}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  history.resultKorean,
                  style: TextStyle(
                    color: isSuccess ? AppTheme.accentBlue : Colors.red,
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
                '${history.profitLossPercent >= 0 ? '+' : ''}${history.profitLossPercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: isSuccess ? AppTheme.accentBlue : Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                dateFormatter.format(history.entryTime),
                style: AppTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 코인 선택 및 차트 위젯
  Widget _buildCoinChart() {
    final coins = ['BTC', 'ETH', 'DOGE', 'TRUMP', 'MAGA', 'SHIB', 'FLOKI'];
    final activeSignals = ref.watch(activeSignalsProvider);

    // 선택된 코인의 실제 가격 데이터 가져오기
    SignalModel? selectedSignal;
    try {
      selectedSignal = activeSignals.firstWhere(
        (signal) => signal.symbol == _selectedCoin,
      );
    } catch (e) {
      if (activeSignals.isNotEmpty) {
        selectedSignal = activeSignals.first;
      }
    }

    // 실제 API에서 가져온 가격 히스토리 데이터 사용
    List<FlSpot> spots = _chartData.isNotEmpty ? _chartData : [];

    return Container(
      padding: const EdgeInsets.all(20),
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
                  const Icon(
                    Icons.show_chart,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '가격 차트',
                    style: AppTheme.headingMedium.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // 코인 선택 드롭다운 (작게)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6B46C1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: DropdownButton<String>(
                      value: _selectedCoin,
                      underline: const SizedBox(),
                      dropdownColor: const Color(0xFF1E1B4B),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
                      isDense: true,
                      items: coins.map((coin) {
                        return DropdownMenuItem(
                          value: coin,
                          child: Text(coin),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCoin = value;
                          });
                          _loadChartData(); // 코인 변경 시 차트 데이터 다시 로드
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 현재 가격 및 변동 표시
              if (selectedSignal != null) ...[
                Row(
                  children: [
                    Text(
                      _exchangeService.formatCurrency(
                        _exchangeService.convertFromUSD(selectedSignal.currentPrice, 'KRW'),
                        'KRW'
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: selectedSignal.priceChangePercent >= 0
                            ? AppTheme.successGreen.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        selectedSignal.priceChangeFormatted,
                        style: TextStyle(
                          color: selectedSignal.priceChangePercent >= 0
                              ? AppTheme.successGreen
                              : Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              // 차트 유형 토글 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildChartTypeButton('캔들', _showCandlestick, () {
                    setState(() {
                      _showCandlestick = true;
                    });
                  }),
                  const SizedBox(width: 8),
                  _buildChartTypeButton('라인', !_showCandlestick, () {
                    setState(() {
                      _showCandlestick = false;
                    });
                  }),
                ],
              ),
              const SizedBox(height: 16),
              // 차트
              SizedBox(
                height: 250,
                child: _showCandlestick && _candleData.isNotEmpty
                    ? CandlestickChart(
                        candles: _candleData,
                        symbol: _selectedCoin,
                        currentPrice: selectedSignal?.currentPrice,
                        showVolume: false, // 공간 절약을 위해 거래량 숨김
                        showMovingAverage: true,
                        priceFormatter: _formatUSDPrice,
                      )
                    : !_showCandlestick && spots.isNotEmpty
                    ? LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            verticalInterval: 4,
                            horizontalInterval: (spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) -
                                    spots.map((e) => e.y).reduce((a, b) => a < b ? a : b)) /
                                5,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.white.withOpacity(0.1),
                                strokeWidth: 1,
                                dashArray: [5, 5],
                              );
                            },
                            getDrawingVerticalLine: (value) {
                              return FlLine(
                                color: Colors.white.withOpacity(0.05),
                                strokeWidth: 1,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 4,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() % 4 != 0) return const SizedBox();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      '${value.toInt()}h',
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 60,
                                interval: (spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) -
                                        spots.map((e) => e.y).reduce((a, b) => a < b ? a : b)) /
                                    5,
                                getTitlesWidget: (value, meta) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      _formatUSDPrice(value),
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              bottom: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
                              left: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
                            ),
                          ),
                          minX: 0,
                          maxX: 23,
                          minY: spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) * 0.995,
                          maxY: spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.005,
                          // 현재 시점 표시선 (세로선)
                          extraLinesData: ExtraLinesData(
                            verticalLines: [
                              VerticalLine(
                                x: 23, // 가장 오른쪽 = 현재 시점
                                color: Colors.orange.withOpacity(0.8),
                                strokeWidth: 2,
                                dashArray: [8, 4],
                                label: VerticalLineLabel(
                                  show: true,
                                  alignment: Alignment.topRight,
                                  padding: const EdgeInsets.only(right: 4, top: 4),
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  labelResolver: (line) => '현재',
                                ),
                              ),
                            ],
                          ),
                          lineBarsData: [
                            // 실제 가격 라인
                            LineChartBarData(
                              spots: spots,
                              isCurved: false,
                              gradient: LinearGradient(
                                colors: selectedSignal != null && selectedSignal.priceChangePercent >= 0
                                    ? [AppTheme.successGreen, AppTheme.accentBlue]
                                    : [Colors.red, Colors.orange],
                              ),
                              barWidth: 2.5,
                              isStrokeCapRound: false,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 2,
                                    color: Colors.white,
                                    strokeWidth: 1,
                                    strokeColor: selectedSignal != null && selectedSignal.priceChangePercent >= 0
                                        ? AppTheme.successGreen
                                        : Colors.red,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: selectedSignal != null && selectedSignal.priceChangePercent >= 0
                                      ? [
                                          AppTheme.successGreen.withOpacity(0.3),
                                          AppTheme.successGreen.withOpacity(0.1),
                                          AppTheme.successGreen.withOpacity(0.0),
                                        ]
                                      : [
                                          Colors.red.withOpacity(0.3),
                                          Colors.red.withOpacity(0.1),
                                          Colors.red.withOpacity(0.0),
                                        ],
                                ),
                              ),
                            ),
                            // 이동평균선 (7시간 MA) - 짧은 평균
                            LineChartBarData(
                              spots: _calculateMovingAverage(spots, 7),
                              isCurved: true,
                              color: Colors.yellow.withOpacity(0.8),
                              barWidth: 1.5,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(show: false),
                            ),
                            // 이동평균선 (14시간 MA) - 중간 평균
                            LineChartBarData(
                              spots: _calculateMovingAverage(spots, 14),
                              isCurved: true,
                              color: Colors.purple.withOpacity(0.7),
                              barWidth: 1.5,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(show: false),
                            ),
                          ],
                          lineTouchData: LineTouchData(
                            enabled: true,
                            touchTooltipData: LineTouchTooltipData(
                              tooltipBgColor: const Color(0xFF1E1B4B),
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  return LineTooltipItem(
                                    '${spot.x.toInt()}h\n${_formatUSDPrice(spot.y)}',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                        ),
                      )
                    : const Center(
                        child: Text(
                          '차트 데이터 로딩 중...',
                          style: TextStyle(color: Colors.white60),
                        ),
                      ),
              ),
              // 평균선 설명
              if (spots.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildChartLegend('현재가', selectedSignal != null && selectedSignal.priceChangePercent >= 0 ? AppTheme.successGreen : Colors.red),
                    const SizedBox(width: 16),
                    _buildChartLegend('MA7', Colors.yellow.withOpacity(0.8)),
                    const SizedBox(width: 16),
                    _buildChartLegend('MA14', Colors.purple.withOpacity(0.7)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 근거 항목 위젯 (고신뢰도 시그널 근거 표시용)
  Widget _buildEvidenceItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 10,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // 차트 유형 토글 버튼
  Widget _buildChartTypeButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF6B46C1), Color(0xFF8B5CF6)],
                )
              : null,
          color: isActive ? null : const Color(0x1A1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? AppTheme.primaryBlue.withOpacity(0.5)
                : const Color(0x331E293B),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white60,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // 🧪 차트 업데이트 디버그 패널
  Widget _buildChartDebugPanel() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E293B).withOpacity(0.9),
            const Color(0xFF0F172A).withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFBBF24).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFBBF24).withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFBBF24).withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bug_report,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '🧪 차트 업데이트 무한 체크',
                style: TextStyle(
                  color: Color(0xFFFBBF24),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              // 패널 닫기 버튼
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                onPressed: () {
                  setState(() => _showDebugPanel = false);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 통계 그리드
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildDebugStat(
                    '총 업데이트',
                    '$_totalChartUpdates회',
                    Icons.refresh,
                    const Color(0xFF06FFF5),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.2),
                ),
                Expanded(
                  child: _buildDebugStat(
                    '현재 코인',
                    _selectedCoin,
                    Icons.currency_bitcoin,
                    const Color(0xFFB24BF3),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.2),
                ),
                Expanded(
                  child: _buildDebugStat(
                    '마지막 업데이트',
                    _lastChartUpdateTime ?? '-',
                    Icons.access_time,
                    const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 업데이트 로그
          if (_chartUpdateLog.isNotEmpty) ...[
            const Text(
              '📋 최근 업데이트 로그',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 120,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: ListView.builder(
                reverse: true, // 최신 항목이 아래로
                itemCount: _chartUpdateLog.length,
                itemBuilder: (context, index) {
                  final log = _chartUpdateLog[_chartUpdateLog.length - 1 - index];
                  final time = log['time'] as DateTime;
                  final coin = log['coin'] as String;
                  final updateNum = log['updateNumber'] as int;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        // 업데이트 번호
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF06FFF5).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFF06FFF5).withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '#$updateNum',
                            style: const TextStyle(
                              color: Color(0xFF06FFF5),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 코인 심볼
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFB24BF3), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            coin,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 시간
                        Text(
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Spacer(),
                        // 상태 표시
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.6),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  '📭 아직 업데이트 기록이 없습니다',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 디버그 통계 위젯
  Widget _buildDebugStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}