#!/usr/bin/env python3
"""
트위터 인플루언서 모니터링 모듈
reverageAI.py 기반 개선 버전
"""

import os
import json
import logging
from datetime import datetime, timedelta
from typing import List, Dict
from pathlib import Path

logger = logging.getLogger(__name__)


# 모니터링 대상 인플루언서 (PRD 2.2 기반)
INFLUENCERS = [
    {
        "name": "Elon Musk",
        "twitter_username": "elonmusk",
        "coins": ["DOGE", "SHIB", "FLOKI", "BTC"],
        "impact_weight": 1.5,
        "avg_reaction_time_minutes": 7
    },
    {
        "name": "Donald Trump",
        "twitter_username": "realDonaldTrump",
        "coins": ["TRUMP", "MAGA", "BTC", "ETH", "XRP"],
        "impact_weight": 1.4,
        "avg_reaction_time_minutes": 15
    },
    {
        "name": "Michael Saylor",
        "twitter_username": "saylor",
        "coins": ["BTC"],
        "impact_weight": 1.3,
        "avg_reaction_time_minutes": 10
    },
    {
        "name": "Vitalik Buterin",
        "twitter_username": "VitalikButerin",
        "coins": ["ETH"],
        "impact_weight": 1.2,
        "avg_reaction_time_minutes": 12
    }
]

# 암호화폐 관련 키워드
CRYPTO_KEYWORDS = [
    'bitcoin', 'btc', 'crypto', 'cryptocurrency',
    'ethereum', 'eth', 'doge', 'dogecoin',
    'shib', 'shiba', 'floki', 'trump', 'maga',
    'xrp', 'ripple', 'blockchain', 'mining',
    'wallet', 'exchange', 'binance', 'coinbase',
    'defi', 'nft', 'web3', 'token'
]


def collect_influencer_tweets() -> List[Dict]:
    """
    인플루언서 트윗 수집 (현재는 더미 데이터, 향후 실제 API 연동)

    Returns:
    --------
    List[Dict] : 수집된 트윗 리스트
    """
    logger.info("🐦 트위터 인플루언서 모니터링 시작...")

    collected_tweets = []

    for influencer in INFLUENCERS:
        # 현재는 더미 트윗 생성 (실제 구현 시 Twitter API v2 사용)
        tweets = _get_recent_tweets_dummy(
            username=influencer['twitter_username'],
            name=influencer['name'],
            coins=influencer['coins']
        )

        # 암호화폐 관련 트윗만 필터링
        crypto_tweets = _filter_crypto_related(tweets)

        # 메타데이터 추가
        for tweet in crypto_tweets:
            tweet['influencer'] = influencer['name']
            tweet['impact_weight'] = influencer['impact_weight']
            tweet['avg_reaction_time'] = influencer['avg_reaction_time_minutes']
            tweet['source'] = 'twitter'
            tweet['collected_at'] = datetime.now().isoformat()

        collected_tweets.extend(crypto_tweets)

        logger.info(f"  ✅ {influencer['name']}: {len(crypto_tweets)}개 수집")

    # 파일로 저장
    _save_tweets_to_file(collected_tweets)

    logger.info(f"✅ 총 {len(collected_tweets)}개 트윗 수집 완료")

    return collected_tweets


def _get_recent_tweets_dummy(username: str, name: str, coins: List[str]) -> List[Dict]:
    """
    더미 트윗 생성 (실제 API 연동 전까지 사용)

    TODO: Twitter API v2로 교체
    """
    # 인플루언서별 트윗 템플릿
    tweet_templates = {
        'elonmusk': [
            "Dogecoin might be my favorite cryptocurrency. It's pretty cool.",
            "Just bought some more Bitcoin because why not",
            "My Shiba Inu puppy is so cute today!",
            "Floki to the moon! 🚀",
            "DOGE will be used as currency on Mars",
            "Considering accepting DOGE for Tesla purchases",
            "Crypto is the future of finance",
            "Working on FLOKI utility, stay tuned",
            "SHIB has an interesting community"
        ],
        'realDonaldTrump': [
            "Bitcoin will make America great again!",
            "We need strategic cryptocurrency reserves",
            "MAGA coin is doing tremendous things",
            "The future of money is here - and it's American",
            "Crypto regulation will be fair under my administration",
            "ETH and BTC are important for our economy"
        ],
        'saylor': [
            "Bitcoin is digital property",
            "MicroStrategy acquires more BTC for treasury",
            "Bitcoin is the apex property of the human race",
            "Hope is the most valuable asset - Bitcoin preserves it",
            "Corporate treasury allocation to Bitcoin makes sense"
        ],
        'VitalikButerin': [
            "Ethereum scaling solutions are progressing well",
            "Layer 2 adoption is accelerating",
            "DeFi innovation continues to amaze me",
            "Excited about ETH staking participation",
            "Ethereum upgrade on track"
        ]
    }

    templates = tweet_templates.get(username, [
        f"Interesting developments in {coins[0] if coins else 'crypto'} today"
    ])

    # 최근 5개 트윗 생성
    tweets = []
    for i, template in enumerate(templates[:5]):
        tweet = {
            'id': f"dummy_{username}_{i}_{int(datetime.now().timestamp())}",
            'author': username,
            'author_name': name,
            'content': template,
            'created_at': (datetime.now() - timedelta(minutes=i*10)).isoformat(),
            'coins_mentioned': coins
        }
        tweets.append(tweet)

    return tweets


