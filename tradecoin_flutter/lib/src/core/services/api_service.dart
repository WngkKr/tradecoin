import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';

class ApiService {
  // 안드로이드 에뮬레이터에서는 10.0.2.2, 웹 환경에서는 localhost 사용
  final String _baseUrl = AppConstants.apiBaseUrl;
  static const Duration _timeout = Duration(seconds: 10); // 타임아웃 설정
  
  final http.Client _client = http.Client();

  Future<T> _makeRequest<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final finalUri = queryParams != null 
          ? uri.replace(queryParameters: queryParams)
          : uri;

      final response = await _client
          .get(finalUri)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // 백엔드는 'success' 필드 사용 (예: {"success": true, "data": [...]})
        if (data['success'] == true) {
          return fromJson(data);
        } else {
          throw ApiException('API error: ${data['error'] ?? 'Unknown error'}');
        }
      } else {
        throw ApiException('HTTP ${response.statusCode}: ${response.body}');
      }
    } on TimeoutException {
      throw ApiException('Request timeout - please check your connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  Future<MarketDataResponse> getMarketData() async {
    return _makeRequest(
      '/api/market/data',
      (data) => MarketDataResponse.fromJson(data),
    );
  }

  // 개별 코인 정보 조회
  Future<CoinInfoResponse> getCoinInfo(String symbol) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/market/coin/$symbol');
      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return CoinInfoResponse.fromJson(data);
        } else {
          throw ApiException('API error: ${data['error'] ?? 'Unknown error'}');
        }
      } else {
        throw ApiException('HTTP ${response.statusCode}: ${response.body}');
      }
    } on TimeoutException {
      throw ApiException('Request timeout - please check your connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  Future<TradingSignalsResponse> getTradingSignals() async {
    return _makeRequest(
      '/api/trading/signals',
      (data) => TradingSignalsResponse.fromJson(data),
    );
  }

  Future<PortfolioSummaryResponse> getPortfolioSummary() async {
    return _makeRequest(
      '/api/portfolio/summary',
      (data) => PortfolioSummaryResponse.fromJson(data),
    );
  }

  Future<PortfolioPositionsResponse> getPortfolioPositions() async {
    return _makeRequest(
      '/api/portfolio/positions',
      (data) => PortfolioPositionsResponse.fromJson(data),
    );
  }

  Future<PortfolioSummaryResponse> getUserPortfolioSummary(String userId) async {
    return _makeRequest(
      '/api/portfolio/summary?userId=$userId',
      (data) => PortfolioSummaryResponse.fromJson(data),
    );
  }

  Future<NewsResponse> getNews() async {
    return _makeRequest(
      '/api/news',
      (data) => NewsResponse.fromJson(data),
    );
  }

  Future<bool> checkHealth() async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/api/health'))
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<BinanceConnectionResponse> getBinanceConnectionStatus() async {
    return _makeRequest(
      '/api/binance/connection-status',
      (data) => BinanceConnectionResponse.fromJson(data),
    );
  }

  Future<BinanceConnectionResponse> getConnectionStatus() async {
    return getBinanceConnectionStatus();
  }

  Future<BinanceConnectionResponse> getUserConnectionStatus(String userId) async {
    return _makeRequest(
      '/api/user/connection-status?userId=$userId',
      (data) => BinanceConnectionResponse.fromJson(data),
    );
  }

  Future<BinanceAccountInfoResponse> getBinanceAccountInfo(String userId) async {
    return _makeRequest(
      '/api/binance/account-info?userId=$userId',
      (data) => BinanceAccountInfoResponse.fromJson(data),
    );
  }

  // Trading Settings API methods
  Future<TradingSettingsResponse> getTradingSettings(String userId) async {
    return _makeRequest(
      '/api/user/$userId/trading-settings',
      (data) => TradingSettingsResponse.fromJson(data),
    );
  }

  Future<TradingSettingsResponse> updateTradingSettings({
    required String userId,
    required Map<String, dynamic> settings,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/user/$userId/trading-settings');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'settings': settings}),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return TradingSettingsResponse.fromJson(data);
        } else {
          throw ApiException('API error: ${data['error'] ?? 'Unknown error'}');
        }
      } else {
        final data = json.decode(response.body);
        throw ApiException(data['error'] ?? 'HTTP ${response.statusCode}: ${response.body}');
      }
    } on TimeoutException {
      throw ApiException('Request timeout - please check your connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  Future<TradingRiskAnalysisResponse> getTradingRiskAnalysis(String userId) async {
    return _makeRequest(
      '/api/user/$userId/trading-risk-analysis',
      (data) => TradingRiskAnalysisResponse.fromJson(data),
    );
  }

  Future<TradingPerformanceResponse> getTradingPerformance(String userId) async {
    return _makeRequest(
      '/api/user/$userId/trading-performance',
      (data) => TradingPerformanceResponse.fromJson(data),
    );
  }

  // User Profile API methods
  Future<UserProfileResponse> getUserProfile(String userId) async {
    return _makeRequest(
      '/api/user/$userId/profile',
      (data) => UserProfileResponse.fromJson(data),
    );
  }

  Future<UserProfileResponse> updateUserProfile({
    required String userId,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/user/$userId/profile');
      final response = await _client.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(profileData),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return UserProfileResponse.fromJson(data);
        } else {
          throw ApiException('API error: ${data['error'] ?? 'Unknown error'}');
        }
      } else {
        final data = json.decode(response.body);
        throw ApiException(data['error'] ?? 'HTTP ${response.statusCode}: ${response.body}');
      }
    } on TimeoutException {
      throw ApiException('Request timeout - please check your connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  Future<AuthenticationResponse> authenticateUser(String email, String password) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/auth/login');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return AuthenticationResponse.fromJson(data);
        } else {
          throw ApiException('API error: ${data['error'] ?? 'Unknown error'}');
        }
      } else {
        final data = json.decode(response.body);
        throw ApiException(data['error'] ?? 'HTTP ${response.statusCode}: ${response.body}');
      }
    } on TimeoutException {
      throw ApiException('Request timeout - please check your connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  Future<UserRegistrationResponse> registerUser({
    required String email,
    required String displayName,
    String? password,
    Map<String, dynamic>? profileData,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/auth/register');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'display_name': displayName,
          'password': password,
          'profile_data': profileData,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return UserRegistrationResponse.fromJson(data);
        } else {
          throw ApiException('API error: ${data['error'] ?? 'Unknown error'}');
        }
      } else {
        final data = json.decode(response.body);
        throw ApiException(data['error'] ?? 'HTTP ${response.statusCode}: ${response.body}');
      }
    } on TimeoutException {
      throw ApiException('Request timeout - please check your connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  Future<BinanceApiUpdateResponse> updateBinanceKeys({
    required String apiKey,
    required String secretKey,
    required String userId,
    bool isTestnet = true,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/binance/update-keys');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'api_key': apiKey,
          'secret_key': secretKey,
          'user_id': userId,
          'is_testnet': isTestnet,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return BinanceApiUpdateResponse.fromJson(data);
        } else {
          throw ApiException('API error: ${data['error'] ?? 'Unknown error'}');
        }
      } else {
        final data = json.decode(response.body);
        throw ApiException(data['error'] ?? 'HTTP ${response.statusCode}: ${response.body}');
      }
    } on TimeoutException {
      throw ApiException('Request timeout - please check your connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  Future<BinanceApiUpdateResponse> testBinanceConnection({
    required String apiKey,
    required String secretKey,
    required String userId,
    bool isTestnet = true,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/binance/test-connection');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'api_key': apiKey,
          'secret_key': secretKey,
          'user_id': userId,
          'is_testnet': isTestnet,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return BinanceApiUpdateResponse.fromJson(data);
        } else {
          throw ApiException('API error: ${data['error'] ?? 'Unknown error'}');
        }
      } else {
        final data = json.decode(response.body);
        throw ApiException(data['error'] ?? 'HTTP ${response.statusCode}: ${response.body}');
      }
    } on TimeoutException {
      throw ApiException('Request timeout - please check your connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  // 병렬 로딩으로 초기 대시보드 데이터 성능 향상
  Future<DashboardData> loadAllDashboardData() async {
    try {
      final results = await Future.wait([
        getMarketData().catchError((e) => null),
        getTradingSignals().catchError((e) => null),
        getPortfolioSummary().catchError((e) => null),
        getPortfolioPositions().catchError((e) => null),
      ]);

      return DashboardData(
        marketData: results[0] as MarketDataResponse?,
        tradingSignals: results[1] as TradingSignalsResponse?,
        portfolioSummary: results[2] as PortfolioSummaryResponse?,
        portfolioPositions: results[3] as PortfolioPositionsResponse?,
      );
    } catch (e) {
      throw ApiException('Dashboard loading failed: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}

// 병렬 로딩을 위한 대시보드 데이터 클래스
class DashboardData {
  final MarketDataResponse? marketData;
  final TradingSignalsResponse? tradingSignals;
  final PortfolioSummaryResponse? portfolioSummary;
  final PortfolioPositionsResponse? portfolioPositions;

  DashboardData({
    this.marketData,
    this.tradingSignals,
    this.portfolioSummary,
    this.portfolioPositions,
  });
}

// Data Models

class MarketDataResponse {
  final bool success;
  final List<MarketCoin> data;
  final DateTime? lastUpdated;

  MarketDataResponse({
    required this.success,
    required this.data,
    this.lastUpdated,
  });

  factory MarketDataResponse.fromJson(Map<String, dynamic> json) {
    return MarketDataResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List)
          .map((coin) => MarketCoin.fromJson(coin))
          .toList(),
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : null,
    );
  }
}

class MarketCoin {
  final String symbol;
  final String name;
  final double price;
  final double change24h;
  final double changePercent24h;
  final double volume24h;
  final double marketCap;
  final String? image;

  MarketCoin({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change24h,
    required this.changePercent24h,
    required this.volume24h,
    required this.marketCap,
    this.image,
  });

  factory MarketCoin.fromJson(Map<String, dynamic> json) {
    return MarketCoin(
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      change24h: (json['change_24h'] ?? 0).toDouble(),
      changePercent24h: (json['change_percent_24h'] ?? 0).toDouble(),
      volume24h: (json['volume_24h'] ?? 0).toDouble(),
      marketCap: (json['market_cap'] ?? 0).toDouble(),
      image: json['image'],
    );
  }
}

class CoinInfoResponse {
  final bool success;
  final CoinInfo data;

  CoinInfoResponse({
    required this.success,
    required this.data,
  });

  factory CoinInfoResponse.fromJson(Map<String, dynamic> json) {
    return CoinInfoResponse(
      success: json['success'] ?? false,
      data: CoinInfo.fromJson(json),
    );
  }
}

class CoinInfo {
  final String symbol;
  final String name;
  final double price;
  final double change24h;
  final double changePercent24h;
  final double volume24h;
  final double high24h;
  final double low24h;
  final double marketCap;
  final String? image;
  final DateTime? lastUpdated;

  CoinInfo({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change24h,
    required this.changePercent24h,
    required this.volume24h,
    required this.high24h,
    required this.low24h,
    required this.marketCap,
    this.image,
    this.lastUpdated,
  });

  factory CoinInfo.fromJson(Map<String, dynamic> json) {
    return CoinInfo(
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      change24h: (json['change_24h'] ?? 0).toDouble(),
      changePercent24h: (json['change_percent_24h'] ?? 0).toDouble(),
      volume24h: (json['volume_24h'] ?? 0).toDouble(),
      high24h: (json['high_24h'] ?? 0).toDouble(),
      low24h: (json['low_24h'] ?? 0).toDouble(),
      marketCap: (json['market_cap'] ?? 0).toDouble(),
      image: json['image'],
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : null,
    );
  }
}

class TradingSignalsResponse {
  final bool success;
  final List<TradingSignal> data;

  TradingSignalsResponse({
    required this.success,
    required this.data,
  });

  factory TradingSignalsResponse.fromJson(Map<String, dynamic> json) {
    return TradingSignalsResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List)
          .map((signal) => TradingSignal.fromJson(signal))
          .toList(),
    );
  }
}

class TradingSignal {
  final String symbol;
  final String signal; // BUY, SELL, HOLD
  final double confidence;
  final double targetPrice;
  final double stopLoss;
  final String reason;
  final DateTime timestamp;

  TradingSignal({
    required this.symbol,
    required this.signal,
    required this.confidence,
    required this.targetPrice,
    required this.stopLoss,
    required this.reason,
    required this.timestamp,
  });

  factory TradingSignal.fromJson(Map<String, dynamic> json) {
    return TradingSignal(
      symbol: json['symbol'] ?? '',
      signal: json['signal'] ?? 'HOLD',
      confidence: (json['confidence'] ?? 0).toDouble(),
      targetPrice: (json['target_price'] ?? 0).toDouble(),
      stopLoss: (json['stop_loss'] ?? 0).toDouble(),
      reason: json['reason'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

class PortfolioSummaryResponse {
  final bool success;
  final PortfolioSummary data;

  PortfolioSummaryResponse({
    required this.success,
    required this.data,
  });

  factory PortfolioSummaryResponse.fromJson(Map<String, dynamic> json) {
    return PortfolioSummaryResponse(
      success: json['success'] ?? false,
      data: PortfolioSummary.fromJson(json['data']),
    );
  }
}

class PortfolioSummary {
  final double totalBalance;
  final double totalProfit;
  final double totalProfitPercent;
  final double availableBalance;
  final double todayProfit;
  final double todayProfitPercent;
  final int totalTrades;
  final int successfulTrades;
  final double winRate;

  PortfolioSummary({
    required this.totalBalance,
    required this.totalProfit,
    required this.totalProfitPercent,
    required this.availableBalance,
    required this.todayProfit,
    required this.todayProfitPercent,
    required this.totalTrades,
    required this.successfulTrades,
    required this.winRate,
  });

  factory PortfolioSummary.fromJson(Map<String, dynamic> json) {
    return PortfolioSummary(
      totalBalance: (json['totalValue'] ?? 0).toDouble(),
      totalProfit: (json['totalPnL'] ?? 0).toDouble(),
      totalProfitPercent: (json['totalPnLPercent'] ?? 0).toDouble(),
      availableBalance: (json['availableBalance'] ?? 0).toDouble(),
      todayProfit: (json['todayPnL'] ?? 0).toDouble(),
      todayProfitPercent: (json['todayPnLPercent'] ?? 0).toDouble(),
      totalTrades: json['totalTrades'] ?? 0,
      successfulTrades: json['successfulTrades'] ?? 0,
      winRate: (json['winRate'] ?? 0).toDouble(),
    );
  }
}

class PortfolioPositionsResponse {
  final bool success;
  final List<PortfolioPosition> data;

  PortfolioPositionsResponse({
    required this.success,
    required this.data,
  });

  factory PortfolioPositionsResponse.fromJson(Map<String, dynamic> json) {
    return PortfolioPositionsResponse(
      success: json['success'],
      data: (json['data'] as List)
          .map((position) => PortfolioPosition.fromJson(position))
          .toList(),
    );
  }
}

class PortfolioPosition {
  final String symbol;
  final String name;
  final double amount;
  final double averagePrice;
  final double currentPrice;
  final double totalValue;
  final double profit;
  final double profitPercent;

  PortfolioPosition({
    required this.symbol,
    required this.name,
    required this.amount,
    required this.averagePrice,
    required this.currentPrice,
    required this.totalValue,
    required this.profit,
    required this.profitPercent,
  });

  factory PortfolioPosition.fromJson(Map<String, dynamic> json) {
    return PortfolioPosition(
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? json['symbol'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      averagePrice: (json['averagePrice'] ?? 0).toDouble(),
      currentPrice: (json['currentPrice'] ?? 0).toDouble(),
      totalValue: (json['value'] ?? 0).toDouble(),
      profit: (json['pnl'] ?? 0).toDouble(),
      profitPercent: (json['pnlPercent'] ?? 0).toDouble(),
    );
  }
}

class NewsResponse {
  final bool success;
  final List<NewsArticle> data;

  NewsResponse({
    required this.success,
    required this.data,
  });

  factory NewsResponse.fromJson(Map<String, dynamic> json) {
    return NewsResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List)
          .map((article) => NewsArticle.fromJson(article))
          .toList(),
    );
  }
}

class NewsArticle {
  final int id;
  final String title;
  final String summary;
  final String url;
  final String source;
  final String category;
  final DateTime publishedAt;

  NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.url,
    required this.source,
    required this.category,
    required this.publishedAt,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
      url: json['url'] ?? '',
      source: json['source'] ?? '',
      category: json['category'] ?? '',
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'])
          : DateTime.now(),
    );
  }
}

class BinanceConnectionResponse {
  final bool success;
  final BinanceConnectionStatus data;

  BinanceConnectionResponse({
    required this.success,
    required this.data,
  });

  factory BinanceConnectionResponse.fromJson(Map<String, dynamic> json) {
    return BinanceConnectionResponse(
      success: json['success'] ?? false,
      data: BinanceConnectionStatus.fromJson(json['data']),
    );
  }
}

class BinanceConnectionStatus {
  final bool connected;
  final String status;
  final String connectionType;
  final String? accountType;
  final BinanceBalance? balance;
  final List<String>? permissions;
  final DateTime? lastChecked;
  final String? error;

  BinanceConnectionStatus({
    required this.connected,
    required this.status,
    required this.connectionType,
    this.accountType,
    this.balance,
    this.permissions,
    this.lastChecked,
    this.error,
  });

  factory BinanceConnectionStatus.fromJson(Map<String, dynamic> json) {
    return BinanceConnectionStatus(
      connected: json['connected'] ?? false,
      status: json['status'] ?? '',
      connectionType: json['connectionType'] ?? json['connection_type'] ?? 'none',
      accountType: json['accountType'] ?? json['account_type'],
      balance: json['balance'] != null
          ? BinanceBalance.fromJson(json['balance'])
          : null,
      permissions: json['permissions'] != null
          ? List<String>.from(json['permissions'])
          : null,
      lastChecked: json['lastCheck'] != null
          ? DateTime.parse(json['lastCheck'])
          : json['last_checked'] != null
              ? DateTime.parse(json['last_checked'])
              : null,
      error: json['error'],
    );
  }
}

class BinanceBalance {
  final double usdt;
  final String formatted;

  BinanceBalance({
    required this.usdt,
    required this.formatted,
  });

  factory BinanceBalance.fromJson(Map<String, dynamic> json) {
    return BinanceBalance(
      usdt: (json['usdt'] ?? 0).toDouble(),
      formatted: json['formatted'] ?? '',
    );
  }
}

class BinanceApiUpdateResponse {
  final bool success;
  final BinanceApiUpdateData data;

  BinanceApiUpdateResponse({
    required this.success,
    required this.data,
  });

  factory BinanceApiUpdateResponse.fromJson(Map<String, dynamic> json) {
    return BinanceApiUpdateResponse(
      success: json['success'] ?? false,
      data: BinanceApiUpdateData.fromJson(json['data']),
    );
  }
}

class BinanceApiUpdateData {
  final String message;
  final String connectionType;
  final BinanceConnectionStatus? connectionStatus;
  final BinanceConnectionStatus? accountInfo;

  BinanceApiUpdateData({
    required this.message,
    required this.connectionType,
    this.connectionStatus,
    this.accountInfo,
  });

  factory BinanceApiUpdateData.fromJson(Map<String, dynamic> json) {
    return BinanceApiUpdateData(
      message: json['message'] ?? '',
      connectionType: json['connection_type'] ?? '',
      connectionStatus: json['connection_status'] != null
          ? BinanceConnectionStatus.fromJson(json['connection_status'])
          : null,
      accountInfo: json['account_info'] != null
          ? BinanceConnectionStatus.fromJson(json['account_info'])
          : null,
    );
  }
}

class BinanceAccountInfoResponse {
  final bool success;
  final BinanceAccountInfo data;

  BinanceAccountInfoResponse({
    required this.success,
    required this.data,
  });

  factory BinanceAccountInfoResponse.fromJson(Map<String, dynamic> json) {
    return BinanceAccountInfoResponse(
      success: json['success'] ?? false,
      data: BinanceAccountInfo.fromJson(json['data']),
    );
  }
}

class BinanceAccountInfo {
  final String accountType;
  final double totalWalletBalance;
  final double totalUnrealizedProfit;
  final double totalMarginBalance;
  final List<BinanceAsset>? balances;
  final List<String>? permissions;
  final bool canTrade;
  final bool canWithdraw;
  final bool canDeposit;
  final int tradeGroupId;
  final DateTime updateTime;
  final String? accountAlias;

  BinanceAccountInfo({
    required this.accountType,
    required this.totalWalletBalance,
    required this.totalUnrealizedProfit,
    required this.totalMarginBalance,
    this.balances,
    this.permissions,
    required this.canTrade,
    required this.canWithdraw,
    required this.canDeposit,
    required this.tradeGroupId,
    required this.updateTime,
    this.accountAlias,
  });

  factory BinanceAccountInfo.fromJson(Map<String, dynamic> json) {
    return BinanceAccountInfo(
      accountType: json['accountType'] ?? 'SPOT',
      totalWalletBalance: (json['totalWalletBalance'] ?? 0).toDouble(),
      totalUnrealizedProfit: (json['totalUnrealizedProfit'] ?? 0).toDouble(),
      totalMarginBalance: (json['totalMarginBalance'] ?? 0).toDouble(),
      balances: json['balances'] != null
          ? (json['balances'] as List)
              .map((balance) => BinanceAsset.fromJson(balance))
              .toList()
          : null,
      permissions: json['permissions'] != null
          ? List<String>.from(json['permissions'])
          : null,
      canTrade: json['canTrade'] ?? false,
      canWithdraw: json['canWithdraw'] ?? false,
      canDeposit: json['canDeposit'] ?? false,
      tradeGroupId: json['tradeGroupId'] ?? 0,
      updateTime: json['updateTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updateTime'])
          : DateTime.now(),
      accountAlias: json['accountAlias'],
    );
  }
}

class BinanceAsset {
  final String asset;
  final double free;
  final double locked;
  final double total;

  BinanceAsset({
    required this.asset,
    required this.free,
    required this.locked,
    required this.total,
  });

  factory BinanceAsset.fromJson(Map<String, dynamic> json) {
    return BinanceAsset(
      asset: json['asset'] ?? '',
      free: (json['free'] ?? 0).toDouble(),
      locked: (json['locked'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
    );
  }
}

// Trading Settings Response Models
class TradingSettingsResponse {
  final bool success;
  final TradingSettingsData data;

  TradingSettingsResponse({
    required this.success,
    required this.data,
  });

  factory TradingSettingsResponse.fromJson(Map<String, dynamic> json) {
    return TradingSettingsResponse(
      success: json['success'] ?? false,
      data: TradingSettingsData.fromJson(json['data'] ?? {}),
    );
  }
}

class TradingSettingsData {
  final double maxLeverage;
  final bool dynamicLeverage;
  final double stopLossPercentage;
  final double takeProfitPercentage;
  final bool trailingStopEnabled;
  final double positionSizePercentage;
  final int maxConcurrentPositions;
  final bool autoPositionSizing;
  final bool autoTradingEnabled;
  final double minConfidenceThreshold;
  final bool nightTradingEnabled;
  final Map<String, dynamic>? advancedSettings;
  final DateTime lastUpdated;

  TradingSettingsData({
    required this.maxLeverage,
    required this.dynamicLeverage,
    required this.stopLossPercentage,
    required this.takeProfitPercentage,
    required this.trailingStopEnabled,
    required this.positionSizePercentage,
    required this.maxConcurrentPositions,
    required this.autoPositionSizing,
    required this.autoTradingEnabled,
    required this.minConfidenceThreshold,
    required this.nightTradingEnabled,
    this.advancedSettings,
    required this.lastUpdated,
  });

  factory TradingSettingsData.fromJson(Map<String, dynamic> json) {
    return TradingSettingsData(
      maxLeverage: (json['max_leverage'] ?? 5.0).toDouble(),
      dynamicLeverage: json['dynamic_leverage'] ?? false,
      stopLossPercentage: (json['stop_loss_percentage'] ?? 5.0).toDouble(),
      takeProfitPercentage: (json['take_profit_percentage'] ?? 15.0).toDouble(),
      trailingStopEnabled: json['trailing_stop_enabled'] ?? false,
      positionSizePercentage: (json['position_size_percentage'] ?? 5.0).toDouble(),
      maxConcurrentPositions: json['max_concurrent_positions'] ?? 3,
      autoPositionSizing: json['auto_position_sizing'] ?? false,
      autoTradingEnabled: json['auto_trading_enabled'] ?? false,
      minConfidenceThreshold: (json['min_confidence_threshold'] ?? 75.0).toDouble(),
      nightTradingEnabled: json['night_trading_enabled'] ?? false,
      advancedSettings: json['advanced_settings'],
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : DateTime.now(),
    );
  }
}

class TradingRiskAnalysisResponse {
  final bool success;
  final TradingRiskAnalysis data;

  TradingRiskAnalysisResponse({
    required this.success,
    required this.data,
  });

  factory TradingRiskAnalysisResponse.fromJson(Map<String, dynamic> json) {
    return TradingRiskAnalysisResponse(
      success: json['success'] ?? false,
      data: TradingRiskAnalysis.fromJson(json['data'] ?? {}),
    );
  }
}

class TradingRiskAnalysis {
  final String riskLevel; // Low, Medium, High
  final double riskScore;
  final double maxDailyLoss;
  final double maxDailyProfit;
  final double portfolioVaR; // Value at Risk
  final Map<String, double> riskFactors;
  final List<String> recommendations;
  final DateTime calculatedAt;

  TradingRiskAnalysis({
    required this.riskLevel,
    required this.riskScore,
    required this.maxDailyLoss,
    required this.maxDailyProfit,
    required this.portfolioVaR,
    required this.riskFactors,
    required this.recommendations,
    required this.calculatedAt,
  });

  factory TradingRiskAnalysis.fromJson(Map<String, dynamic> json) {
    return TradingRiskAnalysis(
      riskLevel: json['risk_level'] ?? 'Medium',
      riskScore: (json['risk_score'] ?? 50.0).toDouble(),
      maxDailyLoss: (json['max_daily_loss'] ?? 0.0).toDouble(),
      maxDailyProfit: (json['max_daily_profit'] ?? 0.0).toDouble(),
      portfolioVaR: (json['portfolio_var'] ?? 0.0).toDouble(),
      riskFactors: Map<String, double>.from(json['risk_factors'] ?? {}),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      calculatedAt: json['calculated_at'] != null
          ? DateTime.parse(json['calculated_at'])
          : DateTime.now(),
    );
  }
}

class TradingPerformanceResponse {
  final bool success;
  final TradingPerformance data;

  TradingPerformanceResponse({
    required this.success,
    required this.data,
  });

  factory TradingPerformanceResponse.fromJson(Map<String, dynamic> json) {
    return TradingPerformanceResponse(
      success: json['success'] ?? false,
      data: TradingPerformance.fromJson(json['data'] ?? {}),
    );
  }
}

class TradingPerformance {
  final int totalTrades;
  final int winningTrades;
  final int losingTrades;
  final double winRate;
  final double totalProfit;
  final double totalLoss;
  final double netProfit;
  final double averageWin;
  final double averageLoss;
  final double profitFactor;
  final double sharpeRatio;
  final double maxDrawdown;
  final List<DailyPerformance> dailyPerformance;

  TradingPerformance({
    required this.totalTrades,
    required this.winningTrades,
    required this.losingTrades,
    required this.winRate,
    required this.totalProfit,
    required this.totalLoss,
    required this.netProfit,
    required this.averageWin,
    required this.averageLoss,
    required this.profitFactor,
    required this.sharpeRatio,
    required this.maxDrawdown,
    required this.dailyPerformance,
  });

  factory TradingPerformance.fromJson(Map<String, dynamic> json) {
    return TradingPerformance(
      totalTrades: json['total_trades'] ?? 0,
      winningTrades: json['winning_trades'] ?? 0,
      losingTrades: json['losing_trades'] ?? 0,
      winRate: (json['win_rate'] ?? 0.0).toDouble(),
      totalProfit: (json['total_profit'] ?? 0.0).toDouble(),
      totalLoss: (json['total_loss'] ?? 0.0).toDouble(),
      netProfit: (json['net_profit'] ?? 0.0).toDouble(),
      averageWin: (json['average_win'] ?? 0.0).toDouble(),
      averageLoss: (json['average_loss'] ?? 0.0).toDouble(),
      profitFactor: (json['profit_factor'] ?? 0.0).toDouble(),
      sharpeRatio: (json['sharpe_ratio'] ?? 0.0).toDouble(),
      maxDrawdown: (json['max_drawdown'] ?? 0.0).toDouble(),
      dailyPerformance: (json['daily_performance'] as List? ?? [])
          .map((item) => DailyPerformance.fromJson(item))
          .toList(),
    );
  }
}

class DailyPerformance {
  final DateTime date;
  final double profit;
  final double profitPercent;
  final int trades;
  final int wins;
  final int losses;

  DailyPerformance({
    required this.date,
    required this.profit,
    required this.profitPercent,
    required this.trades,
    required this.wins,
    required this.losses,
  });

  factory DailyPerformance.fromJson(Map<String, dynamic> json) {
    return DailyPerformance(
      date: DateTime.parse(json['date']),
      profit: (json['profit'] ?? 0.0).toDouble(),
      profitPercent: (json['profit_percent'] ?? 0.0).toDouble(),
      trades: json['trades'] ?? 0,
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
    );
  }
}

// User Profile Response Models
class UserProfileResponse {
  final bool success;
  final UserProfileData data;

  UserProfileResponse({
    required this.success,
    required this.data,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      success: json['success'] ?? false,
      data: UserProfileData.fromJson(json['data'] ?? {}),
    );
  }
}

class UserProfileData {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final String subscriptionTier;
  final String subscriptionStatus;
  final String experienceLevel;
  final String riskTolerance;
  final List<String> preferredCoins;
  final String? investmentGoal;
  final double? monthlyBudget;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? additionalSettings;

  UserProfileData({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.subscriptionTier,
    required this.subscriptionStatus,
    required this.experienceLevel,
    required this.riskTolerance,
    required this.preferredCoins,
    this.investmentGoal,
    this.monthlyBudget,
    required this.createdAt,
    required this.updatedAt,
    this.additionalSettings,
  });

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['display_name'] ?? '',
      photoURL: json['photo_url'],
      subscriptionTier: json['subscription_tier'] ?? 'free',
      subscriptionStatus: json['subscription_status'] ?? 'active',
      experienceLevel: json['experience_level'] ?? 'beginner',
      riskTolerance: json['risk_tolerance'] ?? 'conservative',
      preferredCoins: List<String>.from(json['preferred_coins'] ?? []),
      investmentGoal: json['investment_goal'],
      monthlyBudget: json['monthly_budget']?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      additionalSettings: json['additional_settings'],
    );
  }
}

class AuthenticationResponse {
  final bool success;
  final AuthenticationData data;

  AuthenticationResponse({
    required this.success,
    required this.data,
  });

  factory AuthenticationResponse.fromJson(Map<String, dynamic> json) {
    return AuthenticationResponse(
      success: json['success'] ?? false,
      data: AuthenticationData.fromJson(json['data'] ?? {}),
    );
  }
}

class AuthenticationData {
  final String token;
  final UserProfileData user;
  final DateTime expiresAt;

  AuthenticationData({
    required this.token,
    required this.user,
    required this.expiresAt,
  });

  factory AuthenticationData.fromJson(Map<String, dynamic> json) {
    return AuthenticationData(
      token: json['token'] ?? '',
      user: UserProfileData.fromJson(json['user'] ?? {}),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : DateTime.now().add(const Duration(hours: 24)),
    );
  }
}

class UserRegistrationResponse {
  final bool success;
  final UserRegistrationData data;

  UserRegistrationResponse({
    required this.success,
    required this.data,
  });

  factory UserRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return UserRegistrationResponse(
      success: json['success'] ?? false,
      data: UserRegistrationData.fromJson(json['data'] ?? {}),
    );
  }
}

