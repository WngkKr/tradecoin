import React, { useState, useEffect } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import Layout from '../common/Layout';

interface NewsItem {
  id: string;
  title: string;
  summary: string;
  source: string;
  publishedAt: Date;
  sentiment: 'positive' | 'negative' | 'neutral';
  impact: 'high' | 'medium' | 'low';
  relatedCoins: string[];
  url: string;
  imageUrl?: string;
}

const MOCK_NEWS: NewsItem[] = [
  {
    id: '1',
    title: '일론 머스크: "Dogecoin을 테슬라 결제에 도입 검토 중"',
    summary: '테슬라 CEO 일론 머스크가 트위터를 통해 도지코인을 테슬라 차량 구매 결제 수단으로 도입하는 것을 검토 중이라고 발표했습니다.',
    source: 'CoinDesk',
    publishedAt: new Date(Date.now() - 10 * 60 * 1000),
    sentiment: 'positive',
    impact: 'high',
    relatedCoins: ['DOGE'],
    url: '#'
  },
  {
    id: '2',
    title: '비트코인 ETF 승인, SEC 최종 검토 단계 돌입',
    summary: '미국 SEC가 비트코인 현물 ETF 승인을 위한 최종 검토 단계에 들어갔다고 업계 소식통이 전했습니다. 이번 주 내 결정이 나올 것으로 예상됩니다.',
    source: 'Bloomberg',
    publishedAt: new Date(Date.now() - 25 * 60 * 1000),
    sentiment: 'positive',
    impact: 'high',
    relatedCoins: ['BTC'],
    url: '#'
  },
  {
    id: '3',
    title: '이더리움 2.0 스테이킹 보상률 상승세',
    summary: '이더리움 2.0 네트워크의 스테이킹 보상률이 5.2%까지 상승하며 투자자들의 관심이 증가하고 있습니다.',
    source: 'The Block',
    publishedAt: new Date(Date.now() - 45 * 60 * 1000),
    sentiment: 'positive',
    impact: 'medium',
    relatedCoins: ['ETH'],
    url: '#'
  },
  {
    id: '4',
    title: '한국 정부, 가상화폐 거래소 규제 강화 방침',
    summary: '금융위원회가 가상화폐 거래소에 대한 규제를 강화하고 실명확인입출금계정(실계좌) 요구사항을 더욱 엄격히 적용할 방침이라고 발표했습니다.',
    source: '연합뉴스',
    publishedAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
    sentiment: 'negative',
    impact: 'medium',
    relatedCoins: ['BTC', 'ETH', 'XRP'],
    url: '#'
  },
  {
    id: '5',
    title: 'Chainlink, 대형 은행들과 CBDC 프로젝트 파트너십',
    summary: '체인링크가 여러 중앙은행과 협력하여 중앙은행 디지털화폐(CBDC) 인프라 구축을 위한 파트너십을 체결했다고 발표했습니다.',
    source: 'CryptoNews',
    publishedAt: new Date(Date.now() - 3 * 60 * 60 * 1000),
    sentiment: 'positive',
    impact: 'medium',
    relatedCoins: ['LINK'],
    url: '#'
  },
  {
    id: '6',
    title: '솔라나 네트워크 장애 복구, 거래 정상화',
    summary: '어제 발생한 솔라나 네트워크 장애가 완전히 복구되었으며, 모든 거래가 정상적으로 처리되고 있다고 솔라나 재단이 공식 발표했습니다.',
    source: 'Solana Foundation',
    publishedAt: new Date(Date.now() - 4 * 60 * 60 * 1000),
    sentiment: 'neutral',
    impact: 'medium',
    relatedCoins: ['SOL'],
    url: '#'
  }
];

