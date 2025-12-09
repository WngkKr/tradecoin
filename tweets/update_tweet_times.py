#!/usr/bin/env python3
"""
트윗 타임스탬프를 현재 시간 기준으로 동적으로 업데이트하는 스크립트

실행 방법:
    python3 update_tweet_times.py
"""

import json
from datetime import datetime, timedelta, timezone

# 트윗 파일 경로
TWEETS_FILE = 'all_tweets.json'

def update_tweet_times():
    """
    all_tweets.json 파일의 트윗 시간을 현재 시간 기준으로 업데이트
    """
    print("🔄 트윗 타임스탬프 업데이트 시작...")

    # 파일 읽기
    with open(TWEETS_FILE, 'r', encoding='utf-8') as f:
        all_tweets = json.load(f)

    # 현재 시간 (UTC)
    now = datetime.now(timezone.utc)

    # 각 인플루언서의 트윗 시간 업데이트
    time_offsets = {
        'elonmusk': [
            timedelta(hours=2, minutes=30),  # 2.5시간 전
            timedelta(hours=4, minutes=15),  # 4.25시간 전
        ],
        'realDonaldTrump': [
            timedelta(hours=1, minutes=30),  # 1.5시간 전
        ],
        'saylor': [
            timedelta(hours=3, minutes=0),   # 3시간 전
        ],
        'VitalikButerin': [
            timedelta(hours=5, minutes=30),  # 5.5시간 전
        ]
    }

    updated_count = 0

    for username, tweets in all_tweets.items():
        if username not in time_offsets:
            continue

        offsets = time_offsets[username]

        for i, tweet in enumerate(tweets):
            if i < len(offsets):
                # 현재 시간에서 offset만큼 빼기
                tweet_time = now - offsets[i]
                tweet['created_at'] = tweet_time.isoformat()
                updated_count += 1

                print(f"✅ @{username} 트윗 {i+1}: {tweet_time.strftime('%Y-%m-%d %H:%M:%S')} UTC")

    # 파일에 저장
    with open(TWEETS_FILE, 'w', encoding='utf-8') as f:
        json.dump(all_tweets, f, indent=2, ensure_ascii=False)

    print(f"\n✅ {updated_count}개의 트윗 타임스탬프가 업데이트되었습니다!")
    print(f"📁 파일: {TWEETS_FILE}")

if __name__ == '__main__':
    update_tweet_times()
