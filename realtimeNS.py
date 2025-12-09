import time
import json
import os
import logging
import requests
import re
import schedule
import traceback
from datetime import datetime
from bs4 import BeautifulSoup
from concurrent.futures import ThreadPoolExecutor

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("crypto_news.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# 뉴스 소스 목록 (한국어 사이트 중심)
NEWS_SOURCES = {
    "coinreaders": {
        "url": "https://www.coinreaders.com/",
        "selector": "div.news_list dd.title a.link",  # 수정된 선택자
        "title_attr": None,  # text로 가져옴
        "link_attr": "href",
        "base_url": "https://www.coinreaders.com",
        "language": "ko",
        "content_selector": "div.view-wrap"
    },
    "decenter": {
        "url": "https://decenter.kr/NewsView/AllArticle",
        "selector": "div.list-block a.tit",
        "title_attr": None,
        "link_attr": "href",
        "base_url": "",
        "language": "ko",
        "content_selector": "div#article-view-content-div"
    },
    "tokenpost": {
        "url": "https://www.tokenpost.kr/articles",
        "selector": "div.article-list a.title-link",
        "title_attr": None,
        "link_attr": "href",
        "base_url": "https://www.tokenpost.kr",
        "language": "ko",
        "content_selector": "div.article-body"
    },
    "coinpan": {  # 추가: 커뮤니티 성격 강함
        "url": "https://coinpan.com/",
        "selector": "div.list-item a.item-subject",
        "title_attr": None,
        "link_attr": "href",
        "base_url": "https://coinpan.com",
        "language": "ko",
        "content_selector": "div.board-content"
    },
    "coindesk_korea": {
        "url": "https://www.coindeskkorea.com/news/articleList.html",
        "selector": "div.list-titles a",
        "title_attr": None,
        "link_attr": "href",
        "base_url": "https://www.coindeskkorea.com",
        "language": "ko",
        "content_selector": "div#article-view-content-div"
    }
}

# 영어 뉴스 소스 추가 (글로벌 정보 수집)
GLOBAL_NEWS_SOURCES = {
    "coindesk": {
        "url": "https://www.coindesk.com/",
        "selector": "div.card a.card-title",
        "title_attr": None,
        "link_attr": "href",
        "base_url": "https://www.coindesk.com",
        "language": "en",
        "content_selector": "div.article-hero + div"
    },
    "cointelegraph": {
        "url": "https://cointelegraph.com/",
        "selector": "div.post-card-inline__content a.post-card-inline__title-link",
        "title_attr": None,
        "link_attr": "href",
        "base_url": "https://cointelegraph.com",
        "language": "en",
        "content_selector": "div.post-content"
    }
}

# 모든 뉴스 소스 통합
ALL_NEWS_SOURCES = {**NEWS_SOURCES, **GLOBAL_NEWS_SOURCES}

# 모니터링할 인플루언서 목록 (관련 뉴스 필터링용)
INFLUENCERS = [
    {"name": "Elon Musk", "keywords": ["일론 머스크", "머스크", "Elon Musk", "테슬라", "Tesla", "SpaceX", "스페이스X"], "coins": ["DOGE", "SHIB", "FLOKI", "BTC"]},
    {"name": "Donald Trump", "keywords": ["도널드 트럼프", "트럼프", "Donald Trump", "공화당", "대통령", "President"], "coins": ["TRUMP", "MAGA"]},
    {"name": "Michael Saylor", "keywords": ["마이클 세일러", "세일러", "Michael Saylor", "MicroStrategy", "마이크로스트래티지"], "coins": ["BTC"]},
    {"name": "Vitalik Buterin", "keywords": ["비탈릭 부테린", "부테린", "Vitalik Buterin", "이더리움", "Ethereum"], "coins": ["ETH"]},
    {"name": "Gary Gensler", "keywords": ["게리 겐슬러", "겐슬러", "Gary Gensler", "SEC", "증권거래위원회"], "coins": ["BTC", "ETH", "XRP"]}
]

# 민감 키워드 정의 (확장된 버전)
RISK_KEYWORDS = {
    "HIGH": [
        # 정치적 키워드
        "트럼프", "바이든", "대통령", "선거", "정부", "규제", "SEC", "제재", "법안",
        "국회", "소송", "고발", "조사", "의회", "상원", "하원", "대법원", "판결", "탄핵", "스캔들",
        
        # 경제적 키워드
        "금리", "인플레이션", "인플레", "침체", "경기침체", "불황", "불경기", "연준", "Fed", "중앙은행",
        "중은", "FOMC", "금융위기", "붕괴", "급락", "파산", "디폴트", "부도", "국채", "채권", "신용등급",
        "신용강등", "양적완화", "테이퍼링", "리세션", "경기후퇴", "베이러트", "환율", "달러", "유로",
        
        # 코인 특화 키워드
        "ETF", "상장폐지", "해킹", "보안사고", "51%공격", "거래소파산", "거래중단", "입출금중단",
        "에어드랍", "발행량", "소각", "인사이더", "내부자", "증자", "대량매도", "스캠", "사기", "폰지",
        "자금세탁", "블랙리스트", "제재목록", "스테이블코인", "페깅해제",
        
        # 인물 관련 키워드
        "Elon Musk", "일론 머스크", "머스크", "Michael Saylor", "마이클 세일러", "세일러",
        "Vitalik Buterin", "비탈릭 부테린", "부테린", "Sam Bankman-Fried", "SBF", "샘 뱅크먼",
        "Brian Armstrong", "브라이언 암스트롱", "Gary Gensler", "게리 겐슬러", "겐슬러"
    ],
    "MEDIUM": [
        "상승", "하락", "상장", "지갑", "네트워크", "하드포크", "소프트포크", "업그레이드", "투자", 
        "매수", "매도", "수익", "손실", "알트코인", "밈코인", "디파이", "스테이킹", "NFT", "메타버스",
        "Web3", "웹3", "채굴", "블록", "지갑", "컨퍼런스", "서밋", "발표", "합의", "업데이트"
    ],
    "LOW": [
        "뉴스", "정보", "시장", "가격", "차트", "분석", "예측", "전망", "개발", "기술", "회의",
        "토론", "인터뷰", "보고서", "아티클", "아이디어", "계획", "프로젝트", "테스트", "베타", "알파"
    ]
}

# 사회적, 정치적, 경제적, 환경적 키워드 (특화된 모니터링용)
SPECIAL_KEYWORDS = {
    "사회적": [
        "시위", "데모", "시민운동", "사회갈등", "혐오", "차별", "인권", "소셜미디어", "트렌드", 
        "viral", "바이럴", "meme", "밈", "대중문화", "셀러브리티"
    ],
    "정치적": [
        "선거", "투표", "정권", "정부", "의회", "행정부", "사법부", "법원", "대통령", "총리", 
        "법안", "정책", "제재", "외교", "국제관계", "국방", "동맹", "갈등", "전쟁", "평화협정"
    ],
    "경제적": [
        "중앙은행", "기준금리", "이자율", "inflation", "인플레이션", "소비자물가", "생산자물가", 
        "GDP", "경제성장률", "실업률", "고용", "주식시장", "증권", "유가", "원자재", "공급망", 
        "무역전쟁", "관세", "환율", "달러", "유로", "위안", "엔화"
    ],
    "환경적": [
        "기후변화", "탄소배출", "지구온난화", "재생에너지", "그린에너지", "화석연료", "태양광", 
        "풍력", "수력", "전기차", "ESG", "지속가능성", "친환경", "탄소중립", "탄소발자국", 
        "환경규제", "폐기물", "재활용", "생태계", "자연재해"
    ]
}

# 코인별 패턴 데이터 (레버리지 거래 참조용)
COIN_PATTERNS = {
    'ETH': {
        'avgReactionTimeMinutes': 12,
        'avgPriceImpactPercent': 8,
        'volatilityLevel': 'MEDIUM',
        'leverageRiskLevel': 'MEDIUM',
        'recommendedLeverageRange': {"LOW": [2, 5], "MEDIUM": [5, 10], "HIGH": [10, 15]},
        'positiveKeywords': ['scaling', 'staking', 'defi', 'layer 2', 'upgrade', 'eth', 'ethereum', 'eth2', 'pos', 'merge', '이더리움', '스테이킹', '업그레이드'],
        'negativeKeywords': ['delay', 'issue', 'problem', 'bug', 'vulnerability', 'exploit', 'hack', 'sec', '지연', '문제', '버그', '취약점', '해킹']
    },
    'DOGE': {
        'avgReactionTimeMinutes': 7,
        'avgPriceImpactPercent': 12,
        'volatilityLevel': 'HIGH',
        'leverageRiskLevel': 'HIGH',
        'recommendedLeverageRange': {"LOW": [1, 3], "MEDIUM": [3, 7], "HIGH": [7, 12]},
        'positiveKeywords': ['dog', 'moon', 'favorite', 'love', 'doge', 'dogecoin', 'shiba', 'pet', 'elon', 'musk', 'tesla', '도지', '도지코인', '머스크', '테슬라'],
        'negativeKeywords': ['sell', 'overvalued', 'joke', 'meme', 'dump', '과대평가', '농담', '밈', '덤프']
    },
    'BTC': {
        'avgReactionTimeMinutes': 10,
        'avgPriceImpactPercent': 5,
        'volatilityLevel': 'MEDIUM',
        'leverageRiskLevel': 'MEDIUM',
        'recommendedLeverageRange': {"LOW": [2, 5], "MEDIUM": [5, 10], "HIGH": [10, 15]},
        'positiveKeywords': ['reserve', 'property', 'hope', 'acquire', 'hold', 'btc', 'bitcoin', 'etf', 'spot', 'halving', 'institutional', '비트코인', '비트', '반감기', '기관', '헤지펀드'],
        'negativeKeywords': ['sell', 'risk', 'ban', 'regulation', 'mining ban', 'china', 'sec', 'denial', '리스크', '금지', '규제', '채굴금지', '중국', '거부']
    },
    'SHIB': {
        'avgReactionTimeMinutes': 8,
        'avgPriceImpactPercent': 15,
        'volatilityLevel': 'VERY HIGH',
        'leverageRiskLevel': 'VERY HIGH',
        'recommendedLeverageRange': {"LOW": [1, 2], "MEDIUM": [2, 5], "HIGH": [5, 10]},
        'positiveKeywords': ['dog', 'community', 'cute', 'pet', 'shib', 'shiba', 'shibarium', 'burn', 'elon', '시바', '강아지', '커뮤니티', '머스크'],
        'negativeKeywords': ['dump', 'meme', 'joke', 'scam', 'ponzi', 'worthless', '사기', '폰지', '가치없는']
    },
    'FLOKI': {
        'avgReactionTimeMinutes': 5,
        'avgPriceImpactPercent': 25,
        'volatilityLevel': 'EXTREME',
        'leverageRiskLevel': 'EXTREME',
        'recommendedLeverageRange': {"LOW": [1, 2], "MEDIUM": [2, 4], "HIGH": [4, 8]},
        'positiveKeywords': ['puppy', 'cute', 'moon', 'pet', 'floki', 'elon', 'dog', '강아지', '귀여운', '플로키', '머스크'],
        'negativeKeywords': ['sell', 'scam', 'joke', 'ponzi', 'worthless', '사기', '농담', '가치없는']
    },
    'TRUMP': {
        'avgReactionTimeMinutes': 15,
        'avgPriceImpactPercent': 35,
        'volatilityLevel': 'EXTREME',
        'leverageRiskLevel': 'EXTREME',
        'recommendedLeverageRange': {"LOW": [1, 2], "MEDIUM": [2, 5], "HIGH": [5, 10]},
        'positiveKeywords': ['president', 'win', 'election', 'victory', 'trump', 'maga', 'america', 'republican', 'poll', '대통령', '승리', '선거', '트럼프', '공화당'],
        'negativeKeywords': ['case', 'trial', 'verdict', 'conviction', 'lose', 'defeat', 'democrat', 'harris', '재판', '유죄', '패배', '민주당']
    },
    'MAGA': {
        'avgReactionTimeMinutes': 14,
        'avgPriceImpactPercent': 30,
        'volatilityLevel': 'EXTREME',
        'leverageRiskLevel': 'EXTREME',
        'recommendedLeverageRange': {"LOW": [1, 2], "MEDIUM": [2, 5], "HIGH": [5, 10]},
        'positiveKeywords': ['america', 'win', 'great', 'huge', 'maga', 'trump', 'president', 'republican', 'victory', '미국', '승리', '트럼프', '대통령', '공화당'],
        'negativeKeywords': ['lose', 'bad', 'fake', 'fraud', 'democrat', 'harris', 'defeat', '패배', '가짜', '사기', '민주당', '해리스']
    }
}

# 이미 처리한 뉴스 URL 저장
processed_news_urls = set()

# 폴더 생성 함수
def ensure_directories_exist():
    """필요한 데이터 폴더 생성"""
    directories = ['data', 'news', 'news/coins', 'news/influencers', 'news/special', 'logs']
    for directory in directories:
        os.makedirs(directory, exist_ok=True)

# JSON 저장 함수
def save_to_json(data, filename):
    """데이터를 JSON 파일로 저장"""
    try:
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2, default=str)
        return True
    except Exception as e:
        logger.error(f"JSON 저장 오류 ({filename}): {e}")
        return False

