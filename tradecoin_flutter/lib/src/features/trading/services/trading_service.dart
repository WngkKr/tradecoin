import 'package:flutter/foundation.dart';

class TradingService {
  // Mock data for now - will be replaced with real Firebase/API data
  static const List<Map<String, dynamic>> _mockCoins = [
    {
      'id': 'bitcoin',
      'symbol': 'BTC',
      'name': 'Bitcoin',
      'price': 43250.00,
      'change24h': 2.5,
      'volume24h': 25000000000,
    },
    {
      'id': 'ethereum',
      'symbol': 'ETH',
      'name': 'Ethereum',
      'price': 2650.00,
      'change24h': -1.2,
      'volume24h': 15000000000,
    },
    {
      'id': 'cardano',
      'symbol': 'ADA',
      'name': 'Cardano',
      'price': 0.52,
      'change24h': 3.8,
      'volume24h': 800000000,
    },
    {
      'id': 'solana',
      'symbol': 'SOL',
      'name': 'Solana',
      'price': 98.50,
      'change24h': 5.2,
      'volume24h': 2000000000,
    },
  ];

  // Get available coins for trading
  Future<List<Map<String, dynamic>>> getAvailableCoins() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockCoins;
  }

  // Execute buy order
  Future<Map<String, dynamic>> executeBuyOrder({
    required String coinId,
    required double amount,
    required double price,
  }) async {
    try {
      // Simulate order processing delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock successful order
      final orderId = DateTime.now().millisecondsSinceEpoch.toString();
      final coin = _mockCoins.firstWhere((c) => c['id'] == coinId);
      
      final order = {
        'orderId': orderId,
        'type': 'buy',
        'coinId': coinId,
        'symbol': coin['symbol'],
        'amount': amount,
        'price': price,
        'total': amount * price,
        'status': 'completed',
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (kDebugMode) {
        print('Buy order executed: $order');
      }

      return {
        'success': true,
        'order': order,
        'message': '매수 주문이 성공적으로 체결되었습니다.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': '매수 주문 처리 중 오류가 발생했습니다.',
      };
    }
  }

  // Execute sell order
  Future<Map<String, dynamic>> executeSellOrder({
    required String coinId,
    required double amount,
    required double price,
  }) async {
    try {
      // Simulate order processing delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock successful order
      final orderId = DateTime.now().millisecondsSinceEpoch.toString();
      final coin = _mockCoins.firstWhere((c) => c['id'] == coinId);
      
      final order = {
        'orderId': orderId,
        'type': 'sell',
        'coinId': coinId,
        'symbol': coin['symbol'],
        'amount': amount,
        'price': price,
        'total': amount * price,
        'status': 'completed',
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (kDebugMode) {
        print('Sell order executed: $order');
      }

      return {
        'success': true,
        'order': order,
        'message': '매도 주문이 성공적으로 체결되었습니다.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': '매도 주문 처리 중 오류가 발생했습니다.',
      };
    }
  }

  // Get user's trading history
  Future<List<Map<String, dynamic>>> getTradingHistory(String userId) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Mock trading history
    return [
      {
        'orderId': '1',
        'type': 'buy',
        'coinId': 'bitcoin',
        'symbol': 'BTC',
        'amount': 0.1,
        'price': 42800.00,
        'total': 4280.00,
        'status': 'completed',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'orderId': '2',
        'type': 'sell',
        'coinId': 'ethereum',
        'symbol': 'ETH',
        'amount': 1.5,
        'price': 2620.00,
        'total': 3930.00,
        'status': 'completed',
        'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'orderId': '3',
        'type': 'buy',
        'coinId': 'cardano',
        'symbol': 'ADA',
        'amount': 1000,
        'price': 0.51,
        'total': 510.00,
        'status': 'pending',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
      },
    ];
  }

  // Get user's portfolio/holdings
  Future<List<Map<String, dynamic>>> getUserPortfolio(String userId) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 400));
    
    // Mock portfolio data
    return [
      {
        'coinId': 'bitcoin',
        'symbol': 'BTC',
        'name': 'Bitcoin',
        'amount': 0.25,
        'averagePrice': 41200.00,
        'currentPrice': 43250.00,
        'totalValue': 10812.50,
        'profitLoss': 512.50,
        'profitLossPercentage': 4.97,
      },
      {
        'coinId': 'ethereum',
        'symbol': 'ETH',
        'name': 'Ethereum',
        'amount': 2.0,
        'averagePrice': 2580.00,
        'currentPrice': 2650.00,
        'totalValue': 5300.00,
        'profitLoss': 140.00,
        'profitLossPercentage': 2.71,
      },
      {
        'coinId': 'cardano',
        'symbol': 'ADA',
        'name': 'Cardano',
        'amount': 2000,
        'averagePrice': 0.49,
        'currentPrice': 0.52,
        'totalValue': 1040.00,
        'profitLoss': 60.00,
        'profitLossPercentage': 6.12,
      },
    ];
  }
}