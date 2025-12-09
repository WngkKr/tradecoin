import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/services/api_service.dart';
import '../providers/trading_settings_provider.dart';

class TradingSettingsScreen extends ConsumerWidget {
  const TradingSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final localeState = ref.watch(localeProvider);
    final tradingSettings = ref.watch(tradingSettingsProvider);
    final riskAnalysis = ref.watch(tradingRiskAnalysisProvider);
    final performance = ref.watch(tradingPerformanceProvider);
    final isKorean = localeState.currentLanguage == AppLanguage.korean;

    return Scaffold(
      appBar: AppBar(
        title: Text(isKorean ? '거래 설정' : 'Trading Settings'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 현재 설정 미리보기
            _buildCurrentSettingsPreview(context, tradingSettings, isKorean),
            const SizedBox(height: 24),

            // 레버리지 설정
            _buildLeverageSettings(context, ref, tradingSettings, isKorean),
            const SizedBox(height: 24),

            // 리스크 관리 설정
            _buildRiskManagementSettings(context, ref, tradingSettings, isKorean),
            const SizedBox(height: 24),

            // 포지션 관리 설정
            _buildPositionManagementSettings(context, ref, tradingSettings, isKorean),
            const SizedBox(height: 24),

            // 자동 거래 설정
            _buildAutoTradingSettings(context, ref, tradingSettings, isKorean),
            const SizedBox(height: 24),

            // 설정 정보 및 경고
            _buildSettingsInfo(context, isKorean),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSettingsPreview(BuildContext context, TradingSettings settings, bool isKorean) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                isKorean ? '현재 거래 설정' : 'Current Trading Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 설정 미리보기 카드들
          Row(
            children: [
              Expanded(
                child: _buildPreviewCard(
                  context,
                  icon: Icons.trending_up,
                  title: isKorean ? '레버리지' : 'Leverage',
                  value: '${settings.maxLeverage.toInt()}x',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPreviewCard(
                  context,
                  icon: Icons.trending_down,
                  title: isKorean ? '손절매' : 'Stop Loss',
                  value: '${settings.stopLossPercentage.toStringAsFixed(1)}%',
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPreviewCard(
                  context,
                  icon: Icons.trending_up,
                  title: isKorean ? '익절' : 'Take Profit',
                  value: '${settings.takeProfitPercentage.toStringAsFixed(1)}%',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPreviewCard(
                  context,
                  icon: Icons.account_balance_wallet,
                  title: isKorean ? '포지션 크기' : 'Position Size',
                  value: '${settings.positionSizePercentage.toStringAsFixed(1)}%',
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLeverageSettings(BuildContext context, WidgetRef ref, TradingSettings settings, bool isKorean) {
    return _buildSettingsSection(
      context,
      title: isKorean ? '레버리지 설정' : 'Leverage Settings',
      icon: Icons.trending_up,
      children: [
        _buildSliderSetting(
          context,
          ref,
          title: isKorean ? '최대 레버리지' : 'Maximum Leverage',
          value: settings.maxLeverage,
          min: 1.0,
          max: 20.0,
          divisions: 19,
          suffix: 'x',
          onChanged: (value) {
            ref.read(tradingSettingsProvider.notifier).updateMaxLeverage(value);
          },
          description: isKorean
            ? '높은 레버리지는 높은 수익과 위험을 동반합니다'
            : 'Higher leverage brings higher profits and risks',
        ),
        const SizedBox(height: 16),
        _buildToggleSetting(
          context,
          ref,
          title: isKorean ? '동적 레버리지 조정' : 'Dynamic Leverage Adjustment',
          value: settings.dynamicLeverage,
          onChanged: (value) {
            ref.read(tradingSettingsProvider.notifier).toggleDynamicLeverage(value);
          },
          description: isKorean
            ? '시장 변동성에 따라 레버리지를 자동 조정합니다'
            : 'Automatically adjusts leverage based on market volatility',
        ),
      ],
    );
  }

  Widget _buildRiskManagementSettings(BuildContext context, WidgetRef ref, TradingSettings settings, bool isKorean) {
    return _buildSettingsSection(
      context,
      title: isKorean ? '리스크 관리' : 'Risk Management',
      icon: Icons.security,
      children: [
        _buildSliderSetting(
          context,
          ref,
          title: isKorean ? '손절매 비율' : 'Stop Loss Percentage',
          value: settings.stopLossPercentage,
          min: 1.0,
          max: 20.0,
          divisions: 38,
          suffix: '%',
          onChanged: (value) {
            ref.read(tradingSettingsProvider.notifier).updateStopLoss(value);
          },
          description: isKorean
            ? '손실을 제한하는 최대 비율입니다'
            : 'Maximum percentage to limit losses',
        ),
        const SizedBox(height: 16),
        _buildSliderSetting(
          context,
          ref,
          title: isKorean ? '익절 비율' : 'Take Profit Percentage',
          value: settings.takeProfitPercentage,
          min: 2.0,
          max: 50.0,
          divisions: 48,
          suffix: '%',
          onChanged: (value) {
            ref.read(tradingSettingsProvider.notifier).updateTakeProfit(value);
          },
          description: isKorean
            ? '수익을 확정하는 목표 비율입니다'
            : 'Target percentage to secure profits',
        ),
        const SizedBox(height: 16),
        _buildToggleSetting(
          context,
          ref,
          title: isKorean ? '트레일링 스톱' : 'Trailing Stop',
          value: settings.trailingStopEnabled,
          onChanged: (value) {
            ref.read(tradingSettingsProvider.notifier).toggleTrailingStop(value);
          },
          description: isKorean
            ? '수익이 증가할 때 손절가를 자동으로 조정합니다'
            : 'Automatically adjusts stop loss as profits increase',
        ),
      ],
    );
  }

  Widget _buildPositionManagementSettings(BuildContext context, WidgetRef ref, TradingSettings settings, bool isKorean) {
    return _buildSettingsSection(
      context,
      title: isKorean ? '포지션 관리' : 'Position Management',
      icon: Icons.account_balance_wallet,
      children: [
        _buildSliderSetting(
          context,
          ref,
          title: isKorean ? '포지션 크기 (%자금)' : 'Position Size (% of Capital)',
          value: settings.positionSizePercentage,
          min: 1.0,
          max: 25.0,
          divisions: 24,
          suffix: '%',
          onChanged: (value) {
            ref.read(tradingSettingsProvider.notifier).updatePositionSize(value);
          },
          description: isKorean
            ? '총 자금 대비 한 포지션에 사용할 비율입니다'
            : 'Percentage of total capital to use per position',
        ),
        const SizedBox(height: 16),
        _buildSliderSetting(
          context,
          ref,
          title: isKorean ? '최대 동시 포지션' : 'Max Concurrent Positions',
          value: settings.maxConcurrentPositions.toDouble(),
          min: 1.0,
          max: 10.0,
          divisions: 9,
          suffix: isKorean ? '개' : '',
          onChanged: (value) {
            ref.read(tradingSettingsProvider.notifier).updateMaxPositions(value.toInt());
          },
          description: isKorean
            ? '동시에 보유할 수 있는 최대 포지션 수입니다'
            : 'Maximum number of positions to hold simultaneously',
        ),
        const SizedBox(height: 16),
        _buildToggleSetting(
          context,
          ref,
          title: isKorean ? '포지션 사이징 자동화' : 'Automated Position Sizing',
          value: settings.autoPositionSizing,
          onChanged: (value) {
            ref.read(tradingSettingsProvider.notifier).toggleAutoPositionSizing(value);
          },
          description: isKorean
            ? '변동성과 신뢰도에 따라 포지션 크기를 자동 조정합니다'
            : 'Automatically adjusts position size based on volatility and confidence',
        ),
      ],
    );
  }

  Widget _buildAutoTradingSettings(BuildContext context, WidgetRef ref, TradingSettings settings, bool isKorean) {
    return _buildSettingsSection(
      context,
      title: isKorean ? '자동 거래' : 'Auto Trading',
      icon: Icons.smart_toy,
      children: [
        _buildToggleSetting(
          context,
          ref,
          title: isKorean ? '자동 거래 활성화' : 'Enable Auto Trading',
          value: settings.autoTradingEnabled,
          onChanged: (value) {
            ref.read(tradingSettingsProvider.notifier).toggleAutoTrading(value);
          },
          description: isKorean
            ? '시그널에 따라 자동으로 거래를 실행합니다'
            : 'Automatically executes trades based on signals',
        ),
        const SizedBox(height: 16),
        _buildSliderSetting(
          context,
          ref,
          title: isKorean ? '최소 신뢰도 임계값' : 'Minimum Confidence Threshold',
          value: settings.minConfidenceThreshold,
          min: 50.0,
          max: 95.0,
          divisions: 45,
          suffix: '%',
          onChanged: (value) {
            ref.read(tradingSettingsProvider.notifier).updateConfidenceThreshold(value);
          },
          description: isKorean
            ? '자동 거래를 실행할 최소 신뢰도입니다'
            : 'Minimum confidence level to execute automatic trades',
        ),
        const SizedBox(height: 16),
        _buildToggleSetting(
          context,
          ref,
          title: isKorean ? '야간 거래 허용' : 'Allow Night Trading',
          value: settings.nightTradingEnabled,
          onChanged: (value) {
            ref.read(tradingSettingsProvider.notifier).toggleNightTrading(value);
          },
          description: isKorean
            ? '야간 시간대에도 자동 거래를 허용합니다'
            : 'Allows automatic trading during night hours',
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSliderSetting(BuildContext context, WidgetRef ref, {
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String suffix,
    required ValueChanged<double> onChanged,
    String? description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}$suffix',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
        if (description != null) ...[
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildToggleSetting(BuildContext context, WidgetRef ref, {
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsInfo(BuildContext context, bool isKorean) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isKorean ? '중요 안내사항' : 'Important Notice',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isKorean
                ? '• 레버리지 거래는 높은 위험을 수반합니다\n'
                  '• 손절매 설정을 통해 리스크를 관리하세요\n'
                  '• 자동 거래 전 충분한 테스트를 권장합니다\n'
                  '• 투자 금액은 손실을 감당할 수 있는 범위 내에서 설정하세요\n'
                  '• 시장 상황에 따라 설정을 주기적으로 검토하세요'
                : '• Leverage trading involves high risks\n'
                  '• Use stop-loss settings to manage risks\n'
                  '• Thorough testing is recommended before auto-trading\n'
                  '• Set investment amounts within your loss tolerance\n'
                  '• Regularly review settings based on market conditions',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              height: 1.5,
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}