# JSON 로드 함수
def load_from_json(filename):
    """JSON 파일에서 데이터 로드"""
    try:
        if os.path.exists(filename):
            with open(filename, 'r', encoding='utf-8') as f:
                return json.load(f)
        return {}
    except Exception as e:
        logger.error(f"JSON 로드 오류 ({filename}): {e}")
        return {}

# 민감도 판단 함수
def determine_risk_level(text):
    """텍스트의 위험 수준 판단"""
    if not text:
        return "LOW"
        
    text = text.lower()
    
    for level in ["HIGH", "MEDIUM"]:
        for word in RISK_KEYWORDS[level]:
            if word.lower() in text:
                return level
    
    return "LOW"

# 코인 관련성 확인 함수
def check_coin_relevance(text, coin_symbol):
    """텍스트가 특정 코인과 관련 있는지 확인"""
    if not text or not coin_symbol:
        return False
        
    text = text.lower()
    pattern = COIN_PATTERNS.get(coin_symbol, {})
    
    # 코인 심볼 자체가 포함되어 있는지
    if coin_symbol.lower() in text:
        return True
    
    # 키워드 체크
    positive_keywords = pattern.get('positiveKeywords', [])
    negative_keywords = pattern.get('negativeKeywords', [])
    
    for keyword in positive_keywords + negative_keywords:
        if keyword.lower() in text:
            return True
    
    return False

