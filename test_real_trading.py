#!/usr/bin/env python3
"""
실거래 모드 연결 테스트
"""
import os
from dotenv import load_dotenv
import ccxt

load_dotenv()

print('🔍 실거래 모드 연결 테스트')
print(f'API Key: {os.getenv("BINANCE_API_KEY")[:10]}...')
print(f'Sandbox: {os.getenv("BINANCE_SANDBOX")}')

try:
    exchange = ccxt.binance({
        'apiKey': os.getenv('BINANCE_API_KEY'),
        'secret': os.getenv('BINANCE_SECRET'),
        'sandbox': False,  # 실거래 모드
        'enableRateLimit': True,
    })

    # 계정 정보 조회 테스트
    print('\n📊 계정 정보 조회 중...')
    balance = exchange.fetch_balance()
    print('✅ 실거래 연결 성공!')

    usdt_balance = balance.get("USDT", {}).get("free", 0)
    print(f'USDT 잔고: ${usdt_balance}')

    # 현재 가격 조회
    print('\n💰 BTC 현재가 조회 중...')
    ticker = exchange.fetch_ticker('BTC/USDT')
    btc_price = ticker["last"]
    print(f'BTC/USDT: ${btc_price:,.2f}')

    # 다른 코인들도 조회
    print('\n📈 주요 코인 현재가:')
    symbols = ['ETH/USDT', 'BNB/USDT', 'DOGE/USDT']
    for symbol in symbols:
        ticker = exchange.fetch_ticker(symbol)
        price = ticker["last"]
        change = ticker["percentage"]
        print(f'{symbol}: ${price:,.4f} ({change:+.2f}%)')

except Exception as e:
    print(f'❌ 연결 실패: {e}')
    print('API 키 권한을 확인하세요.')