# CryptoLeverageAI Backend

AI 기반 암호화폐 레버리지 자동 거래 시스템 백엔드

## 🚀 시스템 개요

PRD 기반으로 구현된 통합 트레이딩 시스템:

- **뉴스 수집**: 한국 암호화폐 뉴스 실시간 크롤링
- **트위터 모니터링**: 주요 인플루언서 (일론 머스크, 트럼프 등) 트윗 수집
- **Claude API 감정 분석**: AI 기반 시장 심리 분석
- **기술적 분석**: MACD, RSI, 볼린저 밴드
- **3계층 검증**: 신호 신뢰도 검증 시스템
- **자동 거래 실행**: Binance API 연동
- **리스크 관리**: 포지션 사이징, 손절/익절 자동화

## 📁 디렉토리 구조

```
backend/
├── main.py                      # FastAPI 메인 서버
├── sentiment_analyzer.py        # Claude API 감정 분석
├── twitter_monitor.py           # 트위터 모니터링
├── signal_generator.py          # 시그널 생성 (기술적 분석)
├── position_manager.py          # 포지션 관리
├── risk_manager.py              # 리스크 관리
├── firestore_service.py         # Firebase Firestore 연동
├── requirements.txt             # Python 의존성
└── README.md                    # 이 파일
```

## 🛠️ 설치 방법

### 1. Python 환경 설정

```bash
# Python 3.9 이상 필요
python --version

# 가상환경 생성 (선택사항)
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
```

### 2. 의존성 설치

```bash
cd backend
pip install -r requirements.txt
```

**참고**: `ta-lib` 설치 시 시스템에 TA-Lib C 라이브러리가 필요합니다.

```bash
# macOS
brew install ta-lib

# Ubuntu/Debian
sudo apt-get install ta-lib

# Windows
# https://github.com/TA-Lib/ta-lib-python#windows 참고
```

### 3. 환경 변수 설정

`.env` 파일 생성:

```env
# Anthropic Claude API
ANTHROPIC_API_KEY=your_claude_api_key_here

# Binance API (거래 실행용)
BINANCE_API_KEY=your_binance_api_key
BINANCE_SECRET=your_binance_secret
BINANCE_TESTNET=True  # 테스트넷 사용 여부

# Twitter API (선택사항, 실제 API 연동 시)
TWITTER_BEARER_TOKEN=your_twitter_bearer_token

# Firebase (선택사항, 인증 파일 사용 시)
GOOGLE_APPLICATION_CREDENTIALS=path/to/firebase-credentials.json
```

### 4. Firebase 설정

Firebase 프로젝트 (`emotra-9ebdb`) 인증 파일을 다운로드하여 프로젝트 루트에 배치:

```bash
# Firebase Console에서 서비스 계정 키 다운로드
# 파일명: emotra-9ebdb-firebase-adminsdk-xxxxx.json
```

## 🚦 실행 방법

### 개발 모드 (자동 재시작)

```bash
cd backend
python main.py
```

또는

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 프로덕션 모드

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
```

## 📡 API 엔드포인트

### 기본

- `GET /` - API 상태 확인
- `GET /docs` - Swagger UI (자동 문서화)

### 신호 관리

- `GET /api/signals` - 신호 목록 조회
- `GET /api/signals?status=analyzing` - 상태별 신호 조회

### 포지션 관리

- `GET /api/positions` - 포지션 목록 조회
- `GET /api/positions?status=open` - 열린 포지션 조회

### 성과

- `GET /api/performance` - 성과 통계 조회

### 수동 거래

- `POST /api/manual-trade` - 수동 거래 실행

Request Body:
```json
{
  "symbol": "BTC/USDT",
  "side": "buy",
  "leverage": 5,
  "amount": 100.0
}
```

### WebSocket

- `WS /ws` - 실시간 데이터 스트리밍

## 🔄 자동 스케줄링

시스템 시작 시 자동으로 실행되는 작업:

1. **데이터 수집** (5분마다)
   - 한국 뉴스 크롤링
   - 트위터 인플루언서 모니터링
   - Claude API 감정 분석
   - Firestore 저장

2. **거래 신호 분석** (1분마다)
   - Firestore에서 분석 중인 신호 조회
   - 기술적 분석 수행
   - 3계층 검증
   - 조건 충족 시 거래 실행

3. **포지션 모니터링** (30초마다)
   - 열린 포지션 상태 확인
   - 손익 계산
   - 손절/익절 체크
   - 필요 시 자동 청산

## 🧪 테스트

각 모듈 개별 테스트:

```bash
# 감정 분석 테스트
python sentiment_analyzer.py