# 인플루언서 관련성 확인 함수
def check_influencer_relevance(text, influencer_name=None):
    """텍스트가 특정 인플루언서와 관련 있는지 확인"""
    if not text:
        return False, []
    
    text = text.lower()
    relevant_influencers = []
    
    for influencer in INFLUENCERS:
        if influencer_name and influencer['name'] != influencer_name:
            continue
            
        for keyword in influencer['keywords']:
            if keyword.lower() in text:
                relevant_influencers.append(influencer['name'])
                break
    
    return len(relevant_influencers) > 0, relevant_influencers

# 특별 키워드 카테고리 확인 함수
def check_special_keywords(text):
    """텍스트에 특별 키워드 카테고리가 포함되어 있는지 확인"""
    if not text:
        return []
    
    text = text.lower()
    categories = []
    
    for category, keywords in SPECIAL_KEYWORDS.items():
        for keyword in keywords:
            if keyword.lower() in text:
                categories.append(category)
                break
    
    return categories

# 최신 정보 필터링 함수 강화
def is_recent_article(article_date, max_hours_old=24):
    """기사가 최근 것인지 확인 (기본값: 최근 24시간 이내)"""
    if isinstance(article_date, str):
        try:
            # 다양한 날짜 형식 처리
            if 'T' in article_date:  # ISO 형식
                article_date = datetime.fromisoformat(article_date.replace('Z', '+00:00'))
            elif '.' in article_date:  # 2023.05.08 형식
                article_date = datetime.strptime(article_date, '%Y.%m.%d %H:%M')
            elif '/' in article_date:  # 05/08 형식
                current_year = datetime.now().year
                article_date = datetime.strptime(f"{current_year}/{article_date}", '%Y/%m/%d')
            elif ':' in article_date:  # 시:분 형식 (오늘)
                today = datetime.now().date()
                time_obj = datetime.strptime(article_date, '%H:%M').time()
                article_date = datetime.combine(today, time_obj)
        except:
            # 날짜 파싱 실패 시 최신 기사로 가정 (안전)
            return True
    
    now = datetime.now()
    if not isinstance(article_date, datetime):
        return True  # 확인 불가능한 경우 기본적으로 포함
        
    # 시간대 정보가 없는 경우 로컬 시간 기준으로 계산
    if article_date.tzinfo is not None:
        now = datetime.now(article_date.tzinfo)
        
    time_diff = now - article_date
    return time_diff.total_seconds() <= max_hours_old * 3600  # 시간을 초로 변환

