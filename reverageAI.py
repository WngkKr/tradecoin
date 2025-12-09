# 트위터 API와 LLM을 활용한 코인 감정 분석 및 트레이딩 시그널 시스템
# pip install requests python-dotenv apscheduler
# 1. 필요한 라이브러리 가져오기
import os
import json
import re
import time
import random
import requests
from datetime import datetime, timedelta
import logging
from dotenv import load_dotenv
import anthropic

# 환경 변수 로드
load_dotenv()

# Claude API 클라이언트 설정
client = anthropic.Anthropic(api_key=os.getenv('ANTHROPIC_API_KEY'))

# 로깅 설정
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# 2. 모니터링할 인플루언서 목록 설정
influencers = [
    {"name": "Elon Musk", "twitter_username": "elonmusk", "coins": ["DOGE", "SHIB", "FLOKI"]},
    {"name": "Donald Trump", "twitter_username": "realDonaldTrump", "coins": ["TRUMP", "MAGA"]},
    {"name": "Michael Saylor", "twitter_username": "saylor", "coins": ["BTC"]},
    {"name": "Vitalik Buterin", "twitter_username": "VitalikButerin", "coins": ["ETH"]}
]

# 3. 코인별 과거 반응 패턴 데이터 (실제로는 DB에서 관리)
coin_patterns = {
    'DOGE': {
        'avgReactionTimeMinutes': 7,
        'avgPriceImpactPercent': 12,
        'positiveKeywords': ['dog', 'moon', 'favorite', 'love'],
        'negativeKeywords': ['sell', 'overvalued']
    },
    'TRUMP': {
        'avgReactionTimeMinutes': 15,
        'avgPriceImpactPercent': 35,
        'positiveKeywords': ['president', 'win', 'election', 'victory'],
        'negativeKeywords': ['case', 'trial', 'verdict']
    },
    'BTC': {
        'avgReactionTimeMinutes': 10,
        'avgPriceImpactPercent': 5,
        'positiveKeywords': ['reserve', 'property', 'hope', 'acquire', 'hold'],
        'negativeKeywords': ['sell', 'risk', 'ban', 'regulation']
    },
    'ETH': {
        'avgReactionTimeMinutes': 12,
        'avgPriceImpactPercent': 8,
        'positiveKeywords': ['scaling', 'staking', 'defi', 'layer 2', 'upgrade'],
        'negativeKeywords': ['delay', 'issue', 'problem', 'bug']
    },
    'SHIB': {
        'avgReactionTimeMinutes': 8,
        'avgPriceImpactPercent': 15,
        'positiveKeywords': ['dog', 'community', 'cute', 'pet'],
        'negativeKeywords': ['dump', 'meme', 'joke']
    },
    'FLOKI': {
        'avgReactionTimeMinutes': 5,
        'avgPriceImpactPercent': 25,
        'positiveKeywords': ['puppy', 'cute', 'moon', 'pet'],
        'negativeKeywords': ['sell', 'scam', 'joke']
    },
    'MAGA': {
        'avgReactionTimeMinutes': 14,
        'avgPriceImpactPercent': 30,
        'positiveKeywords': ['america', 'win', 'great', 'huge'],
        'negativeKeywords': ['lose', 'bad', 'fake']
    }
}

# 4. 더미 트윗 생성 함수
def get_recent_tweets(username, count=10):
    """더미 트윗 데이터 생성"""
    logger.info(f"{username}의 더미 트윗 생성 중...")
    
    dummy_tweets = []
    
    # 인플루언서별 더미 트윗 생성
    if "elonmusk" in username.lower():
        tweet_options = [
            "Dogecoin might be my favorite cryptocurrency. It's pretty cool.",
            "Thinking about the future of sustainable energy and cryptocurrency mining.",
            "Just bought some more Bitcoin because why not",
            "My Shiba Inu puppy is so cute today!",
            "Floki to the moon!",
            "DOGE will be used as currency on Mars",
            "Considering accepting DOGE for Tesla purchases",
            "Crypto is the future of finance",
            "Working on FLOKI utility, stay tuned",
            "SHIB has an interesting community"
        ]
        author_id = "44196397"
    elif "trump" in username.lower():
        tweet_options = [
            "MAKE AMERICA GREAT AGAIN! #MAGA",
            "We're going to win, and we're going to win big in the markets too!",
            "Our economy is the strongest it's ever been. Tremendous!",
            "The election is coming up. Victory for America!",
            "America First policies are working!",
            "TRUMP currency is going to be huge, believe me!",
            "MAGA coin supporters are the best supporters",
            "We're building something big with cryptocurrency",
            "Nobody understands markets better than me",
            "Very exciting news about MAGA coin coming soon"
        ]
        author_id = "25073877"
    elif "saylor" in username.lower():
        tweet_options = [
            "Bitcoin is digital property and the first engineered monetary system in the history of the world.",
            "Just acquired another 1000 BTC for the corporate treasury.",
            "Bitcoin is hope for billions of people across the planet.",
            "The most efficient use of energy in the world is the Bitcoin network.",
            "We now hold more than 100,000 BTC as our primary treasury reserve asset.",
            "Bitcoin is the apex property of the human race",
            "BTC scarcity is accelerating with the halving",
            "Our strategy remains: acquire and hold Bitcoin",
            "Traditional currencies are melting in your pocket while BTC appreciates",
            "Added 500 more BTC to treasury this morning"
        ]
        author_id = "244647486"
    elif "vitalik" in username.lower():
        tweet_options = [
            "Ethereum 2.0 progress is looking good. Exciting developments ahead.",
            "Working on improving scalability solutions for ETH.",
            "The future of decentralized finance is bright.",
            "Exploring new technical possibilities for Ethereum L2 solutions.",
            "Just donated 100 ETH to support open source development.",
            "ETH staking yields are stabilizing nicely",
            "Zero-knowledge proofs will transform scalability",
            "Layer 2 is where most transaction volume will live",
            "Protocol improvements coming in next update",
            "Community governance of ETH is maturing well"
        ]
        author_id = "295218901"
    else:
        tweet_options = [f"이것은 {username}의 더미 트윗 #{i+1}입니다. 이 트윗은 데모용으로 생성되었습니다." for i in range(20)]
        author_id = "000000"
    
    # 랜덤하게 트윗 선택
    selected_tweets = random.sample(tweet_options, min(count, len(tweet_options)))
    
    # 최근 날짜/시간 생성 (최근 3일 이내)
    def random_recent_time():
        now = datetime.now()
        random_hours = random.randint(1, 72)  # 최근 3일 이내
        return now - timedelta(hours=random_hours)
    
    # 트윗 객체 생성
    for i, tweet_text in enumerate(selected_tweets):
        created_at = random_recent_time()
        
        tweet_obj = {
            "id": f"{int(time.time())}{i}",
            "text": tweet_text,
            "created_at": created_at,
            "author_id": author_id,
            "public_metrics": {
                "like_count": random.randint(1000, 50000),
                "retweet_count": random.randint(100, 5000),
                "reply_count": random.randint(50, 2000),
                "quote_count": random.randint(10, 500)
            }
        }
        dummy_tweets.append(tweet_obj)
    
    return dummy_tweets

# 5. 코인 가격 데이터 가져오기 함수 
def get_coin_price(symbol):
    """실제 API에서 코인 가격 데이터를 가져오는 함수"""
    logger.info(f"{symbol} 실시간 가격 데이터 요청 중...")
    
    # 캐시된 가격 먼저 확인
    cached_price = get_cached_price(symbol, max_age_seconds=60)  # 1분 이내 캐시 사용
    if cached_price:
        logger.info(f"{symbol} 캐시된 가격 사용: ${cached_price:.6f}")
        return cached_price
    
    # 다양한 API 소스 설정
    api_sources = [
        {
            "name": "Binance",
            "url": f"https://api.binance.com/api/v3/ticker/price?symbol={symbol}USDT",
            "price_extractor": lambda data: float(data.get('price', 0)),
            "headers": {}
        },
        {
            "name": "CoinGecko",
            "url": f"https://api.coingecko.com/api/v3/simple/price?ids={symbol.lower()}&vs_currencies=usd",
            "price_extractor": lambda data: float(data.get(symbol.lower(), {}).get('usd', 0)),
            "headers": {}
        },
        {
            "name": "CoinMarketCap",
            "url": f"https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest?symbol={symbol}",
            "price_extractor": lambda data: float(data.get('data', {}).get(symbol, {}).get('quote', {}).get('USD', {}).get('price', 0)),
            "headers": {"X-CMC_PRO_API_KEY": os.getenv("CMC_API_KEY", "")}
        }
    ]
    
    errors = []
    
    # 각 API 소스 시도
    for source in api_sources:
        try:
            logger.info(f"{source['name']} API에서 {symbol} 가격 요청 중...")
            
            # API 키가 필요하지만 설정되지 않은 경우 스킵
            if "X-CMC_PRO_API_KEY" in source["headers"] and not source["headers"]["X-CMC_PRO_API_KEY"]:
                logger.warning(f"{source['name']} API 키가 설정되지 않아 스킵합니다.")
                continue
                
            # 속도 제한 대응을 위한 재시도 로직
            max_retries = 3
            retry_count = 0
            retry_delay = 2  # 초기 지연 시간 (초)
            
            while retry_count < max_retries:
                try:
                    # API 요청
                    response = requests.get(source["url"], headers=source["headers"], timeout=5)
                    
                    # 속도 제한 감지 (429 Too Many Requests)
                    if response.status_code == 429:
                        retry_count += 1
                        if retry_count >= max_retries:
                            logger.warning(f"{source['name']} API 속도 제한 최대 재시도 횟수 초과")
                            errors.append(f"{source['name']}: HTTP 429 (속도 제한)")
                            break
                            
                        wait_time = retry_delay * (2 ** retry_count)  # 지수 백오프
                        logger.warning(f"{source['name']} API 속도 제한. {wait_time}초 후 재시도 ({retry_count}/{max_retries})...")
                        time.sleep(wait_time)
                        continue
                    
                    # 기타 오류 응답
                    if response.status_code != 200:
                        logger.warning(f"{source['name']} API 응답 오류: {response.status_code}")
                        errors.append(f"{source['name']}: HTTP {response.status_code}")
                        break
                    
                    # 성공적인 응답 처리
                    data = response.json()
                    
                    # 가격 추출
                    price = source["price_extractor"](data)
                    
                    # 가격 유효성 검사
                    if price <= 0:
                        logger.warning(f"{source['name']}에서 가져온 {symbol} 가격이 유효하지 않음: {price}")
                        errors.append(f"{source['name']}: 유효하지 않은 가격 ({price})")
                        break
                        
                    # 유효한 가격 반환
                    logger.info(f"{symbol} 가격을 {source['name']}에서 성공적으로 가져옴: ${price:.6f}")
                    
                    # 가격 캐싱
                    cache_price(symbol, price, source["name"])
                    
                    return price
                
                except requests.exceptions.Timeout:
                    retry_count += 1
                    if retry_count >= max_retries:
                        logger.warning(f"{source['name']} API 타임아웃 최대 재시도 횟수 초과")
                        errors.append(f"{source['name']}: 타임아웃")
                        break
                        
                    wait_time = retry_delay * retry_count
                    logger.warning(f"{source['name']} API 타임아웃. {wait_time}초 후 재시도 ({retry_count}/{max_retries})...")
                    time.sleep(wait_time)
                
                except Exception as e:
                    logger.warning(f"{source['name']} API 요청 중 오류: {str(e)}")
                    errors.append(f"{source['name']}: {str(e)}")
                    break
            
            # 다음 API 시도 전 짧은 지연 시간 추가 (속도 제한 방지)
            time.sleep(0.5)
            
        except requests.exceptions.ConnectionError:
            logger.warning(f"{source['name']} API 연결 오류")
            errors.append(f"{source['name']}: 연결 오류")
        except json.JSONDecodeError:
            logger.warning(f"{source['name']} API 응답 JSON 파싱 오류")
            errors.append(f"{source['name']}: JSON 파싱 오류")
        except Exception as e:
            logger.warning(f"{source['name']} API 오류: {str(e)}")
            errors.append(f"{source['name']}: {str(e)}")
    
    # 마지막 대안으로 추가 캐시 확인 (만료된 것도 포함)
    expired_cache = get_cached_price(symbol, max_age_seconds=3600)  # 1시간 이내 캐시
    if expired_cache:
        logger.warning(f"모든 API 실패 후 {symbol}의 만료된 캐시 가격 사용: ${expired_cache:.6f}")
        return expired_cache
    
    # 모든 API 소스가 실패한 경우
    error_message = f"모든 API 소스에서 {symbol} 가격을 가져오지 못했습니다. 오류: {', '.join(errors)}"
    logger.error(error_message)
    raise ValueError(error_message)

