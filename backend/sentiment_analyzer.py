#!/usr/bin/env python3
"""
Claude API 기반 감정 분석 모듈
PRD 3.1.2 AI 감정 분석 모듈 구현
"""

import anthropic
import os
import json
import logging
from typing import Dict, List
from datetime import datetime

logger = logging.getLogger(__name__)


class SentimentAnalyzer:
    """
    Claude API를 사용한 암호화폐 감정 분석기

    목표:
    - 텍스트의 암호화폐별 감정과 영향도를 정량화
    - 감정 분류 정확도: ≥ 85%
    - 코인 연관성 매핑: ≥ 90%
    - False Positive Rate: ≤ 10%
    """

    def __init__(self):
        """감정 분석기 초기화"""
        # Claude API 클라이언트 설정
        api_key = os.getenv('ANTHROPIC_API_KEY')
        self.client = anthropic.Anthropic(api_key=api_key)

        # 모델 설정
        self.model = "claude-3-5-sonnet-20241022"

        # 코인 키워드 매핑
        self.coin_keywords = {
            'BTC': ['bitcoin', 'btc', 'bitcoin'],
            'ETH': ['ethereum', 'eth', 'ether', 'vitalik'],
            'DOGE': ['dogecoin', 'doge', 'dog', 'shiba'],
            'SHIB': ['shiba', 'shib', 'shiba inu'],
            'FLOKI': ['floki', 'puppy'],
            'TRUMP': ['trump', 'president', 'election', 'maga'],
            'MAGA': ['maga', 'make america great'],
            'XRP': ['xrp', 'ripple'],
            'ADA': ['cardano', 'ada'],
            'SOL': ['solana', 'sol']
        }

        # 인플루언서별 영향도 가중치
        self.influencer_weights = {
            'elonmusk': 1.5,
            'realDonaldTrump': 1.4,
            'saylor': 1.3,
            'VitalikButerin': 1.2,
            'default': 1.0
        }

        logger.info("✅ Sentiment Analyzer 초기화 완료")

    def analyze(self, text: str, source: str, author: str = 'unknown') -> Dict:
        """
        텍스트 감정 분석 수행

        Parameters:
        -----------
        text : str
            분석할 텍스트
        source : str
            출처 ('twitter', 'news', 'official')
        author : str
            작성자 (트위터 username 등)

        Returns:
        --------
        Dict : 감정 분석 결과
            {
                'sentiment': float (-1.0 ~ 1.0),
                'coins': List[str],
                'impact': float (0 ~ 100),
                'confidence': float (0 ~ 1.0)
            }
        """
        try:
            # Claude API로 감정 분석 수행
            response = self.client.messages.create(
                model=self.model,
                max_tokens=1024,
                messages=[{
                    "role": "user",
                    "content": self._create_analysis_prompt(text, source)
                }]
            )

            # 응답 파싱
            result_text = response.content[0].text
            result = self._parse_claude_response(result_text)

            # 코인 연관성 매핑
            coins = self._map_coin_relevance(text, result.get('coins', []))

            # 영향도 계산
            impact = self._calculate_impact(
                sentiment=result['sentiment'],
                coins=coins,
                source=source,
                author=author
            )

            # 신뢰도 계산
            confidence = self._calculate_confidence(
                sentiment=result['sentiment'],
                coins=coins,
                source=source
            )

            return {
                'sentiment': result['sentiment'],
                'coins': coins,
                'impact': impact,
                'confidence': confidence,
                'raw_result': result,
                'analyzed_at': datetime.now().isoformat()
            }

        except Exception as e:
            logger.error(f"❌ 감정 분석 실패: {e}")
            return {
                'sentiment': 0.0,
                'coins': [],
                'impact': 0.0,
                'confidence': 0.0,
                'error': str(e)
            }

    def _create_analysis_prompt(self, text: str, source: str) -> str:
        """Claude API용 분석 프롬프트 생성"""
        return f"""다음 텍스트를 분석하여 암호화폐 시장에 대한 감정과 영향을 평가해주세요.

출처: {source}
텍스트: {text}

다음 JSON 형식으로 답변해주세요:
{{
    "sentiment": <-1.0(매우 부정) ~ 1.0(매우 긍정) 사이의 숫자>,
    "coins": [<언급되거나 영향받을 코인 심볼 리스트, 예: "BTC", "ETH", "DOGE">],
    "reasoning": "<분석 근거>",
    "key_phrases": [<감정에 영향을 준 주요 문구들>],
    "market_impact_potential": <"low", "medium", "high">
}}

분석 시 고려사항:
1. 직접적인 코인 언급뿐만 아니라 간접적 영향도 고려
2. 긍정/부정 키워드의 강도 파악
3. 맥락과 뉘앙스 고려
4. 시장에 실제 영향을 줄 수 있는지 평가

JSON만 출력하세요."""

    def _parse_claude_response(self, response_text: str) -> Dict:
        """Claude 응답 파싱"""
        try:
            # JSON 추출 (마크다운 코드 블록 제거)
            if '```json' in response_text:
                json_text = response_text.split('```json')[1].split('```')[0].strip()
            elif '```' in response_text:
                json_text = response_text.split('```')[1].split('```')[0].strip()
            else:
                json_text = response_text.strip()

            result = json.loads(json_text)

            # 필수 필드 확인
            if 'sentiment' not in result:
                result['sentiment'] = 0.0
            if 'coins' not in result:
                result['coins'] = []

            # sentiment 값 정규화 (-1.0 ~ 1.0)
            result['sentiment'] = max(-1.0, min(1.0, float(result['sentiment'])))

            return result

        except Exception as e:
            logger.error(f"❌ 응답 파싱 실패: {e}")
            return {
                'sentiment': 0.0,
                'coins': [],
                'reasoning': 'parsing error',
                'key_phrases': [],
                'market_impact_potential': 'low'
            }

    def _map_coin_relevance(self, text: str, claude_coins: List[str]) -> List[str]:
        """
        코인 연관성 매핑

        Claude가 제안한 코인 + 키워드 기반 추가 매칭
        """
        text_lower = text.lower()
        matched_coins = set(claude_coins)

        # 키워드 기반 매칭
        for coin, keywords in self.coin_keywords.items():
            for keyword in keywords:
                if keyword.lower() in text_lower:
                    matched_coins.add(coin)
                    break

        return list(matched_coins)

    def _calculate_impact(
        self,
        sentiment: float,
        coins: List[str],
        source: str,
        author: str
    ) -> float:
        """
        영향도 스코어 계산 (0-100)

        고려사항:
        - 감정 강도
        - 코인 개수
        - 출처 가중치
        - 인플루언서 가중치
        """
        # 기본 임팩트 (감정 절대값)
        base_impact = abs(sentiment) * 50

        # 출처 가중치
        source_weights = {
            'twitter': 1.3,
            'news': 1.0,
            'official': 1.5
        }
        source_weight = source_weights.get(source, 1.0)

        # 인플루언서 가중치
        author_weight = self.influencer_weights.get(author, 1.0)

        # 코인 수에 따른 가중치 (여러 코인 언급 시 분산)
        coin_weight = 1.0 if len(coins) <= 1 else 0.8

        # 최종 임팩트 계산
        impact = base_impact * source_weight * author_weight * coin_weight

        # 0-100 범위로 제한
        return min(100.0, max(0.0, impact))

    def _calculate_confidence(
        self,
        sentiment: float,
        coins: List[str],
        source: str
    ) -> float:
        """
        신뢰도 계산 (0-1.0)

        고려사항:
        - 감정 명확성 (절대값)
        - 코인 매칭 여부
        - 출처 신뢰도
        """
        # 기본 신뢰도 (감정 절대값)
        base_confidence = abs(sentiment)

        # 코인 매칭 보너스
        coin_bonus = 0.2 if len(coins) > 0 else -0.2

        # 출처 신뢰도
        source_confidence = {
            'twitter': 0.8,
            'news': 0.9,
            'official': 1.0
        }.get(source, 0.7)

        # 최종 신뢰도
        confidence = (base_confidence + coin_bonus) * source_confidence

        # 0-1.0 범위로 제한
        return min(1.0, max(0.0, confidence))

    def batch_analyze(self, texts: List[Dict]) -> List[Dict]:
        """
        여러 텍스트 일괄 분석

        Parameters:
        -----------
        texts : List[Dict]
            [{'text': str, 'source': str, 'author': str}, ...]

        Returns:
        --------
        List[Dict] : 분석 결과 리스트
        """
        results = []

        for item in texts:
            result = self.analyze(
                text=item['text'],
                source=item.get('source', 'unknown'),
                author=item.get('author', 'unknown')
            )
            results.append(result)

        logger.info(f"✅ 배치 분석 완료: {len(results)}개")

        return results