# 뉴스 수집 함수에 최신성 필터 적용
def fetch_all_news(max_articles_per_site=15, max_hours_old=24):
    """모든 뉴스 사이트에서 최신 기사만 수집"""
    logger.info(f"모든 뉴스 사이트에서 최근 {max_hours_old}시간 이내 기사 수집 시작...")
    
    all_articles = []
    
    # 각 뉴스 소스에 대해 작업 수행
    for source_key in ALL_NEWS_SOURCES:
        try:
            # 일반 또는 HTML 크롤링 선택
            if source_key in ["decenter", "coinpan"]:
                articles = fetch_news_from_html_site(source_key, max_articles_per_site)
            else:
                articles = fetch_news_from_site(source_key, max_articles_per_site)
            
            # 최신 기사만 필터링
            recent_articles = []
            for article in articles:
                if is_recent_article(article.get('timestamp'), max_hours_old):
                    recent_articles.append(article)
            
            all_articles.extend(recent_articles)
            logger.info(f"{source_key}에서 {len(recent_articles)}개의 최신 기사 수집 완료")
        except Exception as e:
            logger.error(f"{source_key} 처리 중 오류: {e}")
    
    # 기사 분류 및 저장
    categorize_and_save_articles(all_articles)
    
    logger.info(f"총 {len(all_articles)}개의 최신 기사 수집 완료")
    return all_articles

