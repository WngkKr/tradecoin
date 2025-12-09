# TradeCoin PRD (Product Requirements Document)

무조건 한글로 설명!!!!

## 1. 제품 개요

### 1.1 프로젝트명
**TradeCoin Mobile Web Platform**

### 1.2 제품 비전
AI 기반 감정 분석과 기술적 분석을 결합한 차세대 암호화폐 자동 트레이딩 플랫폼

### 1.3 목표
- 실시간 뉴스/소셜미디어 감정 분석을 통한 스마트 트레이딩
- 사용자 친화적인 모바일 웹 인터페이스 제공
- 자동화된 포트폴리오 관리 및 리스크 컨트롤

## 2. 회원 관리 및 인증 시스템

### 2.1 Firebase 인증 및 사용자 관리
**Project ID**: `emotra-9ebdb`

#### 2.1.1 사용자 인증 프로세스
**순서**: 0단계 - 사용자 진입점
- **회원가입/로그인 방식**:
  - 이메일/패스워드
  - 구글 소셜 로그인
  - 애플 소셜 로그인 (iOS)
  - 카카오 소셜 로그인 (한국 사용자)
- **보안 강화**:
  - Firebase Authentication
  - 이메일 인증 필수
  - 2단계 인증 (2FA) 옵션
  - 비정상 로그인 감지 및 알림

#### 2.1.2 회원 등급 및 정책

##### 2.1.2.1 멤버십 등급 시스템
```
🆓 Free Tier (무료)
├── 기본 시그널 조회 (일 3개 제한)
├── 뉴스 피드 접근
├── 기본 포트폴리오 추적
└── 광고 표시

💎 Premium (월 $29.99)
├── 무제한 시그널 접근
├── 실시간 알림 (푸시, 이메일)
├── 고급 기술 분석 도구
├── 자동 거래 연동 (기본)
├── 월간 성과 리포트
└── 광고 제거

👑 Pro (월 $99.99)
├── Premium 모든 기능
├── AI 맞춤형 전략 추천
├── 고급 자동거래 설정
├── 1:1 전담 지원
├── API 접근 권한
├── 백테스팅 도구
└── 우선순위 신규 기능 접근

🏆 Enterprise (월 $299.99)
├── Pro 모든 기능
├── 무제한 API 호출
├── 커스텀 알고리즘 개발 지원
├── 전용 서버 자원
├── 실시간 컨설팅
└── 맞춤형 대시보드
```

##### 2.1.2.2 사용량 제한 정책
```javascript
// Firebase Firestore 사용자 제한 규칙
const USER_LIMITS = {
  free: {
    signalsPerDay: 3,
    portfolioAssets: 3,
    apiCallsPerHour: 10,
    historicalDataDays: 7,
    notifications: false,
    autoTrading: false
  },
  premium: {
    signalsPerDay: Infinity,
    portfolioAssets: 10,
    apiCallsPerHour: 100,
    historicalDataDays: 90,
    notifications: true,
    autoTrading: 'basic'
  },
  pro: {
    signalsPerDay: Infinity,
    portfolioAssets: 50,
    apiCallsPerHour: 1000,
    historicalDataDays: 365,
    notifications: true,
    autoTrading: 'advanced'
  },
  enterprise: {
    signalsPerDay: Infinity,
    portfolioAssets: Infinity,
    apiCallsPerHour: Infinity,
    historicalDataDays: Infinity,
    notifications: true,
    autoTrading: 'custom'
  }
};
```

#### 2.1.3 사용자 온보딩 프로세스
**순서**: 0-1단계 - 신규 사용자 가이드

