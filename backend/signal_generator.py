#!/usr/bin/env python3
"""
시그널 생성 모듈
기술적 분석 + 감정 분석 통합
"""

import ccxt
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import logging
from typing import Dict, List
import sys
from pathlib import Path

# 기존 모듈 임포트
sys.path.append(str(Path(__file__).parent.parent))
from BaseTradingStrategy import BaseTradingStrategy

logger = logging.getLogger(__name__)


class SignalGenerator:
    """
    거래 신호 생성기

    감정 분석 + 기술적 분석을 결합하여 최종 거래 신호 생성
    """

    def __init__(self):
        """초기화"""
        self.exchange = ccxt.binance({
            'enableRateLimit': True,
        })

        # 기술적 분석 전략 (Base클래스는 인스턴스화 불가하므로 주석 처리)
        # self.strategy = BaseTradingStrategy()

        logger.info("✅ Signal Generator 초기화 완료")

    def analyze_technical(
        self,
        symbol: str,
        sentiment_score: float,
        impact_score: float,
        timeframe: str = '1h'
    ) -> Dict:
        """
        기술적 분석 수행

        Parameters:
        -----------
        symbol : str
            거래 심볼 (예: 'BTC/USDT')
        sentiment_score : float
            감정 점수 (-1.0 ~ 1.0)
        impact_score : float
            영향도 점수 (0 ~ 100)
        timeframe : str
            시간 프레임 (기본 '1h')

        Returns:
        --------
        Dict : 기술적 분석 결과
        """
        try:
            # OHLCV 데이터 가져오기
            ohlcv = self.exchange.fetch_ohlcv(
                symbol,
                timeframe=timeframe,
                limit=100
            )

            df = pd.DataFrame(
                ohlcv,
                columns=['timestamp', 'open', 'high', 'low', 'close', 'volume']
            )
            df['timestamp'] = pd.to_datetime(df['timestamp'], unit='ms')

            # MACD 분석
            macd_signal = self._calculate_macd(df)

            # RSI 분석
            rsi_signal = self._calculate_rsi(df)

            # 볼린저 밴드 분석
            bb_signal = self._calculate_bollinger_bands(df)

            # 거래량 확인
            volume_confirmed = self._check_volume(df)

            # 감정 분석과 결합
            combined_signal = self._combine_signals(
                sentiment_score=sentiment_score,
                impact_score=impact_score,
                macd_signal=macd_signal,
                rsi_signal=rsi_signal,
                bb_signal=bb_signal,
                volume_confirmed=volume_confirmed
            )

            return {
                'symbol': symbol,
                'timeframe': timeframe,
                'macd_signal': macd_signal,
                'rsi_signal': rsi_signal,
                'bb_signal': bb_signal,
                'volume_confirmed': volume_confirmed,
                'action': combined_signal['action'],
                'confidence': combined_signal['confidence'],
                'recommended_leverage': combined_signal['leverage'],
                'entry_price': df['close'].iloc[-1],
                'analyzed_at': datetime.now().isoformat()
            }

        except Exception as e:
            logger.error(f"❌ 기술적 분석 실패 ({symbol}): {e}")
            return {
                'symbol': symbol,
                'error': str(e),
                'action': 'hold',
                'confidence': 0.0
            }

    def _calculate_macd(self, df: pd.DataFrame) -> bool:
        """
        MACD 계산 및 신호 판단

        Returns:
        --------
        bool : True if bullish signal
        """
        # EMA 계산
        exp1 = df['close'].ewm(span=12, adjust=False).mean()
        exp2 = df['close'].ewm(span=26, adjust=False).mean()

        # MACD 라인
        macd = exp1 - exp2

        # Signal 라인
        signal = macd.ewm(span=9, adjust=False).mean()

        # Histogram
        histogram = macd - signal

        # 신호 판단: MACD가 Signal을 위로 돌파하면 매수 신호
        current_hist = histogram.iloc[-1]
        prev_hist = histogram.iloc[-2]

        is_bullish = current_hist > 0 and prev_hist <= 0

        return is_bullish

    def _calculate_rsi(self, df: pd.DataFrame, period: int = 14) -> bool:
        """
        RSI 계산 및 신호 판단

        Returns:
        --------
        bool : True if good entry point
        """
        # 가격 변화
        delta = df['close'].diff()

        # 상승/하락 분리
        gain = (delta.where(delta > 0, 0)).rolling(window=period).mean()
        loss = (-delta.where(delta < 0, 0)).rolling(window=period).mean()

        # RS 및 RSI
        rs = gain / loss
        rsi = 100 - (100 / (1 + rs))

        current_rsi = rsi.iloc[-1]

        # 과매도 구간 (30 이하) 또는 중립 구간 (30-50)에서 매수 신호
        is_good_entry = 30 < current_rsi < 50

        return is_good_entry

    def _calculate_bollinger_bands(self, df: pd.DataFrame, period: int = 20) -> bool:
        """
        볼린저 밴드 계산 및 신호 판단

        Returns:
        --------
        bool : True if bouncing from lower band
        """
        # 중간선 (SMA)
        sma = df['close'].rolling(window=period).mean()

        # 표준편차
        std = df['close'].rolling(window=period).std()

        # 상단/하단 밴드
        upper_band = sma + (std * 2)
        lower_band = sma - (std * 2)

        current_price = df['close'].iloc[-1]
        current_lower = lower_band.iloc[-1]
        current_upper = upper_band.iloc[-1]

        # 하단 밴드 근처에서 반등 신호
        is_bouncing = current_price <= (current_lower * 1.02)

        return is_bouncing

    def _check_volume(self, df: pd.DataFrame) -> bool:
        """
        거래량 확인

        Returns:
        --------
        bool : True if volume is high
        """
        # 평균 거래량
        avg_volume = df['volume'].rolling(window=20).mean().iloc[-1]

        # 현재 거래량
        current_volume = df['volume'].iloc[-1]

        # 평균 대비 1.5배 이상이면 충분
        is_high_volume = current_volume >= (avg_volume * 1.5)

        return is_high_volume

    def _combine_signals(
        self,
        sentiment_score: float,
        impact_score: float,
        macd_signal: bool,
        rsi_signal: bool,
        bb_signal: bool,
        volume_confirmed: bool
    ) -> Dict:
        """
        감정 분석과 기술적 분석 결합

        Returns:
        --------
        Dict : {'action': str, 'confidence': float, 'leverage': int}
        """
        # 기술적 신호 점수
        technical_score = sum([
            macd_signal * 0.4,
            rsi_signal * 0.3,
            bb_signal * 0.2,
            volume_confirmed * 0.1
        ])

        # 감정 점수 정규화 (0~1)
        normalized_sentiment = (sentiment_score + 1) / 2

        # 영향도 정규화 (0~1)
        normalized_impact = impact_score / 100

        # 최종 신뢰도 (가중 평균)
        confidence = (
            technical_score * 0.6 +
            normalized_sentiment * 0.25 +
            normalized_impact * 0.15
        )

        # 액션 결정
        if confidence >= 0.65:
            if sentiment_score > 0:
                action = 'buy'
            else:
                action = 'sell'
        else:
            action = 'hold'

        # 레버리지 결정 (신뢰도에 따라)
        if confidence >= 0.85:
            leverage = 10  # 최고 신뢰도: 10배
        elif confidence >= 0.75:
            leverage = 5   # 높은 신뢰도: 5배
        elif confidence >= 0.65:
            leverage = 3   # 중간 신뢰도: 3배
        else:
            leverage = 1   # 낮은 신뢰도: 레버리지 없음

        return {
            'action': action,
            'confidence': confidence,
            'leverage': leverage,
            'technical_score': technical_score,
            'sentiment_score': normalized_sentiment,
            'impact_score': normalized_impact
        }


# 테스트 코드
if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)

    generator = SignalGenerator()

    # 테스트
    result = generator.analyze_technical(
        symbol='BTC/USDT',
        sentiment_score=0.7,
        impact_score=75,
        timeframe='1h'
    )

    print("\n" + "="*80)
    print("시그널 생성 테스트")
    print("="*80 + "\n")
    print(f"심볼: {result['symbol']}")
    print(f"액션: {result['action'].upper()}")
    print(f"신뢰도: {result['confidence']:.2%}")
    print(f"추천 레버리지: {result['recommended_leverage']}x")
    print(f"진입 가격: ${result['entry_price']:.2f}")
    print("\n기술적 분석:")
    print(f"  MACD: {'✅' if result['macd_signal'] else '❌'}")
    print(f"  RSI: {'✅' if result['rsi_signal'] else '❌'}")
    print(f"  BB: {'✅' if result['bb_signal'] else '❌'}")
    print(f"  Volume: {'✅' if result['volume_confirmed'] else '❌'}")
