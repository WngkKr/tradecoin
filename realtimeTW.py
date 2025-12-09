import time
import json
import os
import logging
import random
import schedule
import re
from datetime import datetime, timedelta
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, NoSuchElementException, WebDriverException
from webdriver_manager.chrome import ChromeDriverManager  # 웹드라이버 자동 관리

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("twitter_monitor.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# 모니터링할 인플루언서 목록
influencers = [
    {"name": "Elon Musk", "twitter_username": "elonmusk", "coins": ["DOGE", "SHIB", "FLOKI"]},
    {"name": "Michael Saylor", "twitter_username": "saylor", "coins": ["BTC"]},
    {"name": "Vitalik Buterin", "twitter_username": "VitalikButerin", "coins": ["ETH"]},
    {"name": "Donald Trump", "twitter_username": "realDonaldTrump", "coins": ["TRUMP", "MAGA"]}
]

# 민감 키워드 정의
risk_keywords = {
    "HIGH": ["ETF", "SEC", "금리", "트럼프", "도지코인", "DOGE", "SHIB", "제재", "탄소", "파산", "리스크", "투자 중단"],
    "MEDIUM": ["상승", "하락", "호재", "악재", "합의", "업데이트"],
    "LOW": []
}

# 코인별 패턴 데이터 
coin_patterns = {
    'ETH': {
        'avgReactionTimeMinutes': 12,
        'avgPriceImpactPercent': 8,
        'positiveKeywords': ['scaling', 'staking', 'defi', 'layer 2', 'upgrade', 'eth', 'ethereum'],
        'negativeKeywords': ['delay', 'issue', 'problem', 'bug']
    },
    'DOGE': {
        'avgReactionTimeMinutes': 7,
        'avgPriceImpactPercent': 12,
        'positiveKeywords': ['dog', 'moon', 'favorite', 'love', 'doge', 'dogecoin'],
        'negativeKeywords': ['sell', 'overvalued']
    },
    'BTC': {
        'avgReactionTimeMinutes': 10,
        'avgPriceImpactPercent': 5,
        'positiveKeywords': ['reserve', 'property', 'hope', 'acquire', 'hold', 'btc', 'bitcoin'],
        'negativeKeywords': ['sell', 'risk', 'ban', 'regulation']
    },
    'SHIB': {
        'avgReactionTimeMinutes': 8,
        'avgPriceImpactPercent': 15,
        'positiveKeywords': ['dog', 'community', 'cute', 'pet', 'shib', 'shiba'],
        'negativeKeywords': ['dump', 'meme', 'joke']
    },
    'FLOKI': {
        'avgReactionTimeMinutes': 5,
        'avgPriceImpactPercent': 25,
        'positiveKeywords': ['puppy', 'cute', 'moon', 'pet', 'floki'],
        'negativeKeywords': ['sell', 'scam', 'joke']
    },
    'TRUMP': {
        'avgReactionTimeMinutes': 15,
        'avgPriceImpactPercent': 35,
        'positiveKeywords': ['president', 'win', 'election', 'victory', 'trump'],
        'negativeKeywords': ['case', 'trial', 'verdict']
    },
    'MAGA': {
        'avgReactionTimeMinutes': 14,
        'avgPriceImpactPercent': 30,
        'positiveKeywords': ['america', 'win', 'great', 'huge', 'maga'],
        'negativeKeywords': ['lose', 'bad', 'fake']
    }
}

# 이미 처리한 트윗 ID 저장
processed_tweet_ids = set()

# 민감도 판단 함수
def determine_risk(text):
    for level in ["HIGH", "MEDIUM"]:
        for word in risk_keywords[level]:
            if word.upper() in text.upper():
                return level
    return "LOW"

# 뉴스 수집 함수 (코인리더스)
def fetch_coinreaders_news():
    url = "https://www.coinreaders.com/"
    try:
        res = requests.get(url, timeout=10)
        soup = BeautifulSoup(res.text, 'html.parser')
        articles = soup.select("ul.list-type01 li a")

        news_events = []
        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        for a in articles:
            title = a.get_text(strip=True)
            link = a.get("href")
            if not link.startswith("http"):
                link = "https://www.coinreaders.com" + link
            risk = determine_risk(title)
            if risk != "LOW":
                news_events.append({
                    "timestamp": now,
                    "source": "news",
                    "headline": title,
                    "risk_level": risk,
                    "url": link
                })
        return news_events
    except Exception as e:
        print(f"⚠️ 뉴스 수집 에러: {e}")
        return []

# 웹드라이버 초기화 함수 (개선된 버전)
def initialize_webdriver():
    """webdriver-manager를 사용하여 Chrome 웹드라이버 자동 초기화"""
    try:
        # Chrome 옵션 설정
        chrome_options = Options()
        chrome_options.add_argument("--headless")  # 헤드리스 모드 (화면 표시 X)
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
        chrome_options.add_argument("--disable-notifications")
        chrome_options.add_argument("--disable-infobars")
        chrome_options.add_argument("--mute-audio")
        
        # 무작위 User-Agent 설정 (탐지 방지)
        user_agents = [
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
            "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.107 Safari/537.36",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:90.0) Gecko/20100101 Firefox/90.0",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 11.5; rv:91.0) Gecko/20100101 Firefox/91.0",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36 Edg/91.0.864.59"
        ]
        chrome_options.add_argument(f"--user-agent={random.choice(user_agents)}")
        
        # 브라우저 창 크기 설정
        chrome_options.add_argument("--window-size=1920,1080")
        
        # 기타 유용한 옵션
        chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])
        chrome_options.add_experimental_option("useAutomationExtension", False)
        
        # 로깅 레벨 설정 (웹드라이버 매니저 로그 줄이기)
        import logging
        logging.getLogger('WDM').setLevel(logging.ERROR)
        
        # 자동으로 최신 크롬드라이버 설치 및 서비스 생성
        try:
            # 표준 크롬 드라이버 시도
            service = Service(ChromeDriverManager().install())
            driver = webdriver.Chrome(service=service, options=chrome_options)
        except Exception as chrome_error:
            logger.warning(f"기본 크롬 드라이버 초기화 실패, 다른 방법 시도: {chrome_error}")
            
            try:
                # 직접 명시적 버전 지정 시도
                try:
                    specific_version = "135.0.7049.0"  # 현재 크롬 버전과 호환되는 드라이버 버전
                    service = Service(ChromeDriverManager(version=specific_version).install())
                    driver = webdriver.Chrome(service=service, options=chrome_options)
                except Exception as version_error:
                    logger.error(f"특정 버전 드라이버 초기화 실패: {version_error}")
                    raise
            except Exception as chrome_error2:
                logger.warning(f"모든 크롬 드라이버 초기화 실패, Safari 시도: {chrome_error2}")
                return initialize_safari_webdriver()
        
        driver.set_page_load_timeout(30)  # 페이지 로드 타임아웃 설정
        
        logger.info("웹드라이버 초기화 성공")
        return driver
    
    except Exception as e:
        logger.error(f"웹드라이버 초기화 오류: {e}")
        
        # Firefox 웹드라이버로 대체 시도 (선택적)
        try:
            from selenium.webdriver.firefox.options import Options as FirefoxOptions
            from webdriver_manager.firefox import GeckoDriverManager
            
            logger.info("Firefox 웹드라이버로 대체 시도")
            
            firefox_options = FirefoxOptions()
            firefox_options.add_argument("--headless")
            
            driver = webdriver.Firefox(
                service=Service(GeckoDriverManager().install()),
                options=firefox_options
            )
            driver.set_page_load_timeout(30)
            
            logger.info("Firefox 웹드라이버 초기화 성공")
            return driver
        except Exception as firefox_error:
            logger.error(f"Firefox 웹드라이버 초기화 오류: {firefox_error}")
            return None