##### Step 1: 회원가입 및 프로필 설정
```
┌─────────────────────────────────┐
│ 🚀 TradeCoin에 오신 것을 환영합니다 │
├─────────────────────────────────┤
│ [📧 이메일로 시작하기]            │
│ [🔍 구글로 시작하기]             │
│ [🍎 애플로 시작하기]             │
│ [💬 카카오로 시작하기]            │
├─────────────────────────────────┤
│ ✅ 이용약관 동의                 │
│ ✅ 개인정보처리방침 동의          │
│ ⭕ 마케팅 수신 동의 (선택)        │
└─────────────────────────────────┘
```

##### Step 2: 투자 성향 설문
```
┌─────────────────────────────────┐
│ 📊 투자 프로필 설정              │
├─────────────────────────────────┤
│ 💰 투자 경험은 어느 정도인가요?    │
│ ○ 초보자 (1년 미만)             │
│ ○ 중급자 (1-3년)               │
│ ○ 고급자 (3년 이상)             │
├─────────────────────────────────┤
│ ⚡ 선호하는 리스크 수준은?         │
│ ○ 안전 추구형 (저위험)           │
│ ○ 균형 추구형 (중위험)           │
│ ○ 수익 추구형 (고위험)           │
├─────────────────────────────────┤
│ 🎯 주요 관심 코인 선택 (최대 5개)  │
│ ☑️ BTC  ☑️ ETH  ⬜ DOGE      │
│ ⬜ SHIB ⬜ FLOKI ⬜ TRUMP     │
└─────────────────────────────────┘
```

##### Step 3: 맞춤 대시보드 생성
```
┌─────────────────────────────────┐
│ 🎨 대시보드 개인화               │
├─────────────────────────────────┤
│ 📈 시그널 알림 설정              │
│ • 신뢰도 임계값: 75% 이상        │
│ • 푸시 알림: ON                 │
│ • 이메일 요약: 일 1회            │
├─────────────────────────────────┤
│ 💎 멤버십 업그레이드              │
│ [🆓 무료로 시작] [💎 Premium 체험]│
└─────────────────────────────────┘
```

### 2.2 사용자 데이터 스키마 (Firebase Firestore)

#### 2.2.1 Users Collection
```javascript
// users/{userId}
{
  uid: string,
  email: string,
  displayName: string,
  photoURL: string,
  phoneNumber?: string,
  
  // 멤버십 정보
  subscription: {
    tier: 'free' | 'premium' | 'pro' | 'enterprise',
    status: 'active' | 'cancelled' | 'expired',
    startDate: Timestamp,
    endDate: Timestamp,
    autoRenew: boolean
  },
  
  // 투자 프로필
  profile: {
    experienceLevel: 'beginner' | 'intermediate' | 'advanced',
    riskTolerance: 'conservative' | 'moderate' | 'aggressive',
    preferredCoins: string[],
    investmentGoal: string,
    monthlyBudget?: number
  },
  
  // 설정
  settings: {
    notifications: {
      push: boolean,
      email: boolean,
      sms: boolean,
      signalThreshold: number
    },
    trading: {
      autoTrading: boolean,
      maxPositions: number,
      maxLeverage: number,
      stopLoss: number,
      takeProfit: number
    }
  },
  
  // 통계
  stats: {
    signalsUsed: number,
    tradesExecuted: number,
    totalPnL: number,
    winRate: number,
    lastLogin: Timestamp
  },
  
  // 메타데이터
  createdAt: Timestamp,
  updatedAt: Timestamp,
  isActive: boolean,
  version: number
}
```

#### 2.2.2 User Portfolios Collection
```javascript
// userPortfolios/{userId}/assets/{assetId}
{
  symbol: string,
  name: string,
  amount: number,
  averagePrice: number,
  currentPrice: number,
  pnl: number,
  pnlPercent: number,
  addedAt: Timestamp,
  updatedAt: Timestamp
}
```

#### 2.2.3 User Activity Collection
```javascript
// userActivity/{userId}/actions/{actionId}
{
  type: 'signal_view' | 'trade_execute' | 'portfolio_update',
  data: any,
  timestamp: Timestamp,
  metadata: {
    ip: string,
    userAgent: string,
    platform: 'web' | 'mobile'
  }
}
```

