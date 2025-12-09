import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/storage_service.dart';
import '../models/portfolio_model.dart';

class PortfolioService {
  static final String _baseUrl = AppConstants.apiBaseUrl;

  // 포트폴리오 전체 정보 가져오기 (실제 API 연동)
  Future<PortfolioModel> getPortfolio(String userId) async {
    try {
      print('🚀 [포트폴리오 서비스] 포트폴리오 데이터 요청 시작: $userId');

      // 먼저 바이낸스 API 키 확인
      final storage = StorageService.instance;
      final binanceKeyData = await storage.loadBinanceApiKeys();

      if (binanceKeyData != null && binanceKeyData['hasApiKey'] == true) {
        print('🔗 바이낸스 연결됨 - 실제 포트폴리오 데이터 가져오기 시도');

        // 먼저 백엔드를 통해 시도
        try {
          final binancePortfolio = await _getBinancePortfolio(userId, binanceKeyData);
          if (binancePortfolio != null) {
            print('✅ 백엔드를 통한 바이낸스 포트폴리오 데이터 로드 성공');
            return binancePortfolio;
          }
        } catch (backendError) {
          print('⚠️ 백엔드 연결 실패 - 직접 바이낸스 API 호출 시도: $backendError');
        }

        // 백엔드 실패 시 직접 바이낸스 API 호출
        print('🔄 [포트폴리오 서비스] 직접 바이낸스 API 호출로 전환...');
        return await _getDirectBinancePortfolioData(userId);
      }

      print('⚠️ 바이낸스가 연결되지 않음 - 빈 포트폴리오 반환');
      return _createEmptyPortfolio(userId);

    } catch (e) {
      print('❌ [포트폴리오 서비스] 에러 발생: $e');
      // 에러 발생 시에도 빈 포트폴리오 반환 (더미 데이터 제거)
      return _createEmptyPortfolio(userId);
    }
  }

