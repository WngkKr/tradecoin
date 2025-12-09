
// 포트폴리오 모델
class PortfolioModel {
  final String userId;
  final double totalValue;
  final double totalBalance;
  final double totalPnl;
  final double totalPnlPercent;
  final List<AssetHolding> holdings;
  final List<Transaction> transactions;
  final Map<String, double> allocation;
  final PortfolioStats stats;
  final DateTime lastUpdated;

  const PortfolioModel({
    required this.userId,
    required this.totalValue,
    required this.totalBalance,
    required this.totalPnl,
    required this.totalPnlPercent,
    required this.holdings,
    required this.transactions,
    required this.allocation,
    required this.stats,
    required this.lastUpdated,
  });

  factory PortfolioModel.fromJson(Map<String, dynamic> json) {
    return PortfolioModel(
      userId: json['userId'] ?? '',
      totalValue: (json['totalValue'] ?? 0.0).toDouble(),
      totalBalance: (json['totalBalance'] ?? 0.0).toDouble(),
      totalPnl: (json['totalPnl'] ?? 0.0).toDouble(),
      totalPnlPercent: (json['totalPnlPercent'] ?? 0.0).toDouble(),
      holdings: (json['holdings'] as List<dynamic>? ?? [])
          .map((item) => AssetHolding.fromJson(item))
          .toList(),
      transactions: (json['transactions'] as List<dynamic>? ?? [])
          .map((item) => Transaction.fromJson(item))
          .toList(),
      allocation: Map<String, double>.from(json['allocation'] ?? {}),
      stats: PortfolioStats.fromJson(json['stats'] ?? {}),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalValue': totalValue,
      'totalBalance': totalBalance,
      'totalPnl': totalPnl,
      'totalPnlPercent': totalPnlPercent,
      'holdings': holdings.map((item) => item.toJson()).toList(),
      'transactions': transactions.map((item) => item.toJson()).toList(),
      'allocation': allocation,
      'stats': stats.toJson(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  PortfolioModel copyWith({
    String? userId,
    double? totalValue,
    double? totalBalance,
    double? totalPnl,
    double? totalPnlPercent,
    List<AssetHolding>? holdings,
    List<Transaction>? transactions,
    Map<String, double>? allocation,
    PortfolioStats? stats,
    DateTime? lastUpdated,
  }) {
    return PortfolioModel(
      userId: userId ?? this.userId,
      totalValue: totalValue ?? this.totalValue,
      totalBalance: totalBalance ?? this.totalBalance,
      totalPnl: totalPnl ?? this.totalPnl,
      totalPnlPercent: totalPnlPercent ?? this.totalPnlPercent,
      holdings: holdings ?? this.holdings,
      transactions: transactions ?? this.transactions,
      allocation: allocation ?? this.allocation,
      stats: stats ?? this.stats,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // 유틸리티 메서드들
  bool get isProfitable => totalPnl > 0;

  String get formattedTotalValue => '\$${totalValue.toStringAsFixed(2)}';

  String get formattedTotalPnl {
    final sign = totalPnl >= 0 ? '+' : '';
    return '$sign\$${totalPnl.toStringAsFixed(2)} ($sign${totalPnlPercent.toStringAsFixed(1)}%)';
  }

  List<AssetHolding> get topHoldings {
    final sortedHoldings = List<AssetHolding>.from(holdings);
    sortedHoldings.sort((a, b) => b.value.compareTo(a.value));
    return sortedHoldings.take(5).toList();
  }

  List<Transaction> get recentTransactions {
    final sortedTransactions = List<Transaction>.from(transactions);
    sortedTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sortedTransactions.take(10).toList();
  }
}

// 자산 보유 정보 모델
class AssetHolding {
  final String symbol;
  final String name;
  final double quantity;
  final double averagePrice;
  final double currentPrice;
  final double value;
  final double pnl;
  final double pnlPercent;
  final double percentageOfPortfolio;
  final DateTime lastUpdated;

  const AssetHolding({
    required this.symbol,
    required this.name,
    required this.quantity,
    required this.averagePrice,
    required this.currentPrice,
    required this.value,
    required this.pnl,
    required this.pnlPercent,
    required this.percentageOfPortfolio,
    required this.lastUpdated,
  });

  factory AssetHolding.fromJson(Map<String, dynamic> json) {
    return AssetHolding(
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      quantity: (json['quantity'] ?? 0.0).toDouble(),
      averagePrice: (json['averagePrice'] ?? 0.0).toDouble(),
      currentPrice: (json['currentPrice'] ?? 0.0).toDouble(),
      value: (json['value'] ?? 0.0).toDouble(),
      pnl: (json['pnl'] ?? 0.0).toDouble(),
      pnlPercent: (json['pnlPercent'] ?? 0.0).toDouble(),
      percentageOfPortfolio: (json['percentageOfPortfolio'] ?? 0.0).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'quantity': quantity,
      'averagePrice': averagePrice,
      'currentPrice': currentPrice,
      'value': value,
      'pnl': pnl,
      'pnlPercent': pnlPercent,
      'percentageOfPortfolio': percentageOfPortfolio,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  AssetHolding copyWith({
    String? symbol,
    String? name,
    double? quantity,
    double? averagePrice,
    double? currentPrice,
    double? value,
    double? pnl,
    double? pnlPercent,
    double? percentageOfPortfolio,
    DateTime? lastUpdated,
  }) {
    return AssetHolding(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      averagePrice: averagePrice ?? this.averagePrice,
      currentPrice: currentPrice ?? this.currentPrice,
      value: value ?? this.value,
      pnl: pnl ?? this.pnl,
      pnlPercent: pnlPercent ?? this.pnlPercent,
      percentageOfPortfolio: percentageOfPortfolio ?? this.percentageOfPortfolio,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // 유틸리티 메서드들
  bool get isProfitable => pnl > 0;

  String get formattedQuantity => quantity.toStringAsFixed(quantity < 1 ? 6 : 2);

  String get formattedValue => '\$${value.toStringAsFixed(2)}';

  String get formattedPnl {
    final sign = pnl >= 0 ? '+' : '';
    return '$sign\$${pnl.toStringAsFixed(2)} ($sign${pnlPercent.toStringAsFixed(1)}%)';
  }

  String get formattedCurrentPrice => '\$${currentPrice.toStringAsFixed(currentPrice < 1 ? 6 : 2)}';
}

// 거래 내역 모델
class Transaction {
  final String id;
  final String symbol;
  final TransactionType type;
  final TransactionSide side;
  final double quantity;
  final double price;
  final double fee;
  final double totalAmount;
  final DateTime timestamp;
  final String? orderId;
  final TransactionStatus status;
  final Map<String, dynamic>? metadata;

  const Transaction({
    required this.id,
    required this.symbol,
    required this.type,
    required this.side,
    required this.quantity,
    required this.price,
    required this.fee,
    required this.totalAmount,
    required this.timestamp,
    this.orderId,
    this.status = TransactionStatus.completed,
    this.metadata,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      symbol: json['symbol'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => TransactionType.market,
      ),
      side: TransactionSide.values.firstWhere(
        (e) => e.toString().split('.').last == json['side'],
        orElse: () => TransactionSide.buy,
      ),
      quantity: (json['quantity'] ?? 0.0).toDouble(),
      price: (json['price'] ?? 0.0).toDouble(),
      fee: (json['fee'] ?? 0.0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      orderId: json['orderId'],
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => TransactionStatus.completed,
      ),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'type': type.toString().split('.').last,
      'side': side.toString().split('.').last,
      'quantity': quantity,
      'price': price,
      'fee': fee,
      'totalAmount': totalAmount,
      'timestamp': timestamp.toIso8601String(),
      'orderId': orderId,
      'status': status.toString().split('.').last,
      'metadata': metadata,
    };
  }

  // 유틸리티 메서드들
  bool get isBuy => side == TransactionSide.buy;
  bool get isSell => side == TransactionSide.sell;

  String get sideKorean => isBuy ? '매수' : '매도';
  String get typeKorean {
    switch (type) {
      case TransactionType.market:
        return '시장가';
      case TransactionType.limit:
        return '지정가';
      case TransactionType.stopLimit:
        return '손절/익절';
      case TransactionType.oco:
        return 'OCO';
    }
  }

  String get formattedQuantity => quantity.toStringAsFixed(quantity < 1 ? 6 : 2);
  String get formattedPrice => '\$${price.toStringAsFixed(price < 1 ? 6 : 2)}';
  String get formattedTotalAmount => '\$${totalAmount.toStringAsFixed(2)}';
  String get formattedFee => '\$${fee.toStringAsFixed(2)}';

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.month}/${timestamp.day}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}

// 거래 타입 enum
enum TransactionType {
  market,    // 시장가
  limit,     // 지정가
  stopLimit, // 손절/익절
  oco,       // OCO (One-Cancels-Other)
}

// 거래 방향 enum
enum TransactionSide {
  buy,  // 매수
  sell, // 매도
}

// 거래 상태 enum
enum TransactionStatus {
  pending,   // 대기중
  completed, // 완료
  cancelled, // 취소됨
  failed,    // 실패
}

// 포트폴리오 통계 모델
class PortfolioStats {
  final double totalInvested;
  final double totalWithdrawn;
  final double realizedPnl;
  final double unrealizedPnl;
  final double totalFees;
  final int totalTrades;
  final int winningTrades;
  final int losingTrades;
  final double winRate;
  final double averageWin;
  final double averageLoss;
  final double largestWin;
  final double largestLoss;
  final double sharpeRatio;
  final double maxDrawdown;
  final Map<String, double> monthlyReturns;
  final DateTime firstTradeDate;

  const PortfolioStats({
    required this.totalInvested,
    required this.totalWithdrawn,
    required this.realizedPnl,
    required this.unrealizedPnl,
    required this.totalFees,
    required this.totalTrades,
    required this.winningTrades,
    required this.losingTrades,
    required this.winRate,
    required this.averageWin,
    required this.averageLoss,
    required this.largestWin,
    required this.largestLoss,
    required this.sharpeRatio,
    required this.maxDrawdown,
    required this.monthlyReturns,
    required this.firstTradeDate,
  });

  factory PortfolioStats.fromJson(Map<String, dynamic> json) {
    return PortfolioStats(
      totalInvested: (json['totalInvested'] ?? 0.0).toDouble(),
      totalWithdrawn: (json['totalWithdrawn'] ?? 0.0).toDouble(),
      realizedPnl: (json['realizedPnl'] ?? 0.0).toDouble(),
      unrealizedPnl: (json['unrealizedPnl'] ?? 0.0).toDouble(),
      totalFees: (json['totalFees'] ?? 0.0).toDouble(),
      totalTrades: json['totalTrades'] ?? 0,
      winningTrades: json['winningTrades'] ?? 0,
      losingTrades: json['losingTrades'] ?? 0,
      winRate: (json['winRate'] ?? 0.0).toDouble(),
      averageWin: (json['averageWin'] ?? 0.0).toDouble(),
      averageLoss: (json['averageLoss'] ?? 0.0).toDouble(),
      largestWin: (json['largestWin'] ?? 0.0).toDouble(),
      largestLoss: (json['largestLoss'] ?? 0.0).toDouble(),
      sharpeRatio: (json['sharpeRatio'] ?? 0.0).toDouble(),
      maxDrawdown: (json['maxDrawdown'] ?? 0.0).toDouble(),
      monthlyReturns: Map<String, double>.from(json['monthlyReturns'] ?? {}),
      firstTradeDate: DateTime.parse(json['firstTradeDate'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalInvested': totalInvested,
      'totalWithdrawn': totalWithdrawn,
      'realizedPnl': realizedPnl,
      'unrealizedPnl': unrealizedPnl,
      'totalFees': totalFees,
      'totalTrades': totalTrades,
      'winningTrades': winningTrades,
      'losingTrades': losingTrades,
      'winRate': winRate,
      'averageWin': averageWin,
      'averageLoss': averageLoss,
      'largestWin': largestWin,
      'largestLoss': largestLoss,
      'sharpeRatio': sharpeRatio,
      'maxDrawdown': maxDrawdown,
      'monthlyReturns': monthlyReturns,
      'firstTradeDate': firstTradeDate.toIso8601String(),
    };
  }

  // 유틸리티 메서드들
  double get totalPnl => realizedPnl + unrealizedPnl;
  double get profitFactor => averageLoss != 0 ? (averageWin * winningTrades) / (averageLoss.abs() * losingTrades) : 0;

  String get formattedWinRate => '${winRate.toStringAsFixed(1)}%';
  String get formattedSharpeRatio => sharpeRatio.toStringAsFixed(2);
  String get formattedMaxDrawdown => '${maxDrawdown.toStringAsFixed(1)}%';
}

// 포트폴리오 기간별 성과 모델
class PortfolioPerformance {
  final String period; // '1D', '1W', '1M', '3M', '1Y', 'ALL'
  final List<PerformanceDataPoint> dataPoints;
  final double totalReturn;
  final double totalReturnPercent;
  final double volatility;
  final double sharpeRatio;
  final double maxDrawdown;

  const PortfolioPerformance({
    required this.period,
    required this.dataPoints,
    required this.totalReturn,
    required this.totalReturnPercent,
    required this.volatility,
    required this.sharpeRatio,
    required this.maxDrawdown,
  });

  factory PortfolioPerformance.fromJson(Map<String, dynamic> json) {
    return PortfolioPerformance(
      period: json['period'] ?? '',
      dataPoints: (json['dataPoints'] as List<dynamic>? ?? [])
          .map((item) => PerformanceDataPoint.fromJson(item))
          .toList(),
      totalReturn: (json['totalReturn'] ?? 0.0).toDouble(),
      totalReturnPercent: (json['totalReturnPercent'] ?? 0.0).toDouble(),
      volatility: (json['volatility'] ?? 0.0).toDouble(),
      sharpeRatio: (json['sharpeRatio'] ?? 0.0).toDouble(),
      maxDrawdown: (json['maxDrawdown'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'dataPoints': dataPoints.map((item) => item.toJson()).toList(),
      'totalReturn': totalReturn,
      'totalReturnPercent': totalReturnPercent,
      'volatility': volatility,
      'sharpeRatio': sharpeRatio,
      'maxDrawdown': maxDrawdown,
    };
  }
}

// 성과 데이터 포인트 모델
class PerformanceDataPoint {
  final DateTime timestamp;
  final double portfolioValue;
  final double pnl;
  final double pnlPercent;

  const PerformanceDataPoint({
    required this.timestamp,
    required this.portfolioValue,
    required this.pnl,
    required this.pnlPercent,
  });

  factory PerformanceDataPoint.fromJson(Map<String, dynamic> json) {
    return PerformanceDataPoint(
      timestamp: DateTime.parse(json['timestamp']),
      portfolioValue: (json['portfolioValue'] ?? 0.0).toDouble(),
      pnl: (json['pnl'] ?? 0.0).toDouble(),
      pnlPercent: (json['pnlPercent'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'portfolioValue': portfolioValue,
      'pnl': pnl,
      'pnlPercent': pnlPercent,
    };
  }
}