## 3. 핵심 기능 순서 및 상세

### 3.1 데이터 수집 레이어 (Backend)

#### 3.1.1 실시간 뉴스 모니터링
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

#### 3.1.2 인플루언서 소셜미디어 모니터링
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

### 3.2 AI 분석 레이어

#### 3.2.1 감정 분석 엔진
**기능**: Claude API 기반 분석
- **순서**: 3단계 - 데이터 해석
- **세부 기능**:
  - 뉴스 콘텐츠 감정 스코어링 (positive/negative/neutral)
  - 트윗 영향도 분석
  - 신뢰도 점수 계산 (0-100)
  - 예상 가격 변동률 예측
- **출력**: 통합 감정 분석 결과

#### 3.2.2 기술적 분석
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

### 3.3 신호 생성 및 의사결정

#### 3.3.1 통합 시그널 생성
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

#### 3.3.2 포지션 관리
**기능**: `BitcoinTradingBot.py`
- **순서**: 6단계 - 실제 거래 실행
- **세부 기능**:
  - 바이낸스 API 연동
  - 레버리지 거래 실행 (기본 5배)
  - 자동 손절매/익절 (손절: 3%, 익절: 10%)
  - 최대 동시 포지션 제한 (2개)
  - 포지션 크기 제한 (자금의 5%)

## 4. 모바일 웹 UI/UX 명세

### 4.1 디자인 철학
**참고**: Dark Mode NFT App Design - 프리미엄 다크 테마 및 글래스모피즘

#### 4.1.1 컬러 팔레트 (Dark Mode NFT Style)
```css
/* Primary Colors - Dark Purple Gradient */
--primary-gradient: linear-gradient(135deg, #6B46C1 0%, #8B5CF6 50%, #A855F7 100%);
--primary-purple: #8B5CF6;   /* 메인 액션 버튼 */
--secondary-purple: #A855F7; /* 강조 요소 */
--accent-purple: #C084FC;    /* 액센트 컬러 */

/* Status Colors */
--success-green: #10B981;    /* 수익/상승 표시 */
--danger-red: #EF4444;       /* 손실/하락 표시 */
--warning-yellow: #F59E0B;   /* 경고/대기 상태 */

/* Dark Theme Base */
--background: linear-gradient(135deg, #1E1B4B 0%, #312E81 50%, #3730A3 100%);
--surface: rgba(255, 255, 255, 0.1);        /* 글래스모피즘 카드 */
--surface-hover: rgba(255, 255, 255, 0.15);  /* 호버 상태 */
--surface-border: rgba(255, 255, 255, 0.2);  /* 카드 테두리 */

/* Glass Effect */
--glass-bg: rgba(255, 255, 255, 0.1);
--glass-border: rgba(255, 255, 255, 0.2);
--glass-shadow: 0 8px 32px rgba(0, 0, 0, 0.37);
--backdrop-blur: blur(16px);

/* Text Colors */
--text-primary: #FFFFFF;     /* 메인 텍스트 */
--text-secondary: rgba(255, 255, 255, 0.8);   /* 보조 텍스트 */
--text-tertiary: rgba(255, 255, 255, 0.6);    /* 삼차 텍스트 */
--text-disabled: rgba(255, 255, 255, 0.4);    /* 비활성 텍스트 */
```

#### 4.1.2 타이포그래피
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

### 4.2 화면 구성 및 레이아웃

#### 4.2.1 로그인/회원가입 화면
```
┌─────────────────────────────────┐
│ 🚀 TradeCoin                    │
│    AI 트레이딩 플랫폼             │
├─────────────────────────────────┤
│ 📧 이메일                       │
│ [example@email.com            ] │
│ 🔒 비밀번호                     │
│ [••••••••••••••••••••••••••••] │
├─────────────────────────────────┤
│ [💎 로그인하기]                  │
│                                 │
│ ──────── 또는 ────────          │
│                                 │
│ [🔍 Google] [🍎 Apple] [💬 Kakao]│
├─────────────────────────────────┤
│ 계정이 없으신가요?                │
│ [회원가입하기] [비밀번호 찾기]     │
└─────────────────────────────────┘
```

