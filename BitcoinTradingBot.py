#!/usr/bin/env python3
"""
Bitcoin Leverage Trading Bot

This script connects the BitcoinTrader and TradingStrategy modules
to create a complete trading bot that can execute trades based on 
technical analysis strategies.
"""

import time
import logging
import argparse
import pandas as pd
from datetime import datetime, timedelta
import schedule
import json
import os

# Import our custom modules
from BitcoinTrader import BitcoinTrader
from TradingStrategy import (
    MACrossoverStrategy, 
    RSIStrategy, 
    BollingerBandsStrategy, 
    MACDStrategy,
    CombinedStrategy
)

class BitcoinTradingBot:
    """
    Bitcoin Trading Bot that combines a BitcoinTrader with trading strategies
    to automate Bitcoin leverage trading.
    """
    
    def __init__(self, config_file=None):
        """
        Initialize the trading bot
        
        Parameters:
        -----------
        config_file : str
            Path to configuration file (JSON)
        """
        # Load configuration
        self.config = self.load_config(config_file)
        
        # Setup logging
        self.setup_logging()
        
        # Initialize trader
        self.trader = self.setup_trader()
        
        # Initialize strategies
        self.strategy = self.setup_strategy()
        
        # Bot state
        self.last_check_time = None
        self.running = False
        
        # Performance metrics
        self.performance = {
            'trades_executed': 0,
            'profitable_trades': 0,
            'losing_trades': 0,
            'total_profit_pct': 0,
            'win_rate': 0
        }
        
        self.logger.info("Bitcoin Trading Bot initialized")
    
    def load_config(self, config_file):
        """
        Load configuration from file
        
        Parameters:
        -----------
        config_file : str
            Path to configuration file (JSON)
            
        Returns:
        --------
        dict : Configuration
        """
        default_config = {
            "exchange": {
                "id": "binance",
                "api_key": "",
                "secret": "",
                "testnet": True
            },
            "trading": {
                "symbol": "BTC/USDT",
                "timeframe": "1h",
                "leverage": 3,
                "position_size_pct": 0.1,
                "max_open_positions": 3,
                "stop_loss_pct": 0.05,
                "take_profit_pct": 0.15
            },
            "strategy": {
                "type": "combined",
                "strategies": [
                    {
                        "name": "MACD",
                        "weight": 1.0,
                        "params": {
                            "fast_period": 12,
                            "slow_period": 26,
                            "signal_period": 9
                        }
                    },
                    {
                        "name": "RSI",
                        "weight": 0.8,
                        "params": {
                            "period": 14,
                            "oversold": 30,
                            "overbought": 70
                        }
                    }
                ],
                "confidence_threshold": 60
            },
            "bot": {
                "check_interval": 300,  # seconds
                "trading_hours": {
                    "active": True,
                    "start": "09:00",
                    "end": "22:00"
                },
                "log_level": "INFO"
            }
        }
        
        # If config file is provided, load and merge with defaults
        if config_file and os.path.exists(config_file):
            try:
                with open(config_file, 'r') as f:
                    user_config = json.load(f)
                
                # Merge configs (nested update)
                self.merge_configs(default_config, user_config)
                
                return default_config
            except Exception as e:
                print(f"Error loading config file: {e}")
                print("Using default configuration")
                return default_config
        
        return default_config
    
    def merge_configs(self, default_config, user_config):
        """
        Recursively merge user config into default config
        
        Parameters:
        -----------
        default_config : dict
            Default configuration
        user_config : dict
            User configuration to merge in
        """
        for key, value in user_config.items():
            if isinstance(value, dict) and key in default_config and isinstance(default_config[key], dict):
                self.merge_configs(default_config[key], value)
            else:
                default_config[key] = value
    
    def setup_logging(self):
        """Set up logging for the bot"""
        log_level = getattr(logging, self.config['bot']['log_level'])
        
        # Create logs directory if it doesn't exist
        today = datetime.today().strftime("%Y%m%d")
        log_folder_path = f"./logs/{today}"
        if not os.path.exists(log_folder_path):
            os.makedirs(log_folder_path)
        
        # Set up logging
        log_file_path = f"{log_folder_path}/trading_bot.log"
        log_format = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
        
        # Configure root logger
        logging.basicConfig(
            level=log_level,
            format=log_format,
            handlers=[
                logging.FileHandler(log_file_path),
                logging.StreamHandler()
            ]
        )
        
        self.logger = logging.getLogger("TradingBot")
    
    def setup_trader(self):
        """
        Set up the Bitcoin trader
        
        Returns:
        --------
        BitcoinTrader : Configured trader instance
        """
        exchange_config = self.config['exchange']
        trading_config = self.config['trading']
        
        trader = BitcoinTrader(
            exchange_id=exchange_config['id'],
            api_key=exchange_config['api_key'],
            secret=exchange_config['secret'],
            leverage=trading_config['leverage']
        )
        
        # Configure trader
        trader.symbol = trading_config['symbol']
        trader.timeframe = trading_config['timeframe']
        trader.position_size_pct = trading_config['position_size_pct']
        trader.max_open_positions = trading_config['max_open_positions']
        trader.stop_loss_pct = trading_config['stop_loss_pct']
        trader.take_profit_pct = trading_config['take_profit_pct']
        
        # Configure trading hours
        trading_hours = self.config['bot']['trading_hours']
        trader.trading_active = trading_hours['active']
        trader.trading_start_time = trading_hours['start']
        trader.trading_end_time = trading_hours['end']
        
        # Set leverage
        trader.set_leverage(trading_config['leverage'])
        
        return trader
    
    def setup_strategy(self):
        """
        Set up the trading strategy
        
        Returns:
        --------
        BaseTradingStrategy : Configured strategy instance
        """
        strategy_config = self.config['strategy']
        strategy_type = strategy_config['type']
        
        if strategy_type == 'combined':
            # Create a combined strategy with multiple sub-strategies
            combined = CombinedStrategy()
            
            for strat_config in strategy_config['strategies']:
                strat_name = strat_config['name']
                strat_weight = strat_config['weight']
                strat_params = strat_config['params']
                
                if strat_name == 'MA':
                    strategy = MACrossoverStrategy(
                        fast_period=strat_params.get('fast_period', 12),
                        slow_period=strat_params.get('slow_period', 26)
                    )
                elif strat_name == 'RSI':
                    strategy = RSIStrategy(
                        period=strat_params.get('period', 14),
                        oversold=strat_params.get('oversold', 30),
                        overbought=strat_params.get('overbought', 70)
                    )
                elif strat_name == 'BB':
                    strategy = BollingerBandsStrategy(
                        period=strat_params.get('period', 20),
                        std_dev=strat_params.get('std_dev', 2)
                    )
                elif strat_name == 'MACD':
                    strategy = MACDStrategy(
                        fast_period=strat_params.get('fast_period', 12),
                        slow_period=strat_params.get('slow_period', 26),
                        signal_period=strat_params.get('signal_period', 9)
                    )
                else:
                    self.logger.warning(f"Unknown strategy type: {strat_name}, skipping")
                    continue
                
                combined.add_strategy(strategy, strat_weight)
            
            return combined
        
        elif strategy_type == 'MA':
            params = strategy_config.get('params', {})
            return MACrossoverStrategy(
                fast_period=params.get('fast_period', 12),
                slow_period=params.get('slow_period', 26)
            )
        
        elif strategy_type == 'RSI':
            params = strategy_config.get('params', {})
            return RSIStrategy(
                period=params.get('period', 14),
                oversold=params.get('oversold', 30),
                overbought=params.get('overbought', 70)
            )
        
        elif strategy_type == 'BB':
            params = strategy_config.get('params', {})
            return BollingerBandsStrategy(
                period=params.get('period', 20),
                std_dev=params.get('std_dev', 2)
            )
        
        elif strategy_type == 'MACD':
            params = strategy_config.get('params', {})
            return MACDStrategy(
                fast_period=params.get('fast_period', 12),
                slow_period=params.get('slow_period', 26),
                signal_period=params.get('signal_period', 9)
            )
        
        else:
            self.logger.warning(f"Unknown strategy type: {strategy_type}, using MACD as default")
            return MACDStrategy()
    
    def check_market(self):
        """
        Check market conditions and execute trades based on strategy signals
        """
        if not self.trader.is_trading_hours():
            self.logger.info("Outside trading hours, skipping market check")
            return
        
        self.logger.info("Checking market conditions...")
        
        # Get historical data
        data = self.trader.get_historical_data(
            symbol=self.trader.symbol,
            timeframe=self.trader.timeframe
        )
        
        if data.empty:
            self.logger.warning("No historical data available, skipping market check")
            return
        
        # Analyze data with the strategy
        signal = self.strategy.analyze(data)
        
        self.logger.info(f"Strategy signal: {signal['action']}, confidence: {signal['confidence']:.2f}%")
        
        # Check confidence threshold
        confidence_threshold = self.config['strategy'].get('confidence_threshold', 60)
        
        if signal['action'] == 'buy' and signal['confidence'] >= confidence_threshold:
            self.execute_buy_signal()
        elif signal['action'] == 'sell' and signal['confidence'] >= confidence_threshold:
            self.execute_sell_signal()
        else:
            self.logger.info("No action taken based on current signals")
        
        # Monitor active positions for stop loss / take profit
        self.monitor_positions()
        
        # Update last check time
        self.last_check_time = datetime.now()
    
    def execute_buy_signal(self):
        """Execute a buy signal if conditions are met"""
        # Check if we have reached max positions
        if len(self.trader.active_positions) >= self.trader.max_open_positions:
            self.logger.info(f"Maximum open positions reached ({self.trader.max_open_positions}), skipping buy signal")
            return
        
        # Check if we have any short positions to close first
        short_positions = [pos_id for pos_id, pos in self.trader.active_positions.items() if pos['type'] == 'short']
        
        if short_positions:
            # Close short positions first
            for pos_id in short_positions:
                self.logger.info(f"Closing short position {pos_id} before opening long")
                self.trader.close_position(pos_id)
        
        # Open long position
        self.logger.info("Executing buy signal")
        result = self.trader.open_long_position()
        
        if result:
            self.logger.info(f"Long position opened successfully")
            self.performance['trades_executed'] += 1
        else:
            self.logger.warning("Failed to open long position")
    
    def execute_sell_signal(self):
        """Execute a sell signal if conditions are met"""
        # Check if we have reached max positions
        if len(self.trader.active_positions) >= self.trader.max_open_positions:
            self.logger.info(f"Maximum open positions reached ({self.trader.max_open_positions}), skipping sell signal")
            return
        
        # Check if we have any long positions to close first
        long_positions = [pos_id for pos_id, pos in self.trader.active_positions.items() if pos['type'] == 'long']
        
        if long_positions:
            # Close long positions first
            for pos_id in long_positions:
                self.logger.info(f"Closing long position {pos_id} before opening short")
                self.trader.close_position(pos_id)
        
        # Open short position
        self.logger.info("Executing sell signal")
        result = self.trader.open_short_position()
        
        if result:
            self.logger.info(f"Short position opened successfully")
            self.performance['trades_executed'] += 1
        else:
            self.logger.warning("Failed to open short position")
    
    def monitor_positions(self):
        """Monitor and manage active positions"""
        if not self.trader.active_positions:
            return
        
        # Log current position status
        positions = self.trader.get_position_summary()
        self.logger.info(f"Monitoring {positions['total_positions']} active positions")
        
        for position in positions['positions']:
            self.logger.info(
                f"Position {position['id']} ({position['type']}): "
                f"Size: {position['size']:.6f} BTC, "
                f"Entry: {position['entry_price']:.2f}, "
                f"Current: {position['current_price']:.2f}, "
                f"PnL: {position['pnl_pct']:.2f}%"
            )
        
        # Check for stop loss / take profit
        closed_positions = self.trader.monitor_positions()
        
        if closed_positions:
            self.logger.info(f"Closed {len(closed_positions)} positions based on SL/TP")
            
            # Update performance metrics
            for pos_id in closed_positions:
                position = next((p for p in self.trader.position_history if p['id'] == pos_id), None)
                if position:
                    pnl = position.get('pnl_pct', 0)
                    self.performance['total_profit_pct'] += pnl
                    
                    if pnl > 0:
                        self.performance['profitable_trades'] += 1
                    else:
                        self.performance['losing_trades'] += 1
                    
                    # Update win rate
                    total_closed = self.performance['profitable_trades'] + self.performance['losing_trades']
                    if total_closed > 0:
                        self.performance['win_rate'] = (self.performance['profitable_trades'] / total_closed) * 100
    
    def start(self):
        """Start the trading bot"""
        if self.running:
            self.logger.warning("Trading bot is already running")
            return
        
        self.running = True
        self.logger.info("Starting trading bot")
        
        # Run initial check
        self.check_market()
        
        # Set up schedule
        check_interval = self.config['bot']['check_interval']
        schedule.every(check_interval).seconds.do(self.check_market)
        
        try:
            while self.running:
                schedule.run_pending()
                time.sleep(1)
        except KeyboardInterrupt:
            self.logger.info("Bot stopped by user")
            self.stop()
        except Exception as e:
            self.logger.error(f"Error in bot main loop: {e}")
            self.stop()
    
    def stop(self):
        """Stop the trading bot"""
        self.running = False
        self.logger.info("Stopping trading bot")
        
        # Cancel all scheduled jobs
        schedule.clear()
        
        # Save state
        self.logger.info("Saving trader state")
        self.trader.save_state()
        
        # Log performance
        self.log_performance()
    
    def log_performance(self):
        """Log bot performance metrics"""
        self.logger.info("------ Performance Summary ------")
        self.logger.info(f"Total trades: {self.performance['trades_executed']}")
        self.logger.info(f"Profitable trades: {self.performance['profitable_trades']}")
        self.logger.info(f"Losing trades: {self.performance['losing_trades']}")
        self.logger.info(f"Win rate: {self.performance['win_rate']:.2f}%")
        self.logger.info(f"Total profit: {self.performance['total_profit_pct']:.2f}%")
        self.logger.info("---------------------------------")
    
    def create_config_template(self, filename="config_template.json"):
        """
        Create a configuration template file
        
        Parameters:
        -----------
        filename : str
            Path to save the template
        """
        with open(filename, 'w') as f:
            json.dump(self.config, f, indent=4)
        
        print(f"Configuration template saved to {filename}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Bitcoin Trading Bot")
    parser.add_argument("-c", "--config", help="Path to configuration file", default=None)
    parser.add_argument("--create-config", action="store_true", help="Create configuration template")
    args = parser.parse_args()
    
    bot = BitcoinTradingBot(args.config)
    
    if args.create_config:
        bot.create_config_template()
    else:
        try:
            bot.start()
        except KeyboardInterrupt:
            print("\nStopping bot...")
        finally:
            bot.stop()