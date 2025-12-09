import React, { useState, useEffect } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { Signal, USER_LIMITS } from '../../types';
import Layout from '../common/Layout';
import { apiService } from '../../services/api';

// Mock data for demonstration
const MOCK_SIGNALS: Signal[] = [
  {
    id: '1',
    timestamp: new Date(Date.now() - 5 * 60 * 1000), // 5 minutes ago
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
    timestamp: new Date(Date.now() - 12 * 60 * 1000), // 12 minutes ago
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
    timestamp: new Date(Date.now() - 25 * 60 * 1000), // 25 minutes ago
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
  }
];

const MOCK_PORTFOLIO = {
  totalValue: 12543.21,
  todayPnL: 234.12,
  todayPnLPercent: 1.9
};

export default function Dashboard() {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [signals, setSignals] = useState<Signal[]>([]);
  const [portfolio, setPortfolio] = useState(MOCK_PORTFOLIO);

  useEffect(() => {
    const fetchDashboardData = async () => {
      setLoading(true);

      try {
        // Fetch signals for dashboard preview
        const signalsResponse = await apiService.getSignals();
        if (signalsResponse.success && signalsResponse.data) {
          const transformedSignals = signalsResponse.data
            .map(apiSignal => apiService.transformApiSignalToSignal(apiSignal))
            .slice(0, 3); // Show only top 3 signals on dashboard

          setSignals(transformedSignals);
        }

        // Try to fetch portfolio data
        try {
          const portfolioData = await apiService.getPortfolio();
          if (portfolioData) {
            setPortfolio({
              totalValue: portfolioData.total_value || MOCK_PORTFOLIO.totalValue,
              todayPnL: portfolioData.pnl_24h || MOCK_PORTFOLIO.todayPnL,
              todayPnLPercent: portfolioData.pnl_percent_24h || MOCK_PORTFOLIO.todayPnLPercent
            });
          }
        } catch (portfolioError) {
          console.warn('Failed to fetch portfolio data, using mock data:', portfolioError);
          // Keep using MOCK_PORTFOLIO
        }

      } catch (error) {
        console.error('Failed to fetch dashboard data:', error);
        // Fallback to mock signals
        setSignals(MOCK_SIGNALS.slice(0, 3));
      } finally {
        setLoading(false);
      }
    };

    fetchDashboardData();

    // Set up polling for updates
    const interval = setInterval(fetchDashboardData, 60000); // Update every minute
    return () => clearInterval(interval);
  }, []);

  return (
    <Layout>
      <div className="px-4 sm:px-6 lg:px-8 py-6 pb-20 md:pb-8 space-y-6">
        {/* Portfolio Balance Card - NFT Style */}
        <div className="relative">
          <div className="bg-white/10 backdrop-blur-md border border-white/20 rounded-3xl p-8 text-white shadow-2xl relative overflow-hidden">
            {/* Gradient overlay */}
            <div className="absolute inset-0 bg-gradient-to-br from-purple-500/10 to-transparent pointer-events-none"></div>
            
            <div className="relative z-10">
              <div className="flex items-center justify-between mb-6">
                <div className="text-sm text-white/70 font-medium">Portfolio Balance</div>
                <button className="p-2 hover:bg-white/10 rounded-full transition-colors">
                  <svg className="w-5 h-5 text-white/70" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 616 0z" />
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                  </svg>
                </button>
              </div>
              
              <div className="text-4xl font-bold mb-2">${MOCK_PORTFOLIO.totalValue.toLocaleString()}</div>
              <div className="text-green-400 text-sm font-medium mb-8">+{MOCK_PORTFOLIO.todayPnLPercent}% Today</div>
              
              <div className="grid grid-cols-2 gap-4">
                <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-2xl p-4 hover:bg-white/10 transition-colors">
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="text-xs text-white/60 mb-1 font-medium">Income</div>
                      <div className="font-bold text-lg">${MOCK_PORTFOLIO.todayPnL.toLocaleString()}</div>
                    </div>
                    <div className="w-8 h-8 bg-green-500/20 border border-green-500/30 rounded-xl flex items-center justify-center">
                      <svg className="w-4 h-4 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 11l5-5m0 0l5 5m-5-5v12" />
                      </svg>
                    </div>
                  </div>
                </div>
                <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-2xl p-4 hover:bg-white/10 transition-colors">
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="text-xs text-white/60 mb-1 font-medium">Expenses</div>
                      <div className="font-bold text-lg">${(MOCK_PORTFOLIO.todayPnL * 0.3).toLocaleString()}</div>
                    </div>
                    <div className="w-8 h-8 bg-red-500/20 border border-red-500/30 rounded-xl flex items-center justify-center">
                      <svg className="w-4 h-4 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 13l-5 5m0 0l-5-5m5 5V6" />
                      </svg>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Quick Actions - NFT Style */}
        <div className="grid grid-cols-4 gap-3">
          <button className="flex flex-col items-center p-4 bg-white/10 backdrop-blur-md border border-white/20 rounded-2xl hover:bg-white/15 active:scale-95 transition-all duration-200">
            <div className="w-10 h-10 bg-white/10 rounded-xl flex items-center justify-center mb-3">
              <svg className="w-5 h-5 text-white/80" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
              </svg>
            </div>
            <span className="text-xs font-medium text-white/80">Transfer</span>
          </button>
          <button className="flex flex-col items-center p-4 bg-white/10 backdrop-blur-md border border-white/20 rounded-2xl hover:bg-white/15 active:scale-95 transition-all duration-200">
            <div className="w-10 h-10 bg-white/10 rounded-xl flex items-center justify-center mb-3">
              <svg className="w-5 h-5 text-white/80" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1" />
              </svg>
            </div>
            <span className="text-xs font-medium text-white/80">Withdraw</span>
          </button>
          <button className="flex flex-col items-center p-4 bg-white/10 backdrop-blur-md border border-white/20 rounded-2xl hover:bg-white/15 active:scale-95 transition-all duration-200">
            <div className="w-10 h-10 bg-white/10 rounded-xl flex items-center justify-center mb-3">
              <svg className="w-5 h-5 text-white/80" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
              </svg>
            </div>
            <span className="text-xs font-medium text-white/80">Top Up</span>
          </button>
          <button className="flex flex-col items-center p-4 bg-white/10 backdrop-blur-md border border-white/20 rounded-2xl hover:bg-white/15 active:scale-95 transition-all duration-200">
            <div className="w-10 h-10 bg-white/10 rounded-xl flex items-center justify-center mb-3">
              <svg className="w-5 h-5 text-white/80" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" />
              </svg>
            </div>
            <span className="text-xs font-medium text-white/80">More</span>
          </button>
        </div>

        {/* Recent Transactions - NFT Style */}
        <div>
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-bold text-white">Recent Activity</h2>
            <button className="text-white/70 text-sm font-medium hover:text-white transition-colors px-3 py-2 rounded-lg hover:bg-white/10">
              View all
            </button>
          </div>
          
          <div className="bg-white/10 backdrop-blur-md border border-white/20 rounded-2xl overflow-hidden">
            {loading ? (
              <div className="p-6 space-y-4">
                {[1, 2, 3].map((i) => (
                  <div key={i} className="flex items-center space-x-4 animate-pulse">
                    <div className="w-12 h-12 bg-white/10 rounded-xl"></div>
                    <div className="flex-1 space-y-2">
                      <div className="h-4 bg-white/10 rounded w-3/4"></div>
                      <div className="h-3 bg-white/10 rounded w-1/2"></div>
                    </div>
                    <div className="h-4 bg-white/10 rounded w-20"></div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="divide-y divide-white/10">
                <div className="flex items-center space-x-4 p-6 hover:bg-white/5 transition-colors cursor-pointer">
                  <div className="w-12 h-12 bg-white/10 rounded-xl flex items-center justify-center">
                    <svg className="w-6 h-6 text-white/70" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z" />
                    </svg>
                  </div>
                  <div className="flex-1">
                    <div className="font-medium text-white text-sm">Online Purchase</div>
                    <div className="text-xs text-white/60">Feb 5, 2025 • 08:14 PM</div>
                  </div>
                  <div className="text-red-400 font-semibold">-$320.75</div>
                </div>
                <div className="flex items-center space-x-4 p-6 hover:bg-white/5 transition-colors cursor-pointer">
                  <div className="w-12 h-12 bg-white/10 rounded-xl flex items-center justify-center">
                    <svg className="w-6 h-6 text-white/70" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M13 10V3L4 14h7v7l9-11h-7z" />
                    </svg>
                  </div>
                  <div className="flex-1">
                    <div className="font-medium text-white text-sm">Utility Bill</div>
                    <div className="text-xs text-white/60">Jan 28, 2025 • 10:03 AM</div>
                  </div>
                  <div className="text-red-400 font-semibold">-$98.40</div>
                </div>
                <div className="flex items-center space-x-4 p-6 hover:bg-white/5 transition-colors cursor-pointer">
                  <div className="w-12 h-12 bg-white/10 rounded-xl flex items-center justify-center">
                    <svg className="w-6 h-6 text-white/70" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1" />
                    </svg>
                  </div>
                  <div className="flex-1">
                    <div className="font-medium text-white text-sm">Salary Deposit</div>
                    <div className="text-xs text-white/60">Jan 25, 2025 • 09:45 AM</div>
                  </div>
                  <div className="text-green-400 font-semibold">+$14,200.00</div>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </Layout>
  );
}