last_api_call_time = datetime.now() - timedelta(minutes=10)  # 초기값
api_calls_count = 0
MAX_API_CALLS_PER_MINUTE = 10  # 분당 최대 API 호출 수

# Claude API 호출 제한 관리
def can_call_claude_api():
    """Claude API 호출 제한 확인"""
    global last_api_call_time, api_calls_count
    
    current_time = datetime.now()
    time_diff = (current_time - last_api_call_time).total_seconds()
    
    # 1분이 지났으면 카운터 초기화
    if time_diff > 60:
        last_api_call_time = current_time
        api_calls_count = 0
        return True
    
    # 분당 호출 제한 확인
    if api_calls_count < MAX_API_CALLS_PER_MINUTE:
        api_calls_count += 1
        return True
    
    # 제한 초과
    return False

#  """Claude API를 사용하여 뉴스/트윗 내용을 분석"""
def analyze_with_claude(content, coin_symbol, source_type):
    """Claude API를 사용하여 뉴스/트윗 내용을 분석 (리스트 응답 처리 추가)"""
    try:
        # API 호출 제한 확인
        if not can_call_claude_api():
            logger.warning("Claude API 호출 제한 초과. 기본 분석으로 대체합니다.")
            # 기본 분석 사용 (fallback)
            if source_type == "트윗":
                return analyze_tweet_basic({'text': content}, coin_symbol)
            else:
                return analyze_news_basic({'content': content}, coin_symbol)
        
        # 최신 모델 사용
        model = "claude-3-5-sonnet-20240620"
        
        # 분석 프롬프트 생성
        prompt = f"""
        당신은 암호화폐 트레이딩 시그널 분석 전문가입니다. 다음 {source_type}을 분석하고 {coin_symbol}에 대한 영향을 평가해주세요.

        {source_type} 내용: 
        "{content}"

        다음 항목을 평가해주세요:
        1. 이 내용이 {coin_symbol}에 대해 긍정적인지, 부정적인지, 중립적인지 평가하고 그 이유를 설명하세요.
        2. 이 내용의 영향력과 신뢰도를 낮음/중간/높음으로 평가하고 이유를 설명하세요.
        3. 유사한 과거 이벤트에 기반하여 예상되는 가격 영향(%)을 추정하고 이유를 설명하세요.
        4. 이 정보를 바탕으로 추천 거래 행동(매수/매도/홀드)과 적정 레버리지 배수(1-20)를 제안하고 이유를 설명하세요.
        5. 이 정보에 기반한 거래의 위험도(낮음/중간/높음)를 평가하고 이유를 설명하세요.

        각 항목에 대해 구체적인 수치와 이유를 JSON 형식으로 응답해주세요:
        각 항목에 대해 구체적인 수치와 이유를 다음 형식의 JSON으로 정확히 응답해주세요:

        [json 형식]
        "sentiment": "positive/negative/neutral",
        "confidenceScore": 숫자(0-100),
        "predictedImpact": "매우 긍정적/긍정적/중립/부정적/매우 부정적",
        "estimatedPriceChangePercent": 숫자(-100 to 100),
        "reasoningExplanation": "분석 설명",
        "recommendedAction": "buy/sell/hold",
        "recommendedLeverageMultiple": 숫자(1-20),
        "riskLevel": "low/medium/high"        

        다른 형식이나 추가 필드를 사용하지 말고 정확히 위 형식을 따라주세요.
        """

        # 프롬프트 로깅 추가
        logger.info(f"=== Claude로 보낸 프롬프트 ===")
        logger.info(f"분석 대상 {source_type}: {content}")
        logger.info(f"코인: {coin_symbol}")
        logger.info(f"프롬프트: {prompt}")

        # Claude API 호출 시도
        try:
            # API 키 확인
            api_key = os.getenv("ANTHROPIC_API_KEY")
            if not api_key:
                logger.error("Anthropic API 키가 설정되지 않았습니다.")
                raise ValueError("API 키가 없습니다.")
                
            client = anthropic.Anthropic(api_key=api_key)
            
            # API 호출
            response = client.messages.create(
                model=model,
                max_tokens=1000,
                temperature=0.2,  # 낮은 온도로 일관된 응답 생성
                system="당신은 암호화폐 시장 분석 전문가로, 뉴스와 소셜 미디어 데이터를 분석하여 암호화폐 가격 변동을 예측합니다. 항상 구체적이고 수치에 기반한 분석을 제공합니다.",
                messages=[
                    {"role": "user", "content": prompt}
                ]
            )
            
            # 응답 객체 구조 로깅
            log_response_structure(response)
            
            # 응답에서 텍스트 추출
            response_text = ""
            
            # 응답 객체 구조 확인
            logger.info(f"응답 타입: {type(response)}")
            
            # 리스트 형태의 content 처리
            if hasattr(response, 'content'):
                if isinstance(response.content, str):
                    # 문자열인 경우 직접 사용
                    response_text = response.content
                    logger.info(f"응답이 문자열입니다. 길이: {len(response_text)}")
                elif isinstance(response.content, list):
                    # 리스트인 경우 모든 텍스트 항목 결합
                    logger.info(f"응답이 리스트입니다. 길이: {len(response.content)}")
                    
                    for item in response.content:
                        # 리스트의 각 항목 처리
                        if isinstance(item, dict):
                            # 'text' 또는 'value' 키가 있는 경우
                            if 'text' in item:
                                response_text += item['text']
                            elif 'value' in item:
                                response_text += item['value']
                            # 다른 가능한 키도 확인
                            elif 'content' in item:
                                if isinstance(item['content'], str):
                                    response_text += item['content']
                                    
                        elif hasattr(item, 'text'):
                            # 객체에 text 속성이 있는 경우
                            response_text += item.text
                        elif hasattr(item, 'value'):
                            # 객체에 value 속성이 있는 경우
                            response_text += item.value
                        elif isinstance(item, str):
                            # 항목이 문자열인 경우
                            response_text += item

                    
                            
                    logger.info(f"결합된 응답 텍스트 길이: {len(response_text)}")
                else:
                    # 다른 타입인 경우
                    logger.error(f"응답 content가 예상치 못한 타입입니다: {type(response.content)}")
                    logger.info(f"응답 content 내용 미리보기: {str(response.content)[:100]}...")
            else:
                # content 속성이 없는 경우
                logger.error("응답 객체에 content 속성이 없습니다.")
                # 가능한 다른 속성 확인
                if hasattr(response, 'message'):
                    if hasattr(response.message, 'content'):
                        response_text = response.message.content
                elif hasattr(response, 'choices') and len(response.choices) > 0:
                    if hasattr(response.choices[0], 'message'):
                        response_text = response.choices[0].message.content
            
            # 응답 텍스트가 추출되었으면 JSON 파싱 시도
            if response_text:

                logger.info(f"=== Claude 응답 전문 ===")
                logger.info(response_text)

                # JSON 패턴 찾기
                import re
                import json
                
                json_match = re.search(r'```json\s*(.*?)\s*```', response_text, re.DOTALL)
                if json_match:
                    json_str = json_match.group(1)
                    try:
                        analysis_result = json.loads(json_str)
                        return analysis_result
                    except json.JSONDecodeError:
                        logger.warning("JSON 파싱 오류, 다른 방법 시도")
                
                # 중괄호로 둘러싸인 JSON 패턴 찾기
                json_pattern = re.search(r'(\{.*\})', response_text, re.DOTALL)
                if json_pattern:
                    json_str = json_pattern.group(1)
                    try:
                        analysis_result = json.loads(json_str)
                        return analysis_result
                    except json.JSONDecodeError:
                        logger.warning("중괄호 패턴 JSON 파싱 오류")
                
                # 직접 텍스트 파싱
                logger.info("텍스트 기반 파싱 시도")
                analysis_result = parse_claude_response(response_text)
                return analysis_result
            else:
                logger.error("응답에서 텍스트를 추출할 수 없습니다.")
            
            # 응답 처리 실패 시 기본 분석으로 대체
            logger.info("응답 처리 실패. 기본 분석으로 대체합니다.")
        
        except anthropic.BadRequestError as e:
            logger.error(f"Claude API 오류 (BadRequest): {e}")
            if "credit balance is too low" in str(e):
                logger.error("API 크레딧 부족. 기본 분석으로 대체합니다.")
            elif "migrate to a newer model" in str(e):
                logger.error("모델이 더 이상 지원되지 않습니다. 코드의 모델을 업데이트해야 합니다.")
            # 다른 BadRequest 오류 처리
        
        except anthropic.RateLimitError as e:
            logger.error(f"Claude API 속도 제한 오류: {e}")
            logger.info("API 속도 제한 초과. 5초 대기 후 기본 분석으로 대체합니다.")
            time.sleep(5)  # 속도 제한 오류 시 대기
        
        except anthropic.APIError as e:
            logger.error(f"Claude API 오류: {e}")
        
        except Exception as e:
            logger.error(f"예상치 못한 오류: {e}")
            import traceback
            logger.error(traceback.format_exc())
        
        # 모든 오류 시 기본 분석 대체
        logger.info("오류로 인해 기본 분석으로 대체합니다.")
        if source_type == "트윗":
            return analyze_tweet_basic({'text': content}, coin_symbol)
        else:
            return analyze_news_basic({'content': content}, coin_symbol)
    
    except Exception as e:
        logger.error(f"Claude 분석 함수 오류: {e}")
        import traceback
        logger.error(traceback.format_exc())
        
        # 최종 fallback - 기본 분석
        if source_type == "트윗":
            return analyze_tweet_basic({'text': content}, coin_symbol)
        else:
            return analyze_news_basic({'content': content}, coin_symbol)

def log_response_structure(response):
    """응답 객체의 구조와 내용을 자세히 로깅"""
    try:
        logger.info(f"=== 응답 객체 구조 분석 시작 ===")
        logger.info(f"응답 객체 타입: {type(response)}")
        logger.info(f"응답 객체 속성: {dir(response)}")
        
        # 주요 속성 확인
        for attr in ['id', 'model', 'type', 'role', 'content', 'message', 'choices']:
            if hasattr(response, attr):
                value = getattr(response, attr)
                logger.info(f"속성 '{attr}' 타입: {type(value)}")
                
                if isinstance(value, (str, int, float, bool)):
                    logger.info(f"속성 '{attr}' 값: {value}")
                elif isinstance(value, list):
                    logger.info(f"속성 '{attr}' 길이: {len(value)}")
                    if len(value) > 0:
                        logger.info(f"첫 항목 타입: {type(value[0])}")
                        if isinstance(value[0], dict):
                            logger.info(f"첫 항목 키: {list(value[0].keys())}")
                elif isinstance(value, dict):
                    logger.info(f"속성 '{attr}' 키: {list(value.keys())}")
                else:
                    logger.info(f"속성 '{attr}' 복잡한 객체, 추가 정보: {str(value)[:100]}...")
        
        logger.info(f"=== 응답 객체 구조 분석 완료 ===")
    except Exception as e:
        logger.error(f"응답 구조 로깅 오류: {e}")
        import traceback
        logger.error(traceback.format_exc())

