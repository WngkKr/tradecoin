import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/trading_provider.dart';
import '../../../core/services/exchange_rate_service.dart';

/// 현물 거래 전용 다이얼로그 (매수/매도만)
class TradingDialog extends ConsumerStatefulWidget {
  final String tradeType; // 'buy' or 'sell'
  final Map<String, dynamic> coin;

  const TradingDialog({
    super.key,
    required this.tradeType,
    required this.coin,
  });

  @override
  ConsumerState<TradingDialog> createState() => _TradingDialogState();
}

class _TradingDialogState extends ConsumerState<TradingDialog> {
  final TextEditingController _amountController = TextEditingController();
  double _amount = 0.0;
  final _exchangeRate = ExchangeRateService();

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    final value = double.tryParse(_amountController.text) ?? 0.0;
    setState(() {
      _amount = value;
    });
    ref.read(tradingFormProvider.notifier).updateAmount(value);
  }

  double get _totalValue => _amount * (widget.coin['price'] as double);

  // 보유 수량 (매도 시에만 사용)
  double get _availableQuantity {
    if (widget.coin.containsKey('quantity')) {
      return widget.coin['quantity'] as double;
    }
    return 0.0;
  }

  bool get _isBuy => widget.tradeType == 'buy';

  @override
  Widget build(BuildContext context) {
    final tradingState = ref.watch(tradingFormProvider);

    return Dialog(
      backgroundColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (_isBuy ? AppTheme.successGreen : AppTheme.dangerRed).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _isBuy ? Icons.trending_up : Icons.trending_down,
                    color: _isBuy ? AppTheme.successGreen : AppTheme.dangerRed,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_isBuy ? '매수' : '매도'} 주문 (현물)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${widget.coin['name']} (${widget.coin['symbol']})',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Current price
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassmorphism(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '현재 가격',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _exchangeRate.formatUSDWithKRW(widget.coin['price']),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 보유 수량 (매도 시에만 표시)
            if (!_isBuy && _availableQuantity > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.glassmorphism(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '보유 수량',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${_availableQuantity.toStringAsFixed(8)} ${widget.coin['symbol']}',
                      style: const TextStyle(
                        color: AppTheme.accentBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Amount input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '수량',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '거래할 ${widget.coin['symbol']} 수량을 입력하세요',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: AppTheme.backgroundDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.accentBlue),
                    ),
                    suffixText: widget.coin['symbol'],
                    suffixStyle: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Total value (현물거래만)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassmorphism(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '총 금액',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _exchangeRate.formatUSDWithKRW(_totalValue),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Error message
            if (tradingState.error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.dangerRed, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tradingState.error!,
                        style: const TextStyle(
                          color: AppTheme.dangerRed,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Success message
            if (tradingState.successMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppTheme.successGreen, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tradingState.successMessage!,
                        style: const TextStyle(
                          color: AppTheme.successGreen,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: tradingState.isLoading ? null : () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: tradingState.isLoading || _amount <= 0 ? null : () async {
                      final notifier = ref.read(tradingFormProvider.notifier);

                      if (_isBuy) {
                        await notifier.executeBuyOrder(
                          widget.coin['id'],
                          widget.coin['price'],
                        );
                      } else {
                        await notifier.executeSellOrder(
                          widget.coin['id'],
                          widget.coin['price'],
                        );
                      }

                      // 자동으로 닫지 않음 - 사용자가 직접 확인하고 닫도록 변경
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isBuy ? AppTheme.successGreen : AppTheme.dangerRed,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: tradingState.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _isBuy ? '매수 주문' : '매도 주문',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
