import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/news_model.dart';
import '../services/news_service.dart';

// 뉴스 상태 클래스
class NewsState {
  final List<NewsModel> latestNews;
  final List<NewsModel> breakingNews;
  final Map<String, List<NewsModel>> categorizedNews;
  final MarketInsightData? marketInsights;
  final NewsStatsData? newsStats;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;
  final Map<String, dynamic> crawlingStatus;

  const NewsState({
    this.latestNews = const [],
    this.breakingNews = const [],
    this.categorizedNews = const {},
    this.marketInsights,
    this.newsStats,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
    this.crawlingStatus = const {},
  });

  NewsState copyWith({
    List<NewsModel>? latestNews,
    List<NewsModel>? breakingNews,
    Map<String, List<NewsModel>>? categorizedNews,
    MarketInsightData? marketInsights,
    NewsStatsData? newsStats,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
    Map<String, dynamic>? crawlingStatus,
  }) {
    return NewsState(
      latestNews: latestNews ?? this.latestNews,
      breakingNews: breakingNews ?? this.breakingNews,
      categorizedNews: categorizedNews ?? this.categorizedNews,
      marketInsights: marketInsights ?? this.marketInsights,
      newsStats: newsStats ?? this.newsStats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      crawlingStatus: crawlingStatus ?? this.crawlingStatus,
    );
  }
}

// 뉴스 상태 관리 Notifier
class NewsNotifier extends StateNotifier<NewsState> {
  final NewsService _newsService;

  NewsNotifier(this._newsService) : super(const NewsState()) {
    loadAllNewsData();
  }

  // 모든 뉴스 데이터 로드
  Future<void> loadAllNewsData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 병렬로 모든 데이터 로드
      final results = await Future.wait([
        _newsService.getLatestNews(),
        _newsService.getBreakingNews(),
        _newsService.getNewsByCategory(),
        _newsService.getMarketInsights(),
        _newsService.getNewsStats(),
      ]);

      state = state.copyWith(
        latestNews: results[0] as List<NewsModel>,
        breakingNews: results[1] as List<NewsModel>,
        categorizedNews: results[2] as Map<String, List<NewsModel>>,
        marketInsights: results[3] as MarketInsightData,
        newsStats: results[4] as NewsStatsData,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // 최신 뉴스 새로고침
  Future<void> refreshLatestNews() async {
    try {
      final latestNews = await _newsService.getLatestNews();
      state = state.copyWith(
        latestNews: latestNews,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // 주요 뉴스 새로고침
  Future<void> refreshBreakingNews() async {
    try {
      final breakingNews = await _newsService.getBreakingNews();
      state = state.copyWith(
        breakingNews: breakingNews,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // 마켓 인사이트 새로고침
  Future<void> refreshMarketInsights() async {
    try {
      final marketInsights = await _newsService.getMarketInsights();
      state = state.copyWith(
        marketInsights: marketInsights,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // 특정 카테고리 뉴스 가져오기
  List<NewsModel> getNewsByCategory(String category) {
    return state.categorizedNews[category] ?? [];
  }

  // 뉴스 검색
  Future<List<NewsModel>> searchNews({
    required String query,
    int limit = 20,
    List<String>? categories,
  }) async {
    try {
      return await _newsService.searchNews(
        query: query,
        limit: limit,
        categories: categories,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  // 에러 클리어
  void clearError() {
    state = state.copyWith(error: null);
  }

  // 크롤링 상태 로드
  Future<void> loadCrawlingStatus() async {
    try {
      final status = await _newsService.getCrawlingStatus();
      state = state.copyWith(crawlingStatus: status);
    } catch (e) {
      state = state.copyWith(error: '크롤링 상태 로드 실패: $e');
    }
  }

  // 수동 크롤링 트리거
  Future<void> triggerManualCrawling() async {
    try {
      final success = await _newsService.triggerNewsCrawling();
      if (success) {
        await loadCrawlingStatus();
        // 크롤링 완료 후 뉴스 새로고침
        await Future.delayed(const Duration(seconds: 5));
        await loadAllNewsData();
      } else {
        state = state.copyWith(error: '크롤링 실행 실패');
      }
    } catch (e) {
      state = state.copyWith(error: '크롤링 실행 중 오류: $e');
    }
  }

  // 자동 새로고침 시작 (5분마다)
  void startAutoRefresh() {
    Future.delayed(const Duration(minutes: 5), () {
      if (mounted) {
        refreshLatestNews();
        refreshBreakingNews();
        loadCrawlingStatus(); // 크롤링 상태도 함께 업데이트
        startAutoRefresh(); // 재귀 호출로 지속적 새로고침
      }
    });
  }
}

// 뉴스 서비스 인스턴스 제공
final newsServiceProvider = Provider<NewsService>((ref) {
  return NewsService();
});

// 뉴스 상태 제공
final newsProvider = StateNotifierProvider<NewsNotifier, NewsState>((ref) {
  final newsService = ref.read(newsServiceProvider);
  final notifier = NewsNotifier(newsService);

  // 자동 새로고침 시작
  notifier.startAutoRefresh();

  return notifier;
});

// 개별 데이터 접근을 위한 편의 Provider들
final latestNewsProvider = Provider<List<NewsModel>>((ref) {
  return ref.watch(newsProvider).latestNews;
});

final breakingNewsProvider = Provider<List<NewsModel>>((ref) {
  return ref.watch(newsProvider).breakingNews;
});

final marketInsightsProvider = Provider<MarketInsightData?>((ref) {
  return ref.watch(newsProvider).marketInsights;
});

final newsStatsProvider = Provider<NewsStatsData?>((ref) {
  return ref.watch(newsProvider).newsStats;
});

final newsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(newsProvider).isLoading;
});

final newsErrorProvider = Provider<String?>((ref) {
  return ref.watch(newsProvider).error;
});

// 카테고리별 뉴스 Provider
final categoryNewsProvider = Provider.family<List<NewsModel>, String>((ref, category) {
  final newsState = ref.watch(newsProvider);
  return newsState.categorizedNews[category] ?? [];
});

// 뉴스 통계 요약 Provider
final newsStatsSummaryProvider = Provider<Map<String, dynamic>>((ref) {
  final stats = ref.watch(newsStatsProvider);
  if (stats == null) return {};

  return {
    'totalNews': stats.totalNewsToday,
    'breakingNews': stats.breakingNewsCount,
    'sentiment': _getOverallSentiment(stats.sentimentBreakdown),
    'lastUpdated': stats.lastUpdated,
  };
});

// 시장 감정 요약 Provider
final marketSentimentProvider = Provider<Map<String, dynamic>>((ref) {
  final insights = ref.watch(marketInsightsProvider);
  if (insights == null) return {};

  return {
    'fearGreedIndex': insights.fearGreedIndex,
    'fearGreedLabel': insights.fearGreedLabel,
    'sentiment': insights.marketSentiment,
    'volumeChange': insights.volumeChange24h,
    'institutionalFlow': insights.institutionalFlow,
  };
});

// 도우미 함수들
String _getOverallSentiment(Map<String, double> sentimentBreakdown) {
  final positive = sentimentBreakdown['positive'] ?? 0.0;
  final negative = sentimentBreakdown['negative'] ?? 0.0;

  if (positive > 50) return '긍정적';
  if (negative > 30) return '부정적';
  return '중립적';
}