# """Claude의 텍스트 응답을 구조화된 형식으로 파싱"""
def parse_claude_response(response_text):
    try:
        # JSON 파싱
        data = json.loads(response_text)
        
        # 결과 객체 초기화
        result = {
            "sentiment": "neutral",
            "confidenceScore": 50,
            "predictedImpact": "중립",
            "estimatedPriceChangePercent": 0.0,
            "reasoningExplanation": "",
            "recommendedAction": "hold",
            "recommendedLeverageMultiple": 1,
            "riskLevel": "medium"
        }
        
        # 두 가지 구조 모두 처리
        # 구조 1: 시스템 예상 구조
        if "sentiment" in data:
            result["sentiment"] = data["sentiment"]
        if "confidenceScore" in data:
            result["confidenceScore"] = data["confidenceScore"]
        if "predictedImpact" in data:
            result["predictedImpact"] = data["predictedImpact"]
        if "estimatedPriceChangePercent" in data:
            result["estimatedPriceChangePercent"] = data["estimatedPriceChangePercent"]
        if "reasoningExplanation" in data:
            result["reasoningExplanation"] = data["reasoningExplanation"]
        if "recommendedAction" in data:
            result["recommendedAction"] = data["recommendedAction"]
        if "recommendedLeverageMultiple" in data:
            result["recommendedLeverageMultiple"] = data["recommendedLeverageMultiple"]
        if "riskLevel" in data:
            result["riskLevel"] = data["riskLevel"]
            
        # 구조 2: Claude 실제 응답 구조
        # 감정 분석
        if "1_sentiment" in data and isinstance(data["1_sentiment"], dict):
            sentiment_value = data["1_sentiment"].get("value", "")
            if sentiment_value == "긍정적":
                result["sentiment"] = "positive"
                result["predictedImpact"] = "긍정적"
                result["confidenceScore"] = 80
            elif sentiment_value == "부정적":
                result["sentiment"] = "negative"
                result["predictedImpact"] = "부정적"
                result["confidenceScore"] = 80
            elif sentiment_value == "중립적":
                result["sentiment"] = "neutral"
                result["predictedImpact"] = "중립"
                result["confidenceScore"] = 60
            
            # 이유 추가
            reason = data["1_sentiment"].get("reason", "")
            if reason:
                result["reasoningExplanation"] += reason + " "
        
        # 가격 영향 예측
        if "3_price_impact" in data and isinstance(data["3_price_impact"], dict):
            price_impact = data["3_price_impact"].get("value", "")
            if price_impact:
                # 숫자 추출 (예: "+3~5%" -> 4)
                import re
                numbers = re.findall(r'-?\d+\.?\d*', price_impact)
                if numbers:
                    if len(numbers) >= 2:  # 범위인 경우 (예: 3~5)
                        avg = (float(numbers[0]) + float(numbers[1])) / 2
                    else:  # 단일 값인 경우
                        avg = float(numbers[0])
                    # 부호 확인
                    result["estimatedPriceChangePercent"] = avg if "+" in price_impact else -avg
            
            # 이유 추가
            reason = data["3_price_impact"].get("reason", "")
            if reason:
                result["reasoningExplanation"] += reason + " "
        
        # 거래 추천
        if "4_trade_recommendation" in data and isinstance(data["4_trade_recommendation"], dict):
            action = data["4_trade_recommendation"].get("action", "")
            if action == "매수":
                result["recommendedAction"] = "buy"
            elif action == "매도":
                result["recommendedAction"] = "sell"
            elif action == "홀드":
                result["recommendedAction"] = "hold"
            
            # 레버리지
            leverage = data["4_trade_recommendation"].get("leverage", 1)
            if isinstance(leverage, (int, float)):
                result["recommendedLeverageMultiple"] = int(leverage)
            
            # 이유 추가
            reason = data["4_trade_recommendation"].get("reason", "")
            if reason:
                result["reasoningExplanation"] += reason + " "
        
        # 위험도 평가
        if "5_risk_assessment" in data and isinstance(data["5_risk_assessment"], dict):
            risk_level = data["5_risk_assessment"].get("value", "")
            if risk_level == "낮음":
                result["riskLevel"] = "low"
            elif risk_level == "중간":
                result["riskLevel"] = "medium"
            elif risk_level == "높음":
                result["riskLevel"] = "high"
            
            # 이유 추가
            reason = data["5_risk_assessment"].get("reason", "")
            if reason:
                result["reasoningExplanation"] += reason
        
        return result
    
    except Exception as e:
        logger.error(f"응답 파싱 오류: {e}")
        # 기본값 반환
        return {
            "sentiment": "neutral",
            "confidenceScore": 50,
            "predictedImpact": "중립",
            "estimatedPriceChangePercent": 0.0,
            "reasoningExplanation": "파싱 오류로 인한 기본 분석",
            "recommendedAction": "hold",
            "recommendedLeverageMultiple": 1,
            "riskLevel": "medium"
        }
       
