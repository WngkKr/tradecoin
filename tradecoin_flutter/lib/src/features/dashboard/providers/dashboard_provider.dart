import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/dashboard_screen.dart';

// 대시보드 데이터 Provider
final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  // 시뮬레이션된 데이터 (실제로는 API 호출)
  await Future.delayed(const Duration(seconds: 1));
  
  return DashboardData(
    portfolioBalance: 12543.21,
    todayPnL: 234.12,
    todayPnLPercent: 1.9,
    marketOverview: const MarketOverviewData(
      btcPrice: 67234.56,
      btcChange: 2.5,
      ethPrice: 3456.78,
      ethChange: -1.2,
      marketStatus: 'open',
    ),
    recentActivities: [
      ActivityItem(
        id: '1',
        type: 'buy',
        coinSymbol: 'BTC',
        amount: 0.5,
        price: 67000.0,
        timestamp: DateTime.parse('2024-03-15T10:30:00Z'),
        status: 'completed',
      ),
      ActivityItem(
        id: '2',
        type: 'sell',
        coinSymbol: 'ETH',
        amount: 2.0,
        price: 3400.0,
        timestamp: DateTime.parse('2024-03-15T09:15:00Z'),
        status: 'completed',
      ),
    ],
  );
});

