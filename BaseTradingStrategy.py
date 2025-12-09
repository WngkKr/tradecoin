import pandas as pd
import numpy as np
import talib
from abc import ABC, abstractmethod

class BaseTradingStrategy(ABC):
    """
    Abstract base class for trading strategies.
    All trading strategies should inherit from this class.
    """
    
    def __init__(self, name="BaseStrategy"):
        self.name = name
        self.indicators = {}
    
    @abstractmethod
    def analyze(self, data):
        """
        Analyze market data and generate signals
        
        Parameters:
        -----------
        data : pandas.DataFrame
            OHLCV data for analysis
            
        Returns:
        --------
        dict : Signal information
        """
        pass
    
    def calculate_indicators(self, data):
        """
        Calculate technical indicators used by the strategy
        
        Parameters:
        -----------
        data : pandas.DataFrame
            OHLCV data for calculation
            
        Returns:
        --------
        dict : Calculated indicators
        """
        return {}
    
    def get_name(self):
        """Get strategy name"""
        return self.name


class MACrossoverStrategy(BaseTradingStrategy):
    """
    Moving Average Crossover Strategy
    
    Generates buy signals when the fast MA crosses above the slow MA,
    and sell signals when the fast MA crosses below the slow MA.
    """
    
    def __init__(self, fast_period=12, slow_period=26, name="MA Crossover"):
        super().__init__(name)
        self.fast_period = fast_period
        self.slow_period = slow_period
    
    def calculate_indicators(self, data):
        """Calculate fast and slow moving averages"""
        self.indicators = {
            'fast_ma': data['close'].rolling(window=self.fast_period).mean(),
            'slow_ma': data['close'].rolling(window=self.slow_period).mean()
        }
        return self.indicators
    
    def analyze(self, data):
        """
        Analyze price data and generate trading signals
        
        Returns:
        --------
        dict : Signal with action, price, confidence, and metadata
        """
        # Calculate indicators if not already calculated
        if not self.indicators:
            self.calculate_indicators(data)
        
        fast_ma = self.indicators['fast_ma']
        slow_ma = self.indicators['slow_ma']
        
        # Get the last two values to determine crossover
        fast_ma_current = fast_ma.iloc[-1]
        fast_ma_prev = fast_ma.iloc[-2]
        slow_ma_current = slow_ma.iloc[-1]
        slow_ma_prev = slow_ma.iloc[-2]
        
        # Check for crossovers
        if fast_ma_prev < slow_ma_prev and fast_ma_current > slow_ma_current:
            # Bullish crossover (buy signal)
            action = "buy"
            confidence = min(100, abs(fast_ma_current - slow_ma_current) / slow_ma_current * 1000)
        elif fast_ma_prev > slow_ma_prev and fast_ma_current < slow_ma_current:
            # Bearish crossover (sell signal)
            action = "sell"
            confidence = min(100, abs(fast_ma_current - slow_ma_current) / slow_ma_current * 1000)
        else:
            # No crossover
            action = "hold"
            confidence = 0
        
        # Current price
        current_price = data['close'].iloc[-1]
        
        return {
            'action': action,
            'price': current_price,
            'confidence': confidence,
            'fast_ma': fast_ma_current,
            'slow_ma': slow_ma_current,
            'timestamp': data.index[-1]
        }


class RSIStrategy(BaseTradingStrategy):
    """
    Relative Strength Index (RSI) Strategy
    
    Generates buy signals when RSI falls below oversold level,
    and sell signals when RSI rises above overbought level.
    """
    
    def __init__(self, period=14, oversold=30, overbought=70, name="RSI Strategy"):
        super().__init__(name)
        self.period = period
        self.oversold = oversold
        self.overbought = overbought
    
    def calculate_indicators(self, data):
        """Calculate RSI indicator"""
        try:
            # Use talib for RSI calculation if available
            import talib
            rsi = talib.RSI(data['close'].values, timeperiod=self.period)
            self.indicators = {'rsi': pd.Series(rsi, index=data.index)}
        except ImportError:
            # Fallback to manual calculation
            delta = data['close'].diff()
            gain = delta.where(delta > 0, 0)
            loss = -delta.where(delta < 0, 0)
            
            avg_gain = gain.rolling(window=self.period).mean()
            avg_loss = loss.rolling(window=self.period).mean()
            
            rs = avg_gain / avg_loss
            rsi = 100 - (100 / (1 + rs))
            self.indicators = {'rsi': rsi}
            
        return self.indicators
    
    def analyze(self, data):
        """
        Analyze price data using RSI and generate trading signals
        
        Returns:
        --------
        dict : Signal with action, price, confidence, and metadata
        """
        # Calculate indicators if not already calculated
        if not self.indicators:
            self.calculate_indicators(data)
        
        rsi = self.indicators['rsi']
        
        # Get the last two values to determine trend
        rsi_current = rsi.iloc[-1]
        rsi_prev = rsi.iloc[-2]
        
        # Check RSI conditions
        if rsi_current < self.oversold and rsi_prev > self.oversold:
            # RSI crossed below oversold (buy signal)
            action = "buy"
            confidence = min(100, (self.oversold - rsi_current) * 5)
        elif rsi_current > self.overbought and rsi_prev < self.overbought:
            # RSI crossed above overbought (sell signal)
            action = "sell"
            confidence = min(100, (rsi_current - self.overbought) * 5)
        else:
            # No significant RSI movement
            action = "hold"
            confidence = 0
        
        # Current price
        current_price = data['close'].iloc[-1]
        
        return {
            'action': action,
            'price': current_price,
            'confidence': confidence,
            'rsi': rsi_current,
            'timestamp': data.index[-1]
        }