# 뉴스 사이트에서 기사 수집
def fetch_news_from_site(source_key, max_articles=15):
    """특정 뉴스 사이트에서 최신 기사 수집"""
    source_info = ALL_NEWS_SOURCES.get(source_key)
    if not source_info:
        logger.error(f"알 수 없는 뉴스 소스: {source_key}")
        return []
    
    url = source_info['url']
    selector = source_info['selector']
    base_url = source_info['base_url']
    
    logger.info(f"{source_key} 뉴스 사이트에서 기사 수집 중...")

    # 헤더 정의를 먼저 합니다
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Accept-Language': 'ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache'
    }

    try:
        # 오류 처리 개선: 타임아웃 증가 및 오류 구체화
        try:
            response = requests.get(url, headers=headers, timeout=15)
            response.raise_for_status()
        except requests.exceptions.ConnectionError as ce:
            if "NameResolutionError" in str(ce):
                logger.error(f"도메인 이름 해석 오류 - {source_key}: {url}. DNS 확인 필요")
            else:
                logger.error(f"연결 오류 - {source_key}: {ce}")
            return []
        except requests.exceptions.HTTPError as he:
            logger.error(f"HTTP 오류 - {source_key}: {he}")
            return []
        except requests.exceptions.Timeout:
            logger.error(f"타임아웃 - {source_key}: 사이트 응답이 너무 느림")
            return []
        except requests.exceptions.RequestException as re:
            logger.error(f"요청 오류 - {source_key}: {re}")
            return []
        
        soup = BeautifulSoup(response.text, 'html.parser')
        article_elements = soup.select(selector)
        
        if not article_elements:
            # 선택자 실패 시 로그 남기고 원본 HTML 일부 저장 (디버깅용)
            debug_html = response.text[:500] + "..." if len(response.text) > 500 else response.text
            logger.warning(f"{source_key}에서 선택자 '{selector}'로 기사를 찾을 수 없음")
            logger.debug(f"페이지 HTML 일부: {debug_html}")
            
            # 추가 디버깅 정보: 다른 선택자 시도
            alt_selectors = [
                "div.news_list a.link",  # 다른 가능한 선택자
                "dd.title a",            # 더 단순한 선택자
                "div#news_list2_area div.news_list dl dd.title a"  # 더 구체적인 선택자
            ]
            
            for alt_selector in alt_selectors:
                alt_elements = soup.select(alt_selector)
                if alt_elements:
                    logger.info(f"대체 선택자 '{alt_selector}'로 {len(alt_elements)}개의 요소 발견")
                    article_elements = alt_elements
                    logger.info(f"대체 선택자 '{alt_selector}'로 전환합니다")
                    break
            
            # 여전히 기사를 찾을 수 없는 경우
            if not article_elements:
                logger.error(f"{source_key}에서 모든 대체 선택자로도 기사를 찾을 수 없음")
                return []
        
        articles = []
        
        for i, element in enumerate(article_elements[:max_articles]):
            try:
                # 제목 추출
                if source_info['title_attr']:
                    title = element.get(source_info['title_attr'])
                else:
                    title = element.get_text(strip=True)
                
                # 링크 추출
                link = element.get(source_info['link_attr'])
                
                # 링크가 없거나 비어있는 경우
                if not link or link == "#" or link.startswith("javascript:"):
                    logger.warning(f"{source_key} - 유효하지 않은 링크: {link}")
                    continue
                
                # 상대 URL인 경우 기본 URL 추가
                if link and not link.startswith(('http://', 'https://')):
                    # 슬래시로 시작하는 경우 (예: /158844)
                    if link.startswith('/'):
                        link = base_url + link
                    # 슬래시 없이 숫자로 시작하는 경우 (예: 158844)
                    elif link.isdigit() or (link[0].isdigit() and link.split('/')[0].isdigit()):
                        link = base_url + '/' + link
                    else:
                        link = base_url + '/' + link
                
                # 이미 처리한 URL인지 확인
                if link in processed_news_urls:
                    continue
                
                # 위험 수준 판단
                risk_level = determine_risk_level(title)
                
                # 코인 관련성 판단
                related_coins = []
                for coin_symbol in COIN_PATTERNS.keys():
                    if check_coin_relevance(title, coin_symbol):
                        related_coins.append(coin_symbol)
                
                # 인플루언서 관련성 판단
                is_influencer_related, related_influencers = check_influencer_relevance(title)
                
                # 특별 키워드 카테고리 확인
                special_categories = check_special_keywords(title)
                
                # 기사 정보 추가
                article = {
                    'id': f"{source_key}_{int(time.time())}_{i}",
                    'title': title,
                    'url': link,
                    'source': source_key,
                    'timestamp': datetime.now().isoformat(),
                    'risk_level': risk_level,
                    'language': source_info['language'],
                    'related_coins': related_coins,
                    'related_influencers': related_influencers,
                    'special_categories': special_categories
                }
                
                # 중요한 기사인 경우 내용 수집
                importance_criteria = (
                    risk_level == "HIGH" or 
                    len(related_coins) > 0 or 
                    is_influencer_related or 
                    len(special_categories) > 0
                )
                
                if importance_criteria:
                    content = fetch_news_content(link, source_info)
                    if content:
                        article['content'] = content
                        
                        # 내용 기반으로 다시 분석 (더 자세한 정보가 있을 수 있음)
                        if content:
                            # 코인 관련성 재확인
                            for coin_symbol in COIN_PATTERNS.keys():
                                if coin_symbol not in related_coins and check_coin_relevance(content, coin_symbol):
                                    related_coins.append(coin_symbol)
                            
                            # 인플루언서 관련성 재확인
                            content_is_influencer_related, content_related_influencers = check_influencer_relevance(content)
                            for influencer in content_related_influencers:
                                if influencer not in related_influencers:
                                    related_influencers.append(influencer)
                            
                            # 특별 키워드 카테고리 재확인
                            content_special_categories = check_special_keywords(content)
                            for category in content_special_categories:
                                if category not in special_categories:
                                    special_categories.append(category)
                            
                            # 업데이트된 정보 반영
                            article['related_coins'] = related_coins
                            article['related_influencers'] = related_influencers
                            article['special_categories'] = special_categories
                
                # URL 처리 기록
                processed_news_urls.add(link)
                
                articles.append(article)
                
            except Exception as e:
                logger.error(f"{source_key} 기사 처리 오류: {e}")
                logger.error(traceback.format_exc())
        
        logger.info(f"{source_key}에서 {len(articles)}개의 기사 수집됨")
        return articles
    
    except Exception as e:
        logger.error(f"{source_key} 뉴스 수집 오류: {e}")
        logger.error(traceback.format_exc())
        return []

# 뉴스 본문 수집 함수
def fetch_news_content(url, source_info):
    """뉴스 기사의 본문 내용 수집"""
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Accept-Language': 'ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7',
        }
        
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # 소스별 본문 선택자 사용
        content_selector = source_info.get('content_selector')
        
        content = None
        
        # 지정된 선택자로 시도
        if content_selector:
            content_element = soup.select_one(content_selector)
            if content_element:
                # 불필요한 요소 제거
                for tag in content_element.select('script, style, footer, nav, aside, iframe, ins, .related-articles, .article-ad'):
                    tag.decompose()
                
                content = content_element.get_text(strip=True)
        
        # 선택자가 없거나 내용을 찾지 못한 경우 일반적인 선택자 시도
        if not content:
            for selector in ['article', 'div.article-content', 'div.entry-content', 'div.post-content', 'div.content-area']:
                content_element = soup.select_one(selector)
                if content_element:
                    # 불필요한 요소 제거
                    for tag in content_element.select('script, style, footer, nav, aside, iframe, ins'):
                        tag.decompose()
                    
                    content = content_element.get_text(strip=True)
                    break
        
        # 여전히 내용을 찾지 못한 경우 p 태그 내용 수집
        if not content:
            paragraphs = soup.select('p')
            if paragraphs:
                content = ' '.join([p.get_text(strip=True) for p in paragraphs])
        
        # 내용 정제
        if content:
            # 연속된 공백 제거
            content = re.sub(r'\s+', ' ', content).strip()
            
            # 내용이 너무 길면 요약
            if len(content) > 2000:
                content = content[:2000] + '...'
        
        return content
    
    except Exception as e:
        logger.error(f"뉴스 본문 수집 오류 ({url}): {e}")
        logger.error(traceback.format_exc())
        return None

