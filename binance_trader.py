#!/usr/bin/env python3
"""
Binance Trading Integration for TradeCoin
Real-time cryptocurrency trading via Binance API with comprehensive features.
"""

import os
import json
import ccxt
import sqlite3
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

logger = logging.getLogger(__name__)

class BinanceTrader:
    """
    Enhanced Binance trading client with real-time data and execution capabilities
    """

    def __init__(self, api_key: str = None, secret: str = None, sandbox: bool = None):
        """
        Initialize Binance trader

        Args:
            api_key: Binance API key (defaults to env BINANCE_API_KEY)
            secret: Binance secret key (defaults to env BINANCE_SECRET)
            sandbox: Use testnet sandbox (defaults to BINANCE_SANDBOX env variable)
        """
        self.api_key = api_key or os.getenv('BINANCE_API_KEY')
        self.secret = secret or os.getenv('BINANCE_SECRET')
        # If sandbox parameter is explicitly passed, use it. Otherwise check environment
        if sandbox is not None:
            self.sandbox = sandbox
        else:
            # Convert string environment variable to boolean
            env_sandbox = os.getenv('BINANCE_SANDBOX', 'true').lower()
            self.sandbox = env_sandbox in ['true', '1', 'yes', 'on']

        # Initialize exchange client
        self.exchange = self._connect_exchange()

        # Trading configuration
        self.default_symbol = 'BTC/USDT'
        self.position_cache = {}
        self.last_price_update = None
        self.price_cache = {}

        logger.info(f"BinanceTrader initialized - Sandbox: {self.sandbox}")

    def _connect_exchange(self) -> ccxt.binance:
        """Connect to Binance exchange"""
        try:
            config = {
                'enableRateLimit': True,
                'options': {
                    'adjustForTimeDifference': True,
                }
            }

            # Only add API credentials if they exist and are not placeholders
            if (self.api_key and self.secret and
                self.api_key != 'your_binance_api_key_here' and
                self.secret != 'your_binance_secret_here'):
                config['apiKey'] = self.api_key
                config['secret'] = self.secret

            # For public data, we don't need testnet
            # Only use testnet when we have valid API keys for trading
            if (self.sandbox and self.api_key and self.secret and
                self.api_key != 'your_binance_api_key_here'):
                config['urls'] = {
                    'api': {
                        'public': 'https://testnet.binance.vision/api',
                        'private': 'https://testnet.binance.vision/api',
                    }
                }
                config['hostname'] = 'testnet.binance.vision'
                config['options']['hostname'] = 'testnet.binance.vision'

            exchange = ccxt.binance(config)

            # Test connection for market data (public API)
            try:
                exchange.load_markets()
                if config.get('apiKey'):
                    logger.info("✅ Binance connection successful with API keys")
                else:
                    logger.info("✅ Binance connection successful (public data only)")
            except Exception as e:
                logger.warning(f"⚠️ Binance connection issue: {e}, using mock data")

            return exchange

        except Exception as e:
            logger.error(f"Failed to initialize Binance exchange: {e}")
            # Return a minimal config for fallback
            return ccxt.binance({'enableRateLimit': True})

    def get_account_info(self) -> Dict[str, Any]:
        """
        Get account information including balances and positions

        Returns:
            Dict containing account information
        """
        try:
            if not self.api_key or not self.secret:
                return self._get_demo_account_info()

            # Fetch account balance
            balance = self.exchange.fetch_balance()

            # Get positions for futures
            positions = []
            try:
                if hasattr(self.exchange, 'fapiPrivateGetPositionRisk'):
                    position_data = self.exchange.fapiPrivateGetPositionRisk()
                    for pos in position_data:
                        if float(pos['positionAmt']) != 0:
                            positions.append({
                                'symbol': pos['symbol'],
                                'side': 'long' if float(pos['positionAmt']) > 0 else 'short',
                                'size': abs(float(pos['positionAmt'])),
                                'notional': float(pos['notional']),
                                'pnl': float(pos['unRealizedProfit']),
                                'percentage': float(pos['percentage']),
                                'entry_price': float(pos['entryPrice']) if pos['entryPrice'] else 0,
                                'mark_price': float(pos['markPrice']) if pos['markPrice'] else 0,
                            })
            except:
                logger.warning("Could not fetch positions (normal for spot-only accounts)")

            # Format balance data
            formatted_balances = {}
            for currency, balance_info in balance['total'].items():
                if balance_info > 0:
                    formatted_balances[currency] = {
                        'free': balance['free'][currency],
                        'used': balance['used'][currency],
                        'total': balance_info
                    }

            return {
                'connected': True,
                'exchange': 'binance',
                'account_type': 'testnet' if self.sandbox else 'live',
                'balances': formatted_balances,
                'positions': positions,
                'last_updated': datetime.now().isoformat()
            }

        except Exception as e:
            logger.error(f"Error fetching account info: {e}")
            return {
                'connected': False,
                'error': str(e),
                'balances': {},
                'positions': []
            }

    def _get_demo_account_info(self) -> Dict[str, Any]:
        """Get demo account info when no API credentials provided"""
        return {
            'connected': False,
            'exchange': 'binance_demo',
            'account_type': 'demo',
            'balances': {
                'USDT': {'free': 10000.0, 'used': 2000.0, 'total': 12000.0},
                'BTC': {'free': 0.1, 'used': 0.05, 'total': 0.15},
                'ETH': {'free': 2.5, 'used': 1.0, 'total': 3.5}
            },
            'positions': [
                {
                    'symbol': 'BTCUSDT',
                    'side': 'long',
                    'size': 0.05,
                    'notional': 3400.0,
                    'pnl': 150.0,
                    'percentage': 4.6,
                    'entry_price': 67000.0,
                    'mark_price': 70000.0
                }
            ],
            'last_updated': datetime.now().isoformat(),
            'demo_note': 'Demo account - connect real API keys for live trading'
        }

    def get_market_data(self, symbol: str = None) -> Dict[str, Any]:
        """
        Get real-time market data for a symbol

        Args:
            symbol: Trading pair (e.g., 'BTC/USDT')

        Returns:
            Dict containing market data
        """
        symbol = symbol or self.default_symbol

        try:
            # Fetch ticker data (not OHLCV)
            ticker = self.exchange.fetch_ticker(symbol)

            # Use ticker data for 24h change
            change_24h = ticker.get('change', 0) or 0
            change_percent_24h = ticker.get('percentage', 0) or 0
            price = ticker.get('last', 0) or ticker.get('close', 0) or 0

            market_data = {
                'symbol': symbol.replace('/', '').upper(),
                'name': symbol.split('/')[0],
                'price': price,
                'change_24h': change_24h,
                'change_percent_24h': change_percent_24h,
                'volume_24h': ticker.get('quoteVolume') or ticker.get('baseVolume') or 0,
                'high_24h': ticker.get('high', 0),
                'low_24h': ticker.get('low', 0),
                'market_cap': None,  # Not available from Binance
                'image': self._get_coin_image(symbol.split('/')[0]),
                'last_updated': datetime.now().isoformat()
            }

            self.price_cache[symbol] = market_data
            logger.info(f"✅ {symbol} market data fetched: ${price:,.2f}")
            return market_data

        except Exception as e:
            logger.error(f"Error fetching market data for {symbol}: {e}")
            return self._get_mock_market_data(symbol)

    def _get_coin_image(self, coin_symbol: str) -> str:
        """Get coin image URL based on symbol"""
        image_map = {
            'BTC': 'https://assets.coingecko.com/coins/images/1/small/bitcoin.png',
            'ETH': 'https://assets.coingecko.com/coins/images/279/small/ethereum.png',
            'BNB': 'https://assets.coingecko.com/coins/images/825/small/bnb-icon2_2x.png',
            'ADA': 'https://assets.coingecko.com/coins/images/975/small/cardano.png',
            'DOT': 'https://assets.coingecko.com/coins/images/12171/small/polkadot.png',
            'DOGE': 'https://assets.coingecko.com/coins/images/5/small/dogecoin.png',
        }
        return image_map.get(coin_symbol, 'https://assets.coingecko.com/coins/images/1/small/bitcoin.png')

    def _get_mock_market_data(self, symbol: str) -> Dict[str, Any]:
        """Get mock market data when connection fails"""
        mock_prices = {
            'BTC/USDT': {'price': 69500.0, 'change': 1200.0, 'change_pct': 1.76},
            'ETH/USDT': {'price': 3580.0, 'change': -45.0, 'change_pct': -1.24},
            'BNB/USDT': {'price': 590.0, 'change': 15.0, 'change_pct': 2.61}
        }

        data = mock_prices.get(symbol, mock_prices['BTC/USDT'])

        return {
            'symbol': symbol.replace('/', '').upper(),
            'name': symbol.split('/')[0],
            'price': data['price'],
            'change_24h': data['change'],
            'change_percent_24h': data['change_pct'],
            'volume_24h': 28500000000,
            'high_24h': data['price'] * 1.05,
            'low_24h': data['price'] * 0.95,
            'market_cap': None,
            'image': self._get_coin_image(symbol.split('/')[0]),
            'last_updated': datetime.now().isoformat(),
            'is_mock': True
        }

    def get_multiple_market_data(self, symbols: List[str] = None) -> List[Dict[str, Any]]:
        """
        Get market data for multiple symbols

        Args:
            symbols: List of trading pairs

        Returns:
            List of market data dictionaries
        """
        if symbols is None:
            symbols = ['BTC/USDT', 'ETH/USDT', 'BNB/USDT', 'ADA/USDT', 'DOT/USDT', 'DOGE/USDT']

        market_data = []
        for symbol in symbols:
            data = self.get_market_data(symbol)
            market_data.append(data)

        return market_data

    def place_order(self, symbol: str, side: str, amount: float, price: float = None,
                   order_type: str = 'market') -> Dict[str, Any]:
        """
        Place a trading order

        Args:
            symbol: Trading pair (e.g., 'BTC/USDT')
            side: 'buy' or 'sell'
            amount: Order amount
            price: Order price (for limit orders)
            order_type: 'market' or 'limit'

        Returns:
            Dict containing order information
        """
        try:
            if not self.api_key or not self.secret:
                return self._simulate_order(symbol, side, amount, price, order_type)

            if order_type == 'market':
                if side == 'buy':
                    order = self.exchange.create_market_buy_order(symbol, amount)
                else:
                    order = self.exchange.create_market_sell_order(symbol, amount)
            else:  # limit order
                if not price:
                    raise ValueError("Price required for limit orders")

                if side == 'buy':
                    order = self.exchange.create_limit_buy_order(symbol, amount, price)
                else:
                    order = self.exchange.create_limit_sell_order(symbol, amount, price)

            logger.info(f"Order placed: {order['id']} - {side} {amount} {symbol}")
            return {
                'success': True,
                'order': order,
                'message': f'{side.title()} order placed successfully'
            }

        except Exception as e:
            logger.error(f"Error placing order: {e}")
            return {
                'success': False,
                'error': str(e),
                'message': 'Failed to place order'
            }

    def _simulate_order(self, symbol: str, side: str, amount: float,
                       price: float = None, order_type: str = 'market') -> Dict[str, Any]:
        """Simulate order placement for demo mode"""
        current_price = self.get_market_data(symbol)['price']
        order_price = price if price else current_price

        return {
            'success': True,
            'order': {
                'id': f'demo_{int(datetime.now().timestamp())}',
                'symbol': symbol,
                'side': side,
                'amount': amount,
                'price': order_price,
                'type': order_type,
                'status': 'filled',
                'filled': amount,
                'cost': amount * order_price,
                'timestamp': datetime.now().isoformat()
            },
            'message': f'DEMO: {side.title()} order simulated successfully',
            'demo': True
        }