class BollingerBandsStrategy(BaseTradingStrategy):
    """
    Bollinger Bands Strategy
    
    Generates buy signals when price touches the lower band,
    and sell signals when price touches the upper band.
    """
    
    def __init__(self, period=20, std_dev=2, name="Bollinger Bands"):
        super().__init__(name)
        self.period = period
        self.std_dev = std_dev
    
    def calculate_indicators(self, data):
        """Calculate Bollinger Bands"""
        middle_band = data['close'].rolling(window=self.period).mean()
        std = data['close'].rolling(window=self.period).std()
        upper_band = middle_band + (std * self.std_dev)
        lower_band = middle_band - (std * self.std_dev)
        
        self.indicators = {
            'middle_band': middle_band,
            'upper_band': upper_band,
            'lower_band': lower_band,
            'bandwidth': (upper_band - lower_band) / middle_band
        }
        
        return self.indicators
    
    def analyze(self, data):
        """
        Analyze price data using Bollinger Bands and generate trading signals
        
        Returns:
        --------
        dict : Signal with action, price, confidence, and metadata
        """
        # Calculate indicators if not already calculated
        if not self.indicators:
            self.calculate_indicators(data)
        
        middle_band = self.indicators['middle_band']
        upper_band = self.indicators['upper_band']
        lower_band = self.indicators['lower_band']
        bandwidth = self.indicators['bandwidth']
        
        # Current price and bands
        current_price = data['close'].iloc[-1]
        current_upper = upper_band.iloc[-1]
        current_lower = lower_band.iloc[-1]
        current_middle = middle_band.iloc[-1]
        current_bandwidth = bandwidth.iloc[-1]
        
        # Determine position relative to bands
        band_position = (current_price - current_lower) / (current_upper - current_lower) if (current_upper - current_lower) > 0 else 0.5
        
        # Check for signals
        if current_price <= current_lower:
            # Price at or below lower band (buy signal)
            action = "buy"
            confidence = min(100, (1 - band_position) * 100)
        elif current_price >= current_upper:
            # Price at or above upper band (sell signal)
            action = "sell"
            confidence = min(100, band_position * 100)
        else:
            # Price within bands
            action = "hold"
            confidence = 0
        
        return {
            'action': action,
            'price': current_price,
            'confidence': confidence,
            'middle_band': current_middle,
            'upper_band': current_upper,
            'lower_band': current_lower,
            'bandwidth': current_bandwidth,
            'band_position': band_position,
            'timestamp': data.index[-1]
        }