# RSS가 없는 사이트용 HTML 크롤링 함수 추가
def fetch_news_from_html_site(source_key, max_articles=15):
    """RSS가 없는 사이트에서 HTML 구조 기반으로 직접 뉴스 수집"""
    special_sites = {
        "decenter": {
            "list_url": "https://decenter.kr/NewsView/AllArticle",
            "list_selector": "div.list-block",
            "article_selector": "a.tit",
            "title_selector": None,  # a.tit 자체가 제목
            "date_selector": "span.byline",
            "date_regex": r"(\d{4}\.\d{2}\.\d{2}\s\d{2}:\d{2})"
        },
        "coinpan": {
            "list_url": "https://coinpan.com/free",  # 자유게시판
            "list_selector": "div.board-list",
            "article_selector": "a.item-subject",
            "title_selector": None,
            "date_selector": "div.list-time",
            "date_regex": r"(\d{2}:\d{2}|\d{2}/\d{2})"
        }
    }
    
    if source_key not in special_sites:
        logger.error(f"HTML 크롤링이 구현되지 않은 사이트: {source_key}")
        return []
    
    site_info = special_sites[source_key]
    source_info = ALL_NEWS_SOURCES.get(source_key)
    
    try:
        # 헤더 설정
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Accept-Language': 'ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7',
        }
        
        # 목록 페이지 접속
        response = requests.get(site_info['list_url'], headers=headers, timeout=15)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.text, 'html.parser')
        list_element = soup.select_one(site_info['list_selector'])
        
        if not list_element:
            logger.warning(f"{source_key} 목록 요소를 찾을 수 없음")
            return []
        
        # 기사 요소 추출
        article_elements = list_element.select(site_info['article_selector'])
        
        if not article_elements:
            logger.warning(f"{source_key} 기사 요소를 찾을 수 없음")
            return []
        
        articles = []
        today = datetime.now().strftime("%Y-%m-%d")
        
        # 각 기사 정보 추출
        for i, element in enumerate(article_elements[:max_articles]):
            try:
                # 제목 추출
                if site_info['title_selector']:
                    title_elem = element.select_one(site_info['title_selector'])
                    title = title_elem.get_text(strip=True) if title_elem else element.get_text(strip=True)
                else:
                    title = element.get_text(strip=True)
                
                # 링크 추출
                link = element.get('href')
                if link and not link.startswith(('http://', 'https://')):
                    base_url = source_info.get('base_url', '')
                    link = base_url + link
                
                # 최신 기사인지 확인 (오늘 날짜 포함 여부)
                is_today = True  # 기본값은 오늘 기사로 가정
                if site_info['date_selector']:
                    try:
                        parent = element.parent
                        date_elem = parent.select_one(site_info['date_selector'])
                        if date_elem:
                            date_text = date_elem.get_text(strip=True)
                            # 정규식으로 날짜 형식 추출
                            import re
                            date_match = re.search(site_info['date_regex'], date_text)
                            if date_match:
                                # "HH:MM" 형식이면 오늘 기사로 판단
                                date_str = date_match.group(1)
                                if ":" in date_str and "/" not in date_str:
                                    is_today = True
                                # 그 외 형식은 추가 검증 필요
                                else:
                                    # 여기서는 모든 기사를 포함 (필터링 로직 추가 가능)
                                    is_today = True
                    except Exception as e:
                        logger.error(f"날짜 추출 오류: {e}")
                
                # 최신 기사만 포함
                if is_today:
                    # 기사 정보 생성
                    article = {
                        'id': f"{source_key}_{int(time.time())}_{i}",
                        'title': title,
                        'url': link,
                        'source': source_key,
                        'timestamp': datetime.now().isoformat(),
                        'risk_level': determine_risk_level(title),
                        'language': source_info.get('language', 'ko'),
                        'related_coins': [],
                        'related_influencers': [],
                        'special_categories': []
                    }
                    
                    # 코인 관련성 체크
                    for coin_symbol in COIN_PATTERNS.keys():
                        if check_coin_relevance(title, coin_symbol):
                            article['related_coins'].append(coin_symbol)
                    
                    # 인플루언서 관련성 체크
                    is_influencer_related, related_influencers = check_influencer_relevance(title)
                    if is_influencer_related:
                        article['related_influencers'] = related_influencers
                    
                    # 특별 키워드 카테고리 체크
                    article['special_categories'] = check_special_keywords(title)
                    
                    articles.append(article)
            except Exception as e:
                logger.error(f"{source_key} 기사 처리 오류: {e}")
        
        logger.info(f"{source_key}에서 HTML 크롤링으로 {len(articles)}개의 기사 수집됨")
        return articles
    
    except Exception as e:
        logger.error(f"{source_key} HTML 크롤링 오류: {e}")
        logger.error(traceback.format_exc())
        return []