class TradingConfiguration:
    """
    Manages user trading settings and configurations
    """

    def __init__(self, db_path: str = 'tradecoin.db'):
        self.db_path = db_path
        self._init_config_db()

    def _init_config_db(self):
        """Initialize configuration database tables"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        # User settings table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS user_settings (
                user_id TEXT NOT NULL,
                setting_key TEXT NOT NULL,
                setting_value TEXT NOT NULL,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (user_id, setting_key)
            )
        ''')

        # Exchange configurations table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS exchange_configs (
                user_id TEXT NOT NULL,
                exchange_name TEXT NOT NULL,
                api_key TEXT,
                secret_key TEXT,
                is_sandbox BOOLEAN DEFAULT 1,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (user_id, exchange_name)
            )
        ''')

        conn.commit()
        conn.close()

    def save_user_setting(self, user_id: str, key: str, value: Any):
        """Save user setting"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute('''
            INSERT OR REPLACE INTO user_settings (user_id, setting_key, setting_value, updated_at)
            VALUES (?, ?, ?, datetime('now'))
        ''', (user_id, key, json.dumps(value)))

        conn.commit()
        conn.close()

    def get_user_setting(self, user_id: str, key: str, default=None):
        """Get user setting"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute('''
            SELECT setting_value FROM user_settings
            WHERE user_id = ? AND setting_key = ?
        ''', (user_id, key))

        result = cursor.fetchone()
        conn.close()

        if result:
            return json.loads(result[0])
        return default

    def save_exchange_config(self, user_id: str, exchange_name: str,
                           api_key: str, secret_key: str, is_sandbox: bool = True):
        """Save exchange configuration"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute('''
            INSERT OR REPLACE INTO exchange_configs
            (user_id, exchange_name, api_key, secret_key, is_sandbox, updated_at)
            VALUES (?, ?, ?, ?, ?, datetime('now'))
        ''', (user_id, exchange_name, api_key, secret_key, is_sandbox))

        conn.commit()
        conn.close()

    def get_exchange_config(self, user_id: str, exchange_name: str) -> Optional[Dict]:
        """Get exchange configuration"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute('''
            SELECT api_key, secret_key, is_sandbox FROM exchange_configs
            WHERE user_id = ? AND exchange_name = ?
        ''', (user_id, exchange_name))

        result = cursor.fetchone()
        conn.close()

        if result:
            return {
                'api_key': result[0],
                'secret_key': result[1],
                'is_sandbox': bool(result[2])
            }
        return None

class RegionCurrencyManager:
    """
    Manages regional currency settings and conversions
    """

    def __init__(self):
        # IP to region mapping (simplified)
        self.ip_to_region = {
            '127.0.0.1': 'KR',  # localhost defaults to Korean
            'localhost': 'KR'
        }

        # Region to currency mapping
        self.region_currencies = {
            'KR': {'currency': 'KRW', 'symbol': '₩', 'locale': 'ko_KR'},
            'US': {'currency': 'USD', 'symbol': '$', 'locale': 'en_US'},
            'JP': {'currency': 'JPY', 'symbol': '¥', 'locale': 'ja_JP'},
            'CN': {'currency': 'CNY', 'symbol': '¥', 'locale': 'zh_CN'},
            'GB': {'currency': 'GBP', 'symbol': '£', 'locale': 'en_GB'},
            'EU': {'currency': 'EUR', 'symbol': '€', 'locale': 'en_EU'}
        }

    def get_currency_by_ip(self, ip: str) -> Dict[str, str]:
        """Get currency info based on IP address"""
        region = self.ip_to_region.get(ip, 'US')  # Default to US
        return self.region_currencies.get(region, self.region_currencies['US'])

    def convert_to_local_currency(self, usd_amount: float, target_currency: str) -> float:
        """Convert USD to local currency (mock rates)"""
        rates = {
            'KRW': 1350.0,
            'JPY': 150.0,
            'CNY': 7.3,
            'EUR': 0.85,
            'GBP': 0.75,
            'USD': 1.0
        }

        rate = rates.get(target_currency, 1.0)
        return usd_amount * rate

    def format_currency(self, amount: float, currency: str) -> str:
        """Format currency amount with appropriate symbol"""
        currency_info = None
        for region_info in self.region_currencies.values():
            if region_info['currency'] == currency:
                currency_info = region_info
                break

        if not currency_info:
            return f"${amount:,.2f}"

        symbol = currency_info['symbol']

        if currency in ['KRW', 'JPY']:  # No decimal places
            return f"{symbol}{amount:,.0f}"
        else:
            return f"{symbol}{amount:,.2f}"

def get_default_trading_settings() -> Dict[str, Any]:
    """Get default trading settings"""
    return {
        'max_leverage': int(os.getenv('MAX_LEVERAGE', 10)),
        'risk_level': os.getenv('RISK_LEVEL', 'MEDIUM'),
        'auto_trading': os.getenv('AUTO_TRADING', 'false').lower() == 'true',
        'position_size_pct': 0.05,  # 5% of balance per position
        'stop_loss_pct': 0.03,      # 3% stop loss
        'take_profit_pct': 0.10,    # 10% take profit
        'max_positions': 3,
        'trading_pairs': ['BTC/USDT', 'ETH/USDT', 'BNB/USDT'],
        'notifications': {
            'push': True,
            'email': False,
            'sms': False,
            'signal_threshold': 75
        }
    }

if __name__ == '__main__':
    # Test the binance trader
    trader = BinanceTrader()

    print("=== Testing Binance Connection ===")
    account = trader.get_account_info()
    print(f"Account connected: {account['connected']}")
    print(f"Account balances: {account['balances']}")

    print("\n=== Testing Market Data ===")
    btc_data = trader.get_market_data('BTC/USDT')
    print(f"BTC Price: ${btc_data['price']:,.2f}")
    print(f"24h Change: {btc_data['change_percent_24h']:.2f}%")

    print("\n=== Testing Multi-Symbol Data ===")
    multi_data = trader.get_multiple_market_data(['BTC/USDT', 'ETH/USDT', 'BNB/USDT'])
    for data in multi_data:
        print(f"{data['symbol']}: ${data['price']:,.2f} ({data['change_percent_24h']:+.2f}%)")