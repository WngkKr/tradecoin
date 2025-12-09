#!/usr/bin/env python3
"""
CryptoLeverageAI - FastAPI 메인 서버
PRD 기반 통합 트레이딩 시스템
"""

from fastapi import FastAPI, WebSocket, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from apscheduler.schedulers.background import BackgroundScheduler
from datetime import datetime, timedelta
import asyncio
import logging
import json
import os
from typing import List, Dict, Optional
from pathlib import Path

# 프로젝트 모듈 임포트
import sys
sys.path.append(str(Path(__file__).parent.parent))

from sentiment_analyzer import SentimentAnalyzer
from signal_generator import SignalGenerator
from position_manager import PositionManager
from risk_manager import RiskManager
from firestore_service import FirestoreService

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# FastAPI 앱 생성
app = FastAPI(
    title="CryptoLeverageAI API",
    description="AI 기반 암호화폐 레버리지 자동 거래 시스템",
    version="1.0.0"
)

# CORS 설정 (Flutter 앱 연동)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 전역 서비스 인스턴스
sentiment_analyzer = None
signal_generator = None
position_manager = None
risk_manager = None
firestore_service = None
scheduler = None

# WebSocket 연결 관리
active_connections: List[WebSocket] = []


@app.on_event("startup")
async def startup_event():
    """서버 시작 시 초기화"""
    global sentiment_analyzer, signal_generator, position_manager, risk_manager, firestore_service, scheduler

    logger.info("🚀 CryptoLeverageAI 서버 시작 중...")

    try:
        # 서비스 초기화
        sentiment_analyzer = SentimentAnalyzer()
        signal_generator = SignalGenerator()
        position_manager = PositionManager()
        risk_manager = RiskManager()
        firestore_service = FirestoreService()

        # 스케줄러 설정
        scheduler = BackgroundScheduler()

        # 5분마다 데이터 수집 및 감정 분석
        scheduler.add_job(
            collect_and_analyze_data,
            'interval',
            minutes=5,
            id='data_collection',
            next_run_time=datetime.now()
        )

        # 1분마다 거래 신호 체크 및 실행
        scheduler.add_job(
            execute_trading_signals,
            'interval',
            minutes=1,
            id='trading_execution',
            next_run_time=datetime.now() + timedelta(seconds=30)
        )

        # 30초마다 포지션 모니터링
        scheduler.add_job(
            monitor_positions,
            'interval',
            seconds=30,
            id='position_monitoring',
            next_run_time=datetime.now() + timedelta(seconds=10)
        )

        scheduler.start()
        logger.info("✅ 스케줄러 시작 완료")

        logger.info("✅ CryptoLeverageAI 서버 준비 완료")

    except Exception as e:
        logger.error(f"❌ 서버 초기화 실패: {e}")
        raise


@app.on_event("shutdown")
async def shutdown_event():
    """서버 종료 시 정리"""
    logger.info("🛑 CryptoLeverageAI 서버 종료 중...")

    if scheduler:
        scheduler.shutdown()

    logger.info("✅ 서버 종료 완료")


# ==================== 데이터 수집 및 분석 ====================

def collect_and_analyze_data():
    """
    5분마다 실행: 뉴스 + 트위터 데이터 수집 및 감정 분석
    """
    logger.info("📊 데이터 수집 및 감정 분석 시작...")

    try:
        # 1. 뉴스 데이터 수집 (realtimeNS.py 활용)
        from realtimeNS import collect_korean_news
        news_data = collect_korean_news()
        logger.info(f"📰 뉴스 {len(news_data)}개 수집 완료")

        # 2. 트위터 데이터 수집 (reverageAI.py 활용)
        from twitter_monitor import collect_influencer_tweets
        tweet_data = collect_influencer_tweets()
        logger.info(f"🐦 트윗 {len(tweet_data)}개 수집 완료")

        # 3. Claude API로 감정 분석
        all_data = news_data + tweet_data

        for item in all_data:
            sentiment_result = sentiment_analyzer.analyze(
                text=item['content'],
                source=item['source'],
                author=item.get('author', 'unknown')
            )

            # 4. Firestore에 저장
            firestore_service.save_signal({
                'timestamp': datetime.now(),
                'source': item['source'],
                'author': item.get('author'),
                'content': item['content'],
                'sentiment': sentiment_result['sentiment'],
                'coins': sentiment_result['coins'],
                'impact_score': sentiment_result['impact'],
                'confidence': sentiment_result['confidence'],
                'verification_layers': {
                    'layer1': True,  # 이벤트 감지 완료
                    'layer2': False,  # 기술적 분석 대기
                    'layer3': False   # 감정 검증 대기
                },
                'status': 'analyzing'
            })

            logger.info(f"✅ 신호 저장: {sentiment_result['coins']} - {sentiment_result['sentiment']} ({sentiment_result['confidence']:.2%})")

        # 5. WebSocket으로 실시간 알림
        asyncio.create_task(broadcast_update({
            'type': 'data_collected',
            'news_count': len(news_data),
            'tweet_count': len(tweet_data),
            'timestamp': datetime.now().isoformat()
        }))

        logger.info("✅ 데이터 수집 및 분석 완료")

    except Exception as e:
        logger.error(f"❌ 데이터 수집 실패: {e}")


