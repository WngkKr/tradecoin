import React, { useState, useEffect } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { Signal, USER_LIMITS } from '../../types';
import SignalCard from '../common/SignalCard';
import Layout from '../common/Layout';
import { apiService } from '../../services/api';

// 시그널 데이터 (Dashboard와 동일한 데이터 사용)
const MOCK_SIGNALS: Signal[] = [
  {
    id: '1',
    timestamp: new Date(Date.now() - 5 * 60 * 1000),
    coinSymbol: 'BTC',
    sourceType: 'news',
    sourceId: 'news-1',
    sourceContent: '비트코인 ETF 승인 소식으로 강세 전환 기대',
    sentiment: 'positive',
    confidenceScore: 85,
    predictedImpact: '긍정적',
    estimatedPriceChangePercent: 12,
    recommendedAction: 'buy',
    recommendedLeverageMultiple: 5,
    riskLevel: 'medium',
    reasoning: '최근 비트코인 ETF 승인 소식과 기관 투자자들의 관심 증가로 인해 단기적으로 상승 모멘텀이 예상됩니다. MACD 지표가 골든 크로스를 형성하며 강세 신호를 보이고 있습니다.',
    optimalEntryWindow: { start: '즉시', end: '10분 이내' },
    optimalExitWindow: { start: '15분 후', end: '30분 이내' },
    currentPrice: 67234.56
  },
  {
    id: '2',
    timestamp: new Date(Date.now() - 12 * 60 * 1000),
    coinSymbol: 'DOGE',
    sourceType: 'social',
    sourceId: 'tweet-1',
    sourceContent: 'Elon Musk mentions Dogecoin in latest tweet',
    sentiment: 'positive',
    confidenceScore: 78,
    predictedImpact: '긍정적',
    estimatedPriceChangePercent: 8,
    recommendedAction: 'buy',
    recommendedLeverageMultiple: 3,
    riskLevel: 'high',
    reasoning: '일론 머스크의 트윗이 도지코인에 미치는 영향력을 고려할 때, 단기적으로 상승이 예상됩니다. 소셜 미디어 감정 지수가 급상승하고 있습니다.',
    optimalEntryWindow: { start: '즉시', end: '5분 이내' },
    optimalExitWindow: { start: '10분 후', end: '20분 이내' },
    currentPrice: 0.285
  },
  {
    id: '3',
    timestamp: new Date(Date.now() - 25 * 60 * 1000),
    coinSymbol: 'ETH',
    sourceType: 'technical',
    sourceId: 'ta-1',
    sourceContent: 'Technical analysis shows consolidation pattern',
    sentiment: 'neutral',
    confidenceScore: 65,
    predictedImpact: '중립적',
    estimatedPriceChangePercent: 2,
    recommendedAction: 'hold',
    recommendedLeverageMultiple: 1,
    riskLevel: 'low',
    reasoning: '이더리움은 현재 삼각수렴 패턴을 보이고 있으며, 방향성이 명확하지 않은 상태입니다. RSI는 중립적 위치에 있어 관망이 적절해 보입니다.',
    optimalEntryWindow: { start: '대기', end: '패턴 이탈시' },
    optimalExitWindow: { start: '추세 확인 후', end: '1시간 이내' },
    currentPrice: 3456.78
  },
  {
    id: '4',
    timestamp: new Date(Date.now() - 35 * 60 * 1000),
    coinSymbol: 'ADA',
    sourceType: 'news',
    sourceId: 'news-2',
    sourceContent: '카르다노 스마트 컨트랙트 업데이트 발표',
    sentiment: 'positive',
    confidenceScore: 72,
    predictedImpact: '긍정적',
    estimatedPriceChangePercent: 6,
    recommendedAction: 'buy',
    recommendedLeverageMultiple: 2,
    riskLevel: 'medium',
    reasoning: '카르다노의 스마트 컨트랙트 기능 개선 소식으로 개발자 생태계 확장이 예상됩니다.',
    optimalEntryWindow: { start: '즉시', end: '15분 이내' },
    optimalExitWindow: { start: '30분 후', end: '1시간 이내' },
    currentPrice: 0.421
  },
  {
    id: '5',
    timestamp: new Date(Date.now() - 45 * 60 * 1000),
    coinSymbol: 'SOL',
    sourceType: 'technical',
    sourceId: 'ta-2',
    sourceContent: '솔라나 거래량 급증, 돌파 임박',
    sentiment: 'positive',
    confidenceScore: 81,
    predictedImpact: '긍정적',
    estimatedPriceChangePercent: 15,
    recommendedAction: 'buy',
    recommendedLeverageMultiple: 4,
    riskLevel: 'medium',
    reasoning: '거래량 증가와 함께 저항선 돌파가 임박해 보입니다. 볼린저 밴드 상단을 향한 움직임이 관찰됩니다.',
    optimalEntryWindow: { start: '즉시', end: '8분 이내' },
    optimalExitWindow: { start: '20분 후', end: '45분 이내' },
    currentPrice: 89.42
  }
];