export default function News() {
  const { user } = useAuth();
  const [news, setNews] = useState<NewsItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'positive' | 'negative' | 'neutral'>('all');
  const [selectedCoin, setSelectedCoin] = useState<string>('all');

  useEffect(() => {
    const fetchNews = async () => {
      setLoading(true);
      await new Promise(resolve => setTimeout(resolve, 600));
      setNews(MOCK_NEWS);
      setLoading(false);
    };

    fetchNews();
  }, []);

  const filteredNews = news.filter(item => {
    const sentimentMatch = filter === 'all' || item.sentiment === filter;
    const coinMatch = selectedCoin === 'all' || item.relatedCoins.includes(selectedCoin);
    return sentimentMatch && coinMatch;
  });

  const getSentimentColor = (sentiment: string) => {
    switch (sentiment) {
      case 'positive': return 'text-success-green';
      case 'negative': return 'text-danger-red';
      case 'neutral': return 'text-text-secondary';
      default: return 'text-text-secondary';
    }
  };

  const getSentimentBadge = (sentiment: string) => {
    switch (sentiment) {
      case 'positive': return 'bg-success-green/10 text-success-green border-success-green/30';
      case 'negative': return 'bg-danger-red/10 text-danger-red border-danger-red/30';
      case 'neutral': return 'bg-gray-100 text-gray-600 border-gray-300';
      default: return 'bg-gray-100 text-gray-600 border-gray-300';
    }
  };

  const getImpactBadge = (impact: string) => {
    switch (impact) {
      case 'high': return 'bg-danger-red/10 text-danger-red border-danger-red/30';
      case 'medium': return 'bg-warning-orange/10 text-warning-orange border-warning-orange/30';
      case 'low': return 'bg-success-green/10 text-success-green border-success-green/30';
      default: return 'bg-gray-100 text-gray-600 border-gray-300';
    }
  };

  const getTimeAgo = (date: Date) => {
    const now = new Date();
    const diffInMinutes = Math.floor((now.getTime() - date.getTime()) / (1000 * 60));
    
    if (diffInMinutes < 60) {
      return `${diffInMinutes}분 전`;
    } else if (diffInMinutes < 1440) {
      return `${Math.floor(diffInMinutes / 60)}시간 전`;
    } else {
      return `${Math.floor(diffInMinutes / 1440)}일 전`;
    }
  };

  const allCoins = ['all', ...Array.from(new Set(news.flatMap(item => item.relatedCoins)))];

  return (
    <Layout>
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 pb-20 md:pb-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-2xl font-bold text-text-primary mb-2 flex items-center">
            <span className="mr-2">📰</span>
            암호화폐 뉴스
          </h1>
          <p className="text-text-secondary">
            실시간 암호화폐 관련 뉴스와 시장 분석을 확인하세요
          </p>
        </div>

        {/* Filters */}
        <div className="mb-8 space-y-4">
          {/* Sentiment Filter */}
          <div>
            <h3 className="text-sm font-medium text-text-secondary mb-3">감정 분석</h3>
            <div className="flex items-center space-x-2 bg-white rounded-xl p-2 border border-border">
              {[
                { key: 'all', label: '전체', icon: '📊' },
                { key: 'positive', label: '긍정', icon: '📈' },
                { key: 'negative', label: '부정', icon: '📉' },
                { key: 'neutral', label: '중립', icon: '⚖️' }
              ].map((tab) => (
                <button
                  key={tab.key}
                  onClick={() => setFilter(tab.key as typeof filter)}
                  className={`flex items-center space-x-2 px-3 py-2 rounded-lg transition-all text-sm ${
                    filter === tab.key
                      ? 'bg-primary-blue text-white'
                      : 'text-text-secondary hover:text-primary-blue hover:bg-surface-alt'
                  }`}
                >
                  <span>{tab.icon}</span>
                  <span className="font-medium">{tab.label}</span>
                </button>
              ))}
            </div>
          </div>

          {/* Coin Filter */}
          <div>
            <h3 className="text-sm font-medium text-text-secondary mb-3">관련 코인</h3>
            <div className="flex flex-wrap gap-2">
              {allCoins.map((coin) => (
                <button
                  key={coin}
                  onClick={() => setSelectedCoin(coin)}
                  className={`px-3 py-1 rounded-full text-sm font-medium transition-all ${
                    selectedCoin === coin
                      ? 'bg-primary-blue text-white'
                      : 'bg-white border border-border text-text-secondary hover:border-primary-blue hover:text-primary-blue'
                  }`}
                >
                  {coin === 'all' ? '전체' : coin}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* News List */}
        {loading ? (
          <div className="space-y-6">
            {[1, 2, 3, 4, 5].map((i) => (
              <div key={i} className="signal-card p-6 animate-pulse">
                <div className="flex items-start space-x-4">
                  <div className="w-16 h-16 bg-gray-200 rounded-lg"></div>
                  <div className="flex-1 space-y-3">
                    <div className="h-4 bg-gray-200 rounded w-3/4"></div>
                    <div className="h-3 bg-gray-200 rounded w-full"></div>
                    <div className="h-3 bg-gray-200 rounded w-1/2"></div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : filteredNews.length > 0 ? (
          <div className="space-y-6">
            {filteredNews.map((item) => (
              <article 
                key={item.id} 
                className="signal-card p-6 hover:shadow-lg transition-all duration-200 cursor-pointer"
              >
                <div className="flex items-start space-x-4">
                  {/* Sentiment Indicator */}
                  <div className={`w-4 h-4 rounded-full mt-2 ${
                    item.sentiment === 'positive' ? 'bg-success-green' :
                    item.sentiment === 'negative' ? 'bg-danger-red' : 'bg-gray-400'
                  }`}></div>

                  {/* Content */}
                  <div className="flex-1">
                    {/* Header */}
                    <div className="flex items-start justify-between mb-3">
                      <div className="flex-1">
                        <h2 className="text-lg font-bold text-text-primary mb-2 leading-tight">
                          {item.title}
                        </h2>
                        <div className="flex items-center space-x-4 text-sm text-text-secondary">
                          <span>{item.source}</span>
                          <span>•</span>
                          <span>{getTimeAgo(item.publishedAt)}</span>
                        </div>
                      </div>
                    </div>

                    {/* Summary */}
                    <p className="text-text-primary mb-4 leading-relaxed">
                      {item.summary}
                    </p>

                    {/* Tags */}
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-2">
                        {/* Sentiment Badge */}
                        <span className={`px-2 py-1 rounded-full text-xs font-medium border ${getSentimentBadge(item.sentiment)}`}>
                          {item.sentiment === 'positive' ? '긍정' : 
                           item.sentiment === 'negative' ? '부정' : '중립'}
                        </span>

                        {/* Impact Badge */}
                        <span className={`px-2 py-1 rounded-full text-xs font-medium border ${getImpactBadge(item.impact)}`}>
                          {item.impact === 'high' ? '높은 영향' : 
                           item.impact === 'medium' ? '보통 영향' : '낮은 영향'}
                        </span>

                        {/* Related Coins */}
                        <div className="flex items-center space-x-1">
                          {item.relatedCoins.map((coin) => (
                            <span 
                              key={coin} 
                              className="px-2 py-1 bg-primary-blue/10 text-primary-blue rounded text-xs font-medium"
                            >
                              {coin}
                            </span>
                          ))}
                        </div>
                      </div>

                      {/* Read More */}
                      <button className="text-primary-blue hover:text-primary-blue/80 text-sm font-medium flex items-center space-x-1">
                        <span>자세히 보기</span>
                        <span>→</span>
                      </button>
                    </div>
                  </div>
                </div>
              </article>
            ))}
          </div>
        ) : (
          <div className="text-center py-12">
            <div className="text-6xl mb-4">📰</div>
            <h3 className="text-lg font-medium text-text-primary mb-2">
              해당 조건의 뉴스가 없습니다
            </h3>
            <p className="text-text-secondary">
              다른 필터를 선택하거나 전체 뉴스를 확인해보세요
            </p>
            <button 
              onClick={() => {
                setFilter('all');
                setSelectedCoin('all');
              }}
              className="mt-4 action-button"
            >
              전체 뉴스 보기
            </button>
          </div>
        )}

        {/* News Sources */}
        <div className="mt-12 p-6 bg-gradient-to-r from-primary-blue/5 to-purple-500/5 rounded-2xl border border-primary-blue/10">
          <h3 className="text-lg font-bold text-text-primary mb-4 flex items-center">
            <span className="mr-2">📡</span>
            뉴스 소스
          </h3>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {['CoinDesk', 'Bloomberg', 'The Block', '연합뉴스'].map((source) => (
              <div key={source} className="text-center p-3 bg-white rounded-lg border border-border">
                <div className="text-sm font-medium text-text-primary">{source}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </Layout>
  );
}