def execute_trading_signals():
    """
    1분마다 실행: 저장된 신호를 기반으로 거래 실행 판단
    """
    logger.info("🔍 거래 신호 분석 시작...")

    try:
        # 1. Firestore에서 분석 중인 신호 가져오기
        signals = firestore_service.get_signals_by_status('analyzing')

        for signal in signals:
            # 2. 신뢰도 체크
            if signal['confidence'] < 0.65:
                logger.info(f"⏭️  신호 무시 (낮은 신뢰도): {signal['coins']} - {signal['confidence']:.2%}")
                continue

            # 3. 각 코인별 기술적 분석
            for coin in signal['coins']:
                technical_result = signal_generator.analyze_technical(
                    symbol=f"{coin}/USDT",
                    sentiment_score=signal['sentiment'],
                    impact_score=signal['impact_score']
                )

                # 4. 3계층 검증
                verification = verify_signal_3layers(signal, technical_result)

                # 5. 검증 통과 시 거래 실행
                if verification['approved']:
                    # 리스크 관리 체크
                    risk_check = risk_manager.check_trading_conditions(
                        coin=coin,
                        confidence=signal['confidence'],
                        leverage=technical_result['recommended_leverage']
                    )

                    if risk_check['approved']:
                        # 포지션 계산
                        position_size = position_manager.calculate_position_size(
                            confidence=signal['confidence'],
                            leverage=technical_result['recommended_leverage'],
                            risk_pct=risk_check['risk_percentage']
                        )

                        # 거래 실행
                        trade_result = position_manager.execute_trade(
                            symbol=f"{coin}/USDT",
                            side=technical_result['action'],  # 'buy' or 'sell'
                            leverage=technical_result['recommended_leverage'],
                            amount=position_size,
                            stop_loss_pct=risk_check['stop_loss_pct'],
                            take_profit_pct=risk_check['take_profit_pct']
                        )

                        # Firestore 업데이트
                        firestore_service.update_signal(signal['id'], {
                            'status': 'executed',
                            'verification_layers': verification['layers'],
                            'trade_id': trade_result['trade_id']
                        })

                        firestore_service.save_position(trade_result)

                        # 실시간 알림
                        asyncio.create_task(broadcast_update({
                            'type': 'trade_executed',
                            'coin': coin,
                            'action': technical_result['action'],
                            'leverage': technical_result['recommended_leverage'],
                            'confidence': signal['confidence'],
                            'timestamp': datetime.now().isoformat()
                        }))

                        logger.info(f"✅ 거래 실행: {coin} {technical_result['action'].upper()} "
                                  f"x{technical_result['recommended_leverage']} "
                                  f"(신뢰도: {signal['confidence']:.2%})")
                    else:
                        logger.warning(f"⚠️  리스크 체크 실패: {coin} - {risk_check['reason']}")
                else:
                    logger.info(f"❌ 검증 실패: {coin} - {verification['reason']}")

        logger.info("✅ 거래 신호 분석 완료")

    except Exception as e:
        logger.error(f"❌ 거래 신호 분석 실패: {e}")


def monitor_positions():
    """
    30초마다 실행: 열린 포지션 모니터링 및 관리
    """
    try:
        # 열린 포지션 가져오기
        open_positions = firestore_service.get_open_positions()

        for position in open_positions:
            # 현재 가격 확인
            current_price = position_manager.get_current_price(position['symbol'])

            # 손익 계산
            pnl = position_manager.calculate_pnl(
                entry_price=position['entry_price'],
                current_price=current_price,
                side=position['side'],
                leverage=position['leverage'],
                amount=position['amount']
            )

            # 포지션 업데이트
            firestore_service.update_position(position['id'], {
                'current_price': current_price,
                'pnl': pnl['pnl'],
                'pnl_percent': pnl['pnl_percent'],
                'updated_at': datetime.now()
            })

            # 손절/익절 체크
            should_close, reason = position_manager.should_close_position(
                position=position,
                current_price=current_price,
                pnl_percent=pnl['pnl_percent']
            )

            if should_close:
                # 포지션 청산
                close_result = position_manager.close_position(position)

                firestore_service.update_position(position['id'], {
                    'status': 'closed',
                    'close_price': current_price,
                    'close_reason': reason,
                    'final_pnl': pnl['pnl'],
                    'closed_at': datetime.now()
                })

                # 실시간 알림
                asyncio.create_task(broadcast_update({
                    'type': 'position_closed',
                    'coin': position['symbol'],
                    'reason': reason,
                    'pnl': pnl['pnl'],
                    'pnl_percent': pnl['pnl_percent'],
                    'timestamp': datetime.now().isoformat()
                }))

                logger.info(f"🔒 포지션 청산: {position['symbol']} - {reason} "
                          f"(손익: {pnl['pnl_percent']:.2%})")

    except Exception as e:
        logger.error(f"❌ 포지션 모니터링 실패: {e}")


