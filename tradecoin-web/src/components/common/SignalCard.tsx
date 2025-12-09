import React from 'react';
import { Signal } from '../../types';

interface SignalCardProps {
  signal: Signal;
  onClick?: () => void;
}

export default function SignalCard({ signal, onClick }: SignalCardProps) {
  const getActionIcon = (action: string) => {
    switch (action) {
      case 'buy': return '📈';
      case 'sell': return '📉';
      case 'hold': return '⏸️';
      default: return '📊';
    }
  };

  const getActionColor = (action: string) => {
    switch (action) {
      case 'buy': return 'text-success-green';
      case 'sell': return 'text-danger-red';
      case 'hold': return 'text-warning-orange';
      default: return 'text-text-secondary';
    }
  };

  const getRiskColor = (risk: string) => {
    switch (risk) {
      case 'low': return 'text-success-green bg-success-green/10';
      case 'medium': return 'text-warning-orange bg-warning-orange/10';
      case 'high': return 'text-danger-red bg-danger-red/10';
      default: return 'text-text-secondary bg-gray-100';
    }
  };

  const getRiskIcon = (risk: string) => {
    switch (risk) {
      case 'low': return '🟢';
      case 'medium': return '🟡';
      case 'high': return '🔴';
      default: return '⚪';
    }
  };

  const getConfidenceColor = (confidence: number) => {
    if (confidence >= 80) return 'bg-success-green';
    if (confidence >= 60) return 'bg-warning-orange';
    return 'bg-danger-red';
  };

  const formatTimeAgo = (timestamp: Date) => {
    const now = new Date();
    const diffInMinutes = Math.floor((now.getTime() - timestamp.getTime()) / (1000 * 60));
    
    if (diffInMinutes < 1) return '방금 전';
    if (diffInMinutes < 60) return `${diffInMinutes}분 전`;
    if (diffInMinutes < 1440) return `${Math.floor(diffInMinutes / 60)}시간 전`;
    return `${Math.floor(diffInMinutes / 1440)}일 전`;
  };

  return (
    <div 
      className="signal-card cursor-pointer p-6"
      onClick={onClick}
    >
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center space-x-3">
          <div className="flex items-center space-x-2">
            <span className="text-2xl font-bold text-text-primary">{signal.coinSymbol}</span>
            <span className="text-sm text-text-secondary">${signal.currentPrice.toFixed(2)}</span>
          </div>
        </div>
        
        <div className="flex items-center space-x-2">
          <div className={`flex items-center space-x-1 ${getActionColor(signal.recommendedAction)}`}>
            <span>{getActionIcon(signal.recommendedAction)}</span>
            <span className="font-semibold text-sm uppercase">{signal.recommendedAction}</span>
          </div>
          
          <div className={`px-2 py-1 rounded-full text-xs font-medium ${getRiskColor(signal.riskLevel)}`}>
            <span className="mr-1">{getRiskIcon(signal.riskLevel)}</span>
            {signal.riskLevel}
          </div>
        </div>
      </div>

      {/* Confidence Gauge */}
      <div className="mb-4">
        <div className="flex justify-between items-center mb-2">
          <span className="text-sm font-medium text-text-primary">🎯 신뢰도</span>
          <span className="text-sm font-bold text-text-primary">{signal.confidenceScore}%</span>
        </div>
        <div className="confidence-gauge">
          <div 
            className={`gauge-fill ${getConfidenceColor(signal.confidenceScore)}`}
            style={{ width: `${signal.confidenceScore}%` }}
          ></div>
        </div>
      </div>

      {/* Prediction */}
      <div className="mb-4">
        <div className="grid grid-cols-2 gap-4">
          <div>
            <p className="text-xs text-text-secondary mb-1">예상 수익률</p>
            <p className={`text-sm font-bold ${signal.estimatedPriceChangePercent >= 0 ? 'text-success-green' : 'text-danger-red'}`}>
              {signal.estimatedPriceChangePercent >= 0 ? '+' : ''}{signal.estimatedPriceChangePercent}%
            </p>
          </div>
          <div>
            <p className="text-xs text-text-secondary mb-1">레버리지</p>
            <p className="text-sm font-bold text-text-primary">x{signal.recommendedLeverageMultiple}</p>
          </div>
        </div>
      </div>

      {/* Timing */}
      <div className="mb-4">
        <div className="grid grid-cols-2 gap-4">
          <div>
            <p className="text-xs text-text-secondary mb-1">⏰ 진입 시점</p>
            <p className="text-sm font-medium text-text-primary">{signal.optimalEntryWindow.start}</p>
          </div>
          <div>
            <p className="text-xs text-text-secondary mb-1">⏳ 청산 시점</p>
            <p className="text-sm font-medium text-text-primary">{signal.optimalExitWindow.start}</p>
          </div>
        </div>
      </div>

      {/* Source Info */}
      <div className="flex items-center justify-between text-xs text-text-secondary pt-4 border-t border-border">
        <div className="flex items-center space-x-2">
          <span className="capitalize">{signal.sourceType}</span>
          <span>•</span>
          <span>{formatTimeAgo(signal.timestamp)}</span>
        </div>
        
        <div className="flex items-center space-x-1">
          <div className={`w-2 h-2 rounded-full ${
            signal.sentiment === 'positive' ? 'bg-success-green' : 
            signal.sentiment === 'negative' ? 'bg-danger-red' : 'bg-gray-400'
          }`}></div>
          <span className="capitalize">{signal.sentiment}</span>
        </div>
      </div>

      {/* Quick Preview */}
      <div className="mt-4 p-3 bg-surface-alt/50 rounded-lg">
        <p className="text-sm text-text-primary line-clamp-2">
          {signal.reasoning.length > 100 
            ? signal.reasoning.substring(0, 100) + '...' 
            : signal.reasoning
          }
        </p>
      </div>
    </div>
  );
}