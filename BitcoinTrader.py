import ccxt
import pandas as pd
import time
import os
import logging
from datetime import datetime, timedelta
import numpy as np
import json

class BitcoinTrader:
    """
    Bitcoin leverage trading module that connects to exchanges via CCXT,
    executes trades, and manages positions.
    """
    
    def __init__(self, exchange_id='binance', api_key=None, secret=None, leverage=3):
        """
        Initialize the BitcoinTrader
        
        Parameters:
        -----------
        exchange_id : str
            The exchange to connect to (default: 'binance')
        api_key : str
            API key for the exchange
        secret : str
            API secret for the exchange
        leverage : int
            Default leverage to use for trading (default: 3x)
        """
        self.setup_logging()
        
        # Exchange connection
        self.exchange_id = exchange_id
        self.leverage = leverage
        self.exchange = self.connect_exchange(exchange_id, api_key, secret)
        
        # Trading parameters
        self.symbol = 'BTC/USDT'
        self.timeframe = '1h'  # Default timeframe
        
        # Position tracking
        self.active_positions = {}
        self.position_history = []
        self.trade_history = []
        
        # Risk management
        self.max_open_positions = 3
        self.position_size_pct = 0.1  # 10% of available balance per position
        self.stop_loss_pct = 0.05     # 5% stop loss
        self.take_profit_pct = 0.15   # 15% take profit
        
        # Trading hours
        self.trading_active = True
        self.trading_start_time = "09:00"
        self.trading_end_time = "22:00"
        
        self.logger.info(f"BitcoinTrader initialized with {exchange_id}, leverage: {leverage}x")
        
    def setup_logging(self):
        """Set up logging configuration"""
        # Create logs directory if it doesn't exist
        today = datetime.today().strftime("%Y%m%d")
        log_folder_path = f"./logs/{today}"
        if not os.path.exists(log_folder_path):
            os.makedirs(log_folder_path)
        
        # Set up logging
        log_file_path = f"{log_folder_path}/bitcoin_trader.log"
        log_format = "%(asctime)s - %(levelname)s - %(message)s"
        logging.basicConfig(
            filename=log_file_path,
            level=logging.INFO,
            format=log_format
        )
        self.logger = logging.getLogger("BitcoinTrader")
        
        # Also log to console
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(logging.Formatter(log_format))
        self.logger.addHandler(console_handler)
        
    def connect_exchange(self, exchange_id, api_key=None, secret=None):
        """
        Connect to the exchange using CCXT
        
        Returns:
        --------
        ccxt.Exchange : The exchange instance
        """
        try:
            exchange_class = getattr(ccxt, exchange_id)
            exchange = exchange_class({
                'apiKey': api_key,
                'secret': secret,
                'enableRateLimit': True,
                'options': {
                    'defaultType': 'future',  # Use futures for leverage trading
                }
            })
            self.logger.info(f"Connected to {exchange_id} exchange")
            return exchange
        except Exception as e:
            self.logger.error(f"Failed to connect to exchange: {e}")
            raise
    
    def set_leverage(self, leverage=None):
        """
        Set leverage for trading
        
        Parameters:
        -----------
        leverage : int
            Leverage to use (1-125 depending on exchange)
        """
        if leverage:
            self.leverage = leverage
            
        try:
            self.exchange.fapiPrivatePostLeverage({
                'symbol': self.symbol.replace('/', ''),
                'leverage': self.leverage
            })
            self.logger.info(f"Leverage set to {self.leverage}x for {self.symbol}")
        except Exception as e:
            self.logger.error(f"Failed to set leverage: {e}")
            raise
    
    def get_account_balance(self):
        """
        Get account balance
        
        Returns:
        --------
        float : Available balance in USDT
        """
        try:
            balance = self.exchange.fetch_balance()
            usdt_balance = balance['USDT']['free']
            self.logger.info(f"Account balance: {usdt_balance} USDT")
            return usdt_balance
        except Exception as e:
            self.logger.error(f"Failed to get account balance: {e}")
            return 0
    
    def get_market_price(self, symbol=None):
        """
        Get current market price for a symbol
        
        Parameters:
        -----------
        symbol : str
            Trading pair (default: self.symbol)
            
        Returns:
        --------
        float : Current price
        """
        if not symbol:
            symbol = self.symbol
            
        try:
            ticker = self.exchange.fetch_ticker(symbol)
            return ticker['last']
        except Exception as e:
            self.logger.error(f"Failed to get market price for {symbol}: {e}")
            return None
    
    def get_historical_data(self, symbol=None, timeframe=None, since=None, limit=100):
        """
        Get historical OHLCV data
        
        Parameters:
        -----------
        symbol : str
            Trading pair (default: self.symbol)
        timeframe : str
            Timeframe (default: self.timeframe)
        since : int
            Timestamp in milliseconds
        limit : int
            Number of candles to fetch
            
        Returns:
        --------
        pandas.DataFrame : OHLCV data
        """
        if not symbol:
            symbol = self.symbol
        if not timeframe:
            timeframe = self.timeframe
            
        try:
            ohlcv = self.exchange.fetch_ohlcv(symbol, timeframe, since, limit)
            df = pd.DataFrame(ohlcv, columns=['timestamp', 'open', 'high', 'low', 'close', 'volume'])
            df['timestamp'] = pd.to_datetime(df['timestamp'], unit='ms')
            df.set_index('timestamp', inplace=True)
            return df
        except Exception as e:
            self.logger.error(f"Failed to get historical data: {e}")
            return pd.DataFrame()
    
    def calculate_position_size(self, price, risk_pct=None):
        """
        Calculate position size based on available balance and risk percentage
        
        Parameters:
        -----------
        price : float
            Current price of the asset
        risk_pct : float
            Percentage of available balance to risk (default: self.position_size_pct)
            
        Returns:
        --------
        float : Position size in BTC
        """
        if risk_pct is None:
            risk_pct = self.position_size_pct
            
        balance = self.get_account_balance()
        position_value = balance * risk_pct
        
        # Adjust for leverage
        position_value = position_value * self.leverage
        
        # Convert to BTC
        position_size = position_value / price
        
        # Round to appropriate precision
        position_size = round(position_size, 6)
        
        self.logger.info(f"Calculated position size: {position_size} BTC (value: {position_value} USDT)")
        return position_size
    
    def open_long_position(self, size=None, price=None):
        """
        Open a long position
        
        Parameters:
        -----------
        size : float
            Position size in BTC (if None, calculated based on risk)
        price : float
            Price to open position (if None, market price is used)
            
        Returns:
        --------
        dict : Order information
        """
        if len(self.active_positions) >= self.max_open_positions:
            self.logger.warning(f"Max open positions ({self.max_open_positions}) reached. Cannot open new position.")
            return None
            
        try:
            current_price = self.get_market_price()
            if not price:
                price = current_price
                
            if not size:
                size = self.calculate_position_size(current_price)
                
            # Create market buy order
            order = self.exchange.create_market_buy_order(self.symbol, size)
            
            # Calculate stop loss and take profit levels
            stop_loss = current_price * (1 - self.stop_loss_pct)
            take_profit = current_price * (1 + self.take_profit_pct)
            
            # Track position
            position_id = order['id']
            self.active_positions[position_id] = {
                'id': position_id,
                'type': 'long',
                'symbol': self.symbol,
                'size': size,
                'entry_price': current_price,
                'stop_loss': stop_loss,
                'take_profit': take_profit,
                'leverage': self.leverage,
                'open_time': datetime.now(),
                'status': 'open'
            }
            
            # Add to trade history
            self.trade_history.append({
                'action': 'open_long',
                'symbol': self.symbol,
                'size': size,
                'price': current_price,
                'timestamp': datetime.now()
            })
            
            self.logger.info(f"Opened long position: {size} BTC at {current_price} USDT")
            return order
        except Exception as e:
            self.logger.error(f"Failed to open long position: {e}")
            return None
    
    def open_short_position(self, size=None, price=None):
        """
        Open a short position
        
        Parameters:
        -----------
        size : float
            Position size in BTC (if None, calculated based on risk)
        price : float
            Price to open position (if None, market price is used)
            
        Returns:
        --------
        dict : Order information
        """
        if len(self.active_positions) >= self.max_open_positions:
            self.logger.warning(f"Max open positions ({self.max_open_positions}) reached. Cannot open new position.")
            return None
            
        try:
            current_price = self.get_market_price()
            if not price:
                price = current_price
                
            if not size:
                size = self.calculate_position_size(current_price)
                
            # Create market sell order
            order = self.exchange.create_market_sell_order(self.symbol, size)
            
            # Calculate stop loss and take profit levels
            stop_loss = current_price * (1 + self.stop_loss_pct)
            take_profit = current_price * (1 - self.take_profit_pct)
            
            # Track position
            position_id = order['id']
            self.active_positions[position_id] = {
                'id': position_id,
                'type': 'short',
                'symbol': self.symbol,
                'size': size,
                'entry_price': current_price,
                'stop_loss': stop_loss,
                'take_profit': take_profit,
                'leverage': self.leverage,
                'open_time': datetime.now(),
                'status': 'open'
            }
            
            # Add to trade history
            self.trade_history.append({
                'action': 'open_short',
                'symbol': self.symbol,
                'size': size,
                'price': current_price,
                'timestamp': datetime.now()
            })
            
            self.logger.info(f"Opened short position: {size} BTC at {current_price} USDT")
            return order
        except Exception as e:
            self.logger.error(f"Failed to open short position: {e}")
            return None
    
    def close_position(self, position_id):
        """
        Close a specific position
        
        Parameters:
        -----------
        position_id : str
            ID of the position to close
            
        Returns:
        --------
        dict : Order information
        """
        if position_id not in self.active_positions:
            self.logger.warning(f"Position {position_id} not found in active positions")
            return None
            
        position = self.active_positions[position_id]
        
        try:
            # Create order to close position
            if position['type'] == 'long':
                order = self.exchange.create_market_sell_order(position['symbol'], position['size'])
            else:  # short
                order = self.exchange.create_market_buy_order(position['symbol'], position['size'])
                
            current_price = self.get_market_price()
            
            # Calculate profit/loss
            if position['type'] == 'long':
                pnl_pct = (current_price - position['entry_price']) / position['entry_price'] * 100 * self.leverage
            else:  # short
                pnl_pct = (position['entry_price'] - current_price) / position['entry_price'] * 100 * self.leverage
                
            # Update position status
            position['close_price'] = current_price
            position['close_time'] = datetime.now()
            position['status'] = 'closed'
            position['pnl_pct'] = pnl_pct
            
            # Move to position history
            self.position_history.append(position)
            del self.active_positions[position_id]
            
            # Add to trade history
            self.trade_history.append({
                'action': f"close_{position['type']}",
                'symbol': position['symbol'],
                'size': position['size'],
                'price': current_price,
                'pnl_pct': pnl_pct,
                'timestamp': datetime.now()
            })
            
            self.logger.info(f"Closed {position['type']} position: {position['size']} BTC at {current_price} USDT, PnL: {pnl_pct:.2f}%")
            return order
        except Exception as e:
            self.logger.error(f"Failed to close position {position_id}: {e}")
            return None
    
    def close_all_positions(self):
        """
        Close all active positions
        
        Returns:
        --------
        list : List of closed position IDs
        """
        closed_positions = []
        
        for position_id in list(self.active_positions.keys()):
            result = self.close_position(position_id)
            if result:
                closed_positions.append(position_id)
                
        self.logger.info(f"Closed {len(closed_positions)} positions")
        return closed_positions
    
    def monitor_positions(self):
        """
        Monitor active positions and close them if they hit stop loss or take profit
        
        Returns:
        --------
        list : List of closed position IDs
        """
        closed_positions = []
        current_price = self.get_market_price()
        
        for position_id, position in list(self.active_positions.items()):
            # Skip if already closed
            if position['status'] != 'open':
                continue
                
            # Check if stop loss or take profit hit
            if position['type'] == 'long':
                # Stop loss hit
                if current_price <= position['stop_loss']:
                    self.logger.info(f"Stop loss hit for long position {position_id}")
                    result = self.close_position(position_id)
                    if result:
                        closed_positions.append(position_id)
                
                # Take profit hit
                elif current_price >= position['take_profit']:
                    self.logger.info(f"Take profit hit for long position {position_id}")
                    result = self.close_position(position_id)
                    if result:
                        closed_positions.append(position_id)
                        
            else:  # short
                # Stop loss hit
                if current_price >= position['stop_loss']:
                    self.logger.info(f"Stop loss hit for short position {position_id}")
                    result = self.close_position(position_id)
                    if result:
                        closed_positions.append(position_id)
                
                # Take profit hit
                elif current_price <= position['take_profit']:
                    self.logger.info(f"Take profit hit for short position {position_id}")
                    result = self.close_position(position_id)
                    if result:
                        closed_positions.append(position_id)
        
        return closed_positions
    
    def is_trading_hours(self):
        """
        Check if current time is within trading hours
        
        Returns:
        --------
        bool : True if within trading hours, False otherwise
        """
        if not self.trading_active:
            return False
            
        current_time = datetime.now().strftime("%H:%M")
        return self.trading_start_time <= current_time <= self.trading_end_time
    
    def save_state(self, filename='bitcoin_trader_state.json'):
        """
        Save the current state of the trader to a file
        
        Parameters:
        -----------
        filename : str
            Filename to save state to
        """
        state = {
            'active_positions': self.active_positions,
            'position_history': self.position_history,
            'trade_history': self.trade_history,
            'exchange_id': self.exchange_id,
            'symbol': self.symbol,
            'leverage': self.leverage,
            'max_open_positions': self.max_open_positions,
            'position_size_pct': self.position_size_pct,
            'stop_loss_pct': self.stop_loss_pct,
            'take_profit_pct': self.take_profit_pct,
            'trading_active': self.trading_active,
            'trading_start_time': self.trading_start_time,
            'trading_end_time': self.trading_end_time,
            'last_saved': datetime.now().isoformat()
        }
        
        try:
            with open(filename, 'w') as f:
                json.dump(state, f, default=str)
            self.logger.info(f"Saved state to {filename}")
        except Exception as e:
            self.logger.error(f"Failed to save state: {e}")
    
    def load_state(self, filename='bitcoin_trader_state.json'):
        """
        Load the state of the trader from a file
        
        Parameters:
        -----------
        filename : str
            Filename to load state from
            
        Returns:
        --------
        bool : True if successful, False otherwise
        """
        try:
            with open(filename, 'r') as f:
                state = json.load(f)
                
            # Restore state
            self.active_positions = state.get('active_positions', {})
            self.position_history = state.get('position_history', [])
            self.trade_history = state.get('trade_history', [])
            self.symbol = state.get('symbol', self.symbol)
            self.leverage = state.get('leverage', self.leverage)
            self.max_open_positions = state.get('max_open_positions', self.max_open_positions)
            self.position_size_pct = state.get('position_size_pct', self.position_size_pct)
            self.stop_loss_pct = state.get('stop_loss_pct', self.stop_loss_pct)
            self.take_profit_pct = state.get('take_profit_pct', self.take_profit_pct)
            self.trading_active = state.get('trading_active', self.trading_active)
            self.trading_start_time = state.get('trading_start_time', self.trading_start_time)
            self.trading_end_time = state.get('trading_end_time', self.trading_end_time)
            
            self.logger.info(f"Loaded state from {filename}")
            return True
        except FileNotFoundError:
            self.logger.warning(f"State file {filename} not found")
            return False
        except Exception as e:
            self.logger.error(f"Failed to load state: {e}")
            return False
    
    def get_position_summary(self):
        """
        Get a summary of active positions
        
        Returns:
        --------
        dict : Summary of active positions
        """
        summary = {
            'total_positions': len(self.active_positions),
            'long_positions': 0,
            'short_positions': 0,
            'total_value': 0,
            'positions': []
        }
        
        current_price = self.get_market_price()
        
        for position_id, position in self.active_positions.items():
            position_type = position['type']
            position_size = position['size']
            entry_price = position['entry_price']
            
            # Calculate current value and PnL
            position_value = position_size * current_price
            
            if position_type == 'long':
                summary['long_positions'] += 1
                pnl_pct = (current_price - entry_price) / entry_price * 100 * self.leverage
            else:  # short
                summary['short_positions'] += 1
                pnl_pct = (entry_price - current_price) / entry_price * 100 * self.leverage
                
            summary['total_value'] += position_value
            
            # Add position details
            summary['positions'].append({
                'id': position_id,
                'type': position_type,
                'size': position_size,
                'entry_price': entry_price,
                'current_price': current_price,
                'value': position_value,
                'pnl_pct': pnl_pct,
                'open_time': position['open_time']
            })
            
        return summary