#### 4.2.2 온보딩 화면
```
┌─────────────────────────────────┐
│ [●○○] 투자 경험 선택             │
├─────────────────────────────────┤
│ 💰 암호화폐 투자 경험은?          │
│                                 │
│ 🔰 초보자 (1년 미만)             │
│ • 기본 전략 추천                │
│ • 상세한 가이드 제공             │
│                                 │
│ 📈 중급자 (1-3년)               │
│ • 균형잡힌 포트폴리오            │
│ • 중급 분석 도구                │
│                                 │
│ 🎯 고급자 (3년 이상)             │
│ • 고급 전략 및 도구              │
│ • 맞춤형 알고리즘               │
├─────────────────────────────────┤
│ [건너뛰기]              [다음] │
└─────────────────────────────────┘
```

#### 4.2.3 메인 대시보드
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

#### 4.2.4 시그널 상세 페이지
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

#### 4.2.5 포트폴리오 관리
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

#### 4.2.6 멤버십 관리 화면
```
┌─────────────────────────────────┐
│ 👤 내 멤버십                    │
├─────────────────────────────────┤
│ 현재 플랜: 🆓 Free              │
│ 만료일: -                       │
│ 사용량: 2/3 시그널 (오늘)        │
├─────────────────────────────────┤
│ 💎 Premium ($29.99/월)          │
│ ✅ 무제한 시그널                │
│ ✅ 실시간 알림                  │
│ ✅ 광고 제거                    │
│ [7일 무료체험 시작]              │
├─────────────────────────────────┤
│ 👑 Pro ($99.99/월)              │
│ ✅ Premium 모든 기능             │
│ ✅ AI 맞춤 전략                 │
│ ✅ 자동거래 연동                │
│ [업그레이드]                    │
├─────────────────────────────────┤
│ 🏆 Enterprise ($299.99/월)      │
│ ✅ Pro 모든 기능                │
│ ✅ API 접근                     │
│ ✅ 전담 지원                    │
│ [문의하기]                      │
└─────────────────────────────────┘
```

### 4.3 UI 컴포넌트 명세

#### 4.3.1 시그널 카드 (Glass Morphism)
```css
.signal-card {
  background: var(--glass-bg);
  backdrop-filter: var(--backdrop-blur);
  -webkit-backdrop-filter: var(--backdrop-blur);
  border-radius: 20px;
  border: 1px solid var(--glass-border);
  box-shadow: var(--glass-shadow);
  transition: all 0.3s cubic-bezier(0.4, 0.0, 0.2, 1);
  position: relative;
  overflow: hidden;
}

.signal-card:hover {
  transform: translateY(-4px) scale(1.02);
  background: var(--surface-hover);
  box-shadow: 0 12px 40px rgba(0, 0, 0, 0.5);
  border: 1px solid rgba(255, 255, 255, 0.3);
}

.signal-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 1px;
  background: linear-gradient(90deg, transparent, rgba(255,255,255,0.4), transparent);
}
```

#### 4.3.2 신뢰도 게이지
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