  // 바이낸스 API를 통한 실시간 포트폴리오 동기화
  Future<PortfolioModel> syncPortfolioWithBinance(String userId, {
    String? apiKey,
    String? secretKey,
    bool isTestnet = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/portfolio/$userId/sync'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'apiKey': apiKey,
          'secretKey': secretKey,
          'isTestnet': isTestnet,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return PortfolioModel.fromJson(data);
      } else {
        throw Exception('Failed to sync portfolio: ${response.statusCode}');
      }
    } catch (e) {
      print('Error syncing portfolio: $e');
      // 동기화 실패 시 빈 포트폴리오 반환
      return _createEmptyPortfolio(userId);
    }
  }

  // 자산 보유 현황 가져오기
  Future<List<AssetHolding>> getHoldings(String userId) async {
    try {
      // 포트폴리오 전체 정보에서 보유 자산 추출
      final portfolio = await getPortfolio(userId);
      return portfolio.holdings;
    } catch (e) {
      print('❌ [보유 자산] 에러 발생: $e');
      return []; // 더미 데이터 대신 빈 목록 반환
    }
  }

  // 거래 내역 가져오기
  Future<List<Transaction>> getTransactions(String userId, {
    int limit = 50,
    int offset = 0,
    String? symbol,
    TransactionSide? side,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      print('🔍 [거래 내역] 조회 시작: $userId');

      // 백엔드 API를 통해 거래 내역 가져오기 시도
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      if (symbol != null) queryParams['symbol'] = symbol;
      if (side != null) queryParams['side'] = side.toString().split('.').last;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final uri = Uri.parse('$_baseUrl/api/user/$userId/transactions').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> transactionsData = data['data'] as List<dynamic>? ?? [];

          print('✅ [거래 내역] 백엔드에서 ${transactionsData.length}개 조회 성공');

          return transactionsData
              .map((item) => Transaction.fromJson(item))
              .toList();
        } else {
          print('⚠️ [거래 내역] 백엔드 응답 실패: ${data['error'] ?? 'Unknown error'}');
        }
      } else {
        print('❌ [거래 내역] HTTP 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [거래 내역] 에러 발생: $e');
    }

    // 실패 시 빈 목록 반환 (더미 데이터 제거)
    print('📭 [거래 내역] 빈 목록 반환');
    return [];
  }

  // 포트폴리오 성과 데이터 가져오기
  Future<PortfolioPerformance> getPortfolioPerformance(String userId, String period) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/portfolio/$userId/performance/$period'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return PortfolioPerformance.fromJson(data);
      } else {
        throw Exception('Failed to load portfolio performance: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching portfolio performance: $e');
      // 실패 시 기본 성과 데이터 반환
      return PortfolioPerformance(
        period: period,
        dataPoints: [],
        totalReturn: 0.0,
        totalReturnPercent: 0.0,
        volatility: 0.0,
        sharpeRatio: 0.0,
        maxDrawdown: 0.0,
      );
    }
  }

  // 자산별 성과 분석
  Future<Map<String, dynamic>> getAssetAnalysis(String userId, String symbol) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/portfolio/$userId/analysis/$symbol'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load asset analysis: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching asset analysis: $e');
      return {};
    }
  }

  // 포트폴리오 리밸런싱 제안
  Future<Map<String, dynamic>> getRebalancingSuggestions(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/portfolio/$userId/rebalancing'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load rebalancing suggestions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching rebalancing suggestions: $e');
      return {};
    }
  }

  // 포트폴리오 백테스팅
  Future<Map<String, dynamic>> runBacktest(String userId, Map<String, dynamic> strategy) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/portfolio/$userId/backtest'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(strategy),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to run backtest: ${response.statusCode}');
      }
    } catch (e) {
      print('Error running backtest: $e');
      return {};
    }
  }

  // 실시간 가격 업데이트
  Future<Map<String, double>> getRealTimePrices(List<String> symbols) async {
    try {
      print('📈 [실시간 가격] 조회 시작: ${symbols.join(', ')}');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/market/prices'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'symbols': symbols}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final pricesData = Map<String, double>.from(data['data']['prices'] ?? {});
          print('✅ [실시간 가격] ${pricesData.length}개 가격 조회 성공');
          return pricesData;
        } else {
          print('⚠️ [실시간 가격] 백엔드 응답 실패: ${data['error'] ?? 'Unknown error'}');
        }
      } else {
        print('❌ [실시간 가격] HTTP 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [실시간 가격] 에러 발생: $e');
    }

    // 실패 시 빈 맵 반환 (더미 데이터 제거)
    print('📭 [실시간 가격] 빈 맵 반환');
    return {};
  }

  // ===========================
  // 더미 데이터 메서드들을 모두 제거
  // 실제 API 연동으로 대체됨
  // ===========================

  // 바이낸스 실제 포트폴리오 데이터 가져오기 (백엔드 API 사용)
  Future<PortfolioModel?> _getBinancePortfolio(String userId, Map<String, dynamic> binanceKeyData) async {
    try {
      final apiKey = binanceKeyData['apiKey'] as String;
      final secretKey = binanceKeyData['secretKey'] as String;
      final isTestnet = binanceKeyData['isTestnet'] as bool;

      print('🚀 백엔드 API를 통해 실제 바이낸스 포트폴리오 요청 시작...');
      print('📊 사용자 ID: $userId');
      print('📊 모드: ${isTestnet ? 'TESTNET' : 'MAINNET'}');

      // 백엔드 API를 통해 실제 바이낸스 포트폴리오 가져오기
      final response = await http.get(
        Uri.parse('$_baseUrl/api/portfolio/summary?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('✅ 백엔드 API에서 포트폴리오 데이터 수신 성공');
        print('📄 응답 데이터: ${data.toString()}');

        if (data['success'] == true && data['data'] != null) {
          final portfolioData = data['data'] as Map<String, dynamic>;

          // 빈 포트폴리오인지 확인 - 'holdings' 키 사용 (백엔드와 일치)
          final holdings = portfolioData['holdings'] as List<dynamic>? ?? [];
          if (holdings.isEmpty) {
            print('💰 [백엔드] 빈 포트폴리오 확인됨 - 실제 계정 상태 반영');
            return _createEmptyPortfolio(userId);
          } else {
            print('💰 [백엔드] 보유 자산 발견: ${holdings.length}개');

            // 각 자산 정보 출력
            for (final holding in holdings) {
              final holdingData = holding as Map<String, dynamic>;
              print('  • ${holdingData['symbol']}: ${holdingData['amount']} = \$${holdingData['value_usdt']}');
            }

            return _convertBackendDataToPortfolio(userId, portfolioData);
          }
        } else {
          print('❌ 백엔드 API 응답 실패: ${data['error'] ?? 'Unknown error'}');
          return null;
        }
      } else {
        print('❌ 백엔드 API 호출 실패: ${response.statusCode}');
        print('📄 응답 내용: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ 백엔드 API를 통한 포트폴리오 데이터 가져오기 실패: $e');
      return null;
    }
  }

  // 빈 포트폴리오 생성
  PortfolioModel _createEmptyPortfolio(String userId) {
    return PortfolioModel(
      userId: userId,
      totalValue: 0.0,
      totalBalance: 0.0,
      totalPnl: 0.0,
      totalPnlPercent: 0.0,
      holdings: [],
      transactions: [],
      allocation: {},
      stats: PortfolioStats(
        totalInvested: 0.0,
        totalWithdrawn: 0.0,
        realizedPnl: 0.0,
        unrealizedPnl: 0.0,
        totalFees: 0.0,
        totalTrades: 0,
        winningTrades: 0,
        losingTrades: 0,
        winRate: 0.0,
        averageWin: 0.0,
        averageLoss: 0.0,
        largestWin: 0.0,
        largestLoss: 0.0,
        sharpeRatio: 0.0,
        maxDrawdown: 0.0,
        monthlyReturns: {},
        firstTradeDate: DateTime.now(),
      ),
      lastUpdated: DateTime.now(),
    );
  }

  // 백엔드 데이터를 포트폴리오 모델로 변환
  PortfolioModel _convertBackendDataToPortfolio(String userId, Map<String, dynamic> backendData) {
    try {
      // 'holdings' 키 사용 (백엔드와 일치)
      final holdingsData = backendData['holdings'] as List<dynamic>? ?? [];
      final holdings = <AssetHolding>[];
      final totalBalanceUsd = (backendData['total_balance'] as num?)?.toDouble() ?? 0.0;

      print('🔄 [백엔드 데이터 변환] 시작...');
      print('  📊 총 자산: \$${totalBalanceUsd}');
      print('  📊 자산 개수: ${holdingsData.length}');

      for (final holdingItem in holdingsData) {
        final holdingData = holdingItem as Map<String, dynamic>;
        final symbol = holdingData['symbol'] ?? '';
        final amount = (holdingData['amount'] as num?)?.toDouble() ?? 0.0;
        final currentPrice = (holdingData['price_usdt'] as num?)?.toDouble() ?? 0.0;
        final usdValue = (holdingData['value_usdt'] as num?)?.toDouble() ?? 0.0;

        // 포트폴리오 내 비중 계산
        final percentageOfPortfolio = totalBalanceUsd > 0 ? (usdValue / totalBalanceUsd) * 100 : 0.0;

        print('  • $symbol: $amount × \$${currentPrice} = \$${usdValue} (${percentageOfPortfolio.toStringAsFixed(1)}%)');

        holdings.add(AssetHolding(
          symbol: symbol,
          name: holdingData['name'] ?? symbol,
          quantity: amount,
          averagePrice: currentPrice, // 평균 매입가는 현재가로 임시 설정 (나중에 개선)
          currentPrice: currentPrice,
          value: usdValue,
          pnl: (holdingData['profit'] as num?)?.toDouble() ?? 0.0,
          pnlPercent: (holdingData['profit_percent'] as num?)?.toDouble() ?? 0.0,
          percentageOfPortfolio: percentageOfPortfolio,
          lastUpdated: DateTime.now(),
        ));
      }

      // 포트폴리오 분배 계산
      final allocation = <String, double>{};
      for (final holding in holdings) {
        allocation[holding.symbol] = holding.percentageOfPortfolio;
      }

      final totalPnl = (backendData['total_pnl'] as num?)?.toDouble() ?? 0.0;
      final totalPnlPercent = (backendData['total_pnl_percent'] as num?)?.toDouble() ?? 0.0;

      final portfolio = PortfolioModel(
        userId: userId,
        totalValue: totalBalanceUsd,
        totalBalance: totalBalanceUsd,
        totalPnl: totalPnl,
        totalPnlPercent: totalPnlPercent,
        holdings: holdings,
        transactions: [], // 거래 내역은 별도 API에서 가져옴
        allocation: allocation,
        stats: PortfolioStats(
          totalInvested: totalBalanceUsd - totalPnl, // 실제 투자금액 = 현재가치 - 손익
          totalWithdrawn: 0.0,
          realizedPnl: 0.0,
          unrealizedPnl: totalPnl,
          totalFees: 0.0,
          totalTrades: 0,
          winningTrades: 0,
          losingTrades: 0,
          winRate: 0.0,
          averageWin: 0.0,
          averageLoss: 0.0,
          largestWin: 0.0,
          largestLoss: 0.0,
          sharpeRatio: 0.0,
          maxDrawdown: 0.0,
          monthlyReturns: {},
          firstTradeDate: DateTime.now().subtract(const Duration(days: 30)), // 임시값
        ),
        lastUpdated: DateTime.now(),
      );

      print('✅ [백엔드 데이터 변환] 완료');
      print('  📊 최종 포트폴리오 총 가치: \$${portfolio.totalValue}');
      print('  📊 최종 보유 자산 수: ${portfolio.holdings.length}');

      return portfolio;
    } catch (e) {
      print('❌ 백엔드 데이터 변환 실패: $e');
      return _createEmptyPortfolio(userId);
    }
  }

  // 직접 바이낸스 API 호출로 포트폴리오 데이터 가져오기
  Future<PortfolioModel> _getDirectBinancePortfolioData(String userId) async {
    try {
      print('🚀 [직접 바이낸스] 포트폴리오 조회 시작...');

      final storage = StorageService.instance;
      final binanceKeyData = await storage.loadBinanceApiKeys();

      if (binanceKeyData == null || binanceKeyData['hasApiKey'] != true) {
        print('❌ [직접 바이낸스] API 키가 없습니다');
        return _createEmptyPortfolio(userId);
      }

      final apiKey = binanceKeyData['apiKey'] as String;
      final secretKey = binanceKeyData['secretKey'] as String;
      final isTestnet = binanceKeyData['isTestnet'] as bool;

      print('🔑 [직접 바이낸스] API 키: ${apiKey.substring(0, 8)}...');
      print('🌐 [직접 바이낸스] 모드: ${isTestnet ? "TESTNET" : "MAINNET"}');

      // 바이낸스 계정 정보 가져오기
      final accountInfo = await _getBinanceAccountInfo(apiKey, secretKey, isTestnet);
      if (accountInfo == null) {
        print('❌ [직접 바이낸스] 계정 정보 가져오기 실패');
        return _createEmptyPortfolio(userId);
      }

      // 포트폴리오 데이터 변환
      return await _convertBinanceAccountToPortfolio(userId, accountInfo, isTestnet);

    } catch (e) {
      print('❌ [직접 바이낸스] 오류 발생: $e');
      return _createEmptyPortfolio(userId);
    }
  }

  // 바이낸스 계정 정보 가져오기
  Future<Map<String, dynamic>?> _getBinanceAccountInfo(String apiKey, String secretKey, bool isTestnet) async {
    try {
      final baseUrl = isTestnet
        ? 'https://testnet.binance.vision'
        : 'https://api.binance.com';

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final queryString = 'timestamp=$timestamp';

      // HMAC SHA256 서명 생성
      final signature = _generateSignature(queryString, secretKey);

      final uri = Uri.parse('$baseUrl/api/v3/account?$queryString&signature=$signature');

      print('🌐 [직접 바이낸스] API 호출: ${uri.toString().replaceAll(RegExp(r'signature=.*'), 'signature=***')}');

      final response = await http.get(
        uri,
        headers: {
          'X-MBX-APIKEY': apiKey,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        print('✅ [직접 바이낸스] 계정 정보 조회 성공');

        final balances = data['balances'] as List<dynamic>? ?? [];
        print('📊 [직접 바이낸스] 잔고 항목 수: ${balances.length}');

        // 0이 아닌 잔고만 필터링
        final nonZeroBalances = balances.where((balance) {
          final free = double.tryParse(balance['free']?.toString() ?? '0') ?? 0;
          final locked = double.tryParse(balance['locked']?.toString() ?? '0') ?? 0;
          return (free + locked) > 0;
        }).toList();

        print('💰 [직접 바이낸스] 보유 자산 수: ${nonZeroBalances.length}');

        return {
          'balances': nonZeroBalances,
          'accountType': data['accountType'] ?? 'SPOT',
          'canTrade': data['canTrade'] ?? true,
        };
      } else {
        print('❌ [직접 바이낸스] API 호출 실패: ${response.statusCode}');
        print('📄 [직접 바이낸스] 에러 응답: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ [직접 바이낸스] 계정 정보 가져오기 실패: $e');
      return null;
    }
  }

  // HMAC SHA256 서명 생성
  String _generateSignature(String queryString, String secretKey) {
    final key = utf8.encode(secretKey);
    final bytes = utf8.encode(queryString);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }

  // 바이낸스에서 심볼 가격 조회
  Future<double> _getBinancePrice(String symbol, bool isTestnet) async {
    try {
      final baseUrl = isTestnet
        ? 'https://testnet.binance.vision'
        : 'https://api.binance.com';

      // USDT 페어로 가격 조회
      final pair = '${symbol}USDT';
      final uri = Uri.parse('$baseUrl/api/v3/ticker/price?symbol=$pair');

      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final price = double.tryParse(data['price']?.toString() ?? '0') ?? 0;
        print('💵 [가격 조회] $symbol = \$$price');
        return price;
      }
    } catch (e) {
      print('⚠️ [가격 조회 실패] $symbol: $e');
    }
    return 0.0;
  }

  // 바이낸스 계정 정보를 포트폴리오 모델로 변환
  Future<PortfolioModel> _convertBinanceAccountToPortfolio(String userId, Map<String, dynamic> accountInfo, bool isTestnet) async {
    try {
      final balances = accountInfo['balances'] as List<dynamic>? ?? [];
      final holdings = <AssetHolding>[];

      print('🔄 [바이낸스 변환] 계정 정보 변환 시작...');

      double totalValueUsd = 0.0;

      for (final balance in balances) {
        final asset = balance['asset']?.toString() ?? '';
        final free = double.tryParse(balance['free']?.toString() ?? '0') ?? 0;
        final locked = double.tryParse(balance['locked']?.toString() ?? '0') ?? 0;
        final total = free + locked;

        if (total > 0 && asset.isNotEmpty) {
          print('💰 [바이낸스 변환] $asset: $total');

          // 실제 가격 조회
          double currentPrice = 1.0;
          if (asset == 'USDT' || asset == 'USDC' || asset == 'BUSD') {
            currentPrice = 1.0; // 스테이블코인은 1달러
          } else {
            // 다른 자산은 실시간 가격 조회
            currentPrice = await _getBinancePrice(asset, isTestnet);
          }

          final value = currentPrice * total;
          totalValueUsd += value;

          holdings.add(AssetHolding(
            symbol: asset,
            name: _getAssetName(asset),
            quantity: total,
            averagePrice: currentPrice,
            currentPrice: currentPrice,
            value: value,
            pnl: 0.0, // 실제 PnL 계산은 추가 구현 필요
            pnlPercent: 0.0,
            percentageOfPortfolio: 0.0, // 나중에 계산
            lastUpdated: DateTime.now(),
          ));
        }
      }

      // 포트폴리오 비중 계산
      if (totalValueUsd > 0) {
        for (int i = 0; i < holdings.length; i++) {
          holdings[i] = AssetHolding(
            symbol: holdings[i].symbol,
            name: holdings[i].name,
            quantity: holdings[i].quantity,
            averagePrice: holdings[i].averagePrice,
            currentPrice: holdings[i].currentPrice,
            value: holdings[i].value,
            pnl: holdings[i].pnl,
            pnlPercent: holdings[i].pnlPercent,
            percentageOfPortfolio: (holdings[i].value / totalValueUsd) * 100,
            lastUpdated: holdings[i].lastUpdated,
          );
        }
      }

      final allocation = <String, double>{};
      for (final holding in holdings) {
        allocation[holding.symbol] = holding.percentageOfPortfolio;
      }

      final portfolio = PortfolioModel(
        userId: userId,
        totalValue: totalValueUsd,
        totalBalance: totalValueUsd,
        totalPnl: 0.0, // 실제 PnL 계산은 추가 구현 필요
        totalPnlPercent: 0.0,
        holdings: holdings,
        transactions: [],
        allocation: allocation,
        stats: PortfolioStats(
          totalInvested: totalValueUsd,
          totalWithdrawn: 0.0,
          realizedPnl: 0.0,
          unrealizedPnl: 0.0,
          totalFees: 0.0,
          totalTrades: 0,
          winningTrades: 0,
          losingTrades: 0,
          winRate: 0.0,
          averageWin: 0.0,
          averageLoss: 0.0,
          largestWin: 0.0,
          largestLoss: 0.0,
          sharpeRatio: 0.0,
          maxDrawdown: 0.0,
          monthlyReturns: {},
          firstTradeDate: DateTime.now(),
        ),
        lastUpdated: DateTime.now(),
      );

      print('✅ [바이낸스 변환] 완료');
      print('  📊 총 가치: \$${portfolio.totalValue}');
      print('  📊 보유 자산 수: ${portfolio.holdings.length}');

      return portfolio;
    } catch (e) {
      print('❌ [바이낸스 변환] 실패: $e');
      return _createEmptyPortfolio(userId);
    }
  }

  // 자산명 매핑
  String _getAssetName(String symbol) {
    const assetNames = {
      'BTC': 'Bitcoin',
      'ETH': 'Ethereum',
      'BNB': 'BNB',
      'USDT': 'Tether',
      'USDC': 'USD Coin',
      'ADA': 'Cardano',
      'SOL': 'Solana',
      'DOT': 'Polkadot',
      'DOGE': 'Dogecoin',
      'MATIC': 'Polygon',
      'SHIB': 'Shiba Inu',
      'AVAX': 'Avalanche',
      'LTC': 'Litecoin',
    };
    return assetNames[symbol] ?? symbol;
  }

  // 백엔드 연결 테스트용 메서드
  Future<String> testBackendConnection(String userId) async {
    try {
      print('🌐 [백엔드 테스트] 연결 테스트 시작: $userId');

      final response = await http.get(
        Uri.parse('$_baseUrl/api/user/$userId/portfolio'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      print('📊 [백엔드 테스트] 응답 상태: ${response.statusCode}');
      print('📊 [백엔드 테스트] 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        return '백엔드 연결 성공 (${response.statusCode})';
      } else {
        return '백엔드 연결 실패 (${response.statusCode}): ${response.body}';
      }
    } catch (e) {
      print('❌ [백엔드 테스트] 연결 실패: $e');
      return '백엔드 연결 오류: $e';
    }
  }

}