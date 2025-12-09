import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../models/news_model.dart';

class NewsService {
  static final String _baseUrl = AppConstants.apiBaseUrl;

  // 최신 뉴스 가져오기 (실제 크롤링된 데이터)
  Future<List<NewsModel>> getLatestNews({
    int limit = 20,
    List<String>? categories,
    List<String>? sources,
  }) async {
    try {
      print('🔄 [뉴스] 실제 백엔드에서 최신 뉴스 조회 시작...');

      final queryParams = <String, String>{
        'limit': limit.toString(),
      };

      if (categories != null && categories.isNotEmpty) {
        queryParams['categories'] = categories.join(',');
      }

      if (sources != null && sources.isNotEmpty) {
        queryParams['sources'] = sources.join(',');
      }

      final uri = Uri.parse('$_baseUrl/api/news/latest').replace(
        queryParameters: queryParams,
      );

      print('🌐 [뉴스] API 요청 URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📡 [뉴스] 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        print('📊 [뉴스] 받은 데이터: ${responseData.toString().substring(0, 200)}...');

        List<dynamic> newsData;

        // 응답 데이터 형식에 따라 처리
        if (responseData is List) {
          newsData = responseData;
        } else if (responseData is Map && responseData['news'] != null) {
          newsData = responseData['news'];
        } else {
          print('⚠️ [뉴스] 예상치 못한 응답 형식, 빈 리스트 반환');
          newsData = [];
        }

        final news = newsData
            .map((item) => NewsModel.fromJson(item))
            .toList();

        print('✅ [뉴스] 성공적으로 ${news.length}개의 실제 뉴스 로드됨');
        return news;
      } else {
        print('❌ [뉴스] API 오류: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [뉴스] 실제 API 호출 실패, 빈 리스트 반환: $e');
      // 더미 데이터 대신 빈 리스트 반환
      return [];
    }
  }

  // 주요 뉴스 가져오기 (투자 민감 정보 5분 주기 크롤링)
  Future<List<NewsModel>> getBreakingNews() async {
    try {
      print('🔄 [주요뉴스] 실제 백엔드에서 주요 뉴스 조회 시작...');

      final response = await http.get(
        Uri.parse('$_baseUrl/api/news/breaking'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📡 [주요뉴스] 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        print('📊 [주요뉴스] 받은 데이터: ${responseData.toString().substring(0, 200)}...');

        List<dynamic> newsData;

        // 응답 데이터 형식에 따라 처리
        if (responseData is List) {
          newsData = responseData;
        } else if (responseData is Map && responseData['news'] != null) {
          newsData = responseData['news'];
        } else {
          print('⚠️ [주요뉴스] 예상치 못한 응답 형식, 빈 리스트 반환');
          newsData = [];
        }

        final news = newsData
            .map((item) => NewsModel.fromJson(item))
            .toList();

        print('✅ [주요뉴스] 성공적으로 ${news.length}개의 실제 주요 뉴스 로드됨');
        return news;
      } else {
        print('❌ [주요뉴스] API 오류: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load breaking news: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [주요뉴스] 실제 API 호출 실패, 빈 리스트 반환: $e');
      // 더미 데이터 대신 빈 리스트 반환
      return [];
    }
  }

  // 카테고리별 뉴스 가져오기
  Future<Map<String, List<NewsModel>>> getNewsByCategory() async {
    try {
      print('🔄 [카테고리뉴스] 실제 백엔드에서 카테고리별 뉴스 조회 시작...');

      final response = await http.get(
        Uri.parse('$_baseUrl/api/news/by-category'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📡 [카테고리뉴스] 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Map<String, List<NewsModel>> categorizedNews = {};

        data.forEach((category, newsData) {
          if (newsData is List) {
            categorizedNews[category] = newsData
                .map((item) => NewsModel.fromJson(item))
                .toList();
          }
        });

        print('✅ [카테고리뉴스] 성공적으로 ${categorizedNews.length}개 카테고리의 뉴스 로드됨');
        return categorizedNews;
      } else {
        print('❌ [카테고리뉴스] API 오류: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load categorized news: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [카테고리뉴스] 실제 API 호출 실패, 빈 맵 반환: $e');
      // 더미 데이터 대신 빈 맵 반환
      return {};
    }
  }

  // 마켓 인사이트 가져오기
  Future<MarketInsightData> getMarketInsights() async {
    try {
      print('🔄 [마켓인사이트] 실제 백엔드에서 시장 분석 데이터 조회 시작...');

      final response = await http.get(
        Uri.parse('$_baseUrl/api/market/insights'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📡 [마켓인사이트] 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('📊 [마켓인사이트] 받은 데이터: ${data.toString().substring(0, 200)}...');

        final insights = MarketInsightData.fromJson(data);
        print('✅ [마켓인사이트] 성공적으로 시장 분석 데이터 로드됨');
        return insights;
      } else {
        print('❌ [마켓인사이트] API 오류: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load market insights: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [마켓인사이트] 실제 API 호출 실패, 기본값 반환: $e');
      // 더미 데이터 대신 기본값 반환
      return MarketInsightData(
        fearGreedIndex: 0,
        fearGreedLabel: '데이터 없음',
        marketSentiment: 'unknown',
        tradingVolume24h: 0.0,
        volumeChange24h: 0.0,
        institutionalFlow: 0.0,
        institutionalFlowChange: 0.0,
        dominanceData: {},
        topGainers: [],
        topLosers: [],
      );
    }
  }

  // 뉴스 검색
  Future<List<NewsModel>> searchNews({
    required String query,
    int limit = 20,
    List<String>? categories,
  }) async {
    try {
      print('🔄 [뉴스검색] 실제 백엔드에서 뉴스 검색 시작: "$query"');

      final queryParams = <String, String>{
        'q': query,
        'limit': limit.toString(),
      };

      if (categories != null && categories.isNotEmpty) {
        queryParams['categories'] = categories.join(',');
      }

      final uri = Uri.parse('$_baseUrl/api/news/search').replace(
        queryParameters: queryParams,
      );

      print('🌐 [뉴스검색] API 요청 URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📡 [뉴스검색] 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        List<dynamic> newsData;

        // 응답 데이터 형식에 따라 처리
        if (responseData is List) {
          newsData = responseData;
        } else if (responseData is Map && responseData['news'] != null) {
          newsData = responseData['news'];
        } else {
          print('⚠️ [뉴스검색] 예상치 못한 응답 형식, 빈 리스트 반환');
          newsData = [];
        }

        final searchResults = newsData
            .map((item) => NewsModel.fromJson(item))
            .toList();

        print('✅ [뉴스검색] 성공적으로 ${searchResults.length}개의 검색 결과 로드됨');
        return searchResults;
      } else {
        print('❌ [뉴스검색] API 오류: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to search news: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [뉴스검색] 실제 API 호출 실패, 빈 리스트 반환: $e');
      return [];
    }
  }

  // 뉴스 통계 가져오기 (실제 크롤링 통계)
  Future<NewsStatsData> getNewsStats() async {
    try {
      print('🔄 [뉴스통계] 실제 백엔드에서 뉴스 통계 조회 시작...');

      final response = await http.get(
        Uri.parse('$_baseUrl/api/news/stats'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📡 [뉴스통계] 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('📊 [뉴스통계] 받은 데이터: ${data.toString().substring(0, 200)}...');

        final stats = NewsStatsData.fromJson(data);
        print('✅ [뉴스통계] 성공적으로 뉴스 통계 로드됨');
        return stats;
      } else {
        print('❌ [뉴스통계] API 오류: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load news stats: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [뉴스통계] 실제 API 호출 실패, 기본값 반환: $e');
      // 더미 데이터 대신 기본값 반환
      return NewsStatsData(
        totalNewsToday: 0,
        breakingNewsCount: 0,
        categoryStats: {},
        sentimentBreakdown: {},
        lastUpdated: DateTime.now(),
      );
    }
  }


  // 크롤링 상태 확인 (실제 크롤러 상태)
  Future<Map<String, dynamic>> getCrawlingStatus() async {
    try {
      print('🔄 [크롤링상태] 실제 백엔드에서 크롤링 상태 조회 시작...');

      final response = await http.get(
        Uri.parse('$_baseUrl/api/news/crawling/status'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📡 [크롤링상태] 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final status = json.decode(response.body);
        print('✅ [크롤링상태] 성공적으로 크롤링 상태 로드됨');
        return status;
      } else {
        print('❌ [크롤링상태] API 오류: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load crawling status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [크롤링상태] 실제 API 호출 실패, 기본값 반환: $e');
      // 더미 데이터 대신 기본값 반환
      return {
        'is_active': false,
        'last_update': DateTime.now().toIso8601String(),
        'total_news': 0,
        'today_news': 0,
        'sources': {},
        'error': 'API 연결 실패',
      };
    }
  }

  // 수동 크롤링 트리거 (5-10분 간격 투자 민감 정보)
  Future<bool> triggerNewsCrawling() async {
    try {
      print('🔄 [크롤링트리거] 실제 백엔드에서 수동 크롤링 트리거 시작...');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/news/crawling/trigger'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'force_crawl': true,
          'priority': 'high', // 투자 민감 정보 우선
          'interval_type': 'sensitive', // 5-10분 간격
        }),
      );

      print('📡 [크롤링트리거] 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ [크롤링트리거] 수동 크롤링 트리거 성공');
        return true;
      } else {
        print('❌ [크롤링트리거] API 오류: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ [크롤링트리거] 실제 API 호출 실패: $e');
      return false;
    }
  }

}

class MarketInsightData {
  final int fearGreedIndex;
  final String fearGreedLabel;
  final String marketSentiment;
  final double tradingVolume24h;
  final double volumeChange24h;
  final double institutionalFlow;
  final double institutionalFlowChange;
  final Map<String, double> dominanceData;
  final List<Map<String, dynamic>> topGainers;
  final List<Map<String, dynamic>> topLosers;

  const MarketInsightData({
    required this.fearGreedIndex,
    required this.fearGreedLabel,
    required this.marketSentiment,
    required this.tradingVolume24h,
    required this.volumeChange24h,
    required this.institutionalFlow,
    required this.institutionalFlowChange,
    required this.dominanceData,
    required this.topGainers,
    required this.topLosers,
  });

  factory MarketInsightData.fromJson(Map<String, dynamic> json) {
    return MarketInsightData(
      fearGreedIndex: json['fearGreedIndex'] ?? 50,
      fearGreedLabel: json['fearGreedLabel'] ?? '중립',
      marketSentiment: json['marketSentiment'] ?? 'neutral',
      tradingVolume24h: (json['tradingVolume24h'] ?? 0.0).toDouble(),
      volumeChange24h: (json['volumeChange24h'] ?? 0.0).toDouble(),
      institutionalFlow: (json['institutionalFlow'] ?? 0.0).toDouble(),
      institutionalFlowChange: (json['institutionalFlowChange'] ?? 0.0).toDouble(),
      dominanceData: Map<String, double>.from(json['dominanceData'] ?? {}),
      topGainers: List<Map<String, dynamic>>.from(json['topGainers'] ?? []),
      topLosers: List<Map<String, dynamic>>.from(json['topLosers'] ?? []),
    );
  }
}

class NewsStatsData {
  final int totalNewsToday;
  final int breakingNewsCount;
  final Map<String, int> categoryStats;
  final Map<String, double> sentimentBreakdown;
  final DateTime lastUpdated;

  const NewsStatsData({
    required this.totalNewsToday,
    required this.breakingNewsCount,
    required this.categoryStats,
    required this.sentimentBreakdown,
    required this.lastUpdated,
  });

  factory NewsStatsData.fromJson(Map<String, dynamic> json) {
    return NewsStatsData(
      totalNewsToday: json['totalNewsToday'] ?? 0,
      breakingNewsCount: json['breakingNewsCount'] ?? 0,
      categoryStats: Map<String, int>.from(json['categoryStats'] ?? {}),
      sentimentBreakdown: Map<String, double>.from(json['sentimentBreakdown'] ?? {}),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }
}