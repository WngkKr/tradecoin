import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../screens/dashboard_screen.dart';

class RecentActivitySection extends StatelessWidget {
  final List<ActivityItem> activities;

  const RecentActivitySection({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '최근 활동',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: AppTheme.glassmorphism(),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (context, index) => const Divider(
              color: Colors.white12,
              height: 1,
            ),
            itemBuilder: (context, index) {
              final activity = activities[index];
              return _ActivityItem(activity: activity);
            },
          ),
        ),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final ActivityItem activity;

  const _ActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    final isBuy = activity.type == 'buy';
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isBuy ? AppTheme.successGreen : AppTheme.dangerRed).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: (isBuy ? AppTheme.successGreen : AppTheme.dangerRed).withOpacity(0.3),
              ),
            ),
            child: Icon(
              isBuy ? Icons.trending_up : Icons.trending_down,
              color: isBuy ? AppTheme.successGreen : AppTheme.dangerRed,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isBuy ? '매수' : '매도'} ${activity.coinSymbol}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${activity.amount} ${activity.coinSymbol} @ \$${activity.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.successGreen.withOpacity(0.3),
              ),
            ),
            child: Text(
              activity.status,
              style: const TextStyle(
                color: AppTheme.successGreen,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}