class UserRegistrationData {
  final String message;
  final UserProfileData user;
  final bool requiresVerification;
  final String? verificationMethod;

  UserRegistrationData({
    required this.message,
    required this.user,
    required this.requiresVerification,
    this.verificationMethod,
  });

  factory UserRegistrationData.fromJson(Map<String, dynamic> json) {
    return UserRegistrationData(
      message: json['message'] ?? '',
      user: UserProfileData.fromJson(json['user'] ?? {}),
      requiresVerification: json['requires_verification'] ?? false,
      verificationMethod: json['verification_method'],
    );
  }
}

// Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  final apiService = ApiService();
  ref.onDispose(() => apiService.dispose());
  return apiService;
});

// Real-time data providers - 즉시 로드 후 주기적 갱신
final marketDataProvider = StreamProvider<MarketDataResponse>((ref) async* {
  final apiService = ref.watch(apiServiceProvider);

  // 즉시 첫 데이터 로드 (백엔드 연결 필수)
  try {
    yield await apiService.getMarketData();
  } catch (e) {
    print('❌ [Market Data] 백엔드 서버 연결 실패: $e');
    print('⚠️ 백엔드 서버를 시작하세요: cd backend && ./start_server.sh');
    throw ApiException('백엔드 서버에 연결할 수 없습니다. 서버를 시작하세요.');
  }

  // 이후 30초마다 갱신
  await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
    try {
      yield await apiService.getMarketData();
    } catch (e) {
      print('⚠️ [Market Data] 백엔드 연결 실패: $e');
      // 에러는 던지지 않고 마지막 데이터 유지
    }
  }
});