class MACDStrategy(BaseTradingStrategy):
    """
    MACD (Moving Average Convergence Divergence) Strategy
    
    Generates buy signals when MACD line crosses above signal line,
    and sell signals when MACD line crosses below signal line.
    """
    
    def __init__(self, fast_period=12, slow_period=26, signal_period=9, name="MACD Strategy"):
        super().__init__(name)
        self.fast_period = fast_period
        self.slow_period = slow_period
        self.signal_period = signal_period
    
    def calculate_indicators(self, data):
        """Calculate MACD indicators"""
        try:
            # Use talib for MACD calculation if available
            import talib
            macd, signal, histogram = talib.MACD(
                data['close'].values, 
                fastperiod=self.fast_period, 
                slowperiod=self.slow_period, 
                signalperiod=self.signal_period
            )
            self.indicators = {
                'macd': pd.Series(macd, index=data.index),
                'signal': pd.Series(signal, index=data.index),
                'histogram': pd.Series(histogram, index=data.index)
            }
        except ImportError:
            # Fallback to manual calculation
            exp1 = data['close'].ewm(span=self.fast_period, adjust=False).mean()
            exp2 = data['close'].ewm(span=self.slow_period, adjust=False).mean()
            macd = exp1 - exp2
            signal = macd.ewm(span=self.signal_period, adjust=False).mean()
            histogram = macd - signal
            
            self.indicators = {
                'macd': macd,
                'signal': signal,
                'histogram': histogram
            }
            
        return self.indicators
    
    def analyze(self, data):
        """
        Analyze price data using MACD and generate trading signals
        
        Returns:
        --------
        dict : Signal with action, price, confidence, and metadata
        """
        # Calculate indicators if not already calculated
        if not self.indicators:
            self.calculate_indicators(data)
        
        macd = self.indicators['macd']
        signal = self.indicators['signal']
        histogram = self.indicators['histogram']
        
        # Get the last two values to determine crossover
        macd_current = macd.iloc[-1]
        macd_prev = macd.iloc[-2]
        signal_current = signal.iloc[-1]
        signal_prev = signal.iloc[-2]
        
        # Check for crossovers
        if macd_prev < signal_prev and macd_current > signal_current:
            # Bullish crossover (buy signal)
            action = "buy"
            confidence = min(100, abs(macd_current - signal_current) / abs(signal_current) * 100 if signal_current != 0 else 50)
        elif macd_prev > signal_prev and macd_current < signal_current:
            # Bearish crossover (sell signal)
            action = "sell"
            confidence = min(100, abs(macd_current - signal_current) / abs(signal_current) * 100 if signal_current != 0 else 50)
        else:
            # No crossover
            action = "hold"
            confidence = 0
        
        # Current price
        current_price = data['close'].iloc[-1]
        
        return {
            'action': action,
            'price': current_price,
            'confidence': confidence,
            'macd': macd_current,
            'signal': signal_current,
            'histogram': histogram.iloc[-1],
            'timestamp': data.index[-1]
        }


class CombinedStrategy(BaseTradingStrategy):
    """
    Combined Strategy
    
    Combines multiple strategies and weighs their signals
    to generate a final trading decision.
    """
    
    def __init__(self, strategies=None, weights=None, name="Combined Strategy"):
        super().__init__(name)
        self.strategies = strategies or []
        self.weights = weights or {}
        
        # Set default weights if not provided
        if not self.weights and self.strategies:
            equal_weight = 1.0 / len(self.strategies)
            self.weights = {strategy.get_name(): equal_weight for strategy in self.strategies}
    
    def add_strategy(self, strategy, weight=1.0):
        """
        Add a strategy to the combined strategy
        
        Parameters:
        -----------
        strategy : BaseTradingStrategy
            Strategy to add
        weight : float
            Weight of the strategy (default: 1.0)
        """
        self.strategies.append(strategy)
        self.weights[strategy.get_name()] = weight
        
        # Normalize weights
        total_weight = sum(self.weights.values())
        for key in self.weights:
            self.weights[key] /= total_weight
    
    def analyze(self, data):
        """
        Analyze price data using all strategies and generate a combined signal
        
        Returns:
        --------
        dict : Combined signal with action, price, confidence, and metadata
        """
        if not self.strategies:
            return {
                'action': 'hold',
                'price': data['close'].iloc[-1],
                'confidence': 0,
                'timestamp': data.index[-1]
            }
        
        # Collect signals from all strategies
        signals = []
        for strategy in self.strategies:
            signal = strategy.analyze(data)
            signals.append((strategy.get_name(), signal))
        
        # Convert actions to numeric values
        action_values = {
            'buy': 1,
            'hold': 0,
            'sell': -1
        }
        
        # Calculate weighted signal
        weighted_value = 0
        total_confidence = 0
        
        for strategy_name, signal in signals:
            weight = self.weights.get(strategy_name, 1.0 / len(self.strategies))
            action_value = action_values.get(signal['action'], 0)
            confidence = signal['confidence'] / 100.0  # Normalize to 0-1
            
            weighted_value += action_value * confidence * weight
            total_confidence += confidence * weight
        
        # Determine final action
        if weighted_value > 0.2:
            final_action = 'buy'
        elif weighted_value < -0.2:
            final_action = 'sell'
        else:
            final_action = 'hold'
        
        # Determine confidence
        if final_action != 'hold':
            final_confidence = min(100, abs(weighted_value) * 100)
        else:
            final_confidence = 0
        
        # Current price
        current_price = data['close'].iloc[-1]
        
        # Prepare strategy details
        strategy_details = {f"{name}_action": signal['action'] for name, signal in signals}
        strategy_details.update({f"{name}_confidence": signal['confidence'] for name, signal in signals})
        
        # Combine all information
        result = {
            'action': final_action,
            'price': current_price,
            'confidence': final_confidence,
            'weighted_value': weighted_value,
            'strategies_used': len(self.strategies),
            'timestamp': data.index[-1]
        }
        
        result.update(strategy_details)
        
        return result