export default function Signals() {
  const { user } = useAuth();
  const [signals, setSignals] = useState<Signal[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedSignal, setSelectedSignal] = useState<Signal | null>(null);
  const [filter, setFilter] = useState<'all' | 'buy' | 'sell' | 'hold'>('all');

  useEffect(() => {
    const fetchSignals = async () => {
      setLoading(true);

      try {
        // Try to fetch real signals from API
        const response = await apiService.getSignals();
        if (response.success && response.data) {
          const transformedSignals = response.data.map(apiSignal =>
            apiService.transformApiSignalToSignal(apiSignal)
          );

          // Apply user limits
          const userLimits = user ? USER_LIMITS[user.subscription?.tier || 'free'] : USER_LIMITS.free;
          const availableSignals = userLimits.signalsPerDay === Infinity
            ? transformedSignals
            : transformedSignals.slice(0, userLimits.signalsPerDay);

          setSignals(availableSignals);
        } else {
          // Fallback to mock data
          console.warn('API returned no signals, using mock data');
          throw new Error('No signals from API');
        }
      } catch (error) {
        console.error('Failed to fetch signals from API:', error);

        // Fallback to mock data
        const userLimits = user ? USER_LIMITS[user.subscription?.tier || 'free'] : USER_LIMITS.free;
        const availableSignals = userLimits.signalsPerDay === Infinity
          ? MOCK_SIGNALS
          : MOCK_SIGNALS.slice(0, userLimits.signalsPerDay);

        setSignals(availableSignals);
      } finally {
        setLoading(false);
      }
    };

    fetchSignals();

    // Set up polling for real-time updates
    const interval = setInterval(fetchSignals, 30000); // Update every 30 seconds
    return () => clearInterval(interval);
  }, [user]);

  const filteredSignals = signals.filter(signal => {
    if (filter === 'all') return true;
    return signal.recommendedAction === filter;
  });

  const handleSignalClick = (signal: Signal) => {
    setSelectedSignal(signal);
  };

  const getRiskColor = (risk: string) => {
    switch (risk) {
      case 'low': return 'text-success-green';
      case 'medium': return 'text-warning-orange';
      case 'high': return 'text-danger-red';
      default: return 'text-text-secondary';
    }
  };

  const getActionColor = (action: string) => {
    switch (action) {
      case 'buy': return 'bg-success-green/10 text-success-green border-success-green/30';
      case 'sell': return 'bg-danger-red/10 text-danger-red border-danger-red/30';
      case 'hold': return 'bg-warning-orange/10 text-warning-orange border-warning-orange/30';
      default: return 'bg-gray-100 text-gray-600 border-gray-300';
    }
  };

  return (
    <Layout>
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 pb-20 md:pb-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-2xl font-bold text-text-primary mb-2 flex items-center">
            <span className="mr-2">🔔</span>
            실시간 시그널
          </h1>
          <p className="text-text-secondary">
            AI가 분석한 최신 거래 신호를 확인하세요
          </p>
        </div>

        {/* Filter Tabs */}
        <div className="mb-6">
          <div className="flex items-center space-x-2 bg-white rounded-xl p-2 border border-border">
            {[
              { key: 'all', label: '전체', icon: '📊' },
              { key: 'buy', label: '매수', icon: '📈' },
              { key: 'sell', label: '매도', icon: '📉' },
              { key: 'hold', label: '관망', icon: '⏸️' }
            ].map((tab) => (
              <button
                key={tab.key}
                onClick={() => setFilter(tab.key as typeof filter)}
                className={`flex items-center space-x-2 px-4 py-2 rounded-lg transition-all ${
                  filter === tab.key
                    ? 'bg-primary-blue text-white'
                    : 'text-text-secondary hover:text-primary-blue hover:bg-surface-alt'
                }`}
              >
                <span>{tab.icon}</span>
                <span className="text-sm font-medium">{tab.label}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Usage Info */}
        {user && user.subscription?.tier === 'free' && (
          <div className="mb-6 p-4 bg-gradient-to-r from-purple-500/10 to-primary-blue/10 border border-purple-200 rounded-xl">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-text-primary font-medium">
                  🆓 Free 플랜: {signals.length}/3 시그널 (오늘)
                </p>
                <p className="text-text-secondary text-sm">
                  더 많은 시그널을 받으려면 Premium으로 업그레이드하세요
                </p>
              </div>
              <button className="action-button text-sm px-4 py-2">
                💎 업그레이드
              </button>
            </div>
          </div>
        )}

        {/* Signals Grid */}
        {loading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[1, 2, 3, 4, 5, 6].map((i) => (
              <div key={i} className="signal-card p-6 animate-pulse">
                <div className="h-4 bg-gray-200 rounded w-1/2 mb-4"></div>
                <div className="h-8 bg-gray-200 rounded mb-4"></div>
                <div className="h-3 bg-gray-200 rounded w-3/4 mb-2"></div>
                <div className="h-3 bg-gray-200 rounded w-1/2"></div>
              </div>
            ))}
          </div>
        ) : filteredSignals.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredSignals.map((signal) => (
              <SignalCard
                key={signal.id}
                signal={signal}
                onClick={() => handleSignalClick(signal)}
              />
            ))}
          </div>
        ) : (
          <div className="text-center py-12">
            <div className="text-6xl mb-4">🔍</div>
            <h3 className="text-lg font-medium text-text-primary mb-2">
              해당 조건의 시그널이 없습니다
            </h3>
            <p className="text-text-secondary">
              다른 필터를 선택하거나 전체 시그널을 확인해보세요
            </p>
            <button 
              onClick={() => setFilter('all')}
              className="mt-4 action-button"
            >
              전체 시그널 보기
            </button>
          </div>
        )}

        {/* Premium CTA */}
        {user && user.subscription?.tier === 'free' && (
          <div className="mt-8 p-8 bg-gradient-to-r from-primary-blue/10 to-purple-500/10 border border-primary-blue/20 rounded-2xl text-center">
            <div className="text-4xl mb-4">🚀</div>
            <h3 className="text-xl font-bold text-text-primary mb-2">
              더 많은 시그널과 고급 기능을 원하시나요?
            </h3>
            <p className="text-text-secondary mb-6">
              Premium 플랜으로 무제한 시그널, 실시간 알림, 자동거래 기능을 이용하세요
            </p>
            <button className="action-button text-lg px-8 py-3">
              💎 Premium으로 업그레이드
            </button>
          </div>
        )}
      </div>

      {/* Signal Detail Modal */}
      {selectedSignal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl p-6 max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-bold text-text-primary">
                {selectedSignal.coinSymbol} 시그널 상세
              </h2>
              <button 
                onClick={() => setSelectedSignal(null)}
                className="text-text-secondary hover:text-text-primary"
              >
                ✕
              </button>
            </div>
            
            <SignalCard signal={selectedSignal} />
            
            <div className="mt-6 pt-6 border-t border-border">
              <h3 className="font-semibold text-text-primary mb-4">📊 상세 분석</h3>
              <p className="text-text-primary leading-relaxed">
                {selectedSignal.reasoning}
              </p>
            </div>
            
            <div className="mt-6 flex space-x-3">
              <button className="flex-1 action-button">
                🚀 자동거래 실행
              </button>
              <button className="flex-1 px-6 py-3 border border-border text-text-primary rounded-xl hover:bg-surface-alt transition-colors">
                📋 수동설정
              </button>
            </div>
          </div>
        </div>
      )}
    </Layout>
  );
}