#### 4.3.3 액션 버튼 (Purple Gradient)
```css
.action-button {
  background: var(--primary-gradient);
  border-radius: 16px;
  padding: 16px 32px;
  color: var(--text-primary);
  font-weight: 600;
  font-size: 16px;
  border: 1px solid rgba(255, 255, 255, 0.2);
  backdrop-filter: blur(10px);
  transition: all 0.3s cubic-bezier(0.4, 0.0, 0.2, 1);
  box-shadow: 
    0 4px 20px rgba(139, 92, 246, 0.4),
    inset 0 1px 0 rgba(255, 255, 255, 0.2);
  position: relative;
  overflow: hidden;
}

.action-button:hover {
  transform: translateY(-2px) scale(1.05);
  box-shadow: 
    0 8px 30px rgba(139, 92, 246, 0.6),
    inset 0 1px 0 rgba(255, 255, 255, 0.3);
  background: linear-gradient(135deg, #7C3AED 0%, #8B5CF6 50%, #A855F7 100%);
}

.action-button:active {
  transform: translateY(-1px) scale(1.02);
}

.action-button::before {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 100%;
  height: 100%;
  background: linear-gradient(90deg, transparent, rgba(255,255,255,0.2), transparent);
  transition: left 0.5s;
}

.action-button:hover::before {
  left: 100%;
}
```

#### 4.3.4 멤버십 티어 표시기 (Glass Style)
```css
.tier-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 8px 16px;
  border-radius: 24px;
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  transition: all 0.3s ease;
}

.tier-free {
  background: rgba(107, 114, 128, 0.2);
  color: var(--text-secondary);
  border: 1px solid rgba(107, 114, 128, 0.3);
}

.tier-premium {
  background: linear-gradient(135deg, rgba(139, 92, 246, 0.3) 0%, rgba(168, 85, 247, 0.3) 100%);
  color: #C084FC;
  border: 1px solid rgba(139, 92, 246, 0.4);
  box-shadow: 0 4px 16px rgba(139, 92, 246, 0.2);
}

.tier-pro {
  background: linear-gradient(135deg, rgba(245, 158, 11, 0.3) 0%, rgba(249, 115, 22, 0.3) 100%);
  color: #FBBF24;
  border: 1px solid rgba(245, 158, 11, 0.4);
  box-shadow: 0 4px 16px rgba(245, 158, 11, 0.2);
}

.tier-enterprise {
  background: linear-gradient(135deg, rgba(5, 150, 105, 0.3) 0%, rgba(16, 185, 129, 0.3) 100%);
  color: #34D399;
  border: 1px solid rgba(16, 185, 129, 0.4);
  box-shadow: 0 4px 16px rgba(16, 185, 129, 0.2);
}

.tier-badge:hover {
  transform: scale(1.05);
  backdrop-filter: blur(15px);
}
```

### 4.4 반응형 디자인

#### 4.4.1 Grid System
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

#### 4.4.2 모바일 네비게이션 (Dark Glass Style)
```
┌─────────────────────────────────┐
│                                 │
│         메인 콘텐츠              │
│      (다크 퍼플 그라디언트)        │
│                                 │
├─────────────────────────────────┤
│ [홈] [포트폴리오] [시그널] [프로필] │ ← 글래스모피즘 Bottom Navigation
└─────────────────────────────────┘

/* Bottom Navigation Styles */
.bottom-navigation {
  background: rgba(0, 0, 0, 0.2);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  z-index: 50;
}

.nav-item {
  color: rgba(255, 255, 255, 0.6);
  transition: all 0.3s ease;
}

.nav-item.active {
  color: #FFFFFF;
  transform: scale(1.1);
}

.nav-item:hover {
  color: rgba(255, 255, 255, 0.8);
  background: rgba(255, 255, 255, 0.1);
}
```

## 5. 기술 스택

### 5.1 Backend
- **Python**: 메인 언어
- **FastAPI**: API 서버
- **SQLite/PostgreSQL**: 데이터베이스
- **Redis**: 캐싱
- **APScheduler**: 작업 스케줄링

### 5.2 Frontend (Mobile Web)
- **React 18**: UI 프레임워크
- **TypeScript**: 타입 안전성
- **Tailwind CSS**: 유틸리티 CSS
- **Chart.js**: 차트 라이브러리
- **PWA**: 프로그레시브 웹 앱

