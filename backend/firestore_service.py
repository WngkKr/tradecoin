#!/usr/bin/env python3
"""
Firestore 연동 서비스
Firebase Project: emotra-9ebdb
"""

import firebase_admin
from firebase_admin import credentials, firestore
import logging
from typing import Dict, List, Optional
from datetime import datetime, timedelta
from pathlib import Path

logger = logging.getLogger(__name__)


class FirestoreService:
    """
    Firestore 데이터베이스 서비스

    컬렉션 구조:
    - signals: 거래 신호
    - positions: 포지션 정보
    - users: 사용자 정보
    - performance: 성과 통계
    """

    def __init__(self, credentials_path: Optional[str] = None):
        """
        초기화

        Parameters:
        -----------
        credentials_path : str, optional
            Firebase 인증 파일 경로
        """
        try:
            # Firebase 초기화 (이미 초기화되어 있으면 스킵)
            if not firebase_admin._apps:
                if credentials_path:
                    cred = credentials.Certificate(credentials_path)
                else:
                    # 기본 경로에서 찾기
                    default_paths = [
                        Path(__file__).parent.parent / 'firebase-credentials.json',
                        Path(__file__).parent.parent / 'emotra-9ebdb-firebase-adminsdk.json'
                    ]

                    cred_path = None
                    for path in default_paths:
                        if path.exists():
                            cred_path = str(path)
                            break

                    if cred_path:
                        cred = credentials.Certificate(cred_path)
                    else:
                        # 기본 인증 사용
                        firebase_admin.initialize_app()
                        self.db = firestore.client()
                        logger.warning("⚠️  기본 Firebase 인증 사용")
                        return

                firebase_admin.initialize_app(cred)

            self.db = firestore.client()
            logger.info("✅ Firestore 서비스 초기화 완료")

        except Exception as e:
            logger.error(f"❌ Firestore 초기화 실패: {e}")
            self.db = None

    def save_signal(self, signal_data: Dict) -> str:
        """
        신호 저장

        Parameters:
        -----------
        signal_data : Dict
            신호 데이터

        Returns:
        --------
        str : 저장된 문서 ID
        """
        try:
            doc_ref = self.db.collection('signals').document()
            doc_ref.set(signal_data)

            logger.info(f"💾 신호 저장: {doc_ref.id}")
            return doc_ref.id

        except Exception as e:
            logger.error(f"❌ 신호 저장 실패: {e}")
            return None

    def get_signals(self, limit: int = 20, status: Optional[str] = None) -> List[Dict]:
        """
        신호 목록 조회

        Parameters:
        -----------
        limit : int
            최대 개수
        status : str, optional
            상태 필터 ('analyzing', 'verified', 'executed', 'rejected')

        Returns:
        --------
        List[Dict] : 신호 리스트
        """
        try:
            query = self.db.collection('signals')

            if status:
                query = query.where('status', '==', status)

            query = query.order_by('timestamp', direction=firestore.Query.DESCENDING).limit(limit)

            docs = query.stream()

            signals = []
            for doc in docs:
                data = doc.to_dict()
                data['id'] = doc.id
                signals.append(data)

            return signals

        except Exception as e:
            logger.error(f"❌ 신호 조회 실패: {e}")
            return []

    def get_signals_by_status(self, status: str) -> List[Dict]:
        """상태별 신호 조회"""
        return self.get_signals(limit=100, status=status)

    def update_signal(self, signal_id: str, update_data: Dict) -> bool:
        """
        신호 업데이트

        Parameters:
        -----------
        signal_id : str
            신호 ID
        update_data : Dict
            업데이트할 데이터

        Returns:
        --------
        bool : 성공 여부
        """
        try:
            self.db.collection('signals').document(signal_id).update(update_data)
            logger.info(f"✅ 신호 업데이트: {signal_id}")
            return True

        except Exception as e:
            logger.error(f"❌ 신호 업데이트 실패: {e}")
            return False

    def save_position(self, position_data: Dict) -> str:
        """
        포지션 저장

        Parameters:
        -----------
        position_data : Dict
            포지션 데이터

        Returns:
        --------
        str : 저장된 문서 ID
        """
        try:
            doc_ref = self.db.collection('positions').document(position_data['trade_id'])
            doc_ref.set(position_data)

            logger.info(f"💾 포지션 저장: {doc_ref.id}")
            return doc_ref.id

        except Exception as e:
            logger.error(f"❌ 포지션 저장 실패: {e}")
            return None

    def get_open_positions(self) -> List[Dict]:
        """열린 포지션 목록 조회"""
        try:
            query = self.db.collection('positions').where('status', '==', 'open')
            docs = query.stream()

            positions = []
            for doc in docs:
                data = doc.to_dict()
                data['id'] = doc.id
                positions.append(data)

            return positions

        except Exception as e:
            logger.error(f"❌ 포지션 조회 실패: {e}")
            return []

    def get_positions(self, status: Optional[str] = None, limit: int = 50) -> List[Dict]:
        """
        포지션 목록 조회

        Parameters:
        -----------
        status : str, optional
            상태 필터 ('open', 'closed')
        limit : int
            최대 개수

        Returns:
        --------
        List[Dict] : 포지션 리스트
        """
        try:
            query = self.db.collection('positions')

            if status:
                query = query.where('status', '==', status)

            query = query.order_by('executed_at', direction=firestore.Query.DESCENDING).limit(limit)

            docs = query.stream()

            positions = []
            for doc in docs:
                data = doc.to_dict()
                data['id'] = doc.id
                positions.append(data)

            return positions

        except Exception as e:
            logger.error(f"❌ 포지션 조회 실패: {e}")
            return []

    def update_position(self, position_id: str, update_data: Dict) -> bool:
        """
        포지션 업데이트

        Parameters:
        -----------
        position_id : str
            포지션 ID
        update_data : Dict
            업데이트할 데이터

        Returns:
        --------
        bool : 성공 여부
        """
        try:
            self.db.collection('positions').document(position_id).update(update_data)
            logger.info(f"✅ 포지션 업데이트: {position_id}")
            return True

        except Exception as e:
            logger.error(f"❌ 포지션 업데이트 실패: {e}")
            return False

    def get_recent_signals(self, coins: List[str], minutes: int = 60) -> List[Dict]:
        """
        최근 유사 신호 조회 (3계층 검증용)

        Parameters:
        -----------
        coins : List[str]
            코인 리스트
        minutes : int
            조회 기간 (분)

        Returns:
        --------
        List[Dict] : 신호 리스트
        """
        try:
            cutoff_time = datetime.now() - timedelta(minutes=minutes)

            query = self.db.collection('signals') \
                .where('timestamp', '>=', cutoff_time) \
                .where('coins', 'array_contains_any', coins)

            docs = query.stream()

            signals = []
            for doc in docs:
                data = doc.to_dict()
                data['id'] = doc.id
                signals.append(data)

            return signals

        except Exception as e:
            logger.error(f"❌ 최근 신호 조회 실패: {e}")
            return []

    def get_performance_stats(self) -> Dict:
        """
        성과 통계 조회

        Returns:
        --------
        Dict : 통계 데이터
        """
        try:
            # 모든 닫힌 포지션 조회
            closed_positions = self.get_positions(status='closed', limit=1000)

            if not closed_positions:
                return {
                    'total_trades': 0,
                    'win_rate': 0.0,
                    'total_pnl': 0.0,
                    'avg_pnl': 0.0
                }

            total_trades = len(closed_positions)
            winning_trades = len([p for p in closed_positions if p.get('final_pnl', 0) > 0])
            win_rate = winning_trades / total_trades if total_trades > 0 else 0

            total_pnl = sum(p.get('final_pnl', 0) for p in closed_positions)
            avg_pnl = total_pnl / total_trades if total_trades > 0 else 0

            return {
                'total_trades': total_trades,
                'winning_trades': winning_trades,
                'losing_trades': total_trades - winning_trades,
                'win_rate': win_rate,
                'total_pnl': total_pnl,
                'avg_pnl': avg_pnl,
                'best_trade': max((p.get('final_pnl', 0) for p in closed_positions), default=0),
                'worst_trade': min((p.get('final_pnl', 0) for p in closed_positions), default=0)
            }

        except Exception as e:
            logger.error(f"❌ 성과 통계 조회 실패: {e}")
            return {}


# 테스트 코드
if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)

    print("\n" + "="*80)
    print("Firestore 서비스 테스트")
    print("="*80 + "\n")

    service = FirestoreService()

    if service.db:
        print("✅ Firestore 연결 성공\n")

        # 테스트 신호 저장
        test_signal = {
            'timestamp': datetime.now(),
            'source': 'twitter',
            'author': 'elonmusk',
            'content': 'Test signal',
            'sentiment': 0.8,
            'coins': ['BTC', 'DOGE'],
            'impact_score': 75,
            'confidence': 0.85,
            'status': 'analyzing'
        }

        signal_id = service.save_signal(test_signal)
        print(f"신호 저장 완료: {signal_id}\n")

        # 신호 조회
        signals = service.get_signals(limit=5)
        print(f"저장된 신호 수: {len(signals)}\n")

        # 성과 통계
        stats = service.get_performance_stats()
        print("성과 통계:")
        print(f"  총 거래: {stats.get('total_trades', 0)}")
        print(f"  승률: {stats.get('win_rate', 0):.2%}")
        print(f"  총 손익: ${stats.get('total_pnl', 0):.2f}")

    else:
        print("❌ Firestore 연결 실패")
        print("   Firebase 인증 파일을 확인하세요")