# Safari 드라이버 초기화 함수 (macOS 전용 대안)
def initialize_safari_webdriver():
    """Safari 웹드라이버 초기화 (macOS 전용)"""
    try:
        from selenium.webdriver.safari.options import Options as SafariOptions
        
        safari_options = SafariOptions()
        driver = webdriver.Safari(options=safari_options)
        driver.set_page_load_timeout(30)
        
        logger.info("Safari 웹드라이버 초기화 성공")
        return driver
    except Exception as e:
        logger.error(f"Safari 웹드라이버 초기화 오류: {e}")
        return None

# 트윗의 최신성 확인 함수
def is_recent_tweet(created_at, max_days_old=2):
    """트윗이 최근 것인지 확인 (기본값: 최근 2일 이내)"""
    if isinstance(created_at, str):
        try:
            created_at = datetime.fromisoformat(created_at.replace('Z', '+00:00'))
        except:
            # 날짜 파싱 실패 시 현재 시간 기준 (안전)
            return True
    
    now = datetime.now()
    if not isinstance(created_at, datetime):
        return True  # 확인 불가능한 경우 기본적으로 포함
        
    # 시간대 정보가 없는 경우 로컬 시간 기준으로 계산
    if created_at.tzinfo is not None:
        now = datetime.now(created_at.tzinfo)
        
    time_diff = now - created_at
    return time_diff.days <= max_days_old