### 5.3 Firebase 서비스 (Project: emotra-9ebdb)
- **Firebase Authentication**: 사용자 인증
- **Cloud Firestore**: NoSQL 데이터베이스
- **Firebase Functions**: 서버리스 백엔드
- **Firebase Storage**: 파일 저장
- **Firebase Hosting**: 웹 호스팅
- **Firebase Analytics**: 사용자 분석
- **Firebase Crashlytics**: 오류 추적
- **Firebase Remote Config**: 원격 설정

### 5.4 결제 시스템
- **Stripe**: 신용카드 결제
- **PayPal**: 페이팔 결제
- **Iamport(포트원)**: 한국 결제 시스템
- **Google Play Billing**: 안드로이드 인앱 결제
- **Apple In-App Purchase**: iOS 인앱 결제
### 5.5 AI/ML
- **Claude API** (Anthropic): 감정 분석
- **OpenAI API**: 보조 분석
- **TA-Lib**: 기술적 분석

### 5.6 External APIs
- **Binance API**: 거래 실행
- **CoinGecko API**: 가격 데이터
- **News APIs**: 뉴스 데이터

## 6. 성능 요구사항

### 6.1 응답시간
- **API 응답**: < 500ms
- **페이지 로딩**: < 2s
- **시그널 생성**: < 30s

### 6.2 데이터 처리
- **뉴스 수집**: 5분 간격
- **가격 업데이트**: 1분 간격
- **시그널 갱신**: 실시간

### 6.3 확장성
- **동시 사용자**: 1,000명
- **일일 거래**: 10,000건
- **데이터 저장**: 1년치 이력

## 7. 보안 및 컴플라이언스

### 7.1 Firebase 보안 규칙
```javascript
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 사용자 문서 접근 규칙
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 포트폴리오 접근 규칙
    match /userPortfolios/{userId}/assets/{assetId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 시그널 데이터 (읽기 전용)
    match /signals/{signalId} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    
    // 사용량 체크 함수
    function isWithinUsageLimit(tier, action) {
      let userDoc = get(/databases/$(database)/documents/users/$(request.auth.uid));
      let today = timestamp.date(request.time);
      let usage = userDoc.data.stats[today + '_' + action] ?? 0;
      
      return tier == 'free' && action == 'signal_view' && usage < 3 ||
             tier == 'premium' && usage < 1000 ||
             tier in ['pro', 'enterprise'];
    }
  }
}
```

### 7.2 API 보안
- **JWT 토큰**: 인증/인가
- **Rate Limiting**: API 호출 제한
- **HTTPS**: 모든 통신 암호화

### 7.3 거래 보안
- **2FA**: 이중 인증
- **API Key 암호화**: 민감정보 보호
- **거래 한도**: 일일/월간 제한

### 7.4 개인정보 보호
- **GDPR 준수**: 유럽 개인정보보호법
- **CCPA 준수**: 캘리포니아 개인정보보호법
- **개인정보처리방침**: 한국 개인정보보호법
- **데이터 암호화**: AES-256 암호화
- **데이터 익명화**: 분석용 데이터 익명 처리

## 8. 배포 및 운영

### 8.1 배포 환경
- **Production**: AWS/GCP
- **Development**: Local Docker
- **CI/CD**: GitHub Actions

### 8.2 모니터링
- **로깅**: ELK Stack
- **메트릭**: Prometheus + Grafana
- **알림**: Slack/Discord 연동

## 9. 결제 및 구독 관리

### 9.1 결제 플로우
```
사용자 선택 → 결제 처리 → 구독 활성화 → 기능 접근 권한 부여
     ↓            ↓            ↓              ↓
멤버십 선택    결제 정보 입력  Firebase 업데이트  실시간 반영
```