final tradingSignalsProvider = StreamProvider<TradingSignalsResponse>((ref) async* {
  final apiService = ref.watch(apiServiceProvider);

  // 즉시 첫 데이터 로드 (백엔드 연결 필수)
  try {
    yield await apiService.getTradingSignals();
  } catch (e) {
    print('❌ [Trading Signals] 백엔드 서버 연결 실패: $e');
    print('⚠️ 백엔드 서버를 시작하세요: cd backend && ./start_server.sh');
    throw ApiException('백엔드 서버에 연결할 수 없습니다. AI 시그널을 생성하려면 서버를 시작하세요.');
  }

  // 이후 1분마다 갱신
  await for (final _ in Stream.periodic(const Duration(minutes: 1))) {
    try {
      yield await apiService.getTradingSignals();
    } catch (e) {
      print('⚠️ [Trading Signals] 백엔드 연결 실패: $e');
      // 에러는 던지지 않고 마지막 데이터 유지
    }
  }
});

final portfolioSummaryProvider = StreamProvider<PortfolioSummaryResponse>((ref) async* {
  final apiService = ref.watch(apiServiceProvider);

  // 즉시 첫 데이터 로드 (백엔드 연결 필수)
  try {
    yield await apiService.getPortfolioSummary();
  } catch (e) {
    print('❌ [Portfolio Summary] 백엔드 서버 연결 실패: $e');
    print('⚠️ 백엔드 서버를 시작하세요: cd backend && ./start_server.sh');
    throw ApiException('백엔드 서버에 연결할 수 없습니다. 포트폴리오 데이터를 가져오려면 서버를 시작하세요.');
  }

  // 이후 30초마다 갱신
  await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
    try {
      yield await apiService.getPortfolioSummary();
    } catch (e) {
      print('⚠️ [Portfolio Summary] 백엔드 연결 실패: $e');
      // 에러는 던지지 않고 마지막 데이터 유지
    }
  }
});

// 병렬 로딩용 프로바이더는 dashboard_provider.dart에서 정의됨