#!/usr/bin/env python3
"""
바이낸스 실제 잔고 확인 스크립트
"""

import ccxt
import json

# API 키 (Flutter 앱에서 사용 중인 키)
API_KEY = "hZpNCDJQOO5RXfzJGqTCXxcHhPiRJUPo68UqhSkh19vBR1BgKLsxaxGVdHGLdoXR"
SECRET_KEY = "CGNnLpyeVH9YiEQJWJ3JoyVJEH73BxT9B76oKBNP0ODBOzGdmGYXOhxqWgYb44Vh"

def check_binance_balance():
    """바이낸스 계정 잔고 확인"""
    try:
        # 바이낸스 객체 생성 (실서버)
        exchange = ccxt.binance({
            'apiKey': API_KEY,
            'secret': SECRET_KEY,
            'enableRateLimit': True,
            'options': {
                'defaultType': 'spot'  # 현물 거래
            }
        })

        print("🔄 바이낸스 연결 중...")

        # 계정 잔고 조회
        balance = exchange.fetch_balance()

        print("\n✅ 바이낸스 계정 정보:")
        print(f"API 키: {API_KEY[:10]}...{API_KEY[-10:]}")

        print("\n💰 보유 자산 목록:")
        print("-" * 50)

        total_value_usd = 0
        non_zero_balances = {}

        # 잔고가 0이 아닌 자산만 필터링
        for currency, balance_info in balance.items():
            if isinstance(balance_info, dict) and 'total' in balance_info:
                if balance_info['total'] > 0:
                    non_zero_balances[currency] = balance_info

        # 주요 코인들의 현재 가격 조회
        prices = {}
        for symbol in ['BTC/USDT', 'ETH/USDT', 'BNB/USDT']:
            try:
                ticker = exchange.fetch_ticker(symbol)
                coin = symbol.split('/')[0]
                prices[coin] = ticker['last']
            except:
                pass

        # USDT는 1달러로 고정
        prices['USDT'] = 1.0

        # 잔고 출력
        if non_zero_balances:
            for currency, balance_info in sorted(non_zero_balances.items()):
                total = balance_info['total']
                free = balance_info.get('free', 0)
                used = balance_info.get('used', 0)

                # USD 가치 계산
                usd_value = 0
                if currency in prices:
                    usd_value = total * prices[currency]
                    total_value_usd += usd_value

                print(f"\n🪙 {currency}:")
                print(f"  • 총 잔고: {total:.8f}")
                print(f"  • 사용 가능: {free:.8f}")
                print(f"  • 사용 중: {used:.8f}")
                if usd_value > 0:
                    print(f"  • USD 가치: ${usd_value:,.2f}")
        else:
            print("⚠️ 잔고가 있는 자산이 없습니다.")

        print("\n" + "=" * 50)
        print(f"📊 총 자산 가치: ${total_value_usd:,.2f}")

        # 계정 정보 추가 확인
        account_info = exchange.fetch_account_status()
        print(f"\n🔍 계정 상태: {account_info.get('status', 'Unknown')}")

        # API 권한 확인
        print("\n🔑 API 권한:")
        api_restrictions = exchange.fetch_my_trades_ws

        return non_zero_balances

    except Exception as e:
        print(f"\n❌ 오류 발생: {e}")
        print(f"오류 타입: {type(e).__name__}")

        # 상세한 오류 정보
        if hasattr(e, 'args') and e.args:
            print(f"오류 상세: {e.args}")

        return None

if __name__ == "__main__":
    print("=" * 50)
    print("🚀 바이낸스 실계정 잔고 확인 프로그램")
    print("=" * 50)

    result = check_binance_balance()

    print("\n" + "=" * 50)
    print("✨ 확인 완료")