def _filter_crypto_related(tweets: List[Dict]) -> List[Dict]:
    """
    암호화폐 관련 트윗만 필터링
    """
    crypto_tweets = []

    for tweet in tweets:
        text_lower = tweet['content'].lower()

        # 암호화폐 키워드 포함 여부 확인
        is_crypto = any(keyword in text_lower for keyword in CRYPTO_KEYWORDS)

        # 코인 심볼 직접 언급 확인
        has_coin_mention = any(coin.lower() in text_lower for coin in tweet.get('coins_mentioned', []))

        if is_crypto or has_coin_mention:
            crypto_tweets.append(tweet)

    return crypto_tweets


def _save_tweets_to_file(tweets: List[Dict]):
    """트윗 데이터를 파일로 저장"""
    # tweets 디렉토리 생성
    tweets_dir = Path(__file__).parent.parent / 'data' / 'tweets'
    tweets_dir.mkdir(parents=True, exist_ok=True)

    # 파일명: tweets_YYYYMMDD_HHMMSS.json
    filename = f"tweets_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    filepath = tweets_dir / filename

    # 저장
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(tweets, f, ensure_ascii=False, indent=2)

    logger.info(f"💾 트윗 저장: {filepath}")


def get_influencer_info(username: str) -> Dict:
    """
    인플루언서 정보 조회
    """
    for influencer in INFLUENCERS:
        if influencer['twitter_username'] == username:
            return influencer

    return None


def get_all_monitored_coins() -> List[str]:
    """
    모니터링 중인 모든 코인 목록 반환
    """
    coins = set()
    for influencer in INFLUENCERS:
        coins.update(influencer['coins'])

    return sorted(list(coins))


# ==================== Twitter API v2 실제 연동 (향후 구현) ====================

def setup_twitter_api_v2():
    """
    Twitter API v2 설정

    필요한 환경 변수:
    - TWITTER_API_KEY
    - TWITTER_API_SECRET
    - TWITTER_BEARER_TOKEN
    """
    # TODO: Twitter API v2 클라이언트 설정
    pass


def get_recent_tweets_api(username: str, max_results: int = 10) -> List[Dict]:
    """
    Twitter API v2로 실제 트윗 가져오기

    Parameters:
    -----------
    username : str
        트위터 사용자명
    max_results : int
        최대 결과 수 (기본 10)

    Returns:
    --------
    List[Dict] : 트윗 리스트
    """
    # TODO: 실제 Twitter API v2 구현
    """
    import tweepy

    # API 인증
    bearer_token = os.getenv('TWITTER_BEARER_TOKEN')
    client = tweepy.Client(bearer_token=bearer_token)

    # 사용자 ID 조회
    user = client.get_user(username=username)

    # 최근 트윗 가져오기
    tweets = client.get_users_tweets(
        id=user.data.id,
        max_results=max_results,
        tweet_fields=['created_at', 'text', 'public_metrics']
    )

    return tweets
    """
    pass


# 테스트 코드
if __name__ == "__main__":
    # 로깅 설정
    logging.basicConfig(level=logging.INFO)

    print("\n" + "="*80)
    print("트위터 모니터링 테스트")
    print("="*80 + "\n")

    # 트윗 수집
    tweets = collect_influencer_tweets()

    print(f"\n수집된 트윗: {len(tweets)}개\n")

    # 샘플 출력
    for i, tweet in enumerate(tweets[:3], 1):
        print(f"[트윗 {i}]")
        print(f"  작성자: {tweet['author_name']} (@{tweet['author']})")
        print(f"  내용: {tweet['content']}")
        print(f"  영향력: x{tweet['impact_weight']}")
        print(f"  관련 코인: {', '.join(tweet['coins_mentioned'])}")
        print("-" * 80)

    # 모니터링 중인 코인
    print(f"\n모니터링 중인 코인: {', '.join(get_all_monitored_coins())}")
