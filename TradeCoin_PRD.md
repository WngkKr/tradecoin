# TradeCoin PRD (Product Requirements Document)

## 1. 제품 개요

### 1.1 프로젝트명
**TradeCoin Mobile Web Platform**

### 1.2 제품 비전
AI 기반 감정 분석과 기술적 분석을 결합한 차세대 암호화폐 자동 트레이딩 플랫폼
징릐 답변은 항상 한글로 해줘

### 1.3 목표
- 실시간 뉴스/소셜미디어 감정 분석을 통한 스마트 트레이딩
- 사용자 친화적인 모바일 웹 인터페이스 제공
- 자동화된 포트폴리오 관리 및 리스크 컨트롤

## 2. 핵심 기능 순서 및 상세

### 2.1 데이터 수집 레이어 (Backend)

#### 2.1.1 실시간 뉴스 모니터링
**기능**: `realtimeNS.py`
- **순서**: 1단계 - 기본 데이터 수집
- **세부 기능**:
  - 한국 암호화폐 뉴스 사이트 실시간 스크래핑
    - 코인리더스 (coinreaders.com)
    - 디센터 (decenter.kr) 
    - 토큰포스트 (tokenpost.kr)
  - BeautifulSoup 기반 콘텐츠 파싱
  - 5분 간격 자동 수집 스케줄링
- **데이터 저장**: `/news/` 디렉토리에 JSON 형태

#### 2.1.2 인플루언서 소셜미디어 모니터링
**기능**: `reverageAI.py`
- **순서**: 2단계 - 감정 데이터 수집
- **세부 기능**:
  - 타겟 인플루언서 모니터링
    - 일론 머스크 (@elonmusk) → DOGE, SHIB, FLOKI
    - 도널드 트럼프 (@realDonaldTrump) → TRUMP, MAGA
    - 마이클 세일러 (@saylor) → BTC
    - 비탈릭 부테린 (@VitalikButerin) → ETH
  - 트윗 콘텐츠 실시간 수집
  - 코인별 연관성 분석
- **데이터 저장**: `/tweets/` 디렉토리에 JSON 형태

### 2.2 AI 분석 레이어

#### 2.2.1 감정 분석 엔진
**기능**: Claude API 기반 분석
- **순서**: 3단계 - 데이터 해석
- **세부 기능**:
  - 뉴스 콘텐츠 감정 스코어링 (positive/negative/neutral)
  - 트윗 영향도 분석
  - 신뢰도 점수 계산 (0-100)
  - 예상 가격 변동률 예측
- **출력**: 통합 감정 분석 결과

#### 2.2.2 기술적 분석
**기능**: `BaseTradingStrategy.py` + 각종 지표
- **순서**: 4단계 - 기술적 검증
- **세부 기능**:
  - MACD (Moving Average Convergence Divergence)
  - RSI (Relative Strength Index) 
  - 볼린저 밴드 (Bollinger Bands)
  - 복합 전략 조합 및 가중치 적용
- **가중치 시스템**:
  - MACD: 1.0
  - RSI: 0.8  
  - BB: 0.6

### 2.3 신호 생성 및 의사결정

#### 2.3.1 통합 시그널 생성
**기능**: 감정분석 + 기술분석 융합
- **순서**: 5단계 - 매매 신호 생성
- **세부 기능**:
  - 감정 분석 결과와 기술적 분석 결과 가중 평균
  - 신뢰도 임계값 기반 필터링 (기본 65%)
  - 리스크 레벨 분류 (Low/Medium/High)
  - 추천 액션 도출 (Buy/Sell/Hold)
- **최적 진입/청산 시점 예측**:
  - 진입 윈도우: 즉시 ~ 10분
  - 청산 윈도우: 12분 ~ 30분

#### 2.3.2 포지션 관리
**기능**: `BitcoinTradingBot.py`
- **순서**: 6단계 - 실제 거래 실행
- **세부 기능**:
  - 바이낸스 API 연동
  - 레버리지 거래 실행 (기본 5배)
  - 자동 손절매/익절 (손절: 3%, 익절: 10%)
  - 최대 동시 포지션 제한 (2개)
  - 포지션 크기 제한 (자금의 5%)

## 3. 모바일 웹 UI/UX 명세

### 3.1 디자인 철학
**참고**: Canva + Muzli 모던 디자인 트렌드