# 트위터 모니터링 테스트
python twitter_monitor.py

# 시그널 생성 테스트
python signal_generator.py

# 포지션 관리 테스트
python position_manager.py

# 리스크 관리 테스트
python risk_manager.py

# Firestore 서비스 테스트
python firestore_service.py
```

## ⚙️ 설정

### 리스크 매개변수 (risk_manager.py)

```python
max_risk_per_trade = 0.02  # 거래당 2%
max_total_exposure = 0.20  # 전체 노출 20%
max_daily_loss = 0.05      # 일일 최대 손실 5%
```

### 레버리지 제한 (신뢰도별)

| 신뢰도 레벨 | 레버리지 범위 | 손절 비율 |
|------------|--------------|----------|
| Highest (3계층) | 5-10배 | 3% |
| High (2계층) | 3-5배 | 5% |
| Medium (1계층) | 2-3배 | 7% |

### 모니터링 대상 인플루언서

- **Elon Musk** (@elonmusk) - DOGE, SHIB, FLOKI, BTC
- **Donald Trump** (@realDonaldTrump) - TRUMP, MAGA, BTC, ETH
- **Michael Saylor** (@saylor) - BTC
- **Vitalik Buterin** (@VitalikButerin) - ETH

## 📊 Firestore 데이터 구조

### signals 컬렉션

```javascript
{
  timestamp: Date,
  source: 'twitter|news|official',
  author: 'elonmusk',
  content: '트윗/뉴스 내용',
  sentiment: 0.8,  // -1.0 ~ 1.0
  coins: ['BTC', 'DOGE'],
  impact_score: 75,  // 0 ~ 100
  confidence: 0.85,  // 0 ~ 1.0
  verification_layers: {
    layer1: true,
    layer2: false,
    layer3: false
  },
  status: 'analyzing|verified|executed|rejected'
}
```

### positions 컬렉션

```javascript
{
  trade_id: 'BTC/USDT_buy_1234567890',
  symbol: 'BTC/USDT',
  side: 'buy|sell',
  leverage: 5,
  entry_price: 45000,
  amount: 100,
  quantity: 0.00222,
  stop_loss: 43500,
  take_profit: 49500,
  status: 'open|closed',
  pnl: 0,
  executed_at: Date,
  closed_at: Date
}
```

## 🐛 문제 해결

### TA-Lib 설치 오류

```bash
# macOS
brew install ta-lib
pip install ta-lib

# TA-Lib가 설치되지 않으면 기술적 분석 기능이 제한됩니다
```

### Firebase 인증 오류

1. Firebase Console에서 서비스 계정 키 다운로드
2. 프로젝트 루트에 파일 배치
3. 환경 변수 설정 또는 `firestore_service.py` 경로 수정

### Binance API 오류

1. API 키 권한 확인 (거래 권한 필요)
2. 테스트넷 사용 권장 (`BINANCE_TESTNET=True`)
3. IP 화이트리스트 확인

## 📝 로그

로그 파일 위치:
- 콘솔 출력: 실시간 로그
- 파일 저장: (필요 시 설정)

로그 레벨:
- `INFO`: 일반 작동 정보
- `WARNING`: 주의 필요
- `ERROR`: 오류 발생

## 🔒 보안 주의사항

1. **API 키 보안**
   - `.env` 파일을 Git에 커밋하지 마세요
   - 프로덕션 환경에서는 환경 변수 사용

2. **Firebase 인증**
   - 서비스 계정 키를 안전하게 보관
   - Firestore 보안 규칙 설정

3. **거래 권한**
   - 테스트 단계에서는 테스트넷 사용
   - 실제 거래 전 충분한 테스트 필수

## 📞 지원

문제가 발생하면:
1. 로그 확인
2. 환경 변수 확인
3. API 키 권한 확인
4. Issue 등록

## 📜 라이선스

이 프로젝트는 개인/교육용으로만 사용하세요.
실제 거래에는 충분한 테스트와 리스크 관리가 필요합니다.