# 트위터(X) 접속 및 트윗 가져오기
def get_recent_tweets_via_selenium(username, max_tweets=5):
    """Selenium을 사용하여 트위터에서 최근 트윗 가져오기"""
    driver = None
    try:
        logger.info(f"{username}의 최근 트윗 가져오기 시도")
        
        # 웹드라이버 초기화
        driver = initialize_webdriver()
        if not driver:
            return []
        
        # 트윗 수집 방법 1: 직접 트위터(X) 접속
        try:
            return get_tweets_from_twitter(driver, username, max_tweets)
        except Exception as twitter_error:
            logger.warning(f"트위터에서 트윗 가져오기 실패: {twitter_error}")
            return []
    
    except Exception as e:
        logger.error(f"트윗 가져오기 오류: {e}")
        return []
    
    finally:
        if driver:
            try:
                driver.quit()
                logger.info("웹드라이버 종료")
            except:
                pass

# 트위터에서 직접 트윗 가져오기 (날짜 형식 기반 필터링 개선)
def get_tweets_from_twitter(driver, username, max_tweets=5):
    """트위터(X)에서 직접 트윗 가져오기 - 최신 트윗 필터링 강화"""
    # 트위터 프로필 페이지 접속
    url = f"https://twitter.com/{username}"
    
    logger.info(f"트위터 URL 접속: {url}")
    driver.get(url)
    
    # 페이지 로딩 대기
    try:
        WebDriverWait(driver, 15).until(
            EC.presence_of_element_located((By.XPATH, "//article[@data-testid='tweet']"))
        )
    except TimeoutException:
        logger.warning("트위터 페이지 로딩 타임아웃")
        
        # 스크린샷 저장 (디버깅용)
        try:
            os.makedirs('screenshots', exist_ok=True)
            screenshot_path = f"screenshots/twitter_{username}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.png"
            driver.save_screenshot(screenshot_path)
            logger.info(f"스크린샷 저장: {screenshot_path}")
        except Exception as e:
            logger.error(f"스크린샷 저장 오류: {e}")
            
        raise TimeoutException("트위터 페이지 로딩 실패")
    
    # 트윗 요소 찾기
    tweet_elements = driver.find_elements(By.XPATH, "//article[@data-testid='tweet']")
    
    if not tweet_elements:
        logger.warning(f"트위터에서 {username}의 트윗을 찾을 수 없음")
        raise NoSuchElementException("트윗 요소를 찾을 수 없음")
    
    logger.info(f"트위터에서 {len(tweet_elements)}개의 트윗 요소 발견")
    
    # 필요한 경우 스크롤하여 더 많은 트윗 로드
    if len(tweet_elements) < max_tweets:
        scroll_twitter_page(driver, scroll_count=2)
        tweet_elements = driver.find_elements(By.XPATH, "//article[@data-testid='tweet']")
        logger.info(f"스크롤 후 {len(tweet_elements)}개의 트윗 요소 발견")
    
    # 트윗을 저장할 리스트
    tweets = []
    recent_tweets = []  # 최신 트윗(연도 표시 없는)
    older_tweets = []   # 오래된 트윗(연도 표시 있는)
    
    for tweet_elem in tweet_elements:
        try:
            # 트윗 ID 추출
            links = tweet_elem.find_elements(By.XPATH, ".//a[contains(@href, '/status/')]")
            if not links:
                continue
                
            href = links[0].get_attribute("href")
            tweet_id_match = re.search(r'/status/(\d+)', href)
            
            if not tweet_id_match:
                continue
                
            tweet_id = tweet_id_match.group(1)
            
            # 이미 처리한 트윗인지 확인
            if tweet_id in processed_tweet_ids:
                continue
            
            # 트윗 내용 추출
            text_elements = tweet_elem.find_elements(By.XPATH, ".//div[@data-testid='tweetText']")
            if not text_elements:
                continue
                
            tweet_text = text_elements[0].text
            
            # 리트윗 여부 확인
            if "RT @" in tweet_text:
                continue
            
            # 날짜 텍스트 추출 (연도 포함 여부 확인)
            date_text = ""
            is_recent = True  # 기본값은 최신 트윗으로 가정
            
            try:
                # 시간 요소 찾기
                time_elements = tweet_elem.find_elements(By.XPATH, ".//time")
                if time_elements:
                    # 날짜 텍스트 가져오기
                    date_text = time_elements[0].get_attribute("datetime")
                    
                    # 화면에 표시되는 날짜 텍스트 (연도 포함 여부 확인용)
                    displayed_date = ""
                    try:
                        displayed_date = time_elements[0].find_element(By.XPATH, "./..").text
                    except:
                        pass
                    
                    # 연도가 표시되어 있으면 최신 트윗이 아님
                    # 트위터는 최신 트윗에 "n분 전", "n시간 전", "n일 전" 또는 "1월 15일"처럼 표시 (연도 없음)
                    # 오래된 트윗은 "2023년 1월 15일"처럼 연도를 포함하여 표시
                    is_recent = "년" not in displayed_date and "20" not in displayed_date[:4]
            except:
                pass
            
            # 날짜 파싱
            created_at = datetime.now()  # 기본값
            try:
                if date_text:
                    created_at = datetime.fromisoformat(date_text.replace('Z', '+00:00'))
            except:
                pass
            
            # 좋아요 수, 리트윗 수 추출
            likes_count = 0
            retweets_count = 0
            
            try:
                metrics = tweet_elem.find_elements(By.XPATH, ".//*[@data-testid='like' or @data-testid='retweet']")
                for metric in metrics:
                    aria_label = metric.get_attribute("aria-label")
                    if not aria_label:
                        continue
                        
                    if "like" in aria_label.lower():
                        likes_text = aria_label.split()[0]
                        likes_count = parse_count(likes_text)
                    elif "retweet" in aria_label.lower():
                        retweets_text = aria_label.split()[0]
                        retweets_count = parse_count(retweets_text)
            except:
                pass
            
            # 트윗 객체 생성
            if is_recent:
                tweet = {
                    'id': tweet_id,
                    'text': tweet_text,
                    'created_at': created_at,
                    'author_id': username,
                    'public_metrics': {
                        'like_count': likes_count,
                        'retweet_count': retweets_count,
                        'reply_count': 0,
                        'quote_count': 0
                    },
                    'url': f"https://twitter.com/{username}/status/{tweet_id}",
                    'source': 'twitter',
                    'is_recent': is_recent
                }
                recent_tweets.append(tweet)
            
            # ID 기록 (중복 방지)
            processed_tweet_ids.add(tweet_id)
            
        except Exception as e:
            logger.error(f"트위터 트윗 추출 오류: {e}")
    
    # 최신 트윗 우선, 오래된 트윗은 그 다음에 추가 (최대 개수 제한)
    tweets = recent_tweets + older_tweets
    if len(tweets) > max_tweets:
        tweets = tweets[:max_tweets]
    
    logger.info(f"트위터에서 {len(tweets)}개의 트윗 가져오기 성공 (최신 트윗: {len(recent_tweets)}개, 오래된 트윗: {len(older_tweets)}개)")
    return tweets