# 기사 분류 및 저장 함수
def categorize_and_save_articles(articles):
    """수집한 기사를 분류하고 저장"""
    if not articles:
        return {}
    
    # 1. 코인별 분류
    articles_by_coin = {}
    for coin in COIN_PATTERNS:
        # 코인 관련 기사 필터링
        coin_articles = []
        for article in articles:
            if coin in article.get('related_coins', []):
                coin_articles.append(article)
        
        if coin_articles:
            articles_by_coin[coin] = coin_articles
            # 코인별 뉴스 저장
            save_to_json(
                coin_articles,
                f"news/coins/{coin}_news_{datetime.now().strftime('%Y%m%d_%H%M')}.json"
            )
    
    # 2. 인플루언서별 분류
    articles_by_influencer = {}
    for influencer in INFLUENCERS:
        influencer_name = influencer['name']
        # 인플루언서 관련 기사 필터링
        influencer_articles = []
        for article in articles:
            if influencer_name in article.get('related_influencers', []):
                influencer_articles.append(article)
        
        if influencer_articles:
            articles_by_influencer[influencer_name] = influencer_articles
            # 인플루언서별 뉴스 저장
            save_to_json(
                influencer_articles,
                f"news/influencers/{influencer_name.replace(' ', '_')}_news_{datetime.now().strftime('%Y%m%d_%H%M')}.json"
            )
    
    # 3. 특별 카테고리별 분류
    articles_by_category = {}
    for category in SPECIAL_KEYWORDS.keys():
        # 카테고리 관련 기사 필터링
        category_articles = []
        for article in articles:
            if category in article.get('special_categories', []):
                category_articles.append(article)
        
        if category_articles:
            articles_by_category[category] = category_articles
            # 카테고리별 뉴스 저장
            save_to_json(
                category_articles,
                f"news/special/{category}_news_{datetime.now().strftime('%Y%m%d_%H%M')}.json"
            )
    
    # 4. 위험도별 분류
    high_risk_articles = [a for a in articles if a.get('risk_level') == "HIGH"]
    if high_risk_articles:
        save_to_json(
            high_risk_articles,
            f"news/high_risk_news_{datetime.now().strftime('%Y%m%d_%H%M')}.json"
        )
    
    # 5. 전체 뉴스 저장
    save_to_json(
        articles,
        f"news/all_news_{datetime.now().strftime('%Y%m%d_%H%M')}.json"
    )
    
    # 최신 뉴스 상태 파일 저장 (다른 모듈과의 통합용)
    latest_news_state = {
        'timestamp': datetime.now().isoformat(),
        'total_articles': len(articles),
        'coins': {coin: len(articles) for coin, articles in articles_by_coin.items()},
        'influencers': {name: len(articles) for name, articles in articles_by_influencer.items()},
        'categories': {category: len(articles) for category, articles in articles_by_category.items()},
        'high_risk_count': len(high_risk_articles),
        'latest_file': f"news/all_news_{datetime.now().strftime('%Y%m%d_%H%M')}.json"
    }
    
    save_to_json(latest_news_state, "news/latest_state.json")
    
    return {
        'by_coin': articles_by_coin,
        'by_influencer': articles_by_influencer,
        'by_category': articles_by_category,
        'high_risk': high_risk_articles
    }

