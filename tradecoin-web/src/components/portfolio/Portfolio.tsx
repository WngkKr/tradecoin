import React, { useState, useEffect } from 'react';
import { PortfolioAsset, TradingPosition } from '../../types';
import Layout from '../common/Layout';

// Mock data for demonstration
const MOCK_PORTFOLIO_ASSETS: PortfolioAsset[] = [
  {
    symbol: 'BTC',
    name: 'Bitcoin',
    amount: 0.5,
    averagePrice: 65000,
    currentPrice: 67234.56,
    pnl: 1117.28,
    pnlPercent: 3.43,
    addedAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
    updatedAt: new Date()
  },
  {
    symbol: 'ETH',
    name: 'Ethereum',
    amount: 2.5,
    averagePrice: 3200,
    currentPrice: 3456.78,
    pnl: 641.95,
    pnlPercent: 8.02,
    addedAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
    updatedAt: new Date()
  },
  {
    symbol: 'DOGE',
    name: 'Dogecoin',
    amount: 10000,
    averagePrice: 0.25,
    currentPrice: 0.285,
    pnl: 350,
    pnlPercent: 14,
    addedAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
    updatedAt: new Date()
  }
];

const MOCK_ACTIVE_POSITIONS: TradingPosition[] = [
  {
    id: '1',
    userId: 'user1',
    coinSymbol: 'BTC',
    type: 'long',
    leverage: 5,
    entryPrice: 67234,
    currentPrice: 68901,
    size: 1000,
    pnl: 124.38,
    pnlPercent: 2.5,
    stopLoss: 65000,
    takeProfit: 70000,
    status: 'open',
    createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
    updatedAt: new Date()
  },
  {
    id: '2',
    userId: 'user1',
    coinSymbol: 'DOGE',
    type: 'short',
    leverage: 3,
    entryPrice: 0.285,
    currentPrice: 0.276,
    size: 500,
    pnl: 15.79,
    pnlPercent: 3.2,
    stopLoss: 0.30,
    takeProfit: 0.25,
    status: 'open',
    createdAt: new Date(Date.now() - 1 * 60 * 60 * 1000),
    updatedAt: new Date()
  }
];

const PERFORMANCE_STATS = {
  totalTrades: 30,
  winningTrades: 22,
  losingTrades: 8,
  winRate: 73.3,
  avgProfitPercent: 5.2,
  maxDrawdownPercent: 8.1,
  totalPnL: 2847.32,
  totalPnLPercent: 18.7
};