### 9.2 구독 갱신 정책
- **자동 갱신**: 기본 활성화 (사용자가 비활성화 가능)
- **갱신 알림**: 만료 7일, 3일, 1일 전 알림
- **유예 기간**: 결제 실패 시 3일 유예 (기능은 제한)
- **환불 정책**: 14일 무조건 환불, 이후 비례 환불

### 9.3 사용량 추적 시스템
```javascript
// Firebase Functions로 사용량 추적
exports.trackUsage = functions.firestore
  .document('users/{userId}/activity/{actionId}')
  .onCreate(async (snapshot, context) => {
    const userId = context.params.userId;
    const action = snapshot.data();
    
    // 일일 사용량 업데이트
    const today = new Date().toISOString().split('T')[0];
    const usageRef = db.collection('usage').doc(`${userId}_${today}`);
    
    await usageRef.set({
      [action.type]: admin.firestore.FieldValue.increment(1),
      lastUpdate: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    
    // 사용 제한 체크
    const userDoc = await db.collection('users').doc(userId).get();
    const userTier = userDoc.data().subscription.tier;
    const limits = USER_LIMITS[userTier];
    
    if (limits[action.type] && usage[action.type] >= limits[action.type]) {
      // 사용 제한 알림
      await sendUsageLimitNotification(userId);
    }
  });
```

## 10. 푸시 알림 시스템

### 10.1 알림 카테고리
```
🔥 시그널 알림 (High Priority)
├─ 고신뢰도 시그널 (85% 이상)
├─ 긴급 시장 변동
└─ 사용자 맞춤 코인 알림

📊 포트폴리오 알림 (Medium Priority)
├─ 손익 임계점 도달
├─ 포지션 청산 완료
└─ 일일/주간 성과 요약

🎯 마케팅 알림 (Low Priority)
├─ 새로운 기능 소개
├─ 멤버십 할인 이벤트
└─ 교육 콘텐츠 업데이트
```

### 10.2 Firebase Cloud Messaging 설정
```javascript
// FCM 토큰 관리
const messaging = getMessaging();
const saveTokenToDatabase = async (userId, token) => {
  await db.collection('users').doc(userId).update({
    'settings.fcmTokens': arrayUnion(token),
    'settings.lastTokenUpdate': serverTimestamp()
  });
};

// 맞춤형 알림 발송
exports.sendPersonalizedNotification = functions.firestore
  .document('signals/{signalId}')
  .onCreate(async (snapshot, context) => {
    const signal = snapshot.data();
    
    // 해당 코인에 관심있는 사용자들 찾기
    const interestedUsers = await db.collection('users')
      .where('profile.preferredCoins', 'array-contains', signal.coinSymbol)
      .where('settings.notifications.push', '==', true)
      .get();
    
    const notifications = interestedUsers.docs.map(doc => {
      const user = doc.data();
      return {
        token: user.settings.fcmTokens[0],
        notification: {
          title: `🚀 ${signal.coinSymbol} 시그널 발생!`,
          body: `신뢰도 ${signal.confidenceScore}% - ${signal.recommendedAction.toUpperCase()}`,
        },
        data: {
          type: 'signal',
          signalId: context.params.signalId,
          coinSymbol: signal.coinSymbol
        }
      };
    });
    
    if (notifications.length > 0) {
      await admin.messaging().sendAll(notifications);
    }
  });
```

## 11. 분석 및 개인화

### 11.1 사용자 행동 분석 (Firebase Analytics)
```javascript
// 주요 추적 이벤트
const ANALYTICS_EVENTS = {
  SIGNAL_VIEW: 'signal_view',
  SIGNAL_EXECUTE: 'signal_execute', 
  PORTFOLIO_UPDATE: 'portfolio_update',
  SUBSCRIPTION_UPGRADE: 'subscription_upgrade',
  FEATURE_USE: 'feature_use'
};

// 커스텀 사용자 속성
const setUserProperties = (userId) => {
  analytics().setUserProperties({
    user_tier: userTier,
    experience_level: experienceLevel,
    risk_tolerance: riskTolerance,
    preferred_coins_count: preferredCoins.length
  });
};
```

