#!/usr/bin/env python3
"""
🚀 TradeCoin 실거래 모드 라이브 테스트
실제 바이낸스 API로 거래 가능한 상태를 시연합니다.
"""
import os
import json
import time
from dotenv import load_dotenv
import ccxt
import requests

load_dotenv()

def print_header():
    print("=" * 60)
    print("🚀 TradeCoin 실거래 모드 라이브 테스트")
    print("=" * 60)

def check_environment():
    print("\n📋 환경 설정 확인:")
    print(f"   API Key: {os.getenv('BINANCE_API_KEY')[:15]}...")
    print(f"   Sandbox: {os.getenv('BINANCE_SANDBOX')}")
    print(f"   실거래 모드: {'✅ 활성화' if os.getenv('BINANCE_SANDBOX') == 'false' else '❌ 테스트넷'}")

def test_real_connection():
    print("\n🔗 실거래 연결 테스트:")
    try:
        exchange = ccxt.binance({
            'apiKey': os.getenv('BINANCE_API_KEY'),
            'secret': os.getenv('BINANCE_SECRET'),
            'sandbox': False,
            'enableRateLimit': True,
        })

        # 계정 정보 확인
        balance = exchange.fetch_balance()
        print(f"   ✅ 바이낸스 실거래 서버 연결 성공!")
        print(f"   💰 USDT 잔고: ${balance.get('USDT', {}).get('free', 0)}")

        return exchange
    except Exception as e:
        print(f"   ❌ 연결 실패: {e}")
        return None

def get_live_prices(exchange):
    print("\n📊 실시간 시장 데이터:")
    symbols = ['BTC/USDT', 'ETH/USDT', 'BNB/USDT', 'DOGE/USDT', 'ADA/USDT']

    prices = {}
    for symbol in symbols:
        try:
            ticker = exchange.fetch_ticker(symbol)
            price = ticker['last']
            change = ticker['percentage']
            prices[symbol] = {'price': price, 'change': change}

            color = "🟢" if change > 0 else "🔴" if change < 0 else "⚪"
            print(f"   {color} {symbol}: ${price:,.4f} ({change:+.2f}%)")

        except Exception as e:
            print(f"   ❌ {symbol}: 데이터 조회 실패")

    return prices

def test_order_simulation(exchange):
    print("\n⚠️  주문 시뮬레이션 (실제 실행 안함):")
    try:
        # 실제 주문은 하지 않고 주문 파라미터만 확인
        symbol = 'BTC/USDT'
        ticker = exchange.fetch_ticker(symbol)
        current_price = ticker['last']

        # 가상의 소액 주문 (0.001 BTC)
        test_amount = 0.001
        test_value = test_amount * current_price

        print(f"   📝 테스트 주문 정보:")
        print(f"      심볼: {symbol}")
        print(f"      수량: {test_amount} BTC")
        print(f"      예상 금액: ${test_value:.2f}")
        print(f"      현재가: ${current_price:,.2f}")
        print("   ⚡ 실제 주문 실행하지 않음 (안전)")

    except Exception as e:
        print(f"   ❌ 주문 시뮬레이션 실패: {e}")

def test_backend_api():
    print("\n🖥️  백엔드 API 테스트:")
    try:
        # 연결 상태 확인
        response = requests.get("http://localhost:8000/api/user/wngk@debrix.co.kr/connection-status")
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ 백엔드 API 연결됨")
            print(f"   📊 연결 상태: {data.get('data', {}).get('status', 'Unknown')}")
        else:
            print(f"   ❌ API 응답 오류: {response.status_code}")
    except Exception as e:
        print(f"   ❌ 백엔드 연결 실패: {e}")

def test_flutter_app():
    print("\n📱 Flutter 웹앱 상태:")
    try:
        response = requests.get("http://localhost:4000", timeout=5)
        if response.status_code == 200:
            print("   ✅ Flutter 웹앱 실행 중")
            print("   🌐 접속 URL: http://localhost:4000")
            print("   👤 테스트 로그인: wngk@debrix.co.kr / wngk7001")
        else:
            print(f"   ⚠️  웹앱 응답 상태: {response.status_code}")
    except Exception as e:
        print(f"   ❌ 웹앱 연결 실패: {e}")

def main():
    print_header()

    # 1. 환경 확인
    check_environment()

    # 2. 실거래 연결 테스트
    exchange = test_real_connection()

    if exchange:
        # 3. 실시간 가격 데이터
        prices = get_live_prices(exchange)

        # 4. 주문 시뮬레이션
        test_order_simulation(exchange)

    # 5. 백엔드 API 테스트
    test_backend_api()

    # 6. Flutter 앱 상태
    test_flutter_app()

    print("\n" + "=" * 60)
    print("🎯 실거래 모드 테스트 완료!")
    print("💡 웹브라우저에서 http://localhost:4000 접속해보세요!")
    print("=" * 60)

if __name__ == "__main__":
    main()