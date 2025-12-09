export interface User {
  uid: string;
  email: string;
  displayName?: string;
  photoURL?: string;
  phoneNumber?: string;
  subscription: Subscription;
  profile: UserProfile;
  settings: UserSettings;
  stats: UserStats;
  createdAt: Date;
  updatedAt: Date;
  isActive: boolean;
}

export interface Subscription {
  tier: 'free' | 'premium' | 'pro' | 'enterprise';
  status: 'active' | 'cancelled' | 'expired';
  startDate: Date;
  endDate: Date;
  autoRenew: boolean;
}

export interface UserProfile {
  experienceLevel: 'beginner' | 'intermediate' | 'advanced';
  riskTolerance: 'conservative' | 'moderate' | 'aggressive';
  preferredCoins: string[];
  investmentGoal?: string;
  monthlyBudget?: number;
}

export interface UserSettings {
  notifications: {
    push: boolean;
    email: boolean;
    sms: boolean;
    signalThreshold: number;
  };
  trading: {
    autoTrading: boolean;
    maxPositions: number;
    maxLeverage: number;
    stopLoss: number;
    takeProfit: number;
  };
}

export interface UserStats {
  signalsUsed: number;
  tradesExecuted: number;
  totalPnL: number;
  winRate: number;
  lastLogin: Date;
}

export interface Signal {
  id: string;
  timestamp: Date;
  coinSymbol: string;
  sourceType: 'news' | 'social' | 'technical';
  sourceId: string;
  sourceUrl?: string;
  sourceContent: string;
  sourceAuthor?: string;
  sentiment: 'positive' | 'negative' | 'neutral';
  confidenceScore: number;
  predictedImpact: string;
  estimatedPriceChangePercent: number;
  recommendedAction: 'buy' | 'sell' | 'hold';
  recommendedLeverageMultiple: number;
  riskLevel: 'low' | 'medium' | 'high';
  reasoning: string;
  optimalEntryWindow: {
    start: string;
    end: string;
  };
  optimalExitWindow: {
    start: string;
    end: string;
  };
  currentPrice: number;
}

export interface Portfolio {
  userId: string;
  assets: PortfolioAsset[];
  totalValue: number;
  totalPnL: number;
  totalPnLPercent: number;
  updatedAt: Date;
}

export interface PortfolioAsset {
  symbol: string;
  name: string;
  amount: number;
  averagePrice: number;
  currentPrice: number;
  pnl: number;
  pnlPercent: number;
  addedAt: Date;
  updatedAt: Date;
}

export interface NewsItem {
  id: string;
  title: string;
  content: string;
  source: string;
  url: string;
  publishedAt: Date;
  sentiment: 'positive' | 'negative' | 'neutral';
  relevantCoins: string[];
  impactScore: number;
}

export interface TradingPosition {
  id: string;
  userId: string;
  coinSymbol: string;
  type: 'long' | 'short';
  leverage: number;
  entryPrice: number;
  currentPrice: number;
  size: number;
  pnl: number;
  pnlPercent: number;
  stopLoss?: number;
  takeProfit?: number;
  status: 'open' | 'closed' | 'pending';
  createdAt: Date;
  updatedAt: Date;
}

export const USER_LIMITS = {
  free: {
    signalsPerDay: 3,
    portfolioAssets: 3,
    apiCallsPerHour: 10,
    historicalDataDays: 7,
    notifications: false,
    autoTrading: false
  },
  premium: {
    signalsPerDay: Infinity,
    portfolioAssets: 10,
    apiCallsPerHour: 100,
    historicalDataDays: 90,
    notifications: true,
    autoTrading: 'basic'
  },
  pro: {
    signalsPerDay: Infinity,
    portfolioAssets: 50,
    apiCallsPerHour: 1000,
    historicalDataDays: 365,
    notifications: true,
    autoTrading: 'advanced'
  },
  enterprise: {
    signalsPerDay: Infinity,
    portfolioAssets: Infinity,
    apiCallsPerHour: Infinity,
    historicalDataDays: Infinity,
    notifications: true,
    autoTrading: 'custom'
  }
};