### 11.2 AI 개인화 추천 시스템
```javascript
// 사용자 맞춤 시그널 필터링
const getPersonalizedSignals = async (userId) => {
  const userDoc = await db.collection('users').doc(userId).get();
  const profile = userDoc.data().profile;
  
  const baseQuery = db.collection('signals')
    .where('confidenceScore', '>=', getMinConfidence(profile.experienceLevel))
    .where('riskLevel', 'in', getAllowedRiskLevels(profile.riskTolerance))
    .orderBy('timestamp', 'desc')
    .limit(20);
  
  const signals = await baseQuery.get();
  
  // AI 점수 기반 재정렬
  return signals.docs
    .map(doc => ({
      ...doc.data(),
      personalScore: calculatePersonalScore(doc.data(), profile)
    }))
    .sort((a, b) => b.personalScore - a.personalScore);
};
```

## 12. 고객 지원 시스템

### 12.1 지원 채널
- **인앱 채팅**: Zendesk Chat 연동
- **이메일**: support@tradecoin.kr
- **FAQ**: 자주 묻는 질문 자동응답
- **화상 상담**: Pro/Enterprise 전용

### 12.2 지원 티켓 시스템
```javascript
// 지원 요청 자동 분류
const SUPPORT_CATEGORIES = {
  TECHNICAL: '기술적 문제',
  BILLING: '결제/구독 문의', 
  FEATURE: '기능 사용법',
  BUG: '버그 신고',
  SUGGESTION: '기능 제안'
};

// 우선순위 자동 할당
const assignPriority = (category, userTier) => {
  const priorityMatrix = {
    enterprise: { TECHNICAL: 'HIGH', BILLING: 'HIGH' },
    pro: { TECHNICAL: 'MEDIUM', BILLING: 'HIGH' },
    premium: { TECHNICAL: 'MEDIUM', BILLING: 'MEDIUM' },
    free: { TECHNICAL: 'LOW', BILLING: 'LOW' }
  };
  
  return priorityMatrix[userTier][category] || 'LOW';
};
```

## 13. A/B 테스트 및 실험

### 13.1 Firebase Remote Config 활용
```javascript
// 기능 플래그 관리
const FEATURE_FLAGS = {
  NEW_DASHBOARD_UI: 'new_dashboard_ui_enabled',
  ADVANCED_CHARTS: 'advanced_charts_enabled',
  SOCIAL_TRADING: 'social_trading_enabled',
  DARK_MODE: 'dark_mode_enabled'
};

// 사용자별 실험 그룹 할당
const assignExperimentGroup = async (userId, experimentName) => {
  const hash = hashUserId(userId + experimentName);
  const group = hash % 100 < 50 ? 'control' : 'variant';
  
  await analytics().logEvent('experiment_assignment', {
    experiment_name: experimentName,
    variant: group,
    user_id: userId
  });
  
  return group;
};
```

## 14. 규제 준수 및 라이선스

### 14.1 금융 서비스 규제
- **금융위원회 신고**: 투자자문업 신고 (필요시)
- **가상자산 사업자 신고**: 디지털자산 거래 관련
- **자금세탁방지법**: KYC/AML 절차 준수
- **개인정보보호법**: 사용자 데이터 보호

### 14.2 면책 조항
```
⚠️ 투자 위험 고지
- 모든 투자는 원금 손실 위험이 있습니다
- 과거 수익률이 미래 수익을 보장하지 않습니다  
- 레버리지 거래는 높은 위험을 수반합니다
- 투자 결정은 신중히 하시기 바랍니다

🤖 AI 예측 한계
- AI 분석은 참고용이며 투자 조언이 아닙니다
- 시장 변동성으로 인한 예측 오차가 있을 수 있습니다
- 최종 투자 결정은 사용자 책임입니다
```