# 테스트 코드
if __name__ == "__main__":
    # 로깅 설정
    logging.basicConfig(level=logging.INFO)

    # 분석기 초기화
    analyzer = SentimentAnalyzer()

    # 테스트 케이스
    test_cases = [
        {
            'text': "Dogecoin might be my favorite cryptocurrency. It's pretty cool.",
            'source': 'twitter',
            'author': 'elonmusk'
        },
        {
            'text': "Bitcoin ETF approval is a major milestone for the crypto industry.",
            'source': 'news',
            'author': 'coindesk'
        },
        {
            'text': "Regulatory concerns continue to pressure the cryptocurrency market.",
            'source': 'news',
            'author': 'bloomberg'
        }
    ]

    print("\n" + "="*80)
    print("감정 분석 테스트")
    print("="*80 + "\n")

    for i, test in enumerate(test_cases, 1):
        print(f"\n[테스트 {i}]")
        print(f"출처: {test['source']} ({test['author']})")
        print(f"텍스트: {test['text']}")

        result = analyzer.analyze(
            text=test['text'],
            source=test['source'],
            author=test['author']
        )

        print(f"\n결과:")
        print(f"  감정: {result['sentiment']:.2f} ({('부정' if result['sentiment'] < 0 else '긍정' if result['sentiment'] > 0 else '중립')})")
        print(f"  코인: {', '.join(result['coins'])}")
        print(f"  영향도: {result['impact']:.1f}/100")
        print(f"  신뢰도: {result['confidence']:.1%}")
        print("-" * 80)
