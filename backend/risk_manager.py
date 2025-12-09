#!/usr/bin/env python3
"""
리스크 관리 모듈
PRD 6. 리스크 관리 구현
"""

import logging
from typing import Dict
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)


class RiskManager:
    """
    리스크 관리자

    - 거래 리스크 관리
    - 레버리지 제한
    - 일일 손실 제한
    - 시장 위험 대응
    """

    def __init__(self):
        """초기화"""
        # 리스크 매개변수 (PRD 6.1 기반)
        self.max_risk_per_trade = 0.02  # 거래당 2%
        self.max_total_exposure = 0.20  # 전체 노출 20%
        self.max_daily_loss = 0.05      # 일일 최대 손실 5%

        # 레버리지 제한 매트릭스 (PRD 6.1)
        self.leverage_limits = {
            'highest': {'range': (5, 10), 'stop_loss': 0.03},   # 3계층 완료
            'high': {'range': (3, 5), 'stop_loss': 0.05},        # 2계층 완료
            'medium': {'range': (2, 3), 'stop_loss': 0.07}       # 1계층만
        }

        # 일일 거래 추적
        self.daily_trades = []
        self.daily_pnl = 0.0

        logger.info("✅ Risk Manager 초기화 완료")

    def check_trading_conditions(
        self,
        coin: str,
        confidence: float,
        leverage: int
    ) -> Dict:
        """
        거래 조건 확인

        Parameters:
        -----------
        coin : str
            거래할 코인
        confidence : float
            신호 신뢰도
        leverage : int
            요청 레버리지

        Returns:
        --------
        Dict : 승인 여부 및 조정된 매개변수
        """
        # 1. 신뢰도별 레버리지 검증
        if confidence >= 0.85:
            confidence_level = 'highest'
        elif confidence >= 0.75:
            confidence_level = 'high'
        elif confidence >= 0.65:
            confidence_level = 'medium'
        else:
            return {
                'approved': False,
                'reason': f'신뢰도 너무 낮음 ({confidence:.2%} < 65%)'
            }

        # 레버리지 제한 확인
        limits = self.leverage_limits[confidence_level]
        min_lev, max_lev = limits['range']

        if leverage > max_lev:
            leverage = max_lev
            logger.warning(f"⚠️  레버리지 조정: {leverage} -> {max_lev} ({confidence_level})")

        # 2. 일일 손실 한도 확인
        if abs(self.daily_pnl) >= self.max_daily_loss:
            return {
                'approved': False,
                'reason': f'일일 손실 한도 도달 ({self.daily_pnl:.2%})'
            }

        # 3. 시장 상황 확인
        market_condition = self._check_market_conditions()
        if not market_condition['safe_to_trade']:
            return {
                'approved': False,
                'reason': f'시장 상황 불안정: {market_condition["reason"]}'
            }

        # 4. 승인
        return {
            'approved': True,
            'leverage': leverage,
            'risk_percentage': self.max_risk_per_trade,
            'stop_loss_pct': limits['stop_loss'],
            'take_profit_pct': self._calculate_take_profit(leverage),
            'confidence_level': confidence_level
        }

    def _check_market_conditions(self) -> Dict:
        """
        시장 상황 모니터링

        TODO: 실제 공포/탐욕 지수 API 연동
        """
        # 현재는 항상 안전하다고 가정
        # 실제 구현 시:
        # - Fear & Greed Index 확인
        # - 변동성 지표 확인
        # - 거래량 확인

        return {
            'safe_to_trade': True,
            'reason': 'normal_market'
        }

    def _calculate_take_profit(self, leverage: int) -> float:
        """
        레버리지에 따른 익절 비율 계산

        레버리지가 높을수록 익절을 빨리
        """
        if leverage >= 10:
            return 0.05  # 5%
        elif leverage >= 5:
            return 0.10  # 10%
        else:
            return 0.15  # 15%

    def update_daily_pnl(self, pnl: float):
        """일일 손익 업데이트"""
        today = datetime.now().date()

        # 날짜가 바뀌면 초기화
        if self.daily_trades and self.daily_trades[0]['date'] != today:
            self.daily_trades = []
            self.daily_pnl = 0.0

        self.daily_pnl += pnl

        self.daily_trades.append({
            'date': today,
            'pnl': pnl,
            'timestamp': datetime.now()
        })

        logger.info(f"📊 일일 손익 업데이트: {self.daily_pnl:+.2%}")

        # 일일 손실 한도 경고
        if abs(self.daily_pnl) >= self.max_daily_loss * 0.8:
            logger.warning(f"⚠️  일일 손실 한도 80% 도달: {self.daily_pnl:.2%}")

    def get_risk_report(self) -> Dict:
        """리스크 현황 보고서"""
        return {
            'daily_pnl': self.daily_pnl,
            'daily_trades_count': len(self.daily_trades),
            'max_daily_loss': self.max_daily_loss,
            'remaining_risk_capacity': self.max_daily_loss - abs(self.daily_pnl),
            'safe_to_trade': abs(self.daily_pnl) < self.max_daily_loss
        }


# 테스트 코드
if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)

    manager = RiskManager()

    print("\n" + "="*80)
    print("리스크 관리 테스트")
    print("="*80 + "\n")

    # 테스트 케이스
    test_cases = [
        {'coin': 'BTC', 'confidence': 0.90, 'leverage': 10},
        {'coin': 'ETH', 'confidence': 0.75, 'leverage': 5},
        {'coin': 'DOGE', 'confidence': 0.65, 'leverage': 3},
        {'coin': 'SHIB', 'confidence': 0.50, 'leverage': 10},
    ]

    for i, test in enumerate(test_cases, 1):
        print(f"\n[테스트 {i}]")
        print(f"코인: {test['coin']}, 신뢰도: {test['confidence']:.2%}, 레버리지: {test['leverage']}x")

        result = manager.check_trading_conditions(
            coin=test['coin'],
            confidence=test['confidence'],
            leverage=test['leverage']
        )

        if result['approved']:
            print(f"✅ 승인됨")
            print(f"   조정된 레버리지: {result['leverage']}x")
            print(f"   손절: {result['stop_loss_pct']:.1%}")
            print(f"   익절: {result['take_profit_pct']:.1%}")
            print(f"   신뢰도 레벨: {result['confidence_level']}")
        else:
            print(f"❌ 거부됨: {result['reason']}")

        print("-" * 80)

    # 리스크 보고서
    print("\n리스크 현황:")
    report = manager.get_risk_report()
    print(f"  일일 손익: {report['daily_pnl']:+.2%}")
    print(f"  일일 거래 수: {report['daily_trades_count']}")
    print(f"  잔여 리스크 용량: {report['remaining_risk_capacity']:.2%}")
    print(f"  거래 가능: {'✅' if report['safe_to_trade'] else '❌'}")