export default function Portfolio() {
  const [activeTab, setActiveTab] = useState<'overview' | 'positions' | 'performance'>('overview');
  const [assets, setAssets] = useState<PortfolioAsset[]>([]);
  const [positions, setPositions] = useState<TradingPosition[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchPortfolioData = async () => {
      setLoading(true);
      await new Promise(resolve => setTimeout(resolve, 1000));
      setAssets(MOCK_PORTFOLIO_ASSETS);
      setPositions(MOCK_ACTIVE_POSITIONS);
      setLoading(false);
    };

    fetchPortfolioData();
  }, []);

  const calculateTotalValue = () => {
    return assets.reduce((total, asset) => total + (asset.amount * asset.currentPrice), 0);
  };

  const calculateTotalPnL = () => {
    return assets.reduce((total, asset) => total + asset.pnl, 0);
  };

  const calculateTotalPnLPercent = () => {
    const totalInvested = assets.reduce((total, asset) => total + (asset.amount * asset.averagePrice), 0);
    return totalInvested > 0 ? (calculateTotalPnL() / totalInvested) * 100 : 0;
  };

  const getPositionIcon = (type: string, pnl: number) => {
    if (type === 'long') return pnl >= 0 ? '📈' : '📉';
    return pnl >= 0 ? '📉' : '📈';
  };

  const formatTimeAgo = (date: Date) => {
    const now = new Date();
    const diffInHours = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60));
    
    if (diffInHours < 1) return '1시간 미만';
    if (diffInHours < 24) return `${diffInHours}시간 전`;
    return `${Math.floor(diffInHours / 24)}일 전`;
  };

  return (
    <Layout>
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 pb-20 md:pb-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-2xl font-bold text-text-primary mb-2 flex items-center">
            <span className="mr-2">📊</span>
            내 포트폴리오
          </h1>
          <p className="text-text-secondary">투자 현황과 성과를 한눈에 확인하세요</p>
        </div>

        {/* Portfolio Summary */}
        <div className="mb-8">
          <div className="signal-card bg-gradient-to-r from-primary-blue to-purple-600 rounded-2xl p-8 text-white animate-fade-in">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
              <div className="text-center md:text-left">
                <div className="flex items-center justify-center md:justify-start mb-3">
                  <div className="w-12 h-12 bg-white/20 rounded-xl flex items-center justify-center mr-3">
                    <span className="text-xl">💰</span>
                  </div>
                  <p className="text-white/80 text-sm font-medium">총 자산</p>
                </div>
                <p className="text-4xl font-bold mb-2">${calculateTotalValue().toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</p>
                <div className="w-full h-1 bg-white/20 rounded-full">
                  <div className="h-full bg-white/40 rounded-full" style={{ width: '85%' }}></div>
                </div>
              </div>
              <div className="text-center">
                <div className="flex items-center justify-center mb-3">
                  <div className="w-12 h-12 bg-white/20 rounded-xl flex items-center justify-center mr-3">
                    <span className="text-xl">📈</span>
                  </div>
                  <p className="text-white/80 text-sm font-medium">총 수익률</p>
                </div>
                <p className={`text-3xl font-bold mb-2 ${calculateTotalPnLPercent() >= 0 ? 'text-green-300' : 'text-red-300'}`}>
                  {calculateTotalPnLPercent() >= 0 ? '+' : ''}{calculateTotalPnLPercent().toFixed(1)}%
                </p>
                <div className="status-success text-xs">우수한 성과</div>
              </div>
              <div className="text-center md:text-right">
                <div className="flex items-center justify-center md:justify-end mb-3">
                  <p className="text-white/80 text-sm font-medium mr-3">총 수익금</p>
                  <div className="w-12 h-12 bg-white/20 rounded-xl flex items-center justify-center">
                    <span className="text-xl">💎</span>
                  </div>
                </div>
                <p className={`text-3xl font-bold mb-2 ${calculateTotalPnL() >= 0 ? 'text-green-300' : 'text-red-300'}`}>
                  {calculateTotalPnL() >= 0 ? '+' : ''}${calculateTotalPnL().toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                </p>
                <div className="text-white/60 text-sm">지난 30일간</div>
              </div>
            </div>
          </div>
        </div>

        {/* Tab Navigation */}
        <div className="mb-8">
          <div className="flex space-x-2 bg-surface-alt rounded-2xl p-2 glassmorphism">
            <button
              onClick={() => setActiveTab('overview')}
              className={`flex-1 py-4 px-6 rounded-xl font-semibold transition-all duration-300 relative overflow-hidden ${
                activeTab === 'overview'
                  ? 'bg-white text-primary-blue shadow-lg transform scale-105'
                  : 'text-text-secondary hover:text-text-primary hover:bg-white/50'
              }`}
            >
              <div className="flex items-center justify-center space-x-2">
                <span className="text-lg">🏛️</span>
                <span>보유 자산</span>
              </div>
              {activeTab === 'overview' && (
                <div className="absolute bottom-0 left-1/2 transform -translate-x-1/2 w-12 h-1 bg-primary-blue rounded-full"></div>
              )}
            </button>
            <button
              onClick={() => setActiveTab('positions')}
              className={`flex-1 py-4 px-6 rounded-xl font-semibold transition-all duration-300 relative overflow-hidden ${
                activeTab === 'positions'
                  ? 'bg-white text-primary-blue shadow-lg transform scale-105'
                  : 'text-text-secondary hover:text-text-primary hover:bg-white/50'
              }`}
            >
              <div className="flex items-center justify-center space-x-2">
                <span className="text-lg">🏃‍♂️</span>
                <span>활성 포지션</span>
              </div>
              {activeTab === 'positions' && (
                <div className="absolute bottom-0 left-1/2 transform -translate-x-1/2 w-12 h-1 bg-primary-blue rounded-full"></div>
              )}
            </button>
            <button
              onClick={() => setActiveTab('performance')}
              className={`flex-1 py-4 px-6 rounded-xl font-semibold transition-all duration-300 relative overflow-hidden ${
                activeTab === 'performance'
                  ? 'bg-white text-primary-blue shadow-lg transform scale-105'
                  : 'text-text-secondary hover:text-text-primary hover:bg-white/50'
              }`}
            >
              <div className="flex items-center justify-center space-x-2">
                <span className="text-lg">📈</span>
                <span>성과 분석</span>
              </div>
              {activeTab === 'performance' && (
                <div className="absolute bottom-0 left-1/2 transform -translate-x-1/2 w-12 h-1 bg-primary-blue rounded-full"></div>
              )}
            </button>
          </div>
        </div>

        {/* Tab Content */}
        {loading ? (
          <div className="space-y-4">
            {[1, 2, 3].map((i) => (
              <div key={i} className="bg-white rounded-xl p-6 animate-pulse">
                <div className="h-4 bg-gray-200 rounded w-1/4 mb-4"></div>
                <div className="h-8 bg-gray-200 rounded w-1/2 mb-2"></div>
                <div className="h-4 bg-gray-200 rounded w-3/4"></div>
              </div>
            ))}
          </div>
        ) : (
          <>
            {/* Overview Tab */}
            {activeTab === 'overview' && (
              <div className="space-y-6">
                {assets.map((asset, index) => (
                  <div key={asset.symbol} className={`signal-card p-8 animate-slide-up`} style={{ animationDelay: `${index * 100}ms` }}>
                    <div className="flex items-center justify-between mb-6">
                      <div className="flex items-center space-x-4">
                        <div className="relative">
                          <div className="w-16 h-16 bg-gradient-to-br from-primary-blue/20 to-purple/20 rounded-2xl flex items-center justify-center border-2 border-primary-blue/30">
                            <span className="font-bold text-xl text-primary-blue">{asset.symbol}</span>
                          </div>
                          <div className="absolute -bottom-2 -right-2 w-6 h-6 bg-success-green rounded-full flex items-center justify-center">
                            <span className="text-xs text-white">✓</span>
                          </div>
                        </div>
                        <div>
                          <h3 className="font-bold text-xl text-text-primary mb-1">{asset.name}</h3>
                          <p className="text-text-secondary font-medium">{asset.amount} {asset.symbol}</p>
                          <div className="mt-2">
                            <span className={`status-${asset.pnl >= 0 ? 'success' : 'danger'}`}>
                              {asset.pnl >= 0 ? '수익중' : '손실중'}
                            </span>
                          </div>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className="text-2xl font-bold text-text-primary mb-2">
                          ${(asset.amount * asset.currentPrice).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                        </p>
                        <div className={`flex items-center justify-end space-x-2 text-lg font-bold ${asset.pnl >= 0 ? 'text-success-green' : 'text-danger-red'}`}>
                          <span className="text-xl">{asset.pnl >= 0 ? '📈' : '📉'}</span>
                          <span>
                            {asset.pnl >= 0 ? '+' : ''}${asset.pnl.toFixed(2)} ({asset.pnl >= 0 ? '+' : ''}{asset.pnlPercent.toFixed(1)}%)
                          </span>
                        </div>
                      </div>
                    </div>
                    
                    {/* Progress Bar for Performance */}
                    <div className="mb-6">
                      <div className="confidence-gauge">
                        <div 
                          className="gauge-fill" 
                          style={{ width: `${Math.min(Math.abs(asset.pnlPercent), 20) * 5}%` }}
                        ></div>
                      </div>
                    </div>
                    
                    <div className="grid grid-cols-3 gap-6">
                      <div className="text-center p-4 bg-surface-alt rounded-xl">
                        <p className="text-text-secondary text-sm font-medium mb-2">평균 단가</p>
                        <p className="font-bold text-lg text-text-primary">${asset.averagePrice.toLocaleString()}</p>
                      </div>
                      <div className="text-center p-4 bg-surface-alt rounded-xl">
                        <p className="text-text-secondary text-sm font-medium mb-2">현재 가격</p>
                        <p className="font-bold text-lg text-text-primary">${asset.currentPrice.toLocaleString()}</p>
                      </div>
                      <div className="text-center p-4 bg-surface-alt rounded-xl">
                        <p className="text-text-secondary text-sm font-medium mb-2">보유 기간</p>
                        <p className="font-bold text-lg text-text-primary">{formatTimeAgo(asset.addedAt)}</p>
                      </div>
                    </div>
                    
                    <div className="mt-6 pt-6 border-t border-border-light">
                      <div className="flex justify-between items-center">
                        <div className="flex space-x-3">
                          <button className="btn-secondary text-sm">📊 차트 보기</button>
                          <button className="btn-ghost text-sm">⚙️ 관리</button>
                        </div>
                        <button className="action-button text-sm px-6 py-3">
                          💼 거래하기
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* Positions Tab */}
            {activeTab === 'positions' && (
              <div className="space-y-6">
                <div className="flex items-center justify-between mb-6">
                  <div>
                    <h2 className="text-2xl font-bold text-text-primary mb-1">
                      활성 포지션
                    </h2>
                    <p className="text-text-secondary">
                      현재 {positions.length}개의 포지션이 활성화되어 있습니다
                    </p>
                  </div>
                  <div className="flex items-center space-x-2">
                    <div className="tier-badge tier-pro">
                      <span>⚡</span>
                      <span>{positions.length}/5</span>
                    </div>
                  </div>
                </div>
                
                {positions.map((position, index) => (
                  <div key={position.id} className={`signal-card p-8 animate-scale-in`} style={{ animationDelay: `${index * 150}ms` }}>
                    <div className="flex items-center justify-between mb-6">
                      <div className="flex items-center space-x-4">
                        <div className="relative">
                          <div className={`w-16 h-16 rounded-2xl flex items-center justify-center border-2 ${
                            position.type === 'long' 
                              ? 'bg-success-green/20 border-success-green/50' 
                              : 'bg-danger-red/20 border-danger-red/50'
                          }`}>
                            <span className="text-2xl">
                              {getPositionIcon(position.type, position.pnl)}
                            </span>
                          </div>
                          <div className="absolute -top-2 -right-2 bg-white rounded-full px-2 py-1 shadow-md">
                            <span className="text-xs font-bold text-primary-blue">x{position.leverage}</span>
                          </div>
                        </div>
                        <div>
                          <h3 className="font-bold text-xl text-text-primary mb-1">
                            {position.coinSymbol} {position.type.toUpperCase()}
                          </h3>
                          <p className="text-text-secondary font-medium">
                            포지션 크기: ${position.size.toLocaleString()}
                          </p>
                          <div className="mt-2">
                            <span className={`status-${position.pnl >= 0 ? 'success' : 'danger'}`}>
                              {formatTimeAgo(position.createdAt)} 진입
                            </span>
                          </div>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className="text-2xl font-bold text-text-primary mb-2">
                          ${position.size.toLocaleString()}
                        </p>
                        <div className={`flex items-center justify-end space-x-2 text-lg font-bold ${position.pnl >= 0 ? 'text-success-green' : 'text-danger-red'}`}>
                          <span className="text-xl">{position.pnl >= 0 ? '🚀' : '⚠️'}</span>
                          <div className="text-right">
                            <div>{position.pnl >= 0 ? '+' : ''}${position.pnl.toFixed(2)}</div>
                            <div className="text-sm">({position.pnl >= 0 ? '+' : ''}{position.pnlPercent.toFixed(1)}%)</div>
                          </div>
                        </div>
                      </div>
                    </div>
                    
                    {/* Performance Progress Bar */}
                    <div className="mb-6">
                      <div className="flex justify-between text-sm text-text-secondary mb-2">
                        <span>수익률</span>
                        <span>{position.pnl >= 0 ? '+' : ''}{position.pnlPercent.toFixed(1)}%</span>
                      </div>
                      <div className="confidence-gauge">
                        <div 
                          className="gauge-fill" 
                          style={{ width: `${Math.min(Math.abs(position.pnlPercent), 10) * 10}%` }}
                        ></div>
                      </div>
                    </div>
                    
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
                      <div className="text-center p-4 bg-surface-alt rounded-xl">
                        <p className="text-text-secondary text-sm font-medium mb-2">진입가</p>
                        <p className="font-bold text-lg text-text-primary">${position.entryPrice.toLocaleString()}</p>
                      </div>
                      <div className="text-center p-4 bg-surface-alt rounded-xl">
                        <p className="text-text-secondary text-sm font-medium mb-2">현재가</p>
                        <p className="font-bold text-lg text-text-primary">${position.currentPrice.toLocaleString()}</p>
                      </div>
                      <div className="text-center p-4 bg-danger-red/5 rounded-xl border border-danger-red/20">
                        <p className="text-danger-red text-sm font-medium mb-2">손절가</p>
                        <p className="font-bold text-lg text-danger-red">${position.stopLoss?.toLocaleString()}</p>
                      </div>
                      <div className="text-center p-4 bg-success-green/5 rounded-xl border border-success-green/20">
                        <p className="text-success-green text-sm font-medium mb-2">익절가</p>
                        <p className="font-bold text-lg text-success-green">${position.takeProfit?.toLocaleString()}</p>
                      </div>
                    </div>
                    
                    <div className="flex space-x-3">
                      <button className="flex-1 btn-secondary">
                        📈 실시간 차트
                      </button>
                      <button className="flex-1 btn-ghost">
                        ⚙️ 설정 변경
                      </button>
                      <button className="action-button px-6">
                        🔒 포지션 청산
                      </button>
                    </div>
                  </div>
                ))}
                
                {positions.length === 0 && (
                  <div className="text-center py-16 signal-card">
                    <div className="text-8xl mb-6 animate-bounce">📊</div>
                    <h3 className="text-2xl font-bold text-text-primary mb-3">
                      활성 포지션이 없습니다
                    </h3>
                    <p className="text-lg text-text-secondary mb-6">
                      새로운 트레이딩 시그널을 확인해보세요
                    </p>
                    <button className="action-button px-8 py-4">
                      📡 시그널 확인하기
                    </button>
                  </div>
                )}
              </div>
            )}

            {/* Performance Tab */}
            {activeTab === 'performance' && (
              <div className="space-y-6">
                {/* Performance Overview */}
                <div className="bg-white rounded-xl shadow-card p-6">
                  <h3 className="text-lg font-semibold text-text-primary mb-6 flex items-center">
                    <span className="mr-2">📊</span>
                    거래 성과 분석
                  </h3>
                  
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
                    <div className="text-center">
                      <p className="text-3xl font-bold text-success-green mb-2">
                        {PERFORMANCE_STATS.winRate}%
                      </p>
                      <p className="text-sm text-text-secondary">승률</p>
                      <p className="text-xs text-text-secondary mt-1">
                        ({PERFORMANCE_STATS.winningTrades}승 {PERFORMANCE_STATS.losingTrades}패)
                      </p>
                    </div>
                    
                    <div className="text-center">
                      <p className="text-3xl font-bold text-primary-blue mb-2">
                        +{PERFORMANCE_STATS.avgProfitPercent}%
                      </p>
                      <p className="text-sm text-text-secondary">평균 수익률</p>
                      <p className="text-xs text-text-secondary mt-1">
                        거래당 평균
                      </p>
                    </div>
                    
                    <div className="text-center">
                      <p className="text-3xl font-bold text-danger-red mb-2">
                        -{PERFORMANCE_STATS.maxDrawdownPercent}%
                      </p>
                      <p className="text-sm text-text-secondary">최대 손실</p>
                      <p className="text-xs text-text-secondary mt-1">
                        최대 낙폭
                      </p>
                    </div>
                    
                    <div className="text-center">
                      <p className="text-3xl font-bold text-text-primary mb-2">
                        {PERFORMANCE_STATS.totalTrades}
                      </p>
                      <p className="text-sm text-text-secondary">총 거래수</p>
                      <p className="text-xs text-text-secondary mt-1">
                        전체 기간
                      </p>
                    </div>
                  </div>
                </div>

                {/* Total Performance */}
                <div className="bg-white rounded-xl shadow-card p-6">
                  <h3 className="text-lg font-semibold text-text-primary mb-6 flex items-center">
                    <span className="mr-2">💎</span>
                    누적 수익 현황
                  </h3>
                  
                  <div className="text-center py-8">
                    <p className="text-5xl font-bold text-success-green mb-4">
                      +${PERFORMANCE_STATS.totalPnL.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                    </p>
                    <p className="text-xl font-semibold text-success-green mb-2">
                      +{PERFORMANCE_STATS.totalPnLPercent}%
                    </p>
                    <p className="text-text-secondary">
                      전체 기간 누적 수익
                    </p>
                  </div>
                  
                  <div className="bg-success-green/5 rounded-xl p-4 border border-success-green/20">
                    <div className="flex items-center justify-center text-success-green">
                      <span className="mr-2">🎉</span>
                      <span className="font-medium">
                        훌륭한 성과입니다! 평균 수익률이 시장 대비 우수합니다.
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            )}
          </>
        )}
      </div>
    </Layout>
  );
}