#### 3.1.1 컬러 팔레트
```css
/* Primary Colors */
--primary-blue: #2E54FF;     /* 메인 액션 버튼 */
--success-green: #009649;    /* 수익/상승 표시 */
--danger-red: #FF4757;       /* 손실/하락 표시 */
--warning-orange: #FFA726;   /* 경고/대기 상태 */

/* Neutral Colors */
--background: #F8F9FA;       /* 메인 배경 */
--surface: #FFFFFF;          /* 카드 배경 */
--surface-alt: #F2F2F2;      /* 보조 배경 */
--border: #E5E5E5;           /* 경계선 */
--text-primary: #1A1A1A;     /* 메인 텍스트 */
--text-secondary: #6B7280;   /* 보조 텍스트 */
--text-disabled: #9CA3AF;    /* 비활성 텍스트 */
```

#### 3.1.2 타이포그래피
```css
/* Font Family */
font-family: 'Poppins', -apple-system, BlinkMacSystemFont, sans-serif;

/* Font Weights & Sizes */
--font-light: 300;
--font-regular: 400;
--font-medium: 500;
--font-semibold: 600;

--text-xs: 12px;      /* 캡션, 라벨 */
--text-sm: 14px;      /* 보조 정보 */
--text-base: 16px;    /* 기본 텍스트 */
--text-lg: 18px;      /* 소제목 */
--text-xl: 20px;      /* 제목 */
--text-2xl: 24px;     /* 큰 제목 */
--text-3xl: 32px;     /* 헤더 */
```

### 3.2 화면 구성 및 레이아웃

#### 3.2.1 메인 대시보드
```
┌─────────────────────────────────┐
│ [📊] TradeCoin        [⚙️] [👤] │ ← Header (고정)
├─────────────────────────────────┤
│ 💰 총 자산: $12,543.21         │
│ 📈 오늘 수익: +$234.12 (+1.9%) │ ← 자산 현황 카드
├─────────────────────────────────┤
│ 🔥 실시간 시그널                │
│ ┌─────┬─────────────┬─────────┐ │
│ │BTC  │ 📈 BUY 85%  │ 🟢 진행중│ │
│ │DOGE │ 📉 SELL 72% │ 🟡 대기 │ │ ← 시그널 리스트
│ │ETH  │ ⏸️ HOLD 45% │ ⚪ 보류 │ │
│ └─────┴─────────────┴─────────┘ │
├─────────────────────────────────┤
│ 📊 포트폴리오 차트              │ ← 차트 영역
├─────────────────────────────────┤
│ 📰 주요 뉴스 & 트윗             │
│ • 일론 머스크: "Doge to moon!" │
│ • 비트코인 ETF 승인 소식...     │ ← 뉴스 피드
└─────────────────────────────────┘
```

#### 3.2.2 시그널 상세 페이지
```
┌─────────────────────────────────┐
│ [←] BTC 매수 시그널             │
├─────────────────────────────────┤
│ 🎯 신뢰도: 85%                  │
│ 📊 예상수익: +12%               │
│ ⚠️ 리스크: Medium               │
│ ⏰ 진입시점: 즉시~5분           │
├─────────────────────────────────┤
│ 📈 기술적 분석                  │
│ • MACD: 강세 전환               │
│ • RSI: 과매도 구간 벗어남       │
│ • 볼린저: 하단 반등             │
├─────────────────────────────────┤
│ 📰 감정 분석                    │
│ • 긍정 뉴스: 67%                │
│ • 소셜미디어: 78%               │
│ • 전체 심리: 낙관적             │
├─────────────────────────────────┤
│ [🚀 자동거래 실행] [📋 수동설정] │
└─────────────────────────────────┘
```

#### 3.2.3 포트폴리오 관리
```
┌─────────────────────────────────┐
│ 📊 내 포트폴리오                │
├─────────────────────────────────┤
│ 💰 총 자산: $12,543.21          │
│ 📈 총 수익률: +18.7%            │
├─────────────────────────────────┤
│ 🏃‍♂️ 활성 포지션 (2/2)            │
│ ┌─BTC Long x5────────────────┐  │
│ │ 진입: $67,234              │  │
│ │ 현재: $68,901 (+2.5%)      │  │
│ │ [📈 차트] [⚙️ 관리]         │  │
│ └────────────────────────────┘  │
│ ┌─DOGE Short x3───────────────┐ │
│ │ 진입: $0.285               │  │
│ │ 현재: $0.276 (+3.2%)       │  │
│ │ [📈 차트] [⚙️ 관리]         │  │
│ └────────────────────────────┘  │
├─────────────────────────────────┤
│ 📊 성과 분석                    │
│ • 승률: 73% (22승 8패)          │
│ • 평균 수익률: +5.2%            │
│ • 최대 손실: -8.1%              │
└─────────────────────────────────┘
```

