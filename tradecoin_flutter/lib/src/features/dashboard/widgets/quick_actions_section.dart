import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../trading/widgets/trading_dialog.dart';
import '../../trading/widgets/leverage_trading_dialog.dart';
import '../../portfolio/providers/portfolio_provider.dart';

class QuickActionsSection extends ConsumerWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '빠른 액션',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.trending_up,
                label: '매수',
                color: AppTheme.successGreen,
                onPressed: () => _showCoinSelectionDialog(context, ref, 'buy'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.trending_down,
                label: '매도',
                color: AppTheme.dangerRed,
                onPressed: () => _showCoinSelectionDialog(context, ref, 'sell'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ActionButton(
          icon: Icons.rocket_launch,
          label: '레버리지 거래',
          color: AppTheme.accentBlue,
          onPressed: () => _showLeverageTradingDialog(context, ref),
        ),
      ],
    );
  }

  void _showCoinSelectionDialog(BuildContext context, WidgetRef ref, String tradeType) {
    if (tradeType == 'sell') {
      // 매도: 보유 코인 목록 표시
      _showHoldingsDialog(context, ref);
    } else {
      // 매수: 전체 시장 코인 표시
      final marketData = ref.read(marketDataProvider);

      marketData.when(
        data: (data) {
          showDialog(
            context: context,
            builder: (context) => _CoinSelectionDialog(
              coins: data.data,
              tradeType: tradeType,
            ),
          );
        },
        loading: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('시장 데이터를 불러오는 중입니다...')),
          );
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류: $error')),
          );
        },
      );
    }
  }

  void _showHoldingsDialog(BuildContext context, WidgetRef ref) {
    // 포트폴리오에서 보유 코인 가져오기
    showDialog(
      context: context,
      builder: (context) => const _HoldingsSelectionDialog(),
    );
  }

  void _showLeverageTradingDialog(BuildContext context, WidgetRef ref) {
    // 레버리지 거래: 롱/숏 선택 후 코인 선택
    showDialog(
      context: context,
      builder: (context) => const _LeverageTypeDialog(),
    );
  }
}

// 레버리지 거래 타입 선택 다이얼로그 (롱/숏)
class _LeverageTypeDialog extends ConsumerWidget {
  const _LeverageTypeDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B4B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.rocket_launch,
                  color: AppTheme.accentBlue,
                ),
                const SizedBox(width: 12),
                const Text(
                  '레버리지 거래',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '거래 방향을 선택하세요',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            // 롱 포지션 버튼
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                _showLeverageCoinSelection(context, ref, 'long');
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.successGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_upward,
                      color: AppTheme.successGreen,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '롱 (Long)',
                            style: TextStyle(
                              color: AppTheme.successGreen,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '가격 상승에 베팅',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppTheme.successGreen.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 숏 포지션 버튼
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                _showLeverageCoinSelection(context, ref, 'short');
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.dangerRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_downward,
                      color: AppTheme.dangerRed,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '숏 (Short)',
                            style: TextStyle(
                              color: AppTheme.dangerRed,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '가격 하락에 베팅',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppTheme.dangerRed.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.warningOrange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: AppTheme.warningOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '레버리지 거래는 높은 위험을 수반합니다',
                      style: TextStyle(
                        color: AppTheme.warningOrange.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLeverageCoinSelection(BuildContext context, WidgetRef ref, String leverageType) {
    final marketData = ref.read(marketDataProvider);

    marketData.when(
      data: (data) {
        showDialog(
          context: context,
          builder: (context) => _CoinSelectionDialog(
            coins: data.data,
            tradeType: leverageType, // 'long' or 'short'
          ),
        );
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('시장 데이터를 불러오는 중입니다...')),
        );
      },
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $error')),
        );
      },
    );
  }
}

