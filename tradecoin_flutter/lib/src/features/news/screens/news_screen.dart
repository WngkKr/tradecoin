import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../shared/widgets/cyberpunk_header.dart';
import '../providers/news_provider.dart';
import '../models/news_model.dart';

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      appBar: const CyberpunkHeader(),
      body: Container(
        decoration: BoxDecoration(
          gradient: themeState.isDarkMode
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E1B4B),
                  Color(0xFF312E81),
                  Color(0xFF3730A3),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8FAFC),
                  Color(0xFFE2E8F0),
                  Color(0xFFCBD5E1),
                ],
              ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 뉴스 헤더
                _buildNewsHeader(),
                const SizedBox(height: 24),
                
                // 주요 뉴스
                _buildBreakingNews(),
                const SizedBox(height: 24),
                
                // 카테고리별 뉴스
                _buildCategoryNews(),
                const SizedBox(height: 24),
                
                // 마켓 인사이트
                _buildMarketInsights(),
                
                const SizedBox(height: 100), // 하단 네비게이션 공간
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewsHeader() {
    final newsStats = ref.watch(newsStatsProvider);
    final marketSentiment = ref.watch(marketSentimentProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassmorphism(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.newspaper,
                    color: AppTheme.primaryBlue,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '크립토 뉴스',
                    style: AppTheme.headingMedium.copyWith(
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const Spacer(),
                  if (ref.watch(newsLoadingProvider))
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildNewsStatCard(
                    '오늘의 뉴스',
                    '${newsStats?.totalNewsToday ?? 0}',
                    AppTheme.accentBlue
                  ),
                  const SizedBox(width: 16),
                  _buildNewsStatCard(
                    '주요 이슈',
                    '${newsStats?.breakingNewsCount ?? 0}',
                    AppTheme.dangerRed
                  ),
                  const SizedBox(width: 16),
                  _buildNewsStatCard(
                    '시장 영향',
                    marketSentiment['sentiment'] ?? '중립적',
                    _getSentimentColor(marketSentiment['sentiment'])
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x1A1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakingNews() {
    final breakingNews = ref.watch(breakingNewsProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassmorphism(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.flash_on,
                    color: AppTheme.accentBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '주요 뉴스',
                    style: AppTheme.headingMedium.copyWith(
                      color: AppTheme.accentBlue,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      ref.read(newsProvider.notifier).refreshBreakingNews();
                    },
                    icon: Icon(
                      Icons.refresh,
                      color: AppTheme.accentBlue,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (breakingNews.isEmpty && !ref.watch(newsLoadingProvider))
                _buildEmptyState('주요 뉴스가 없습니다')
              else
                ...breakingNews.take(3).map((news) => _buildNewsItemFromModel(news)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsItem(String title, String summary, String time, bool isPositive, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1A1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                time,
                style: AppTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary,
            style: AppTheme.bodyMedium.copyWith(
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryNews() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassmorphism(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '카테고리별 뉴스',
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.neutralGray,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildCategoryCard('DeFi', '12', AppTheme.primaryBlue),
                  const SizedBox(width: 12),
                  _buildCategoryCard('NFT', '8', AppTheme.dangerRed),
                  const SizedBox(width: 12),
                  _buildCategoryCard('메타버스', '5', AppTheme.accentBlue),
                  const SizedBox(width: 12),
                  _buildCategoryCard('규제', '7', AppTheme.neutralGray),
                ],
              ),
              const SizedBox(height: 16),
              _buildCategoryNewsItem(
                'DeFi',
                'Uniswap V4 출시로 새로운 DeFi 생태계 구축',
                'DeFi 거래량이 사상 최고치를 경신하며...',
                '45분 전',
                AppTheme.primaryBlue,
              ),
              _buildCategoryNewsItem(
                'NFT',
                '유명 아티스트들의 NFT 컬렉션 출시 예정',
                '디지털 아트 시장이 다시 주목받고 있으며...',
                '1시간 전',
                AppTheme.dangerRed,
              ),
              _buildCategoryNewsItem(
                '메타버스',
                '대형 기업들의 메타버스 투자 확대',
                '가상현실 기술 발전과 함께 메타버스 토큰들이...',
                '2시간 전',
                AppTheme.accentBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String category, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              category,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              count,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryNewsItem(String category, String title, String summary, String time, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1A1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                time,
                style: AppTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summary,
            style: AppTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMarketInsights() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassmorphism(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '마켓 인사이트',
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.successGreen,
                ),
              ),
              const SizedBox(height: 16),
              _buildInsightCard(
                '시장 심리',
                '탐욕 지수: 75 (극도의 탐욕)',
                '투자자들이 매우 낙관적인 상태를 보이고 있어 단기 조정 가능성이 있습니다.',
                Icons.psychology,
                AppTheme.neutralGray,
              ),
              _buildInsightCard(
                '거래량 분석',
                '24시간 거래량: +23.5%',
                '전 구간에서 거래량이 증가하며 강한 상승 모멘텀을 보이고 있습니다.',
                Icons.bar_chart,
                AppTheme.accentBlue,
              ),
              _buildInsightCard(
                '기관 투자',
                '기관 자금 유입: +\$2.3B',
                '대형 기관들의 지속적인 자금 유입으로 시장이 안정화되고 있습니다.',
                Icons.business,
                AppTheme.successGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightCard(String title, String value, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1A1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: AppTheme.bodySmall.copyWith(
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 헬퍼 메소드들
  Color _getSentimentColor(String? sentiment) {
    switch (sentiment) {
      case 'bullish':
      case '긍정적':
        return AppTheme.successGreen;
      case 'bearish':
      case '부정적':
        return AppTheme.dangerRed;
      default:
        return AppTheme.neutralGray;
    }
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0x1A1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.info_outline, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTheme.bodyMedium.copyWith(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsItemFromModel(NewsModel news) {
    final timeFormatter = DateFormat('HH:mm');
    final now = DateTime.now();
    final difference = now.difference(news.publishedAt);

    String timeText;
    if (difference.inMinutes < 60) {
      timeText = '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      timeText = '${difference.inHours}시간 전';
    } else {
      timeText = timeFormatter.format(news.publishedAt);
    }

    final impactColor = _getMarketImpactColor(news.marketImpact.level);
    final isPositive = news.marketImpact.level == MarketImpactLevel.positive ||
                      news.marketImpact.level == MarketImpactLevel.veryPositive;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1A1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: impactColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: impactColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  news.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                timeText,
                style: AppTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            news.summary,
            style: AppTheme.bodyMedium.copyWith(
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (news.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: news.tags.take(3).map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: impactColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: impactColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Color _getMarketImpactColor(MarketImpactLevel level) {
    switch (level) {
      case MarketImpactLevel.veryPositive:
        return AppTheme.successGreen;
      case MarketImpactLevel.positive:
        return AppTheme.accentBlue;
      case MarketImpactLevel.neutral:
        return AppTheme.neutralGray;
      case MarketImpactLevel.negative:
        return AppTheme.warningOrange;
      case MarketImpactLevel.veryNegative:
        return AppTheme.dangerRed;
    }
  }
}