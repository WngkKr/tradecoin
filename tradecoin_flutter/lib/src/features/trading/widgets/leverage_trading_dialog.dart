import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/trading_provider.dart';
import '../../../core/services/exchange_rate_service.dart';

/// 레버리지 거래 전용 다이얼로그 (롱/숏 포지션)
class LeverageTradingDialog extends ConsumerStatefulWidget {
  final String leverageType; // 'long' or 'short'
  final Map<String, dynamic> coin;

  const LeverageTradingDialog({
    super.key,
    required this.leverageType,
    required this.coin,
  });

  @override
  ConsumerState<LeverageTradingDialog> createState() => _LeverageTradingDialogState();
}

class _LeverageTradingDialogState extends ConsumerState<LeverageTradingDialog> {
  final TextEditingController _amountController = TextEditingController();
  double _amount = 0.0;
  int _leverage = 5; // 기본 레버리지 5배
  bool _useStopLoss = true;
  bool _useTakeProfit = true;
  double _stopLossPercent = 3.0; // 손절매 3%
  double _takeProfitPercent = 10.0; // 익절 10%
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
  }

  double get _totalValue => _amount * (widget.coin['price'] as double);
  double get _leveragedValue => _totalValue * _leverage;

  // 보유 수량 (레버리지 거래에서도 참고용으로 표시)
  double get _availableQuantity {
    if (widget.coin.containsKey('quantity')) {
      return widget.coin['quantity'] as double;
    }
    return 0.0;
  }

  // 청산 가격 계산
  double get _liquidationPrice {
    final price = widget.coin['price'] as double;

    if (_isLong) {
      // 롱 포지션: 가격이 떨어져서 청산
      return price * (1 - (1 / _leverage));
    } else {
      // 숏 포지션: 가격이 올라가서 청산
      return price * (1 + (1 / _leverage));
    }
  }

  // 손절매 가격
  double get _stopLossPrice {
    final price = widget.coin['price'] as double;
    if (_isLong) {
      return price * (1 - _stopLossPercent / 100);
    } else {
      return price * (1 + _stopLossPercent / 100);
    }
  }

  // 익절 가격
  double get _takeProfitPrice {
    final price = widget.coin['price'] as double;
    if (_isLong) {
      return price * (1 + _takeProfitPercent / 100);
    } else {
      return price * (1 - _takeProfitPercent / 100);
    }
  }

  bool get _isLong => widget.leverageType == 'long';

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
        constraints: const BoxConstraints(maxHeight: 700),
        child: SingleChildScrollView(
          child: Padding(
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
                        color: (_isLong ? AppTheme.successGreen : AppTheme.dangerRed).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _isLong ? Icons.arrow_upward : Icons.arrow_downward,
                        color: _isLong ? AppTheme.successGreen : AppTheme.dangerRed,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${_isLong ? '롱' : '숏'} 포지션',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.warningOrange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '레버리지',
                                  style: TextStyle(
                                    color: AppTheme.warningOrange,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
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

                const SizedBox(height: 16),

                // 보유 수량 (참고용)
                if (_availableQuantity > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.glassmorphism(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '보유 수량 (참고)',
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
                  const SizedBox(height: 16),
                ],

                // Amount input
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '투자 금액 (USDT)',
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
                        hintText: '투자할 금액을 입력하세요',
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
                        suffixText: 'USDT',
                        suffixStyle: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Leverage selector
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '레버리지 배수',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.dangerRed.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '⚠️ 고위험',
                            style: TextStyle(
                              color: AppTheme.dangerRed,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [3, 5, 10, 20, 50].map((lev) {
                        return ChoiceChip(
                          label: Text('${lev}x'),
                          selected: _leverage == lev,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _leverage = lev;
                              });
                            }
                          },
                          selectedColor: AppTheme.accentBlue.withValues(alpha: 0.3),
                          backgroundColor: AppTheme.backgroundDark,
                          labelStyle: TextStyle(
                            color: _leverage == lev ? AppTheme.accentBlue : Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                          side: BorderSide(
                            color: _leverage == lev ? AppTheme.accentBlue : AppTheme.borderColor,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Total value & Leveraged value
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassmorphism(),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '필요 증거금',
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '포지션 크기 (${_leverage}x)',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _exchangeRate.formatUSDWithKRW(_leveragedValue),
                                style: const TextStyle(
                                  color: AppTheme.accentBlue,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Liquidation price warning
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning, color: AppTheme.dangerRed, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            '청산 가격',
                            style: TextStyle(
                              color: AppTheme.dangerRed,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '\$${_liquidationPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppTheme.dangerRed,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '가격이 이 수준에 도달하면 포지션이 자동으로 청산됩니다',
                        style: TextStyle(
                          color: AppTheme.dangerRed,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Stop-loss and Take-profit settings
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassmorphism(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '자동 청산 설정',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Stop Loss
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _useStopLoss,
                                  onChanged: (value) {
                                    setState(() {
                                      _useStopLoss = value ?? false;
                                    });
                                  },
                                  activeColor: AppTheme.dangerRed,
                                ),
                                const Text(
                                  '손절매',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_useStopLoss)
                            Text(
                              '\$${_stopLossPrice.toStringAsFixed(2)} (-${_stopLossPercent.toStringAsFixed(1)}%)',
                              style: const TextStyle(
                                color: AppTheme.dangerRed,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      // Take Profit
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _useTakeProfit,
                                  onChanged: (value) {
                                    setState(() {
                                      _useTakeProfit = value ?? false;
                                    });
                                  },
                                  activeColor: AppTheme.successGreen,
                                ),
                                const Text(
                                  '익절',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_useTakeProfit)
                            Text(
                              '\$${_takeProfitPrice.toStringAsFixed(2)} (+${_takeProfitPercent.toStringAsFixed(1)}%)',
                              style: const TextStyle(
                                color: AppTheme.successGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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
                          // TODO: 레버리지 거래 실행 로직 구현 필요
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${_isLong ? '롱' : '숏'} 포지션 ${_leverage}x 주문: \$$_leveragedValue',
                              ),
                              backgroundColor: AppTheme.accentBlue,
                            ),
                          );
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isLong ? AppTheme.successGreen : AppTheme.dangerRed,
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
                                '${_isLong ? '롱' : '숏'} 포지션 주문',
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
        ),
      ),
    );
  }
}
