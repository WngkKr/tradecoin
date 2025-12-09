import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';

/// OHLC 캔들 데이터 모델
class CandleData {
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final DateTime timestamp;
  final int index;

  CandleData({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.timestamp,
    required this.index,
  });

  /// 상승 캔들인지 확인
  bool get isBullish => close >= open;

  /// 캔들 바디 높이
  double get bodyHeight => (close - open).abs();

  /// 위 꼬리 길이
  double get upperWickLength => high - (close > open ? close : open);

  /// 아래 꼬리 길이
  double get lowerWickLength => (close > open ? open : close) - low;

  factory CandleData.fromJson(Map<String, dynamic> json, int index) {
    return CandleData(
      open: (json['open'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      close: (json['close'] as num).toDouble(),
      volume: (json['volume'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      index: index,
    );
  }
}

/// 캔들스틱 차트 위젯
class CandlestickChart extends StatelessWidget {
  final List<CandleData> candles;
  final String symbol;
  final double? currentPrice;
  final bool showVolume;
  final bool showMovingAverage;
  final String Function(double)? priceFormatter;

  const CandlestickChart({
    super.key,
    required this.candles,
    required this.symbol,
    this.currentPrice,
    this.showVolume = true,
    this.showMovingAverage = true,
    this.priceFormatter,
  });

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty) {
      return const Center(
        child: Text(
          '차트 데이터가 없습니다',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }

    final minPrice = candles.map((c) => c.low).reduce((a, b) => a < b ? a : b) * 0.995;
    final maxPrice = candles.map((c) => c.high).reduce((a, b) => a > b ? a : b) * 1.005;
    final maxVolume = candles.map((c) => c.volume).reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        // 📊 차트 범례 (Chart Legend)
        if (showMovingAverage)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegendItem('MA7', const Color(0xFF06FFF5)),
                _buildLegendItem('MA21', const Color(0xFFB24BF3)),
                _buildLegendItem('BB(20,2)', const Color(0xFFFBBF24)),
              ],
            ),
          ),
        // 가격 차트 (캔들스틱 + 이동평균선)
        SizedBox(
          height: 250,
          child: Stack(
            children: [
              // 1. 캔들스틱 렌더링 (CustomPainter) - 왼쪽 여백 추가
              Positioned(
                left: 60, // Y축 라벨 영역만큼 왼쪽 여백
                right: 0,
                top: 0,
                bottom: 0,
                child: CustomPaint(
                  painter: CandlestickPainter(
                    candles: candles,
                    minPrice: minPrice,
                    maxPrice: maxPrice,
                  ),
                  size: Size.infinite,
                ),
              ),
              // 2. 이동평균선 + 그리드 (LineChart)
              LineChart(
                LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                verticalInterval: candles.length > 10 ? 4 : 2,
                horizontalInterval: (maxPrice - minPrice) / 5,
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
                    interval: candles.length > 10 ? 4 : 2,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= candles.length) {
                        return const SizedBox();
                      }
                      if (candles.length > 10 && index % 4 != 0) {
                        return const SizedBox();
                      }
                      final candle = candles[index];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${candle.timestamp.hour}:${candle.timestamp.minute.toString().padLeft(2, '0')}',
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
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    interval: (maxPrice - minPrice) / 5,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          priceFormatter?.call(value) ?? _formatPrice(value),
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
              maxX: (candles.length - 1).toDouble(),
              minY: minPrice,
              maxY: maxPrice,
              // 현재가 표시선
              extraLinesData: currentPrice != null
                  ? ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: currentPrice!,
                          color: Colors.orange.withOpacity(0.8),
                          strokeWidth: 1.5,
                          dashArray: [8, 4],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.only(right: 4, top: 4),
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            labelResolver: (line) => '현재가',
                          ),
                        ),
                      ],
                    )
                  : null,
              // 캔들스틱 데이터
              lineBarsData: [
                // 🔵 단기 이동평균선 (7개 캔들 MA) - 밝은 시안색
                if (showMovingAverage && candles.length >= 7)
                  LineChartBarData(
                    spots: _calculateMovingAverage(candles, 7),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF06FFF5).withOpacity(0.9),
                        const Color(0xFF00D9FF).withOpacity(0.8),
                      ],
                    ),
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF06FFF5).withOpacity(0.15),
                          const Color(0xFF06FFF5).withOpacity(0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    shadow: const Shadow(
                      color: Color(0xFF06FFF5),
                      blurRadius: 8,
                    ),
                  ),
                // 🟣 장기 이동평균선 (21개 캔들 MA) - 생동감있는 보라색
                if (showMovingAverage && candles.length >= 21)
                  LineChartBarData(
                    spots: _calculateMovingAverage(candles, 21),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFB24BF3).withOpacity(0.9),
                        const Color(0xFF8B5CF6).withOpacity(0.8),
                      ],
                    ),
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFB24BF3).withOpacity(0.12),
                          const Color(0xFFB24BF3).withOpacity(0.03),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    shadow: const Shadow(
                      color: Color(0xFFB24BF3),
                      blurRadius: 6,
                    ),
                  ),
                // 🟡 볼린저 밴드 상단 - 골든색
                if (showMovingAverage && candles.length >= 20)
                  LineChartBarData(
                    spots: _calculateBollingerBand(candles, 20, 2, true),
                    isCurved: true,
                    color: const Color(0xFFFBBF24).withOpacity(0.6),
                    barWidth: 1.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    dashArray: [8, 4],
                    belowBarData: BarAreaData(show: false),
                  ),
                // 🟡 볼린저 밴드 하단 - 골든색
                if (showMovingAverage && candles.length >= 20)
                  LineChartBarData(
                    spots: _calculateBollingerBand(candles, 20, 2, false),
                    isCurved: true,
                    color: const Color(0xFFFBBF24).withOpacity(0.6),
                    barWidth: 1.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    dashArray: [8, 4],
                    belowBarData: BarAreaData(show: false),
                  ),
              ],
              // 캔들스틱은 CustomPainter로 별도 렌더링
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: const Color(0xFF1E1B4B),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      if (index < 0 || index >= candles.length) {
                        return null;
                      }
                      final candle = candles[index];
                      return LineTooltipItem(
                        'O: ${_formatPrice(candle.open)}\n'
                        'H: ${_formatPrice(candle.high)}\n'
                        'L: ${_formatPrice(candle.low)}\n'
                        'C: ${_formatPrice(candle.close)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
              ),
            ],
          ),
        ),

        // 거래량 차트
        if (showVolume) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVolume * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatVolume(value),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxVolume / 3,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
                    left: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                ),
                barGroups: candles.map((candle) {
                  return BarChartGroupData(
                    x: candle.index,
                    barRods: [
                      BarChartRodData(
                        toY: candle.volume,
                        color: (candle.isBullish
                                ? AppTheme.successGreen
                                : AppTheme.dangerRed)
                            .withOpacity(0.6),
                        width: 3,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '거래량',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  /// 이동평균선 계산
  List<FlSpot> _calculateMovingAverage(List<CandleData> candles, int period) {
    if (candles.length < period) return [];

    List<FlSpot> maSpots = [];
    for (int i = period - 1; i < candles.length; i++) {
      double sum = 0;
      for (int j = 0; j < period; j++) {
        sum += candles[i - j].close;
      }
      double average = sum / period;
      maSpots.add(FlSpot(i.toDouble(), average));
    }
    return maSpots;
  }

  /// 볼린저 밴드 계산
  List<FlSpot> _calculateBollingerBand(List<CandleData> candles, int period, double standardDeviation, bool isUpper) {
    if (candles.length < period) return [];

    List<FlSpot> bandSpots = [];
    for (int i = period - 1; i < candles.length; i++) {
      // 이동평균 계산
      double sum = 0;
      for (int j = 0; j < period; j++) {
        sum += candles[i - j].close;
      }
      double average = sum / period;

      // 표준편차 계산
      double variance = 0;
      for (int j = 0; j < period; j++) {
        variance += (candles[i - j].close - average) * (candles[i - j].close - average);
      }
      double stdDev = (variance / period).isFinite ? (variance / period).abs().clamp(0, double.infinity).toDouble() : 0;
      stdDev = stdDev > 0 ? stdDev : 0.0;

      // 제곱근 계산
      if (stdDev > 0) {
        double temp = stdDev;
        for (int k = 0; k < 10; k++) {
          temp = (temp + stdDev / temp) / 2;
        }
        stdDev = temp;
      }

      // 볼린저 밴드 = MA ± (표준편차 * 배수)
      double band = isUpper
          ? average + (stdDev * standardDeviation)
          : average - (stdDev * standardDeviation);

      bandSpots.add(FlSpot(i.toDouble(), band));
    }
    return bandSpots;
  }

  /// 가격 포맷팅
  String _formatPrice(double price) {
    if (price >= 1000) {
      return '\$${(price / 1000).toStringAsFixed(1)}K';
    } else if (price >= 1) {
      return '\$${price.toStringAsFixed(0)}';
    } else if (price >= 0.01) {
      return '\$${price.toStringAsFixed(2)}';
    } else {
      return '\$${price.toStringAsFixed(4)}';
    }
  }

  /// 거래량 포맷팅
  String _formatVolume(double volume) {
    if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    } else {
      return volume.toStringAsFixed(0);
    }
  }

  /// 차트 범례 아이템 생성
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.6)],
            ),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// 실제 캔들 막대 렌더링 (커스텀 페인터)
class CandlestickPainter extends CustomPainter {
  final List<CandleData> candles;
  final double minPrice;
  final double maxPrice;
  final double candleWidth;

  CandlestickPainter({
    required this.candles,
    required this.minPrice,
    required this.maxPrice,
    this.candleWidth = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final priceRange = maxPrice - minPrice;
    final candleSpacing = size.width / candles.length;

    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final x = (i + 0.5) * candleSpacing;

      // 가격을 Y 좌표로 변환
      final highY = size.height * (1 - (candle.high - minPrice) / priceRange);
      final lowY = size.height * (1 - (candle.low - minPrice) / priceRange);
      final openY = size.height * (1 - (candle.open - minPrice) / priceRange);
      final closeY = size.height * (1 - (candle.close - minPrice) / priceRange);

      final color = candle.isBullish ? AppTheme.successGreen : AppTheme.dangerRed;

      // 위/아래 꼬리 그리기
      final wickPaint = Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(x, highY), Offset(x, lowY), wickPaint);

      // 캔들 바디 그리기
      final bodyPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final bodyRect = Rect.fromLTRB(
        x - candleWidth / 2,
        openY < closeY ? openY : closeY,
        x + candleWidth / 2,
        openY > closeY ? openY : closeY,
      );

      canvas.drawRect(bodyRect, bodyPaint);

      // 바디 테두리 그리기
      final borderPaint = Paint()
        ..color = color.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawRect(bodyRect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CandlestickPainter oldDelegate) {
    return candles != oldDelegate.candles ||
        minPrice != oldDelegate.minPrice ||
        maxPrice != oldDelegate.maxPrice;
  }
}