# 6. 트윗 감정 분석 함수 
# analyze_tweet 함수를 Claude 기반
def analyze_tweet(tweet_data, coin_symbol, use_claude=False):
    """Claude를 사용하여 트윗 분석"""
    try:
        tweet_text = tweet_data.get('text', '')
        if not tweet_text:
            logger.error("트윗 텍스트가 비어 있습니다.")
            return None
            
        # 추가 컨텍스트 정보 준비
        author = tweet_data.get('author_id', '')
        
        # 인플루언서 정보 찾기
        influencer_info = None
        for inf in influencers:
            if inf['twitter_username'] == author or inf['name'] == author:
                influencer_info = inf
                break
        
        # 컨텍스트 정보 추가
        context = ""
        if influencer_info:
            context = f"이 트윗은 {influencer_info['name']}({author})가 작성했습니다. "
            context += f"이 인플루언서는 주로 {', '.join(influencer_info['coins'])} 코인에 영향을 줍니다."
        
        # 풍부한 컨텍스트와 함께 Claude 분석 호출
        content_with_context = f"{context}\n\n트윗 내용: {tweet_text}"
        
        # Claude 사용 여부에 따라 분석 방법 선택
        if use_claude and can_call_claude_api():
            content_with_context = f"{context}\n\n트윗 내용: {tweet_text}"
            return analyze_with_claude(content_with_context, coin_symbol, "트윗")
        else:
            return analyze_tweet_basic(tweet_data, coin_symbol)
        
    except Exception as e:
        logger.error(f"트윗 분석 오류: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return None

# analyze_news 함수를 Claude 기반
def analyze_news(news_signal, coin_symbol, use_claude=False):
    """Claude를 사용하여 뉴스 분석"""
    try:
        content = news_signal.get('content', '')
        if not content:
            logger.error("뉴스 내용이 비어 있습니다.")
            return None
            
        # 추가 컨텍스트 정보 준비
        source = news_signal.get('sourceType', '')
        url = news_signal.get('url', '')
        risk_level = news_signal.get('risk_level', 'MEDIUM')
        related_influencers = news_signal.get('related_influencers', [])
        
        # 컨텍스트 정보 추가
        context = f"이 뉴스는 {source} 매체에서 발행되었습니다. "
        context += f"내부 위험도 평가: {risk_level}. "
        
        if related_influencers:
            context += f"관련 인플루언서: {', '.join(related_influencers)}. "
        
        # 풍부한 컨텍스트와 함께 Claude 분석 호출
        content_with_context = f"{context}\n\n뉴스 제목: {content}\n뉴스 URL: {url}"

        return analyze_tweet_basic(news_signal, coin_symbol)
        
        # Claude 사용 여부에 따라 분석 방법 선택
        # if use_claude and can_call_claude_api():
        #     content_with_context = f"{context}\n\n뉴스 내용: {content}"
        #     return analyze_with_claude(content_with_context, coin_symbol, "뉴스")
        # else:
        #     return analyze_tweet_basic(news_signal, coin_symbol)
        
    except Exception as e:
        logger.error(f"뉴스 분석 오류: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return None

def analyze_tweet_basic(tweet_data, coin_symbol):
    """기본적인 키워드 기반 트윗 분석 (Claude API 사용 불가 시 대체용)"""
    try:
        # tweet_data가 None이거나 필수 필드가 없는 경우 처리
        if not tweet_data:
            logger.error(f"트윗 데이터가 비어 있습니다.")
            return None
            
        # 텍스트 필드가 없으면 분석 불가
        tweet_text = tweet_data.get('text', '')
        if not tweet_text:
            logger.error(f"트윗 텍스트가 비어 있습니다.")
            return None
        
        logger.info(f"기본 분석으로 트윗 처리 중: {tweet_text[:30]}...")
        
        # 코인별 키워드 패턴 로드
        pattern = coin_patterns.get(coin_symbol, {})
        positive_keywords = pattern.get('positiveKeywords', [])
        negative_keywords = pattern.get('negativeKeywords', [])
        
        # 긍정/부정 키워드 확인
        is_positive = any(keyword.lower() in tweet_text.lower() for keyword in positive_keywords)
        is_negative = any(keyword.lower() in tweet_text.lower() for keyword in negative_keywords)
        
        # 추가 긍정/부정 키워드 체크
        generic_positive = ['moon', 'up', 'rise', 'buy', 'bull', 'great', 'good', 'positive', 'win', 'victory', 'launch']
        generic_negative = ['down', 'fall', 'sell', 'bear', 'bad', 'negative', 'case', 'trial', 'problem', 'issue']
        
        is_positive = is_positive or any(keyword.lower() in tweet_text.lower() for keyword in generic_positive)
        is_negative = is_negative or any(keyword.lower() in tweet_text.lower() for keyword in generic_negative)
        
        # 기본값은 중립
        sentiment = "neutral"
        confidence = random.randint(50, 70)
        impact = "중립"
        price_change = random.uniform(-1, 1)
        action = "hold"
        leverage = random.randint(1, 3)
        risk = "medium"
        
        # 긍정적 내용이 있으면
        if is_positive:
            sentiment = "positive"
            confidence = random.randint(70, 95)
            impact = random.choice(["긍정적", "매우 긍정적"])
            price_change = random.uniform(2, 15)
            action = "buy"
            leverage = random.randint(3, 10)
            risk = random.choice(["medium", "high"])
        
        # 부정적 내용이 있으면
        elif is_negative:
            sentiment = "negative"
            confidence = random.randint(70, 90)
            impact = random.choice(["부정적", "매우 부정적"])
            price_change = random.uniform(-15, -2)
            action = "sell"
            leverage = random.randint(3, 8)
            risk = random.choice(["medium", "high"])
        
        # 설명 생성
        explanation = f"기본 분석: 이 트윗은 {coin_symbol}에 대해 {'긍정적' if is_positive else '부정적' if is_negative else '중립적'} 내용을 담고 있습니다. "
        explanation += f"키워드 기반 분석 결과, 과거 유사한 트윗은 {abs(price_change):.2f}% 정도의 {'상승' if price_change > 0 else '하락'} 영향을 주었습니다."
        
        return {
            "sentiment": sentiment,
            "confidenceScore": confidence,
            "predictedImpact": impact,
            "estimatedPriceChangePercent": price_change,
            "reasoningExplanation": explanation,
            "recommendedAction": action,
            "recommendedLeverageMultiple": leverage,
            "riskLevel": risk
        }
        
    except Exception as e:
        logger.error(f"기본 트윗 분석 오류: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return None

def analyze_news_basic(news_signal, coin_symbol):
    """기본적인 키워드 기반 뉴스 분석 (Claude API 사용 불가 시 대체용)"""
    try:
        # 필수 필드가 없으면 분석 불가
        content = news_signal.get('content', '')
        if not content:
            logger.error("뉴스 내용이 비어 있습니다.")
            return None
            
        logger.info(f"기본 분석으로 뉴스 처리 중: {content[:30]}...")
        
        # 코인별 키워드 패턴 로드
        pattern = coin_patterns.get(coin_symbol, {})
        positive_keywords = pattern.get('positiveKeywords', [])
        negative_keywords = pattern.get('negativeKeywords', [])
        
        # 긍정/부정 키워드 확인
        is_positive = any(keyword.lower() in content.lower() for keyword in positive_keywords)
        is_negative = any(keyword.lower() in content.lower() for keyword in negative_keywords)
        
        # 추가 긍정/부정 키워드 체크
        generic_positive = ['호재', '상승', '급등', '돌파', '개선', '긍정', '발전', '성장', 'bull', 'bullish', 'buy']
        generic_negative = ['악재', '하락', '급락', '붕괴', '하락세', '부정', '문제', '우려', 'bear', 'bearish', 'sell']
        
        is_positive = is_positive or any(keyword in content.lower() for keyword in generic_positive)
        is_negative = is_negative or any(keyword in content.lower() for keyword in generic_negative)
        
        # 위험 수준 활용
        risk_level = news_signal.get('risk_level', 'LOW')
        
        # 인플루언서 관련 뉴스인지 확인 (더 높은 가중치)
        related_influencers = news_signal.get('related_influencers', [])
        influencer_boost = len(related_influencers) > 0
        
        # 기본값은 중립
        sentiment = "neutral"
        confidence = random.randint(50, 70)
        impact = "중립"
        price_change = random.uniform(-1, 1)
        action = "hold"
        leverage = random.randint(1, 3)
        risk = "medium"
        
        # 위험 수준이 HIGH이고 부정적 내용이면 더 강한 시그널
        if risk_level == "HIGH" and is_negative:
            sentiment = "negative"
            confidence = random.randint(80, 95)
            impact = "매우 부정적"
            price_change = random.uniform(-20, -5)
            action = "sell"
            leverage = random.randint(5, 10)
            risk = "high"
            
        # 위험 수준이 HIGH이고 긍정적 내용이면 더 강한 시그널
        elif risk_level == "HIGH" and is_positive:
            sentiment = "positive"
            confidence = random.randint(80, 95)
            impact = "매우 긍정적"
            price_change = random.uniform(5, 20)
            action = "buy"
            leverage = random.randint(5, 10)
            risk = "high"
            
        # 긍정적 내용이 있으면
        elif is_positive:
            sentiment = "positive"
            confidence = random.randint(70, 90)
            impact = "긍정적"
            price_change = random.uniform(2, 10)
            action = "buy"
            leverage = random.randint(3, 8)
            risk = "medium"
        
        # 부정적 내용이 있으면
        elif is_negative:
            sentiment = "negative"
            confidence = random.randint(70, 90)
            impact = "부정적"
            price_change = random.uniform(-10, -2)
            action = "sell"
            leverage = random.randint(3, 8)
            risk = "medium"
        
        # 인플루언서 관련 뉴스면 시그널 강화
        if influencer_boost:
            confidence += 10
            price_change *= 1.5
            leverage += 2
        
        # 설명 생성
        explanation = f"기본 분석: 이 뉴스는 {coin_symbol}에 대해 {'긍정적' if is_positive else '부정적' if is_negative else '중립적'} 내용을 담고 있습니다. "
        
        if influencer_boost:
            inf_names = ', '.join(related_influencers[:2])
            explanation += f"주요 인플루언서({inf_names})와 관련있어 영향이 클 것으로 예상됩니다. "
            
        explanation += f"위험도는 {risk_level}이며, "
        explanation += f"과거 유사한 뉴스는 {abs(price_change):.2f}% 정도의 {'상승' if price_change > 0 else '하락'} 영향을 주었습니다."
        
        return {
            "sentiment": sentiment,
            "confidenceScore": confidence,
            "predictedImpact": impact,
            "estimatedPriceChangePercent": price_change,
            "reasoningExplanation": explanation,
            "recommendedAction": action,
            "recommendedLeverageMultiple": leverage,
            "riskLevel": risk
        }
        
    except Exception as e:
        logger.error(f"기본 뉴스 분석 오류: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return None

# 7. 코인 관련 키워드 확인 함수
def check_related_keywords(text, coin_symbol):
    """트윗이 코인과 관련있는지 확인"""
    pattern = coin_patterns.get(coin_symbol)
    if not pattern:
        return False
    
    lower_text = text.lower()
    
    # 코인 이름 포함 여부
    if coin_symbol.lower() in lower_text:
        return True
    
    # 긍정/부정 키워드 체크
    for keyword in pattern['positiveKeywords']:
        if keyword.lower() in lower_text:
            return True
    
    for keyword in pattern['negativeKeywords']:
        if keyword.lower() in lower_text:
            return True
    
    return False

# 8. 최적 진입/청산 시간 계산 함수
def calculate_optimal_entry_window(coin_symbol):
    """최적 진입 시간 계산"""
    pattern = coin_patterns.get(coin_symbol)
    if not pattern:
        return {"start": "즉시", "end": "5분 이내"}
    
    return {
        "start": "즉시",
        "end": f"{round(pattern['avgReactionTimeMinutes'] * 0.7)}분 이내"
    }

def calculate_optimal_exit_window(coin_symbol, estimated_change):
    """최적 청산 시간 계산"""
    pattern = coin_patterns.get(coin_symbol)
    if not pattern:
        return {"start": "15분 후", "end": "1시간 이내"}
    
    multiplier = abs(estimated_change) / pattern['avgPriceImpactPercent']
    exit_start = round(pattern['avgReactionTimeMinutes'] * (1.2 if multiplier > 1 else 0.8))
    exit_end = round(pattern['avgReactionTimeMinutes'] * (3 if multiplier > 1 else 2))
    
    return {
        "start": f"{exit_start}분 후",
        "end": f"{exit_end}분 이내"
    }

# 9. 거래 시그널 생성 함수
def generate_trading_signal(analysis, coin_symbol, source_data):
    """Claude 분석 결과를 기반으로 거래 시그널 생성"""
    try:
        # 분석 결과가 없으면 처리 불가
        if not analysis:
            logger.error("분석 결과가 없어 시그널을 생성할 수 없습니다.")
            return None
            
        # 소스 데이터에서 필요한 정보 추출
        source_type = source_data.get('source', 'unknown')
        source_content = source_data.get('content', '')
        source_url = source_data.get('url', '')
        
        # 소스 타입별 식별자
        if source_type == 'twitter':
            source_id = source_data.get('tweet_id', '')
            source_author = source_data.get('author', '')
        else:  # 뉴스
            source_id = source_url
            source_author = source_data.get('sourceType', '')
        
        # 현재 코인 가격 조회
        current_price = get_coin_price(coin_symbol)
        
        # Claude 분석 결과에서 필요한 정보 추출
        sentiment = analysis.get("sentiment", "neutral")
        confidence = analysis.get("confidence", 50)
        price_change = analysis.get("price_change_percent", 0)
        reasoning = analysis.get("reasoning", "")
        recommended_action = analysis.get("recommended_action", "hold")
        leverage = analysis.get("leverage", 1)
        risk_level = analysis.get("risk_level", "medium")
        
        # 최적 진입/청산 시간 계산 (코인 패턴 기반)
        pattern = coin_patterns.get(coin_symbol, {})
        avg_reaction_time = pattern.get('avgReactionTimeMinutes', 10)
        
        # 진입 시간 (즉시 ~ 패턴의 반응 시간의 70%)
        entry_end_minutes = max(5, round(avg_reaction_time * 0.7))
        
        # 청산 시간 (반응 시간 ~ 반응 시간의 3배)
        exit_start_minutes = avg_reaction_time
        exit_end_minutes = avg_reaction_time * 3
        
        # 거래 시그널 생성
        signal = {
            "timestamp": datetime.now().isoformat(),
            "coinSymbol": coin_symbol,
            "sourceType": source_type,
            "sourceId": source_id,
            "sourceUrl": source_url,
            "sourceContent": source_content[:200] + ("..." if len(source_content) > 200 else ""),
            "sourceAuthor": source_author,
            "sentiment": sentiment,
            "confidenceScore": confidence,
            "predictedImpact": "매우 긍정적" if price_change > 10 else "긍정적" if price_change > 0 else "매우 부정적" if price_change < -10 else "부정적" if price_change < 0 else "중립",
            "estimatedPriceChangePercent": price_change,
            "recommendedAction": recommended_action,
            "recommendedLeverageMultiple": leverage,
            "riskLevel": risk_level,
            "reasoning": reasoning,
            "optimalEntryWindow": {
                "start": "즉시",
                "end": f"{entry_end_minutes}분 이내"
            },
            "optimalExitWindow": {
                "start": f"{exit_start_minutes}분 후",
                "end": f"{exit_end_minutes}분 이내"
            },
            "currentPrice": current_price,
            "analyzed_by": "Claude AI"
        }
        
        return signal
        
    except Exception as e:
        logger.error(f"거래 시그널 생성 오류: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return None

# 가격 캐싱을 위한 전역 변수
price_cache = {}
last_price_update = {}

def cache_price(symbol, price, source):
    """코인 가격을 캐시에 저장"""
    global price_cache, last_price_update
    
    current_time = datetime.now()
    
    price_cache[symbol] = {
        'price': price,
        'source': source,
        'timestamp': current_time.isoformat()
    }
    
    last_price_update[symbol] = current_time
    
    # 캐시 파일에도 저장 (선택 사항)
    try:
        cache_file = 'price_cache.json'
        
        # 기존 캐시 파일 로드
        if os.path.exists(cache_file):
            with open(cache_file, 'r', encoding='utf-8') as f:
                all_cache = json.load(f)
        else:
            all_cache = {}
        
        # 새 가격 정보 추가
        all_cache[symbol] = price_cache[symbol]
        
        # 파일에 저장
        with open(cache_file, 'w', encoding='utf-8') as f:
            json.dump(all_cache, f, ensure_ascii=False, indent=2)
    except Exception as e:
        logger.warning(f"가격 캐시 파일 저장 오류: {e}")

def get_cached_price(symbol, max_age_seconds=300):
    """캐시된 가격 정보 가져오기"""
    global price_cache, last_price_update
    
    if symbol not in price_cache or symbol not in last_price_update:
        return None
    
    # 캐시 유효 시간 확인
    current_time = datetime.now()
    last_update = last_price_update[symbol]
    age_seconds = (current_time - last_update).total_seconds()
    
    if age_seconds > max_age_seconds:
        logger.warning(f"{symbol} 가격 캐시가 만료됨 ({age_seconds:.1f}초 경과)")
        return None
    
    cached_data = price_cache[symbol]
    logger.info(f"{symbol} 캐시된 가격 사용: ${cached_data['price']:.6f} (출처: {cached_data['source']})")
    
    return cached_data['price']

def generate_trading_signal_without_price(analysis, coin_symbol, source_data):
    """가격 정보 없이 거래 시그널 생성 (fallback 용)"""
    try:
        # 분석 결과가 없으면 처리 불가
        if not analysis:
            logger.error("분석 결과가 없어 시그널을 생성할 수 없습니다.")
            return None
            
        # 최적 진입/청산 시간 계산
        optimal_entry_window = calculate_optimal_entry_window(coin_symbol)
        optimal_exit_window = calculate_optimal_exit_window(coin_symbol, analysis.get("estimatedPriceChangePercent", 0))
        
        # 소스 데이터에서 필요한 정보 안전하게 추출
        source_type = source_data.get('source', 'unknown')
        source_content = source_data.get('content', '')
        source_url = source_data.get('url', '')
        
        # 소스 타입별 식별자
        if source_type == 'twitter':
            source_id = source_data.get('tweet_id', '')
            source_author = source_data.get('author', '')
        else:  # 뉴스
            source_id = source_url
            source_author = source_data.get('sourceType', '')
        
        signal = {
            "timestamp": datetime.now().isoformat(),
            "coinSymbol": coin_symbol,
            "sourceType": source_type,
            "sourceId": source_id,
            "sourceUrl": source_url,
            "sourceContent": source_content[:200] + ("..." if len(source_content) > 200 else ""),
            "sourceAuthor": source_author,
            "sentiment": analysis.get("sentiment", "neutral"),
            "confidenceScore": analysis.get("confidenceScore", 50),
            "predictedImpact": analysis.get("predictedImpact", "중립"),
            "estimatedPriceChangePercent": analysis.get("estimatedPriceChangePercent", 0),
            "recommendedAction": analysis.get("recommendedAction", "hold"),
            "recommendedLeverageMultiple": analysis.get("recommendedLeverageMultiple", 1),
            "riskLevel": analysis.get("riskLevel", "medium"),
            "reasoning": analysis.get("reasoningExplanation", ""),
            "optimalEntryWindow": optimal_entry_window,
            "optimalExitWindow": optimal_exit_window,
            "currentPrice": None,  # 가격 정보 없음
            "priceMissing": True   # 가격 정보 누락 표시
        }
        
        return signal
        
    except Exception as e:
        logger.error(f"가격 없는 거래 시그널 생성 오류: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return None

# 10. 시그널 저장 함수
def save_signal(signal):
    """거래 시그널 저장"""
    signal_file = 'trading_signals.json'
    try:
        # 파일이 있으면 읽기
        if os.path.exists(signal_file):
            with open(signal_file, 'r', encoding='utf-8') as f:
                signals = json.load(f)
        else:
            signals = []
        
        # 새 시그널 추가
        signals.append(signal)
        
        # 파일에 저장
        with open(signal_file, 'w', encoding='utf-8') as f:
            json.dump(signals, f, ensure_ascii=False, indent=2)
            
    except Exception as e:
        logger.error(f"시그널 저장 오류: {e}")
        # 새 파일 생성
        with open(signal_file, 'w', encoding='utf-8') as f:
            json.dump([signal], f, ensure_ascii=False, indent=2)

# 11. 알림 전송 함수
def send_alert(signal):
    """트레이딩 시그널 알림"""
    logger.info(f"🚨 알림: {signal['coinSymbol']} {signal['recommendedAction'].upper()} 시그널 발생")
    logger.info(f"💰 추천 레버리지: {signal['recommendedLeverageMultiple']}배")
    logger.info(f"⏱️ 최적 진입 시간: {signal['optimalEntryWindow']['start']} ~ {signal['optimalEntryWindow']['end']}")
    logger.info(f"🔄 최적 청산 시간: {signal['optimalExitWindow']['start']} ~ {signal['optimalExitWindow']['end']}")
    logger.info(f"💵 현재 가격: ${signal['currentPrice']:.6f}")
    logger.info(f"📊 예상 가격 변동: {signal['estimatedPriceChangePercent']:.2f}%")
    logger.info(f"🔎 근거: {signal['reasoning']}")

def load_news_data():
    """realtimeNS.py가 생성한 뉴스 데이터 파일 로드"""
    try:
        # 뉴스 통합 상태 파일 확인
        integration_state_file = "data/news_integration_latest.json"
        
        # 통합 파일이 없으면 뉴스 디렉토리에서 직접 찾기
        if not os.path.exists(integration_state_file):
            logger.warning("뉴스 통합 상태 파일이 없습니다. 직접 뉴스 디렉토리에서 찾습니다.")
            return load_news_from_directory()
            
        with open(integration_state_file, 'r', encoding='utf-8') as f:
            integration_state = json.load(f)
            
        latest_file = integration_state.get('latest_file')
        if not latest_file or not os.path.exists(latest_file):
            logger.warning(f"최신 뉴스 파일을 찾을 수 없습니다: {latest_file}")
            return load_news_from_directory()
            
        # 통합 파일에서 뉴스 로드
        with open(latest_file, 'r', encoding='utf-8') as f:
            news_data = json.load(f)
        
        # 모든 시그널을 저장할 리스트
        all_signals = []
        
        # 1. 고위험 뉴스 처리
        for article in news_data.get('high_risk', []):
            for coin in article.get('related_coins', []):
                signal = {
                    "source": "news",
                    "coinSymbol": coin,
                    "content": article.get('title', ''),
                    "url": article.get('url', ''),
                    "sourceType": article.get('source', ''),
                    "timestamp": article.get('timestamp', datetime.now().isoformat()),
                    "risk_level": "HIGH",
                    "related_influencers": article.get('related_influencers', [])
                }
                all_signals.append(signal)
        
        # 2. 코인별 뉴스 처리
        for coin, articles in news_data.get('by_coin', {}).items():
            for article in articles:
                # 이미 고위험 뉴스로 처리한 경우 스킵
                if article.get('risk_level') == 'HIGH':
                    continue
                    
                # 시그널 생성
                signal = {
                    "source": "news",
                    "coinSymbol": coin,
                    "content": article.get('title', ''),
                    "url": article.get('url', ''),
                    "sourceType": article.get('source', ''),
                    "timestamp": article.get('timestamp', datetime.now().isoformat()),
                    "risk_level": article.get('risk_level', 'MEDIUM'),
                    "related_influencers": article.get('related_influencers', [])
                }
                all_signals.append(signal)
        
        logger.info(f"통합 파일에서 {len(all_signals)}개의 뉴스 시그널을 로드했습니다.")
        return all_signals
        
    except Exception as e:
        logger.error(f"뉴스 데이터 로드 오류: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return load_news_from_directory()  # 오류 시 디렉토리에서 직접 로드 시도

def load_news_from_directory():
    """뉴스 디렉토리에서 직접 뉴스 파일 찾아서 로드"""
    try:
        all_signals = []
        news_dir = "news"
        
        # 디렉토리 존재 확인
        if not os.path.exists(news_dir) or not os.path.isdir(news_dir):
            logger.warning(f"뉴스 디렉토리가 없습니다: {news_dir}")
            return []
        
        # 1. 고위험 뉴스 파일 찾기
        high_risk_files = []
        for file in os.listdir(news_dir):
            if file.startswith("high_risk_news_") and file.endswith(".json"):
                high_risk_files.append(os.path.join(news_dir, file))
        
        # 최신 파일 선택
        if high_risk_files:
            latest_high_risk = max(high_risk_files, key=os.path.getmtime)
            
            # 고위험 뉴스 로드
            with open(latest_high_risk, 'r', encoding='utf-8') as f:
                high_risk_news = json.load(f)
                
            for article in high_risk_news:
                for coin in article.get('related_coins', []):
                    signal = {
                        "source": "news",
                        "coinSymbol": coin,
                        "content": article.get('title', ''),
                        "url": article.get('url', ''),
                        "sourceType": article.get('source', ''),
                        "timestamp": article.get('timestamp', datetime.now().isoformat()),
                        "risk_level": "HIGH",
                        "related_influencers": article.get('related_influencers', [])
                    }
                    all_signals.append(signal)
        
        # 2. 코인별 뉴스 디렉토리 확인
        coins_dir = os.path.join(news_dir, "coins")
        if os.path.exists(coins_dir) and os.path.isdir(coins_dir):
            # 코인별 최신 파일 찾기
            coin_files = {}
            for file in os.listdir(coins_dir):
                if not file.endswith('.json'):
                    continue
                    
                # 파일명에서 코인 심볼 추출
                coin_match = re.search(r'([A-Z]+)_news_\d+', file)
                if not coin_match:
                    continue
                    
                coin = coin_match.group(1)
                file_path = os.path.join(coins_dir, file)
                mod_time = os.path.getmtime(file_path)
                
                # 해당 코인의 가장 최신 파일 저장
                if coin not in coin_files or mod_time > coin_files[coin]['time']:
                    coin_files[coin] = {'path': file_path, 'time': mod_time}
            
            # 각 코인 최신 파일 로드
            for coin, file_info in coin_files.items():
                try:
                    with open(file_info['path'], 'r', encoding='utf-8') as f:
                        coin_news = json.load(f)
                        
                    for article in coin_news:
                        # 고위험 뉴스와 중복 방지
                        if article.get('risk_level') == 'HIGH':
                            continue
                            
                        # URL 중복 확인
                        article_url = article.get('url', '')
                        duplicate = False
                        
                        for existing in all_signals:
                            if existing.get('url') == article_url and existing.get('coinSymbol') == coin:
                                duplicate = True
                                break
                                
                        if duplicate:
                            continue
                            
                        # 시그널 생성
                        signal = {
                            "source": "news",
                            "coinSymbol": coin,
                            "content": article.get('title', ''),
                            "url": article_url,
                            "sourceType": article.get('source', ''),
                            "timestamp": article.get('timestamp', datetime.now().isoformat()),
                            "risk_level": article.get('risk_level', 'MEDIUM'),
                            "related_influencers": article.get('related_influencers', [])
                        }
                        all_signals.append(signal)
                        
                except Exception as e:
                    logger.error(f"{file_info['path']} 처리 중 오류: {e}")
        
        logger.info(f"디렉토리에서 총 {len(all_signals)}개의 뉴스 시그널을 로드했습니다.")
        return all_signals
        
    except Exception as e:
        logger.error(f"뉴스 디렉토리 처리 오류: {e}")
        return []
    
def load_twitter_data():
    """realtimeTW.py가 생성한 트위터 데이터 파일 로드"""
    try:
        # 트위터 all_tweets.json 파일 확인 (realtimeTW.py 생성 파일)
        twitter_file = 'tweets/all_tweets.json'
        if not os.path.exists(twitter_file):
            logger.warning("트위터 데이터 파일이 없습니다: " + twitter_file)
            return []
            
        with open(twitter_file, 'r', encoding='utf-8') as f:
            twitter_data = json.load(f)
        
        # 코인별 트윗 파일 디렉토리 확인
        coin_tweets_dir = 'tweets/coins'
        
        # 모든 시그널을 저장할 리스트
        all_signals = []
        
        # 1. 인플루언서별 트윗 처리
        for username, tweets in twitter_data.items():
            # 해당 인플루언서 정보 찾기
            influencer_info = None
            for inf in influencers:
                if inf['twitter_username'] == username:
                    influencer_info = inf
                    break
            
            if not influencer_info:
                continue
                
            for tweet in tweets:
                # 기본 정보 추출
                tweet_id = tweet.get('id')
                if not tweet_id:
                    continue
                    
                # 이미 처리한 트윗인지 확인
                tweet_created = tweet.get('created_at')
                tweet_text = tweet.get('text', '')
                
                # 관련 코인 확인
                for coin in influencer_info['coins']:
                    # 코인 관련 키워드 확인 로직은 realtimeTW.py와 일치하게 유지
                    pattern = coin_patterns.get(coin, {})
                    positive_keywords = pattern.get('positiveKeywords', [])
                    negative_keywords = pattern.get('negativeKeywords', [])
                    all_keywords = positive_keywords + negative_keywords + [coin.lower()]
                    
                    is_related = False
                    for keyword in all_keywords:
                        if keyword.lower() in tweet_text.lower():
                            is_related = True
                            break
                    
                    if is_related:
                        # 시그널 생성
                        signal = {
                            "source": "twitter",
                            "coinSymbol": coin,
                            "tweet_id": tweet_id,
                            "content": tweet_text,
                            "author": influencer_info['name'],
                            "url": tweet.get('url', f"https://twitter.com/{username}/status/{tweet_id}"),
                            "timestamp": tweet_created if isinstance(tweet_created, str) else str(tweet_created),
                            "metrics": tweet.get('public_metrics', {})
                        }
                        all_signals.append(signal)
        
        # 2. 코인별 트윗 파일 처리 (더 최신 데이터가 있을 수 있음)
        if os.path.exists(coin_tweets_dir):
            # 코인별 최신 파일 찾기
            coin_files = {}
            for filename in os.listdir(coin_tweets_dir):
                if not filename.endswith('.json'):
                    continue
                    
                file_path = os.path.join(coin_tweets_dir, filename)
                if not os.path.isfile(file_path):
                    continue
                    
                # 파일명에서 코인 심볼 추출
                coin_match = re.search(r'([A-Z]+)_\d+', filename)
                if not coin_match:
                    continue
                    
                coin = coin_match.group(1)
                mod_time = os.path.getmtime(file_path)
                
                # 해당 코인의 가장 최신 파일 저장
                if coin not in coin_files or mod_time > coin_files[coin]['time']:
                    coin_files[coin] = {'path': file_path, 'time': mod_time}
            
            # 각 코인의 최신 파일에서 트윗 로드
            for coin, file_info in coin_files.items():
                try:
                    with open(file_info['path'], 'r', encoding='utf-8') as f:
                        coin_tweets = json.load(f)
                        
                    for tweet in coin_tweets:
                        tweet_id = tweet.get('id')
                        if not tweet_id:
                            continue
                            
                        # 중복 시그널 방지 (이미 처리한 경우 스킵)
                        duplicate = False
                        for existing in all_signals:
                            if existing.get('tweet_id') == tweet_id and existing.get('coinSymbol') == coin:
                                duplicate = True
                                break
                        
                        if duplicate:
                            continue
                            
                        # 시그널 생성
                        signal = {
                            "source": "twitter",
                            "coinSymbol": coin,
                            "tweet_id": tweet_id,
                            "content": tweet.get('text', ''),
                            "author": tweet.get('author_id', ''),
                            "url": tweet.get('url', ''),
                            "timestamp": tweet.get('created_at', datetime.now().isoformat()),
                            "metrics": tweet.get('public_metrics', {})
                        }
                        all_signals.append(signal)
                        
                except Exception as e:
                    logger.error(f"{file_info['path']} 처리 중 오류: {e}")
        
        logger.info(f"총 {len(all_signals)}개의 트위터 시그널을 로드했습니다.")
        return all_signals
        
    except Exception as e:
        logger.error(f"트위터 데이터 로드 오류: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return []

def load_news_from_directory():
    """뉴스 디렉토리에서 직접 뉴스 파일 찾아서 로드"""
    try:
        all_signals = []
        news_dir = "news"
        
        # 디렉토리 존재 확인
        if not os.path.exists(news_dir) or not os.path.isdir(news_dir):
            logger.warning(f"뉴스 디렉토리가 없습니다: {news_dir}")
            return []
        
        # 1. 고위험 뉴스 파일 찾기
        high_risk_files = []
        for file in os.listdir(news_dir):
            if file.startswith("high_risk_news_") and file.endswith(".json"):
                high_risk_files.append(os.path.join(news_dir, file))
        
        # 최신 파일 선택
        if high_risk_files:
            latest_high_risk = max(high_risk_files, key=os.path.getmtime)
            
            # 고위험 뉴스 로드
            with open(latest_high_risk, 'r', encoding='utf-8') as f:
                high_risk_news = json.load(f)
                
            for article in high_risk_news:
                for coin in article.get('related_coins', []):
                    signal = {
                        "source": "news",
                        "coinSymbol": coin,
                        "content": article.get('title', ''),
                        "url": article.get('url', ''),
                        "sourceType": article.get('source', ''),
                        "timestamp": article.get('timestamp', datetime.now().isoformat()),
                        "risk_level": "HIGH",
                        "related_influencers": article.get('related_influencers', [])
                    }
                    all_signals.append(signal)
        
        # 2. 코인별 뉴스 디렉토리 확인
        coins_dir = os.path.join(news_dir, "coins")
        if os.path.exists(coins_dir) and os.path.isdir(coins_dir):
            # 코인별 최신 파일 찾기
            coin_files = {}
            for file in os.listdir(coins_dir):
                if not file.endswith('.json'):
                    continue
                    
                # 파일명에서 코인 심볼 추출
                coin_match = re.search(r'([A-Z]+)_news_\d+', file)
                if not coin_match:
                    continue
                    
                coin = coin_match.group(1)
                file_path = os.path.join(coins_dir, file)
                mod_time = os.path.getmtime(file_path)
                
                # 해당 코인의 가장 최신 파일 저장
                if coin not in coin_files or mod_time > coin_files[coin]['time']:
                    coin_files[coin] = {'path': file_path, 'time': mod_time}
            
            # 각 코인 최신 파일 로드
            for coin, file_info in coin_files.items():
                try:
                    with open(file_info['path'], 'r', encoding='utf-8') as f:
                        coin_news = json.load(f)
                        
                    for article in coin_news:
                        # 고위험 뉴스와 중복 방지
                        if article.get('risk_level') == 'HIGH':
                            continue
                            
                        # URL 중복 확인
                        article_url = article.get('url', '')
                        duplicate = False
                        
                        for existing in all_signals:
                            if existing.get('url') == article_url and existing.get('coinSymbol') == coin:
                                duplicate = True
                                break
                                
                        if duplicate:
                            continue
                            
                        # 시그널 생성
                        signal = {
                            "source": "news",
                            "coinSymbol": coin,
                            "content": article.get('title', ''),
                            "url": article_url,
                            "sourceType": article.get('source', ''),
                            "timestamp": article.get('timestamp', datetime.now().isoformat()),
                            "risk_level": article.get('risk_level', 'MEDIUM'),
                            "related_influencers": article.get('related_influencers', [])
                        }
                        all_signals.append(signal)
                        
                except Exception as e:
                    logger.error(f"{file_info['path']} 처리 중 오류: {e}")
        
        logger.info(f"디렉토리에서 총 {len(all_signals)}개의 뉴스 시그널을 로드했습니다.")
        return all_signals
        
    except Exception as e:
        logger.error(f"뉴스 디렉토리 처리 오류: {e}")
        return []

def get_all_signals():
    """모든 시그널 통합"""
    # 뉴스 데이터 로드
    news_signals = load_news_data()
    logger.info(f"{len(news_signals)}개의 뉴스 시그널 로드됨")
    
    # 트위터 데이터 로드
    twitter_signals = load_twitter_data()
    logger.info(f"{len(twitter_signals)}개의 트위터 시그널 로드됨")
    
    # 모든 시그널 통합
    all_signals = news_signals + twitter_signals
    
    # 시간순 정렬
    all_signals.sort(key=lambda x: x.get('timestamp', ''), reverse=True)
    
    return all_signals
    
# def analyze_news(news_signal, coin_symbol):
#     """뉴스 시그널 분석 - 더 안전한 버전"""
#     try:
#         # 필수 필드가 없으면 분석 불가
#         content = news_signal.get('content', '')
#         if not content:
#             logger.error("뉴스 내용이 비어 있습니다.")
#             return None
            
#         url = news_signal.get('url', '')
#         logger.info(f"뉴스 분석 중: {url[:30]}... - {content[:30]}...")
        
#         # 코인별 키워드 패턴 로드
#         pattern = coin_patterns.get(coin_symbol, {})
#         positive_keywords = pattern.get('positiveKeywords', [])
#         negative_keywords = pattern.get('negativeKeywords', [])
        
#         # 긍정/부정 키워드 확인
#         is_positive = any(keyword.lower() in content.lower() for keyword in positive_keywords)
#         is_negative = any(keyword.lower() in content.lower() for keyword in negative_keywords)
        
#         # 추가 긍정/부정 키워드 체크
#         generic_positive = ['호재', '상승', '급등', '돌파', '개선', '긍정', '발전', '성장', 'bull', 'bullish', 'buy']
#         generic_negative = ['악재', '하락', '급락', '붕괴', '하락세', '부정', '문제', '우려', 'bear', 'bearish', 'sell']
        
#         is_positive = is_positive or any(keyword in content.lower() for keyword in generic_positive)
#         is_negative = is_negative or any(keyword in content.lower() for keyword in generic_negative)
        
#         # 위험 수준 활용
#         risk_level = news_signal.get('risk_level', 'LOW')
        
#         # 인플루언서 관련 뉴스인지 확인 (더 높은 가중치)
#         related_influencers = news_signal.get('related_influencers', [])
#         influencer_boost = len(related_influencers) > 0
        
#         # 뉴스 소스 가중치
#         source_weight = 1.0
#         source_type = news_signal.get('sourceType', '').lower()
        
#         # 신뢰도 높은 소스 가중치 부여
#         if any(s in source_type for s in ['coindesk', 'cointelegraph', 'bloomberg', 'reuters']):
#             source_weight = 1.3  # 주요 암호화폐 미디어
#         elif any(s in source_type for s in ['cnbc', 'wsj', 'ft', 'forbes']):
#             source_weight = 1.2  # 주요 금융 미디어
            
#         # 기본값은 중립
#         sentiment = "neutral"
#         confidence = random.randint(50, 70)
#         impact = "중립"
#         price_change = random.uniform(-1, 1)
#         action = "hold"
#         leverage = random.randint(1, 3)
#         risk = "medium"
        
#         # 위험 수준이 HIGH이고 부정적 내용이면 더 강한 시그널
#         if risk_level == "HIGH" and is_negative:
#             sentiment = "negative"
#             confidence = random.randint(80, 95)
#             impact = "매우 부정적"
#             price_change = random.uniform(-20, -5) * source_weight
#             action = "sell"
#             leverage = random.randint(5, 10)
#             risk = "high"
            
#         # 위험 수준이 HIGH이고 긍정적 내용이면 더 강한 시그널
#         elif risk_level == "HIGH" and is_positive:
#             sentiment = "positive"
#             confidence = random.randint(80, 95)
#             impact = "매우 긍정적"
#             price_change = random.uniform(5, 20) * source_weight
#             action = "buy"
#             leverage = random.randint(5, 10)
#             risk = "high"
            
#         # 긍정적 내용이 있으면
#         elif is_positive:
#             sentiment = "positive"
#             confidence = random.randint(70, 90)
#             impact = "긍정적"
#             price_change = random.uniform(2, 10) * source_weight
#             action = "buy"
#             leverage = random.randint(3, 8)
#             risk = "medium"
        
#         # 부정적 내용이 있으면
#         elif is_negative:
#             sentiment = "negative"
#             confidence = random.randint(70, 90)
#             impact = "부정적"
#             price_change = random.uniform(-10, -2) * source_weight
#             action = "sell"
#             leverage = random.randint(3, 8)
#             risk = "medium"
        
#         # 인플루언서 관련 뉴스면 시그널 강화
#         if influencer_boost:
#             confidence += 10
#             price_change *= 1.5
#             leverage += 2
        
#         # 설명 생성
#         explanation = f"분석: 이 뉴스는 {coin_symbol}에 대해 {'긍정적' if is_positive else '부정적' if is_negative else '중립적'} 내용을 담고 있습니다. "
        
#         if influencer_boost:
#             inf_names = ', '.join(related_influencers[:2])
#             explanation += f"주요 인플루언서({inf_names})와 관련있어 영향이 클 것으로 예상됩니다. "
            
#         explanation += f"위험도는 {risk_level}이며, "
        
#         if source_weight > 1.0:
#             explanation += f"신뢰도 높은 뉴스 소스({source_type})의 가중치가 {source_weight:.1f}배 적용되었습니다. "
            
#         explanation += f"과거 유사한 뉴스는 {abs(price_change):.2f}% 정도의 {'상승' if price_change > 0 else '하락'} 영향을 주었습니다."
        
#         return {
#             "sentiment": sentiment,
#             "confidenceScore": confidence,
#             "predictedImpact": impact,
#             "estimatedPriceChangePercent": price_change,
#             "reasoningExplanation": explanation,
#             "recommendedAction": action,
#             "recommendedLeverageMultiple": leverage,
#             "riskLevel": risk
#         }
        
#     except Exception as e:
#         logger.error(f"뉴스 분석 오류: {e}")
#         import traceback
#         logger.error(traceback.format_exc())
#         return None
    
# def analyze_tweet(tweet_data, coin_symbol):
#     """트윗 감정 분석 함수 - 더 안전한 버전"""
#     try:
#         # tweet_data가 None이거나 필수 필드가 없는 경우 처리
#         if not tweet_data:
#             logger.error(f"트윗 데이터가 비어 있습니다.")
#             return None
            
#         # 텍스트 필드가 없으면 분석 불가
#         tweet_text = tweet_data.get('text', '')
#         if not tweet_text:
#             logger.error(f"트윗 텍스트가 비어 있습니다.")
#             return None
        
#         # ID 필드는 옵션으로 처리
#         tweet_id = tweet_data.get('id', 'unknown_id')
        
#         logger.info(f"트윗 분석 중: {tweet_id[:8]}... - {tweet_text[:30]}...")
        
#         # 코인별 키워드 패턴 로드
#         pattern = coin_patterns.get(coin_symbol, {})
#         positive_keywords = pattern.get('positiveKeywords', [])
#         negative_keywords = pattern.get('negativeKeywords', [])
        
#         # 긍정/부정 키워드 확인
#         is_positive = any(keyword.lower() in tweet_text.lower() for keyword in positive_keywords)
#         is_negative = any(keyword.lower() in tweet_text.lower() for keyword in negative_keywords)
        
#         # 추가 긍정/부정 키워드 체크
#         generic_positive = ['moon', 'up', 'rise', 'buy', 'bull', 'great', 'good', 'positive', 'win', 'victory', 'launch']
#         generic_negative = ['down', 'fall', 'sell', 'bear', 'bad', 'negative', 'case', 'trial', 'problem', 'issue']
        
#         is_positive = is_positive or any(keyword.lower() in tweet_text.lower() for keyword in generic_positive)
#         is_negative = is_negative or any(keyword.lower() in tweet_text.lower() for keyword in generic_negative)
        
#         # 기본값은 중립
#         sentiment = "neutral"
#         confidence = random.randint(50, 70)
#         impact = "중립"
#         price_change = random.uniform(-1, 1)
#         action = "hold"
#         leverage = random.randint(1, 3)
#         risk = "medium"
        
#         # 특정 인플루언서의 영향력 고려
#         author_id = tweet_data.get('author_id', '')
#         influencer_impact = 1.0  # 기본 영향력
        
#         # 인플루언서 확인
#         for inf in influencers:
#             if inf['twitter_username'].lower() == author_id.lower() or inf['name'].lower() in author_id.lower():
#                 # 주요 인플루언서의 영향력 증가
#                 if "elon" in author_id.lower() or "musk" in author_id.lower():
#                     influencer_impact = 2.0  # 일론 머스크는 2배 영향력
#                 elif "trump" in author_id.lower():
#                     influencer_impact = 1.8  # 트럼프는 1.8배 영향력
#                 elif "saylor" in author_id.lower():
#                     influencer_impact = 1.5  # 세일러는 1.5배 영향력
#                 else:
#                     influencer_impact = 1.3  # 기타 인플루언서
#                 break
        
#         # 공개 지표 영향력 계산 (좋아요, 리트윗 등)
#         metrics_impact = 1.0  # 기본 영향력
#         public_metrics = tweet_data.get('public_metrics', {})
        
#         if public_metrics:
#             # 지표가 높을수록 영향력 증가
#             like_count = int(public_metrics.get('like_count', 0))
#             retweet_count = int(public_metrics.get('retweet_count', 0))
            
#             if like_count > 10000 or retweet_count > 5000:
#                 metrics_impact = 1.5  # 바이럴 트윗
#             elif like_count > 5000 or retweet_count > 1000:
#                 metrics_impact = 1.3  # 인기 트윗
#             elif like_count > 1000 or retweet_count > 500:
#                 metrics_impact = 1.2  # 평균 이상 트윗
        
#         # 긍정적 내용이 있으면
#         if is_positive:
#             sentiment = "positive"
#             confidence = random.randint(70, 95)
#             impact = random.choice(["긍정적", "매우 긍정적"])
#             base_change = random.uniform(2, 15)
#             price_change = base_change * influencer_impact * metrics_impact
#             action = "buy"
#             leverage = int(random.randint(3, 10) * influencer_impact)
#             risk = random.choice(["medium", "high"])
        
#         # 부정적 내용이 있으면
#         elif is_negative:
#             sentiment = "negative"
#             confidence = random.randint(70, 90)
#             impact = random.choice(["부정적", "매우 부정적"])
#             base_change = random.uniform(-15, -2)
#             price_change = base_change * influencer_impact * metrics_impact
#             action = "sell"
#             leverage = int(random.randint(3, 8) * influencer_impact)
#             risk = random.choice(["medium", "high"])
        
#         # 설명 생성
#         explanation = f"분석: 이 트윗은 {coin_symbol}에 대해 {'긍정적' if is_positive else '부정적' if is_negative else '중립적'} 내용을 담고 있습니다. "
        
#         if influencer_impact > 1.0:
#             explanation += f"작성자의 영향력이 {influencer_impact:.1f}배 고려되었습니다. "
            
#         if metrics_impact > 1.0:
#             explanation += f"트윗의 인기도(좋아요, 리트윗 수)가 {metrics_impact:.1f}배 고려되었습니다. "
            
#         explanation += f"과거 유사한 트윗은 {abs(price_change):.2f}% 정도의 {'상승' if price_change > 0 else '하락'} 영향을 주었습니다."
        
#         return {
#             "sentiment": sentiment,
#             "confidenceScore": confidence,
#             "predictedImpact": impact,
#             "estimatedPriceChangePercent": price_change,
#             "reasoningExplanation": explanation,
#             "recommendedAction": action,
#             "recommendedLeverageMultiple": leverage,
#             "riskLevel": risk
#         }
        
#     except Exception as e:
#         logger.error(f"트윗 분석 오류: {e}")
#         import traceback
#         logger.error(traceback.format_exc())
#         return None

def generate_trading_signal(analysis, coin_symbol, source_data):
    """거래 시그널 생성 - 더 안전한 버전"""
    try:
        # 분석 결과가 없으면 처리 불가
        if not analysis:
            logger.error("분석 결과가 없어 시그널을 생성할 수 없습니다.")
            return None
            
        # 최적 진입/청산 시간 계산
        optimal_entry_window = calculate_optimal_entry_window(coin_symbol)
        optimal_exit_window = calculate_optimal_exit_window(coin_symbol, analysis.get("estimatedPriceChangePercent", 0))
        
        # 소스 데이터에서 필요한 정보 안전하게 추출
        source_type = source_data.get('source', 'unknown')
        source_content = source_data.get('content', '')
        source_url = source_data.get('url', '')
        
        # 소스 타입별 식별자
        if source_type == 'twitter':
            source_id = source_data.get('tweet_id', '')
            source_author = source_data.get('author', '')
        else:  # 뉴스
            source_id = source_url
            source_author = source_data.get('sourceType', '')
        
        # 현재 코인 가격 조회
        current_price = get_coin_price(coin_symbol)
        
        signal = {
            "timestamp": datetime.now().isoformat(),
            "coinSymbol": coin_symbol,
            "sourceType": source_type,
            "sourceId": source_id,
            "sourceUrl": source_url,
            "sourceContent": source_content[:200] + ("..." if len(source_content) > 200 else ""),
            "sourceAuthor": source_author,
            "sentiment": analysis.get("sentiment", "neutral"),
            "confidenceScore": analysis.get("confidenceScore", 50),
            "predictedImpact": analysis.get("predictedImpact", "중립"),
            "estimatedPriceChangePercent": analysis.get("estimatedPriceChangePercent", 0),
            "recommendedAction": analysis.get("recommendedAction", "hold"),
            "recommendedLeverageMultiple": analysis.get("recommendedLeverageMultiple", 1),
            "riskLevel": analysis.get("riskLevel", "medium"),
            "reasoning": analysis.get("reasoningExplanation", ""),
            "optimalEntryWindow": optimal_entry_window,
            "optimalExitWindow": optimal_exit_window,
            "currentPrice": current_price
        }
        
        return signal
        
    except Exception as e:
        logger.error(f"거래 시그널 생성 오류: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return None

def generate_trading_signal_without_price(analysis, coin_symbol, source_data):
    """가격 정보 없이 거래 시그널 생성 (fallback 용)"""
    try:
        # 분석 결과가 없으면 처리 불가
        if not analysis:
            logger.error("분석 결과가 없어 시그널을 생성할 수 없습니다.")
            return None
            
        # 최적 진입/청산 시간 계산
        optimal_entry_window = calculate_optimal_entry_window(coin_symbol)
        optimal_exit_window = calculate_optimal_exit_window(coin_symbol, analysis.get("estimatedPriceChangePercent", 0))
        
        # 소스 데이터에서 필요한 정보 안전하게 추출
        source_type = source_data.get('source', 'unknown')
        source_content = source_data.get('content', '')
        source_url = source_data.get('url', '')
        
        # 소스 타입별 식별자
        if source_type == 'twitter':
            source_id = source_data.get('tweet_id', '')
            source_author = source_data.get('author', '')
        else:  # 뉴스
            source_id = source_url
            source_author = source_data.get('sourceType', '')
        
        signal = {
            "timestamp": datetime.now().isoformat(),
            "coinSymbol": coin_symbol,
            "sourceType": source_type,
            "sourceId": source_id,
            "sourceUrl": source_url,
            "sourceContent": source_content[:200] + ("..." if len(source_content) > 200 else ""),
            "sourceAuthor": source_author,
            "sentiment": analysis.get("sentiment", "neutral"),
            "confidenceScore": analysis.get("confidenceScore", 50),
            "predictedImpact": analysis.get("predictedImpact", "중립"),
            "estimatedPriceChangePercent": analysis.get("estimatedPriceChangePercent", 0),
            "recommendedAction": analysis.get("recommendedAction", "hold"),
            "recommendedLeverageMultiple": analysis.get("recommendedLeverageMultiple", 1),
            "riskLevel": analysis.get("riskLevel", "medium"),
            "reasoning": analysis.get("reasoningExplanation", ""),
            "optimalEntryWindow": optimal_entry_window,
            "optimalExitWindow": optimal_exit_window,
            "currentPrice": None,  # 가격 정보 없음
            "priceMissing": True   # 가격 정보 누락 표시
        }
        
        return signal
        
    except Exception as e:
        logger.error(f"가격 없는 거래 시그널 생성 오류: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return None

def send_alert_without_price(signal):
    """가격 정보 없는 트레이딩 시그널 알림"""
    logger.info(f"🚨 알림: {signal['coinSymbol']} {signal['recommendedAction'].upper()} 시그널 발생 (가격 정보 없음)")
    logger.info(f"💰 추천 레버리지: {signal['recommendedLeverageMultiple']}배")
    logger.info(f"⏱️ 최적 진입 시간: {signal['optimalEntryWindow']['start']} ~ {signal['optimalEntryWindow']['end']}")
    logger.info(f"🔄 최적 청산 시간: {signal['optimalExitWindow']['start']} ~ {signal['optimalExitWindow']['end']}")
    logger.info(f"📊 예상 가격 변동: {signal['estimatedPriceChangePercent']:.2f}%")
    logger.info(f"⚠️ 가격 정보 없음: 최신 시장 가격을 직접 확인하세요")
    logger.info(f"🔎 근거: {signal['reasoning']}")

# 12. 메인 실행 함수
def main():
    """최적화된 코인 레버리지 시그널 분석 시스템"""
    logger.info("코인 레버리지 시그널 분석 시스템 시작...")
    
    try:
        # 이미 처리된 데이터 ID 로드
        processed_ids = load_processed_ids()
        
        # 트위터 데이터 로드
        twitter_signals = load_twitter_data()
        logger.info(f"{len(twitter_signals)}개의 트위터 시그널 로드됨")
        
        # 뉴스 데이터 로드
        news_signals = load_news_data()
        logger.info(f"{len(news_signals)}개의 뉴스 시그널 로드됨")
        
        # 모든 시그널 통합
        all_signals = []
        
        # 트위터 시그널 처리
        for signal in twitter_signals:
            tweet_id = signal.get('tweet_id', '')
            if not tweet_id:
                continue
                
            # 이미 처리된 트윗 스킵
            if is_already_processed(tweet_id, "twitter", processed_ids):
                continue
                
            # 최신성 확인
            timestamp = signal.get('timestamp', '')
            if not is_recent_content(timestamp):
                continue
                
            all_signals.append(signal)
        
        # 뉴스 시그널 처리
        for signal in news_signals:
            url = signal.get('url', '')
            content = signal.get('content', '')
            
            # URL이 없으면 내용 해시 사용
            news_id = url if url else str(hash(content))
            
            # 이미 처리된 뉴스 스킵
            if is_already_processed(news_id, "news", processed_ids):
                continue
                
            # 최신성 확인
            timestamp = signal.get('timestamp', '')
            if not is_recent_content(timestamp):
                continue
                
            all_signals.append(signal)
        
        logger.info(f"처리할 새로운 시그널: {len(all_signals)}개")
        
        # 시그널 처리 카운터
        processed_count = 0
        
        # 코인별 가격 캐시 (중복 API 호출 방지)
        coin_prices = {}
        
        # 각 시그널 처리
        for signal in all_signals:
            try:
                # 기본 정보 추출
                source = signal.get('source', '')
                coin_symbol = signal.get('coinSymbol', '')
                content = signal.get('content', '')

                # Claude 사용 여부 결정 (이 부분이 현재 없음)
                use_claude = should_use_claude(signal)
                logger.info(f"{signal.get('content', '')[:30]}... 분석에 Claude 사용: {use_claude}")
                
                
                # 시그널 ID 결정
                if source == 'twitter':
                    data_id = signal.get('tweet_id', '')
                    data_type = "twitter"
                else:  # news
                    data_id = signal.get('url', '') or str(hash(content))
                    data_type = "news"
                
                # 분석 수행
                if source == 'twitter':
                    analysis = analyze_tweet(signal, coin_symbol, use_claude=use_claude)
                else:  # news
                    analysis = analyze_news(signal, coin_symbol, use_claude=use_claude)
                
                # 분석 결과가 있으면 처리
                if analysis:
                    try:
                        # 코인 가격 가져오기
                        if coin_symbol in coin_prices:
                            current_price = coin_prices[coin_symbol]
                        else:
                            current_price = get_coin_price(coin_symbol)
                            coin_prices[coin_symbol] = current_price
                        
                        # 거래 시그널 생성
                        trading_signal = generate_trading_signal(analysis, coin_symbol, signal)
                        
                        if trading_signal:
                            # 시그널 저장 및 알림
                            save_signal(trading_signal)
                            send_alert(trading_signal)
                            
                            # 처리됨으로 표시
                            mark_as_processed(data_id, data_type, processed_ids)
                            processed_count += 1
                    except Exception as price_error:
                        logger.error(f"가격 정보/시그널 생성 오류: {str(price_error)}")
                else:
                    # 분석 실패해도 중복 처리 방지를 위해 처리됨으로 표시
                    mark_as_processed(data_id, data_type, processed_ids)
            except Exception as e:
                logger.error(f"시그널 처리 오류: {e}")
        
        # 처리된 ID 목록 저장
        save_processed_ids(processed_ids)
        
        logger.info(f"총 {processed_count}개의 시그널이 처리되었습니다.")
        
    except Exception as e:
        logger.error(f"시스템 오류: {e}")

def should_use_claude(signal):
    """Claude AI를 사용할지 결정하는 로직"""
    # 고위험 시그널은 Claude로 분석
    if signal.get('risk_level') == 'HIGH':
        return True
        
    # 특정 인플루언서 관련 시그널은 Claude로 분석
    related_influencers = signal.get('related_influencers', [])
    high_impact_influencers = ["Elon Musk", "Donald Trump", "Michael Saylor"]
    if any(inf in related_influencers for inf in high_impact_influencers):
        return True
    
    # 특정 코인 관련 시그널은 Claude로 분석
    coin_symbol = signal.get('coinSymbol', '')
    high_priority_coins = ["BTC", "ETH", "DOGE", "TRUMP"]
    if coin_symbol in high_priority_coins:
        return True
    
    # 그 외 시그널은 20% 확률로 Claude 사용 (자원 절약)
    return random.random() < 0.2

def can_call_claude_api():
    """Claude API 호출 제한 확인"""
    global last_api_call_time, api_calls_count
    
    current_time = datetime.now()
    time_diff = (current_time - last_api_call_time).total_seconds()
    
    # 1분이 지났으면 카운터 초기화
    if time_diff > 60:
        last_api_call_time = current_time
        api_calls_count = 0
        return True
    
    # 분당 호출 제한 확인
    if api_calls_count < MAX_API_CALLS_PER_MINUTE:
        api_calls_count += 1
        return True
    
    # 제한 초과
    return False

# 처리된 데이터 ID를 저장할 파일
PROCESSED_DATA_FILE = "data/processed_ids.json"

def load_processed_ids():
    """이미 처리된 데이터 ID 목록 로드"""
    try:
        if os.path.exists(PROCESSED_DATA_FILE):
            with open(PROCESSED_DATA_FILE, 'r', encoding='utf-8') as f:
                loaded_data = json.load(f)
                # list를 set으로 변환
                processed_ids = {}
                for key, value in loaded_data.items():
                    processed_ids[key] = set(value)
                return processed_ids
        # 파일이 없을 경우 기본값
        return {"news": set(), "twitter": set()}
    except Exception as e:
        logger.error(f"처리된 ID 로드 오류: {e}")
        return {"news": set(), "twitter": set()}
    
def save_processed_ids(processed_ids):
    """처리된 데이터 ID 목록 저장"""
    try:
        # set을 list로 변환하여 JSON으로 저장
        save_data = {}
        for key, value in processed_ids.items():
            # 타입 검사를 통한 안전한 변환
            if isinstance(value, set):
                save_data[key] = list(value)
            elif isinstance(value, list):
                save_data[key] = value
            else:
                save_data[key] = []
                logger.warning(f"처리된 ID 저장 중 타입 불일치: {key} - {type(value)}")
        
        # 디렉토리 확인
        os.makedirs(os.path.dirname(PROCESSED_DATA_FILE), exist_ok=True)
        
        with open(PROCESSED_DATA_FILE, 'w', encoding='utf-8') as f:
            json.dump(save_data, f, ensure_ascii=False, indent=2)
            
        logger.info(f"처리된 ID 저장 완료 (news: {len(processed_ids.get('news', set()))}, twitter: {len(processed_ids.get('twitter', set()))})")
    except Exception as e:
        logger.error(f"처리된 ID 저장 오류: {e}")

def is_already_processed(data_id, data_type, processed_ids):
    """이미 처리된 데이터인지 확인"""
    # 타입 확인 및 변환
    if data_type in processed_ids:
        if not isinstance(processed_ids[data_type], set):
            processed_ids[data_type] = set(processed_ids[data_type])
        
        # ID 확인
        if data_id in processed_ids[data_type]:
            return True
    return False

def mark_as_processed(data_id, data_type, processed_ids):
    """데이터를 처리됨으로 표시"""
    if data_type not in processed_ids:
        processed_ids[data_type] = set()
    
    # data_id가 None이거나 빈 문자열이면 무시
    if not data_id:
        logger.warning(f"유효하지 않은 ID: {data_id}, 처리됨으로 표시 건너뜀")
        return
        
    # set이 아닐 경우 set으로 변환
    if not isinstance(processed_ids[data_type], set):
        processed_ids[data_type] = set(processed_ids[data_type])
        
    # 처리됨으로 표시
    processed_ids[data_type].add(data_id)

def is_recent_content(timestamp_str, max_minutes_old=30):
    """컨텐츠가 최신 것인지 확인 (기본값: 최근 30분 이내)"""
    try:
        # timestamp_str이 None이면 현재 시간 사용
        if not timestamp_str:
            return True
            
        # datetime 객체로 변환
        timestamp = None
        
        # 이미 datetime 객체인 경우
        if isinstance(timestamp_str, datetime):
            timestamp = timestamp_str
        # 문자열인 경우 여러 형식 시도
        elif isinstance(timestamp_str, str):
            try:
                # ISO 형식 시도 (2025-05-10 01:04:06+00:00 또는 2025-05-10T01:04:06+00:00)
                if '+' in timestamp_str or 'T' in timestamp_str:
                    if 'T' in timestamp_str:
                        timestamp = datetime.fromisoformat(timestamp_str)
                    else:
                        # 공백을 T로 변환하여 ISO 형식으로 만들기
                        iso_format = timestamp_str.replace(' ', 'T')
                        timestamp = datetime.fromisoformat(iso_format)
                # YYYY-MM-DD HH:MM:SS 형식 시도
                elif '-' in timestamp_str and ':' in timestamp_str and len(timestamp_str) >= 16:
                    timestamp = datetime.strptime(timestamp_str, '%Y-%m-%d %H:%M:%S')
                # YYYY.MM.DD HH:MM 형식 시도
                elif '.' in timestamp_str and ':' in timestamp_str:
                    timestamp = datetime.strptime(timestamp_str, '%Y.%m.%d %H:%M')
                # MM/DD/YYYY 형식 시도
                elif '/' in timestamp_str:
                    parts = timestamp_str.split('/')
                    if len(parts) == 3 and len(parts[2]) == 4:  # MM/DD/YYYY
                        timestamp = datetime.strptime(timestamp_str, '%m/%d/%Y')
                    else:  # 다른 / 형식
                        current_year = datetime.now().year
                        timestamp = datetime.strptime(f"{current_year}/{timestamp_str}", '%Y/%m/%d')
                # HH:MM 형식 시도 (오늘 날짜)
                elif ':' in timestamp_str and len(timestamp_str) <= 5:
                    today = datetime.now().date()
                    time_obj = datetime.strptime(timestamp_str, '%H:%M').time()
                    timestamp = datetime.combine(today, time_obj)
                else:
                    # 다른 모든 형식 실패 시 현재 시간 사용
                    timestamp = datetime.now()
            except ValueError:
                # 파싱 실패 시 현재 시간 사용
                logger.warning(f"날짜 형식 파싱 실패: {timestamp_str}")
                timestamp = datetime.now()
        else:
            # 다른 타입인 경우 현재 시간 사용
            timestamp = datetime.now()
            
        # 시간 차이 계산
        current_time = datetime.now()
        
        # 시간대 정보가 있으면 UTC로 변환 (간단한 처리)
        if hasattr(timestamp, 'tzinfo') and timestamp.tzinfo is not None:
            # 현재 시간을 UTC 기준으로 설정
            from datetime import timezone
            current_time = datetime.now(timezone.utc)
            
        time_diff = current_time - timestamp
        minutes_diff = time_diff.total_seconds() / 60
        
        return minutes_diff <= max_minutes_old
    except Exception as e:
        logger.error(f"최신성 확인 오류: {e}")
        # 오류 발생 시 안전을 위해 최신으로 간주
        return True
    
def load_latest_trading_signals(max_signals=30):
    """최근 생성된 거래 시그널 로드"""
    signals_file = 'trading_signals.json'
    
    if not os.path.exists(signals_file):
        return []
        
    try:
        with open(signals_file, 'r', encoding='utf-8') as f:
            all_signals = json.load(f)
            
        # 최신 시그널만 선택
        all_signals.sort(key=lambda x: x.get('timestamp', ''), reverse=True)
        return all_signals[:max_signals]
        
    except Exception as e:
        logger.error(f"거래 시그널 로드 오류: {e}")
        return []

# 13. 스케줄러 설정 (주기적 실행)
def run_scheduler():
    from apscheduler.schedulers.blocking import BlockingScheduler
    
    scheduler = BlockingScheduler()
    # 5분마다 실행
    scheduler.add_job(main, 'interval', minutes=5)
    
    try:
        logger.info("스케줄러 시작... (Ctrl+C로 중지)")
        scheduler.start()
    except KeyboardInterrupt:
        logger.info("스케줄러 종료")

# 프로그램 실행
if __name__ == "__main__":
    try:
        # 한 번 실행하려면:
        main()
        
        # 주기적으로 실행하려면:
        # run_scheduler()
    except Exception as e:
        logger.error(f"시스템 오류: {e}")