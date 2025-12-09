#!/usr/bin/env python3
"""
TradeCoin Flutter App - Binance API 키 저장 및 자동화 테스트 스크립트
"""
import requests
import json
import time
from datetime import datetime

# API 설정
API_BASE_URL = "http://localhost:8000"
BINANCE_API_KEY = "hZpNS9JmN0LdmCETiJO0EkKwrXK8Ay41qzIKljx32uBhE9kgckGp95I3mgtadoXR"
BINANCE_SECRET = "PR7s6LBKBb9qnuNFHrQJ6PFvX9q67QJhaYkt52S1tPmT6Ll1KUVALpIKtnifHjPq"
USER_ID = "wngk@debrix.co.kr"

def print_section(title):
    print(f"\n{'='*50}")
    print(f"🔄 {title}")
    print('='*50)

def test_api_health():
    """API 서버 헬스 체크"""
    print_section("API 서버 헬스 체크")
    try:
        response = requests.get(f"{API_BASE_URL}/api/health", timeout=5)
        if response.status_code == 200:
            print("✅ API 서버 정상 작동")
            return True
        else:
            print(f"❌ API 서버 응답 오류: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ API 서버 연결 실패: {str(e)}")
        return False

def save_api_keys():
    """바이낸스 API 키 저장"""
    print_section("바이낸스 API 키 저장")

    payload = {
        "user_id": USER_ID,
        "api_key": BINANCE_API_KEY,
        "secret_key": BINANCE_SECRET
    }

    try:
        response = requests.post(f"{API_BASE_URL}/api/binance/update-keys", json=payload, timeout=10)

        if response.status_code == 200:
            result = response.json()
            print("✅ API 키 저장 성공")
            print(f"📋 응답: {result}")
            return True
        else:
            print(f"❌ API 키 저장 실패: {response.status_code}")
            print(f"📋 응답: {response.text}")
            return False
    except Exception as e:
        print(f"❌ API 키 저장 중 오류: {str(e)}")
        return False

def test_binance_connection():
    """바이낸스 연결 테스트"""
    print_section("바이낸스 연결 테스트")

    payload = {"user_id": USER_ID}

    try:
        response = requests.post(f"{API_BASE_URL}/api/binance/test-connection", json=payload, timeout=10)

        if response.status_code == 200:
            result = response.json()
            print("✅ 바이낸스 연결 성공")
            print(f"📊 계정 정보: {json.dumps(result, indent=2, ensure_ascii=False)}")
            return True
        else:
            print(f"❌ 바이낸스 연결 실패: {response.status_code}")
            print(f"📋 응답: {response.text}")
            return False
    except Exception as e:
        print(f"❌ 바이낸스 연결 테스트 중 오류: {str(e)}")
        return False

def get_market_data():
    """시장 데이터 조회"""
    print_section("시장 데이터 조회")

    try:
        response = requests.get(f"{API_BASE_URL}/api/market/data", timeout=10)

        if response.status_code == 200:
            result = response.json()
            print("✅ 시장 데이터 조회 성공")

            # 주요 코인 정보 출력
            data = result.get('data', result.get('coins', []))
            for coin in data:
                symbol = coin.get('symbol', 'Unknown')
                price = coin.get('price', 0)
                change_24h = coin.get('change_percent_24h', 0)
                change_emoji = "📈" if change_24h > 0 else "📉" if change_24h < 0 else "➡️"

                print(f"{change_emoji} {symbol}: ${price:,.2f} ({change_24h:+.2f}%)")
            return True
        else:
            print(f"❌ 시장 데이터 조회 실패: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ 시장 데이터 조회 중 오류: {str(e)}")
        return False

