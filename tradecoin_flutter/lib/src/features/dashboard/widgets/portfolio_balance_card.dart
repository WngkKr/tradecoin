import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PortfolioBalanceCard extends StatelessWidget {
  final double balance;
  final double todayPnL;
  final double todayPnLPercent;

  const PortfolioBalanceCard({
    super.key,
    required this.balance,
    required this.todayPnL,
    required this.todayPnLPercent,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = todayPnL >= 0;
    
    return Container(
      decoration: AppTheme.glassmorphism(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '포트폴리오 잔고',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive ? AppTheme.successGreen : AppTheme.dangerRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${isPositive ? '+' : ''}\$${todayPnL.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isPositive ? AppTheme.successGreen : AppTheme.dangerRed,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${isPositive ? '+' : ''}${todayPnLPercent.toStringAsFixed(1)}%)',
                style: TextStyle(
                  color: isPositive ? AppTheme.successGreen : AppTheme.dangerRed,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}