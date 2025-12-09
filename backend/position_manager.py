#!/usr/bin/env python3
"""
포지션 관리 모듈
PRD 3.1.4 자동 거래 실행 모듈 구현
"""

import ccxt
import logging
from typing import Dict, Tuple
from datetime import datetime
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).parent.parent))
from binance_trader import BinanceTrader

logger = logging.getLogger(__name__)


class PositionManager:
    """
    포지션 관리자

    - 포지션 사이징
    - 거래 실행
    - 손절/익절 관리
    """

    def __init__(self):
        """초기화"""
        try:
            self.trader = BinanceTrader()
            self.exchange = self.trader.exchange

            # 계좌 잔고 조회
            self.account_balance = self._get_account_balance()

            logger.info(f"✅ Position Manager 초기화 완료 (잔고: ${self.account_balance:.2f})")

        except Exception as e:
            logger.error(f"❌ Position Manager 초기화 실패: {e}")
            # 테스트 모드로 전환
            self.account_balance = 10000.0  # 더미 잔고
            self.trader = None
            logger.warning("⚠️  테스트 모드로 전환 (거래 실행 안 됨)")

    def _get_account_balance(self) -> float:
        """
        계좌 잔고 조회 (USDT)
        """
        try:
            balance = self.exchange.fetch_balance()
            usdt_balance = balance['USDT']['free']
            return float(usdt_balance)
        except Exception as e:
            logger.error(f"❌ 잔고 조회 실패: {e}")
            return 0.0

    def calculate_position_size(
        self,
        confidence: float,
        leverage: int,
        risk_pct: float = 0.02
    ) -> float:
        """
        포지션 크기 계산 (PRD 기반)

        Parameters:
        -----------
        confidence : float
            신호 신뢰도 (0~1)
        leverage : int
            레버리지 배수
        risk_pct : float
            리스크 비율 (기본 2%)

        Returns:
        --------
        float : 포지션 크기 (USDT)
        """
        # 기본 리스크 금액
        risk_amount = self.account_balance * risk_pct

        # 신뢰도별 조정 (PRD 6.1 기반)
        confidence_multiplier = {
            'high': 1.0,      # 85% 이상
            'medium': 0.7,    # 65-85%
            'low': 0.4        # 65% 미만
        }

        if confidence >= 0.85:
            multiplier = confidence_multiplier['high']
        elif confidence >= 0.65:
            multiplier = confidence_multiplier['medium']
        else:
            multiplier = confidence_multiplier['low']

        adjusted_risk = risk_amount * multiplier

        # 레버리지 적용
        position_size = adjusted_risk * leverage

        # 최대 노출 제한 (계좌의 20%)
        max_exposure = self.account_balance * 0.20
        position_size = min(position_size, max_exposure)

        logger.info(f"📊 포지션 사이즈 계산: ${position_size:.2f} "
                   f"(신뢰도: {confidence:.2%}, 레버리지: {leverage}x)")

        return position_size

    def execute_trade(
        self,
        symbol: str,
        side: str,
        leverage: int,
        amount: float,
        stop_loss_pct: float = 0.03,
        take_profit_pct: float = 0.10
    ) -> Dict:
        """
        거래 실행

        Parameters:
        -----------
        symbol : str
            거래 심볼 (예: 'BTC/USDT')
        side : str
            매수/매도 ('buy' or 'sell')
        leverage : int
            레버리지 배수
        amount : float
            거래 금액 (USDT)
        stop_loss_pct : float
            손절 비율 (기본 3%)
        take_profit_pct : float
            익절 비율 (기본 10%)

        Returns:
        --------
        Dict : 거래 결과
        """
        try:
            # 현재 가격 조회
            ticker = self.exchange.fetch_ticker(symbol)
            current_price = ticker['last']

            # 거래 수량 계산
            quantity = amount / current_price

            logger.info(f"🚀 거래 실행: {symbol} {side.upper()} "
                       f"x{leverage} ${amount:.2f} @ ${current_price:.2f}")

            # 레버리지 설정
            if self.trader:
                self.exchange.set_leverage(leverage, symbol)

            # 주문 실행 (시장가)
            order = None
            if self.trader:
                order = self.exchange.create_market_order(
                    symbol=symbol,
                    side=side,
                    amount=quantity
                )

            # 손절/익절 가격 계산
            if side == 'buy':
                stop_loss_price = current_price * (1 - stop_loss_pct)
                take_profit_price = current_price * (1 + take_profit_pct)
            else:  # sell
                stop_loss_price = current_price * (1 + stop_loss_pct)
                take_profit_price = current_price * (1 - take_profit_pct)

            # 결과 반환
            result = {
                'trade_id': f"{symbol}_{side}_{int(datetime.now().timestamp())}",
                'symbol': symbol,
                'side': side,
                'leverage': leverage,
                'amount': amount,
                'quantity': quantity,
                'entry_price': current_price,
                'stop_loss': stop_loss_price,
                'take_profit': take_profit_price,
                'status': 'open',
                'order': order,
                'executed_at': datetime.now().isoformat()
            }

            logger.info(f"✅ 거래 성공: {result['trade_id']}")
            logger.info(f"   손절가: ${stop_loss_price:.2f} (-{stop_loss_pct:.1%})")
            logger.info(f"   익절가: ${take_profit_price:.2f} (+{take_profit_pct:.1%})")

            return result

        except Exception as e:
            logger.error(f"❌ 거래 실행 실패: {e}")
            return {
                'error': str(e),
                'status': 'failed'
            }

    def get_current_price(self, symbol: str) -> float:
        """현재 가격 조회"""
        try:
            ticker = self.exchange.fetch_ticker(symbol)
            return ticker['last']
        except Exception as e:
            logger.error(f"❌ 가격 조회 실패: {e}")
            return 0.0

    def calculate_pnl(
        self,
        entry_price: float,
        current_price: float,
        side: str,
        leverage: int,
        amount: float
    ) -> Dict:
        """
        손익 계산

        Returns:
        --------
        Dict : {'pnl': float, 'pnl_percent': float}
        """
        if side == 'buy':
            price_change_pct = (current_price - entry_price) / entry_price
        else:  # sell
            price_change_pct = (entry_price - current_price) / entry_price

        # 레버리지 적용
        pnl_percent = price_change_pct * leverage

        # 실제 손익 (USDT)
        pnl = amount * pnl_percent

        return {
            'pnl': pnl,
            'pnl_percent': pnl_percent
        }

    def should_close_position(
        self,
        position: Dict,
        current_price: float,
        pnl_percent: float
    ) -> Tuple[bool, str]:
        """
        포지션 청산 여부 판단

        Returns:
        --------
        Tuple[bool, str] : (청산 여부, 이유)
        """
        stop_loss = position['stop_loss']
        take_profit = position['take_profit']
        side = position['side']

        # 손절 체크
        if side == 'buy':
            if current_price <= stop_loss:
                return True, 'stop_loss'
            if current_price >= take_profit:
                return True, 'take_profit'
        else:  # sell
            if current_price >= stop_loss:
                return True, 'stop_loss'
            if current_price <= take_profit:
                return True, 'take_profit'

        return False, 'holding'

    def close_position(self, position: Dict) -> Dict:
        """
        포지션 청산

        Parameters:
        -----------
        position : Dict
            포지션 정보

        Returns:
        --------
        Dict : 청산 결과
        """
        try:
            symbol = position['symbol']
            side = 'sell' if position['side'] == 'buy' else 'buy'  # 반대 포지션
            quantity = position['quantity']

            logger.info(f"🔒 포지션 청산: {symbol} {side.upper()} {quantity}")

            # 주문 실행
            order = None
            if self.trader:
                order = self.exchange.create_market_order(
                    symbol=symbol,
                    side=side,
                    amount=quantity
                )

            result = {
                'closed': True,
                'order': order,
                'closed_at': datetime.now().isoformat()
            }

            logger.info(f"✅ 청산 완료: {position['trade_id']}")

            return result

        except Exception as e:
            logger.error(f"❌ 청산 실패: {e}")
            return {
                'closed': False,
                'error': str(e)
            }


# 테스트 코드
if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)

    manager = PositionManager()

    print("\n" + "="*80)
    print("포지션 관리 테스트")
    print("="*80 + "\n")

    # 포지션 사이즈 계산
    position_size = manager.calculate_position_size(
        confidence=0.85,
        leverage=5,
        risk_pct=0.02
    )
    print(f"계산된 포지션 크기: ${position_size:.2f}\n")

    # 거래 실행 (테스트 모드)
    trade_result = manager.execute_trade(
        symbol='BTC/USDT',
        side='buy',
        leverage=5,
        amount=position_size,
        stop_loss_pct=0.03,
        take_profit_pct=0.10
    )

    print(f"\n거래 결과:")
    print(f"  ID: {trade_result.get('trade_id', 'N/A')}")
    print(f"  상태: {trade_result.get('status', 'N/A')}")
    print(f"  진입가: ${trade_result.get('entry_price', 0):.2f}")
    print(f"  손절가: ${trade_result.get('stop_loss', 0):.2f}")
    print(f"  익절가: ${trade_result.get('take_profit', 0):.2f}")
