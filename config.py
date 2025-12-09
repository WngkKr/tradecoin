# config.py

"""
시스템 구성 설정
"""

# API 키 설정 (환경 변수에서 로드 또는 직접 설정)
import os


BINANCE_API_KEY = os.getenv("BINANCE_API_KEY", "jhoeFXEYEzkkDZrRViFvlbkAmBM70KCnSn1zxQVv9ytI2iAo00qeanW2DB4Yv2Yx")
BINANCE_API_SECRET = os.getenv("BINANCE_SECRET", "rQmNdhZKzOalGuArsdY5foUkhCS8LnkvCwd4gTaIDDRgK0RL2dvuWpJ9HnemMRIg")
COINMARKETCAP_API_KEY = os.getenv("CMC_API_KEY", "")
COINGECKO_PRO_API_KEY = os.getenv("COINGECKO_API_KEY", "")  # 기본 API는 키 필요 없음

# 가격 데이터 설정
PRICE_CACHE_DURATION = 300  # 초 (5분)
PRICE_REQUEST_TIMEOUT = 5   # 초
RETRY_COUNT = 3             # API 실패 시 재시도 횟수
RETRY_DELAY = 2             # 재시도 간 지연 시간 (초)

# 지원하는 코인 목록
SUPPORTED_COINS = [
    "BTC", "ETH", "DOGE", "SHIB", "FLOKI", "TRUMP", "MAGA"
]

# 거래소별 심볼 매핑 (거래소마다 심볼이 다를 수 있음)
EXCHANGE_SYMBOL_MAPPING = {
    "binance": {
        "BTC": "BTCUSDT",
        "ETH": "ETHUSDT",
        "DOGE": "DOGEUSDT",
        "SHIB": "SHIBUSDT",
        # ... 기타 코인
    },
    "coingecko": {
        "BTC": "bitcoin",
        "ETH": "ethereum",
        "DOGE": "dogecoin",
        "SHIB": "shiba-inu",
        "FLOKI": "floki",
        "TRUMP": "trump-token",  # 이름 확인 필요
        "MAGA": "maga-token"     # 이름 확인 필요
    }
}