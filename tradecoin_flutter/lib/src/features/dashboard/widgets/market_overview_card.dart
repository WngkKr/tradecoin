import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../screens/dashboard_screen.dart';

class MarketOverviewCard extends StatelessWidget {
  final MarketOverviewData marketData;

  const MarketOverviewCard({
    super.key,
    required this.marketData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassmorphism(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '마켓 개요',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _CoinPriceCard(
                  symbol: 'BTC',
                  price: marketData.btcPrice,
                  change: marketData.btcChange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _CoinPriceCard(
                  symbol: 'ETH',
                  price: marketData.ethPrice,
                  change: marketData.ethChange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoinPriceCard extends StatelessWidget {
  final String symbol;
  final double price;
  final double change;

  const _CoinPriceCard({
    required this.symbol,
    required this.price,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = change >= 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            symbol,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${price.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive ? AppTheme.successGreen : AppTheme.dangerRed,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: isPositive ? AppTheme.successGreen : AppTheme.dangerRed,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}