# 트위터 페이지 스크롤 함수 (더 많은 트윗 로드)
def scroll_twitter_page(driver, scroll_count=3, wait_time=1):
    """트위터 페이지를 스크롤하여 더 많은 트윗 로드"""
    try:
        for i in range(scroll_count):
            # 페이지 맨 아래로 스크롤
            driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
            
            # 로딩 대기
            time.sleep(wait_time)
            
            # 새 트윗 로드 확인 시도
            try:
                # 더 로드 중 표시 확인
                loading_elements = driver.find_elements(By.XPATH, "//div[contains(@aria-label, 'Loading')]")
                if loading_elements:
                    # 로딩이 완료될 때까지 추가 대기
                    time.sleep(wait_time * 2)
            except:
                pass
                
            logger.info(f"스크롤 {i+1}/{scroll_count} 완료")
    except Exception as e:
        logger.error(f"스크롤 오류: {e}")

# 숫자 텍스트 파싱 (1.5K -> 1500)
def parse_count(count_text):
    try:
        count_text = str(count_text).strip()
        if 'K' in count_text or 'k' in count_text:
            return int(float(count_text.replace('K', '').replace('k', '')) * 1000)
        elif 'M' in count_text or 'm' in count_text:
            return int(float(count_text.replace('M', '').replace('m', '')) * 1000000)
        else:
            return int(count_text.replace(',', ''))
    except (ValueError, TypeError):
        return 0