def get_coin_info():
    """코인 정보 조회 (심볼, 가격, 24시간 변동률 등)"""
    print_section("코인 정보 상세 조회")

    # 주요 코인 목록
    symbols = ["BTCUSDT", "ETHUSDT", "BNBUSDT", "DOGEUSDT", "SHIBUSDT"]

    try:
        print(f"📋 조회 대상 코인: {', '.join(symbols)}\n")

        for symbol in symbols:
            response = requests.get(
                f"{API_BASE_URL}/api/market/coin/{symbol}",
                timeout=10
            )

            if response.status_code == 200:
                coin = response.json()

                # 코인 정보 파싱
                symbol_name = coin.get('symbol', 'Unknown')
                price = float(coin.get('price', 0))
                change_24h = float(coin.get('change_percent_24h', 0))
                volume_24h = float(coin.get('volume_24h', 0))
                high_24h = float(coin.get('high_24h', 0))
                low_24h = float(coin.get('low_24h', 0))

                change_emoji = "📈" if change_24h > 0 else "📉" if change_24h < 0 else "➡️"

                print(f"{change_emoji} {symbol_name}")
                print(f"   💰 현재가: ${price:,.8f}" if price < 1 else f"   💰 현재가: ${price:,.2f}")
                print(f"   📊 24시간 변동: {change_24h:+.2f}%")
                print(f"   📈 24시간 최고: ${high_24h:,.8f}" if high_24h < 1 else f"   📈 24시간 최고: ${high_24h:,.2f}")
                print(f"   📉 24시간 최저: ${low_24h:,.8f}" if low_24h < 1 else f"   📉 24시간 최저: ${low_24h:,.2f}")
                print(f"   💵 24시간 거래량: ${volume_24h:,.0f}")
                print()
            else:
                print(f"❌ {symbol} 정보 조회 실패: {response.status_code}")

        print("✅ 코인 정보 조회 완료")
        return True

    except Exception as e:
        print(f"❌ 코인 정보 조회 중 오류: {str(e)}")
        return False

def get_user_profile():
    """사용자 프로필 조회"""
    print_section("사용자 프로필 조회")

    try:
        response = requests.get(f"{API_BASE_URL}/api/user/profile/{USER_ID}", timeout=10)

        if response.status_code == 200:
            result = response.json()
            print("✅ 사용자 프로필 조회 성공")
            print(f"📋 프로필: {json.dumps(result, indent=2, ensure_ascii=False)}")
            return True
        else:
            print(f"❌ 사용자 프로필 조회 실패: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ 사용자 프로필 조회 중 오류: {str(e)}")
        return False

def test_trading_signals():
    """거래 시그널 테스트"""
    print_section("거래 시그널 테스트")

    try:
        response = requests.get(f"{API_BASE_URL}/api/trading/signals", timeout=15)

        if response.status_code == 200:
            result = response.json()
            print("✅ 거래 시그널 조회 성공")

            signals = result.get('signals', result.get('data', []))
            if signals:
                print(f"📊 총 {len(signals)}개의 시그널 발견")
                for signal in signals[:3]:  # 상위 3개만 출력
                    symbol = signal.get('symbol', 'Unknown')
                    confidence = signal.get('confidence', 0)
                    action = signal.get('action', signal.get('signal', 'HOLD'))

                    action_emoji = "🟢" if action == "BUY" else "🔴" if action == "SELL" else "🟡"
                    print(f"{action_emoji} {symbol}: {action} (신뢰도: {confidence}%)")
            else:
                print("📋 현재 활성 시그널이 없습니다")
            return True
        else:
            print(f"❌ 거래 시그널 조회 실패: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ 거래 시그널 조회 중 오류: {str(e)}")
        return False

def run_comprehensive_test():
    """종합 테스트 실행"""
    print_section("TradeCoin 바이낸스 통합 테스트 시작")
    print(f"⏰ 테스트 시작 시간: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

    results = {
        "api_health": False,
        "save_keys": False,
        "binance_connection": False,
        "market_data": False,
        "coin_info": False,
        "user_profile": False,
        "trading_signals": False
    }

    # 순차적으로 테스트 실행
    results["api_health"] = test_api_health()
    time.sleep(1)

    if results["api_health"]:
        results["save_keys"] = save_api_keys()
        time.sleep(2)

        if results["save_keys"]:
            results["binance_connection"] = test_binance_connection()
            time.sleep(2)

    results["market_data"] = get_market_data()
    time.sleep(1)

    results["coin_info"] = get_coin_info()
    time.sleep(1)

    results["user_profile"] = get_user_profile()
    time.sleep(1)

    results["trading_signals"] = test_trading_signals()

    # 결과 요약
    print_section("테스트 결과 요약")
    passed_tests = sum(results.values())
    total_tests = len(results)

    for test_name, result in results.items():
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} {test_name.replace('_', ' ').title()}")

    print(f"\n🎯 전체 결과: {passed_tests}/{total_tests} 테스트 통과")
    print(f"📊 성공률: {passed_tests/total_tests*100:.1f}%")

    if passed_tests == total_tests:
        print("\n🎉 모든 테스트가 성공적으로 완료되었습니다!")
        print("🚀 TradeCoin 바이낸스 통합이 정상적으로 작동합니다!")
    else:
        print(f"\n⚠️  {total_tests - passed_tests}개의 테스트가 실패했습니다.")
        print("🔧 문제를 해결한 후 다시 테스트해주세요.")

    print(f"⏰ 테스트 완료 시간: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

if __name__ == "__main__":
    run_comprehensive_test()