// 보유 코인 선택 다이얼로그
class _HoldingsSelectionDialog extends ConsumerWidget {
  const _HoldingsSelectionDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdings = ref.watch(holdingsProvider);
    final isLoading = ref.watch(portfolioLoadingProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B4B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    color: AppTheme.dangerRed,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '매도할 코인 선택',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.accentBlue),
                ),
              )
            else if (holdings.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 48,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '보유한 코인이 없습니다',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '먼저 코인을 매수해주세요',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: holdings.length,
                  itemBuilder: (context, index) {
                    final holding = holdings[index];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.accentBlue.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            holding.symbol.substring(0, 1),
                            style: const TextStyle(
                              color: AppTheme.accentBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        holding.symbol,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '보유량: ${holding.quantity.toStringAsFixed(8)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${holding.value.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${holding.pnlPercent > 0 ? '+' : ''}${holding.pnlPercent.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: holding.pnlPercent >= 0
                                  ? AppTheme.successGreen
                                  : AppTheme.dangerRed,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        showDialog(
                          context: context,
                          builder: (context) => TradingDialog(
                            tradeType: 'sell',
                            coin: {
                              'id': holding.symbol.toLowerCase(),
                              'name': holding.name,
                              'symbol': holding.symbol,
                              'price': holding.currentPrice,
                              'quantity': holding.quantity,  // 보유 수량 추가
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CoinSelectionDialog extends StatefulWidget {
  final List<MarketCoin> coins;
  final String tradeType;

  const _CoinSelectionDialog({
    required this.coins,
    required this.tradeType,
  });

  @override
  State<_CoinSelectionDialog> createState() => _CoinSelectionDialogState();
}

class _CoinSelectionDialogState extends State<_CoinSelectionDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 주요 코인 심볼 리스트
  static const List<String> _majorCoins = ['BTC', 'ETH', 'BNB', 'SOL', 'XRP', 'ADA', 'DOGE', 'MATIC', 'DOT', 'AVAX'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<MarketCoin> get _majorCoinsList {
    return widget.coins.where((coin) => _majorCoins.contains(coin.symbol)).toList();
  }

  List<MarketCoin> get _volumeSortedCoins {
    // 거래량(volume24h)으로 정렬 - volume이 높은 순서대로
    final sorted = List<MarketCoin>.from(widget.coins);
    sorted.sort((a, b) => b.volume24h.compareTo(a.volume24h));
    return sorted.take(50).toList(); // 상위 50개
  }

  // 거래량을 읽기 쉬운 형식으로 포맷 (예: 1.2B, 500M)
  String _formatVolume(double volume) {
    if (volume >= 1000000000) {
      // 10억 이상 (B)
      return '${(volume / 1000000000).toStringAsFixed(1)}B';
    } else if (volume >= 1000000) {
      // 100만 이상 (M)
      return '${(volume / 1000000).toStringAsFixed(1)}M';
    } else if (volume >= 1000) {
      // 1000 이상 (K)
      return '${(volume / 1000).toStringAsFixed(1)}K';
    } else {
      return volume.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B4B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    widget.tradeType == 'buy' ? Icons.trending_up : Icons.trending_down,
                    color: widget.tradeType == 'buy' ? AppTheme.successGreen : AppTheme.dangerRed,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${widget.tradeType == 'buy' ? '매수' : '매도'}할 코인 선택',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            // 탭 바
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.accentBlue,
                labelColor: AppTheme.accentBlue,
                unselectedLabelColor: Colors.white60,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.star, size: 18),
                    text: '주요 코인',
                  ),
                  Tab(
                    icon: Icon(Icons.trending_up, size: 18),
                    text: '거래량 순',
                  ),
                ],
              ),
            ),
            // 탭 뷰
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 주요 코인 탭
                  _buildCoinList(_majorCoinsList, showVolume: false),
                  // 거래량 많은 코인 탭
                  _buildCoinList(_volumeSortedCoins, showVolume: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinList(List<MarketCoin> coins, {bool showVolume = false}) {
    if (coins.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            '코인 목록을 불러오는 중...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: coins.length,
      itemBuilder: (context, index) {
        final coin = coins[index];
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                coin.symbol.substring(0, 1),
                style: const TextStyle(
                  color: AppTheme.accentBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          title: Text(
            coin.symbol,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            showVolume
                ? '거래량: \$${_formatVolume(coin.volume24h)}'
                : coin.name,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${coin.price.toStringAsFixed(coin.price > 100 ? 0 : 2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${coin.changePercent24h > 0 ? '+' : ''}${coin.changePercent24h.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: coin.changePercent24h >= 0
                      ? AppTheme.successGreen
                      : AppTheme.dangerRed,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          onTap: () {
            Navigator.of(context).pop();
            // tradeType이 'long' 또는 'short'이면 LeverageTradingDialog, 아니면 TradingDialog
            if (widget.tradeType == 'long' || widget.tradeType == 'short') {
              showDialog(
                context: context,
                builder: (context) => LeverageTradingDialog(
                  leverageType: widget.tradeType,
                  coin: {
                    'id': coin.symbol.toLowerCase(),
                    'name': coin.name,
                    'symbol': coin.symbol,
                    'price': coin.price,
                  },
                ),
              );
            } else {
              showDialog(
                context: context,
                builder: (context) => TradingDialog(
                  tradeType: widget.tradeType,
                  coin: {
                    'id': coin.symbol.toLowerCase(),
                    'name': coin.name,
                    'symbol': coin.symbol,
                    'price': coin.price,
                  },
                ),
              );
            }
          },
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}