def verify_signal_3layers(signal: Dict, technical_result: Dict) -> Dict:
    """
    3계층 검증 시스템

    Layer 1: 실시간 이벤트 감지 (0-5분)
    Layer 2: 기술적 확인 (5-15분)
    Layer 3: 감정 검증 (1-24시간)
    """
    layers = {
        'layer1': signal['verification_layers']['layer1'],  # 이미 True
        'layer2': False,
        'layer3': False
    }

    # Layer 2: 기술적 분석 확인
    if (technical_result['macd_signal'] and
        technical_result['rsi_signal'] and
        technical_result['volume_confirmed']):
        layers['layer2'] = True

    # Layer 3: 감정 지속성 확인 (시간 경과 확인)
    signal_age = (datetime.now() - signal['timestamp']).total_seconds() / 60
    if signal_age >= 5:  # 5분 이상 경과
        # 최근 유사 신호 확인
        recent_signals = firestore_service.get_recent_signals(
            coins=signal['coins'],
            minutes=60
        )

        if len(recent_signals) >= 2:  # 1시간 내 2개 이상 유사 신호
            layers['layer3'] = True

    # 신뢰도별 레버리지 조정
    if all(layers.values()):
        confidence_level = 'highest'  # 3계층 모두 통과
    elif layers['layer1'] and layers['layer2']:
        confidence_level = 'high'  # 2계층 통과
    elif layers['layer1']:
        confidence_level = 'medium'  # 1계층만 통과
    else:
        confidence_level = 'low'

    approved = confidence_level in ['highest', 'high', 'medium']

    return {
        'approved': approved,
        'layers': layers,
        'confidence_level': confidence_level,
        'reason': f"{confidence_level} confidence - " +
                 f"Layers: {sum(layers.values())}/3"
    }


# ==================== REST API 엔드포인트 ====================

@app.get("/")
async def root():
    """API 상태 확인"""
    return {
        "status": "running",
        "service": "CryptoLeverageAI",
        "version": "1.0.0",
        "timestamp": datetime.now().isoformat()
    }


@app.get("/api/signals")
async def get_signals(limit: int = 20, status: Optional[str] = None):
    """신호 목록 조회"""
    try:
        signals = firestore_service.get_signals(limit=limit, status=status)
        return {"success": True, "data": signals}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/positions")
async def get_positions(status: Optional[str] = 'open'):
    """포지션 목록 조회"""
    try:
        if status == 'open':
            positions = firestore_service.get_open_positions()
        else:
            positions = firestore_service.get_positions(status=status)
        return {"success": True, "data": positions}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/performance")
async def get_performance():
    """성과 통계 조회"""
    try:
        stats = firestore_service.get_performance_stats()
        return {"success": True, "data": stats}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/manual-trade")
async def manual_trade(
    symbol: str,
    side: str,
    leverage: int,
    amount: float
):
    """수동 거래 실행"""
    try:
        result = position_manager.execute_trade(
            symbol=symbol,
            side=side,
            leverage=leverage,
            amount=amount
        )
        return {"success": True, "data": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ==================== WebSocket ====================

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """실시간 데이터 스트리밍"""
    await websocket.accept()
    active_connections.append(websocket)

    logger.info(f"🔌 WebSocket 연결: {len(active_connections)}개 활성")

    try:
        while True:
            # 실시간 데이터 전송
            data = {
                'type': 'heartbeat',
                'timestamp': datetime.now().isoformat(),
                'active_signals': len(firestore_service.get_signals_by_status('analyzing')),
                'open_positions': len(firestore_service.get_open_positions())
            }

            await websocket.send_json(data)
            await asyncio.sleep(5)  # 5초마다 하트비트

    except Exception as e:
        logger.error(f"❌ WebSocket 오류: {e}")
    finally:
        active_connections.remove(websocket)
        logger.info(f"🔌 WebSocket 연결 해제: {len(active_connections)}개 활성")


async def broadcast_update(message: Dict):
    """모든 연결된 클라이언트에 메시지 브로드캐스트"""
    for connection in active_connections:
        try:
            await connection.send_json(message)
        except Exception as e:
            logger.error(f"❌ 브로드캐스트 실패: {e}")


# ==================== 서버 실행 ====================

if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