# 특정 키워드에 대한 트윗 검색
def search_tweets_for_keywords(tweets, keywords):
    """트윗에서 특정 키워드 검색"""
    if not tweets or not keywords:
        return []
    
    matching_tweets = []
    
    for tweet in tweets:
        text = tweet['text'].lower()
        
        if any(keyword.lower() in text for keyword in keywords):
            matching_tweets.append(tweet)
    
    return matching_tweets

# 트윗을 JSON 파일에 저장
def save_tweets_to_file(tweets, username):
    """트윗을 JSON 파일로 저장"""
    if not tweets:
        return
        
    # 폴더 생성
    os.makedirs('tweets', exist_ok=True)
    
    # 파일명 설정
    filename = f"tweets/{username}_{datetime.now().strftime('%Y%m%d_%H%M')}.json"
    
    try:
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(tweets, f, ensure_ascii=False, indent=2, default=str)
        logger.info(f"{username}의 {len(tweets)}개 트윗을 {filename}에 저장")
    except Exception as e:
        logger.error(f"트윗 저장 오류: {e}")

# 모든 트윗을 한 파일에 저장 (실시간 업데이트)
def update_all_tweets_file(username, tweets):
    """모든 트윗을 하나의 파일에 업데이트"""
    if not tweets:
        return
        
    # 폴더 생성
    os.makedirs('tweets', exist_ok=True)
    
    # 파일명 설정
    filename = 'tweets/all_tweets.json'
    
    try:
        # 기존 파일 읽기
        all_tweets = {}
        
        if os.path.exists(filename):
            with open(filename, 'r', encoding='utf-8') as f:
                all_tweets = json.load(f)
        
        # 사용자 트윗 업데이트
        if username not in all_tweets:
            all_tweets[username] = []
            
        # 새 트윗만 추가
        existing_ids = {t['id'] for t in all_tweets[username] if 'id' in t}
        new_tweets = [t for t in tweets if t['id'] not in existing_ids]
        
        if new_tweets:
            all_tweets[username] = new_tweets + all_tweets[username]
            
            # 최대 100개만 유지 (메모리 관리)
            all_tweets[username] = all_tweets[username][:100]
            
            # 파일에 저장
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(all_tweets, f, ensure_ascii=False, indent=2, default=str)
            
            logger.info(f"{username}의 {len(new_tweets)}개 새 트윗을 {filename}에 추가")
    except Exception as e:
        logger.error(f"트윗 업데이트 오류: {e}")