# 뉴스 데이터 추출 및 공유 함수 (leverageAI.py와의 통합용)
def get_news_data_for_integration():
    """분석 모듈(leverageAI.py)과의 통합을 위한 뉴스 데이터 준비"""
    # 최신 상태 파일 확인
    latest_state = load_from_json("news/latest_state.json")
    
    if not latest_state or 'latest_file' not in latest_state:
        logger.warning("최신 뉴스 상태 파일을 찾을 수 없음")
        return None
    
    # 최신 뉴스 파일 로드
    latest_news_file = latest_state['latest_file']
    all_news = load_from_json(latest_news_file)
    
    if not all_news:
        logger.warning(f"최신 뉴스 파일을 로드할 수 없음: {latest_news_file}")
        return None
    
    # 코인별 뉴스 정보 추출
    news_by_coin = {}
    for coin in COIN_PATTERNS.keys():
        coin_news = []
        for article in all_news:
            if coin in article.get('related_coins', []):
                # 필요한 정보만 추출 (크기 축소)
                coin_news.append({
                    'id': article.get('id'),
                    'title': article.get('title'),
                    'url': article.get('url'),
                    'source': article.get('source'),
                    'timestamp': article.get('timestamp'),
                    'risk_level': article.get('risk_level'),
                    'related_influencers': article.get('related_influencers', []),
                    'special_categories': article.get('special_categories', [])
                })
        
        if coin_news:
            news_by_coin[coin] = coin_news
    
    # 인플루언서별 뉴스 정보 추출
    news_by_influencer = {}
    for influencer in INFLUENCERS:
        influencer_name = influencer['name']
        influencer_news = []
        
        for article in all_news:
            if influencer_name in article.get('related_influencers', []):
                # 필요한 정보만 추출 (크기 축소)
                influencer_news.append({
                    'id': article.get('id'),
                    'title': article.get('title'),
                    'url': article.get('url'),
                    'source': article.get('source'),
                    'timestamp': article.get('timestamp'),
                    'risk_level': article.get('risk_level'),
                    'related_coins': article.get('related_coins', []),
                    'special_categories': article.get('special_categories', [])
                })
        
        if influencer_news:
            news_by_influencer[influencer_name] = influencer_news
    
    # 중요 뉴스 정보 추출 (HIGH 리스크 레벨)
    high_risk_news = []
    for article in all_news:
        if article.get('risk_level') == "HIGH":
            # 필요한 정보만 추출 (크기 축소)
            high_risk_news.append({
                'id': article.get('id'),
                'title': article.get('title'),
                'url': article.get('url'),
                'source': article.get('source'),
                'timestamp': article.get('timestamp'),
                'related_coins': article.get('related_coins', []),
                'related_influencers': article.get('related_influencers', []),
                'special_categories': article.get('special_categories', [])
            })
    
    # 통합 데이터 구조 생성
    integration_data = {
        'timestamp': datetime.now().isoformat(),
        'by_coin': news_by_coin,
        'by_influencer': news_by_influencer,
        'high_risk': high_risk_news,
        'total_count': len(all_news),
        'source_file': latest_news_file
    }
    
    # 통합용 파일 저장
    integration_file = f"data/news_integration_{datetime.now().strftime('%Y%m%d_%H%M')}.json"
    save_to_json(integration_data, integration_file)
    
    # 최신 통합 파일 경로 저장 (다른 모듈이 참조할 수 있도록)
    integration_state = {
        'timestamp': datetime.now().isoformat(),
        'latest_file': integration_file
    }
    save_to_json(integration_state, "data/news_integration_latest.json")
    
    logger.info(f"레버리지 AI 통합을 위한 뉴스 데이터 준비 완료: {integration_file}")
    return integration_data

# 뉴스 모니터링 메인 함수
def run_news_monitoring():
    """뉴스 모니터링 메인 함수"""
    logger.info("\n====== 암호화폐 뉴스 모니터링 시작 ======")
    
    # 1. 모든 뉴스 사이트에서 기사 수집
    all_articles = fetch_all_news()
    
    # 2. 통합 데이터 생성 (leverageAI.py와의 통합용)
    integration_data = get_news_data_for_integration()
    
    # 3. 요약 정보 출력
    logger.info("\n====== 뉴스 모니터링 요약 ======")
    logger.info(f"총 수집된 기사: {len(all_articles)}개")
    
    # 코인별 기사 수 출력
    coin_counts = {}
    for article in all_articles:
        for coin in article.get('related_coins', []):
            coin_counts[coin] = coin_counts.get(coin, 0) + 1
    
    if coin_counts:
        logger.info("코인별 기사 수:")
        for coin, count in sorted(coin_counts.items(), key=lambda x: x[1], reverse=True):
            logger.info(f"- {coin}: {count}개")
    
    # 인플루언서별 기사 수 출력
    influencer_counts = {}
    for article in all_articles:
        for influencer in article.get('related_influencers', []):
            influencer_counts[influencer] = influencer_counts.get(influencer, 0) + 1
    
    if influencer_counts:
        logger.info("인플루언서별 기사 수:")
        for influencer, count in sorted(influencer_counts.items(), key=lambda x: x[1], reverse=True):
            logger.info(f"- {influencer}: {count}개")
    
    # 특별 카테고리별 기사 수 출력
    category_counts = {}
    for article in all_articles:
        for category in article.get('special_categories', []):
            category_counts[category] = category_counts.get(category, 0) + 1
    
    if category_counts:
        logger.info("특별 카테고리별 기사 수:")
        for category, count in sorted(category_counts.items(), key=lambda x: x[1], reverse=True):
            logger.info(f"- {category}: {count}개")
    
    # 위험 수준별 기사 수 출력
    risk_counts = {'HIGH': 0, 'MEDIUM': 0, 'LOW': 0}
    for article in all_articles:
        risk_level = article.get('risk_level', 'LOW')
        risk_counts[risk_level] = risk_counts.get(risk_level, 0) + 1
    
    logger.info("위험 수준별 기사 수:")
    for risk_level, count in risk_counts.items():
        logger.info(f"- {risk_level}: {count}개")
    
    logger.info("====== 암호화폐 뉴스 모니터링 완료 ======\n")
    return all_articles

# 메인 실행 함수
def main():
    """메인 실행 함수"""
    try:
        # 필요한 디렉토리 생성
        ensure_directories_exist()
        
        logger.info("===== 실시간 암호화폐 뉴스 모니터링 시스템 시작 =====")
        
        # 첫 실행
        run_news_monitoring()
        
        # 스케줄러 설정 (10분마다)
        schedule.every(10).minutes.do(run_news_monitoring)
        
        # 메인 루프
        logger.info("스케줄링 시작... (Ctrl+C로 중지)")
        while True:
            schedule.run_pending()
            time.sleep(1)
            
    except KeyboardInterrupt:
        logger.info("\n프로그램 종료...")
    except Exception as e:
        logger.error(f"\n⚠️ 오류 발생: {e}")
        logger.error(traceback.format_exc())

# 프로그램 시작
if __name__ == "__main__":
    main()