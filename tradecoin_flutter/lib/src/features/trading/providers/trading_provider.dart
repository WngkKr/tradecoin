import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/trading_service.dart';

// Trading service provider
final tradingServiceProvider = Provider<TradingService>((ref) {
  return TradingService();
});

// Available coins provider
final availableCoinsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  final tradingService = ref.watch(tradingServiceProvider);
  return tradingService.getAvailableCoins();
});

// User portfolio provider
final userPortfolioProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  final tradingService = ref.watch(tradingServiceProvider);
  return tradingService.getUserPortfolio(userId);
});

// Trading history provider
final tradingHistoryProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  final tradingService = ref.watch(tradingServiceProvider);
  return tradingService.getTradingHistory(userId);
});

// Selected coin for trading
final selectedCoinProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

// Trading form state
class TradingFormState {
  final double amount;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const TradingFormState({
    this.amount = 0.0,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  TradingFormState copyWith({
    double? amount,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return TradingFormState(
      amount: amount ?? this.amount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

// Trading form provider
final tradingFormProvider = StateNotifierProvider<TradingFormNotifier, TradingFormState>((ref) {
  return TradingFormNotifier(ref);
});

class TradingFormNotifier extends StateNotifier<TradingFormState> {
  final Ref ref;

  TradingFormNotifier(this.ref) : super(const TradingFormState());

  void updateAmount(double amount) {
    state = state.copyWith(amount: amount, error: null, successMessage: null);
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }

  Future<void> executeBuyOrder(String coinId, double price) async {
    if (state.amount <= 0) {
      state = state.copyWith(error: '올바른 수량을 입력해주세요.');
      return;
    }

    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final tradingService = ref.read(tradingServiceProvider);
      final result = await tradingService.executeBuyOrder(
        coinId: coinId,
        amount: state.amount,
        price: price,
      );

      if (result['success']) {
        state = state.copyWith(
          isLoading: false,
          successMessage: result['message'],
          amount: 0.0,
        );
        // Refresh related data
        ref.invalidate(userPortfolioProvider);
        ref.invalidate(tradingHistoryProvider);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result['message'] ?? '매수 주문에 실패했습니다.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '네트워크 오류가 발생했습니다.',
      );
    }
  }

  Future<void> executeSellOrder(String coinId, double price) async {
    if (state.amount <= 0) {
      state = state.copyWith(error: '올바른 수량을 입력해주세요.');
      return;
    }

    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final tradingService = ref.read(tradingServiceProvider);
      final result = await tradingService.executeSellOrder(
        coinId: coinId,
        amount: state.amount,
        price: price,
      );

      if (result['success']) {
        state = state.copyWith(
          isLoading: false,
          successMessage: result['message'],
          amount: 0.0,
        );
        // Refresh related data
        ref.invalidate(userPortfolioProvider);
        ref.invalidate(tradingHistoryProvider);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result['message'] ?? '매도 주문에 실패했습니다.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '네트워크 오류가 발생했습니다.',
      );
    }
  }
}