# 코인별 트윗 분류 및 저장
def categorize_and_save_coin_tweets(all_new_tweets):
    """코인별로 트윗 분류하여 저장"""
    # 폴더 생성
    os.makedirs('tweets/coins', exist_ok=True)
    
    # 코인별 트윗 필터링 및 저장
    for coin, pattern in coin_patterns.items():
        keywords = pattern.get('positiveKeywords', []) + pattern.get('negativeKeywords', []) + [coin.lower()]
        coin_tweets = []
        
        for username, tweets in all_new_tweets.items():
            matching_tweets = search_tweets_for_keywords(tweets, keywords)
            coin_tweets.extend(matching_tweets)
        
        if coin_tweets:
            # 파일명 설정
            filename = f"tweets/coins/{coin}_{datetime.now().strftime('%Y%m%d_%H%M')}.json"
            
            # 파일에 저장
            try:
                with open(filename, 'w', encoding='utf-8') as f:
                    json.dump(coin_tweets, f, ensure_ascii=False, indent=2, default=str)
                logger.info(f"{coin} 관련 {len(coin_tweets)}개 트윗을 {filename}에 저장")
            except Exception as e:
                logger.error(f"{coin} 트윗 저장 오류: {e}")


# 트윗 모니터링 및 JSON 출력 함수
def monitor_tweets():
    """모든 인플루언서의 트윗을 모니터링하고 JSON으로 저장"""
    now = datetime.now().strftime("%H:%M:%S")
    logger.info(f"\n[{now}] === 인플루언서 트윗 모니터링 ===")
    
    all_new_tweets = {}
    
    # 모든 인플루언서에 대해 최근 트윗 확인
    for influencer in influencers:
        username = influencer["twitter_username"]
        
        logger.info(f"\n👤 {influencer['name']}의 최근 트윗 확인 중...")
        
        # Selenium을 사용하여 최근 트윗 가져오기
        tweets = get_recent_tweets_via_selenium(username)
        
        if not tweets:
            logger.warning(f"⚠️ {username}의 트윗을 가져오지 못했습니다.")
            continue
            
        logger.info(f"✅ {len(tweets)}개의 트윗을 가져왔습니다.")
        
        # 각 트윗 출력
        for tweet in tweets:
            created_at = tweet['created_at'].strftime("%Y-%m-%d %H:%M") if hasattr(tweet['created_at'], 'strftime') else tweet['created_at']
            logger.info(f"- [{created_at}] {tweet['text'][:100]}{'...' if len(tweet['text']) > 100 else ''}")
            
            # 코인 관련 키워드 검사 및 알림
            for coin in influencer["coins"]:
                keywords = coin_patterns.get(coin, {}).get('positiveKeywords', []) + coin_patterns.get(coin, {}).get('negativeKeywords', []) + [coin.lower()]
                if any(keyword.lower() in tweet['text'].lower() for keyword in keywords):
                    logger.info(f"🚨 {coin} 관련 키워드 감지: {tweet['url'] or ''}")
        
        # 트윗 저장
        save_tweets_to_file(tweets, username)
        update_all_tweets_file(username, tweets)
        
        # 새 트윗 기록
        all_new_tweets[username] = tweets
    
    # 코인별 트윗 분류 및 저장
    categorize_and_save_coin_tweets(all_new_tweets)
    
    return all_new_tweets

# 메인 함수
def main():
    """메인 실행 함수"""
    try:
        logger.info("===== Selenium 기반 실시간 트위터 모니터링 시스템 시작 =====")
        
        # 첫 실행
        monitor_tweets()
        
        # 스케줄 설정 (1분마다)
        schedule.every(1).minutes.do(monitor_tweets)
        
        # 메인 루프
        logger.info("스케줄링 시작... (Ctrl+C로 중지)")
        while True:
            schedule.run_pending()
            time.sleep(1)
    except KeyboardInterrupt:
        logger.info("\n프로그램 종료...")
    except Exception as e:
        logger.error(f"\n⚠️ 오류 발생: {e}")
        import traceback
        logger.error(traceback.format_exc())

# 프로그램 시작
if __name__ == "__main__":
    main()