### 3.3 UI 컴포넌트 명세

#### 3.3.1 시그널 카드
```css
.signal-card {
  background: linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%);
  border-radius: 16px;
  box-shadow: 0 4px 16px rgba(0,0,0,0.08);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(229,229,229,0.5);
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.signal-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(0,0,0,0.12);
}
```

#### 3.3.2 신뢰도 게이지
```jsx
<div className="confidence-gauge">
  <div className="gauge-track">
    <div 
      className="gauge-fill" 
      style={{width: `${confidence}%`}}
    />
  </div>
  <span className="confidence-value">{confidence}%</span>
</div>
```

#### 3.3.3 액션 버튼
```css
.action-button {
  background: linear-gradient(135deg, var(--primary-blue) 0%, #1e3fcc 100%);
  border-radius: 12px;
  padding: 14px 24px;
  color: white;
  font-weight: 600;
  transition: all 0.3s ease;
  box-shadow: 0 4px 12px rgba(46,84,255,0.3);
}

.action-button:active {
  transform: scale(0.98);
}
```

### 3.4 반응형 디자인

#### 3.4.1 Grid System
```css
.layout-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 16px;
  padding: 16px;
}

@media (max-width: 768px) {
  .layout-grid {
    grid-template-columns: 1fr;
    gap: 12px;
    padding: 12px;
  }
}
```

#### 3.4.2 모바일 네비게이션
```
┌─────────────────────────────────┐
│                                 │
│         메인 콘텐츠              │
│                                 │
├─────────────────────────────────┤
│ [🏠] [📊] [🔔] [📰] [👤]        │ ← Bottom Navigation
└─────────────────────────────────┘
```

## 4. 기술 스택

### 4.1 Backend
- **Python**: 메인 언어
- **FastAPI**: API 서버
- **SQLite/PostgreSQL**: 데이터베이스
- **Redis**: 캐싱
- **APScheduler**: 작업 스케줄링

### 4.2 Frontend (Mobile Web)
- **React 18**: UI 프레임워크
- **TypeScript**: 타입 안전성
- **Tailwind CSS**: 유틸리티 CSS
- **Chart.js**: 차트 라이브러리
- **PWA**: 프로그레시브 웹 앱

### 4.3 AI/ML
- **Claude API** (Anthropic): 감정 분석
- **OpenAI API**: 보조 분석
- **TA-Lib**: 기술적 분석

### 4.4 External APIs
- **Binance API**: 거래 실행
- **CoinGecko API**: 가격 데이터
- **News APIs**: 뉴스 데이터

## 5. 성능 요구사항

### 5.1 응답시간
- **API 응답**: < 500ms
- **페이지 로딩**: < 2s
- **시그널 생성**: < 30s

### 5.2 데이터 처리
- **뉴스 수집**: 5분 간격
- **가격 업데이트**: 1분 간격
- **시그널 갱신**: 실시간

### 5.3 확장성
- **동시 사용자**: 1,000명
- **일일 거래**: 10,000건
- **데이터 저장**: 1년치 이력

## 6. 보안 및 컴플라이언스

### 6.1 API 보안
- **JWT 토큰**: 인증/인가
- **Rate Limiting**: API 호출 제한
- **HTTPS**: 모든 통신 암호화

### 6.2 거래 보안
- **2FA**: 이중 인증
- **API Key 암호화**: 민감정보 보호
- **거래 한도**: 일일/월간 제한

## 7. 배포 및 운영

### 7.1 배포 환경
- **Production**: AWS/GCP
- **Development**: Local Docker
- **CI/CD**: GitHub Actions

### 7.2 모니터링
- **로깅**: ELK Stack
- **메트릭**: Prometheus + Grafana
- **알림**: Slack/Discord 연동