const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api';

export interface ApiSignal {
  symbol: string;
  signal: 'BUY' | 'SELL' | 'HOLD';
  confidence: number;
  sentiment: 'VERY_BULLISH' | 'BULLISH' | 'NEUTRAL' | 'BEARISH' | 'VERY_BEARISH';
  risk_level: 'LOW' | 'MEDIUM' | 'HIGH' | 'EXTREME';
  leverage_recommendation: number;
  target_price: number | null;
  stop_loss: number | null;
  reason: string;
  timestamp: string;
  urgency_score: number;
  source_count: number;
}

export interface ApiSignalsResponse {
  success: boolean;
  data: ApiSignal[];
}

export interface MarketData {
  symbol: string;
  name: string;
  price: number;
  change_24h: number;
  change_percent_24h: number;
  volume_24h: number;
  market_cap: number;
  timestamp: string;
}

export interface MarketDataResponse {
  success: boolean;
  data: MarketData[];
}

export interface Portfolio {
  total_value: number;
  pnl_24h: number;
  pnl_percent_24h: number;
  positions: Position[];
}

export interface Position {
  symbol: string;
  type: 'long' | 'short';
  size: number;
  entry_price: number;
  current_price: number;
  pnl: number;
  pnl_percent: number;
  leverage: number;
}

class ApiService {
  private async fetchApi<T>(endpoint: string): Promise<T> {
    try {
      const response = await fetch(`${API_BASE_URL}${endpoint}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      return data;
    } catch (error) {
      console.error(`API call failed for ${endpoint}:`, error);
      throw error;
    }
  }

  async getSignals(): Promise<ApiSignalsResponse> {
    return this.fetchApi<ApiSignalsResponse>('/trading/signals');
  }

  async getMarketData(): Promise<MarketDataResponse> {
    return this.fetchApi<MarketDataResponse>('/market/data');
  }

  async getPortfolio(): Promise<Portfolio> {
    return this.fetchApi<Portfolio>('/portfolio/summary');
  }

  async getNews(): Promise<any> {
    return this.fetchApi<any>('/news');
  }

  async getHealth(): Promise<{ status: string; timestamp: string; version: string }> {
    return this.fetchApi<{ status: string; timestamp: string; version: string }>('/health');
  }

  // Transform API signal to our Signal interface
  transformApiSignalToSignal(apiSignal: ApiSignal): any {
    return {
      id: `${apiSignal.symbol}-${Date.now()}`,
      timestamp: new Date(apiSignal.timestamp),
      coinSymbol: apiSignal.symbol,
      sourceType: 'mixed' as const,
      sourceId: `api-${apiSignal.symbol}`,
      sourceContent: apiSignal.reason,
      sentiment: this.mapSentiment(apiSignal.sentiment),
      confidenceScore: Math.round(apiSignal.confidence * 100),
      predictedImpact: this.mapSentimentToImpact(apiSignal.sentiment),
      estimatedPriceChangePercent: this.calculatePriceChange(apiSignal.target_price, apiSignal.stop_loss),
      recommendedAction: apiSignal.signal.toLowerCase() as 'buy' | 'sell' | 'hold',
      recommendedLeverageMultiple: apiSignal.leverage_recommendation,
      riskLevel: apiSignal.risk_level.toLowerCase() as 'low' | 'medium' | 'high',
      reasoning: apiSignal.reason,
      optimalEntryWindow: {
        start: apiSignal.urgency_score > 0.8 ? '즉시' : '5분 이내',
        end: apiSignal.urgency_score > 0.8 ? '5분 이내' : '15분 이내'
      },
      optimalExitWindow: {
        start: '15분 후',
        end: apiSignal.risk_level === 'EXTREME' ? '30분 이내' : '1시간 이내'
      },
      currentPrice: apiSignal.target_price || 0 // Will be updated with market data
    };
  }

  private mapSentiment(sentiment: string): 'positive' | 'negative' | 'neutral' {
    switch (sentiment) {
      case 'VERY_BULLISH':
      case 'BULLISH':
        return 'positive';
      case 'BEARISH':
      case 'VERY_BEARISH':
        return 'negative';
      default:
        return 'neutral';
    }
  }

  private mapSentimentToImpact(sentiment: string): string {
    switch (sentiment) {
      case 'VERY_BULLISH':
        return '매우 긍정적';
      case 'BULLISH':
        return '긍정적';
      case 'BEARISH':
        return '부정적';
      case 'VERY_BEARISH':
        return '매우 부정적';
      default:
        return '중립적';
    }
  }

  private calculatePriceChange(targetPrice: number | null, stopLoss: number | null): number {
    if (!targetPrice || !stopLoss) {
      return 5; // Default expected change
    }
    return Math.round(((targetPrice - stopLoss) / stopLoss) * 100);
  }
}

export const apiService = new ApiService();