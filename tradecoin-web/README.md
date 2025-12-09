# TradeCoin Web App

AI 기반 감정 분석과 기술적 분석을 결합한 차세대 암호화폐 자동 트레이딩 플랫폼

## 🚀 주요 기능

### 📱 모바일 웹 앱
- **반응형 디자인**: 모바일 최적화 UI/UX
- **PWA 지원**: 앱과 같은 사용 경험
- **Canva/Muzli 스타일**: 모던하고 직관적인 디자인

### 🔐 사용자 인증 및 멤버십
- **Firebase Authentication**: Google, Apple, Kakao 소셜 로그인
- **4단계 멤버십**: Free → Premium → Pro → Enterprise
- **온보딩 플로우**: 투자 성향 분석 및 맞춤 설정

### 📊 실시간 트레이딩 시그널
- **AI 감정 분석**: 뉴스 및 소셜미디어 분석
- **기술적 분석**: MACD, RSI, 볼린저 밴드 복합 분석
- **신뢰도 점수**: 85% 이상 고신뢰도 시그널
- **실시간 알림**: FCM 푸시 알림

### 💼 포트폴리오 관리
- **자산 추적**: 실시간 손익 계산
- **활성 포지션**: 레버리지 거래 관리
- **성과 분석**: 승률, 수익률, 최대 손실 추적

### 💳 구독 및 결제
- **Stripe/PayPal**: 해외 결제
- **아임포트**: 한국 결제 시스템
- **자동 갱신**: 유연한 구독 관리

## 🛠 기술 스택

### Frontend
- **React 18** with TypeScript
- **Tailwind CSS** for styling
- **React Router** for navigation
- **Framer Motion** for animations

### Backend Services
- **Firebase** (Project: emotra-9ebdb)
  - Authentication
  - Firestore Database
  - Cloud Functions
  - Analytics
  - Cloud Messaging

### Design System
- **Poppins** typography
- **Gradient** color schemes
- **Card-based** layout
- **Mobile-first** responsive design

## 🎨 디자인 시스템

### 컬러 팔레트
```css
--primary-blue: #2E54FF     /* 메인 액션 */
--success-green: #009649    /* 수익/상승 */
--danger-red: #FF4757       /* 손실/하락 */
--warning-orange: #FFA726   /* 경고/대기 */
--background: #F8F9FA       /* 메인 배경 */
```

### 멤버십 티어
- 🆓 **Free**: 일 3개 시그널 제한
- 💎 **Premium**: 무제한 시그널, 실시간 알림
- 👑 **Pro**: AI 맞춤 전략, 자동거래, API 접근
- 🏆 **Enterprise**: 커스텀 알고리즘, 전담 지원

## 📱 주요 화면

### 🔐 인증
- 로그인/회원가입
- 소셜 로그인 (Google, Apple, Kakao)
- 온보딩 (투자 성향 설정)

### 🏠 대시보드
- 포트폴리오 현황
- 실시간 시그널 카드
- 주요 뉴스 피드

### 📊 포트폴리오
- 보유 자산 현황
- 활성 포지션 관리
- 거래 성과 분석

### 👑 멤버십
- 플랜 비교 및 업그레이드
- 결제 및 구독 관리
- 사용량 현황

## 🚀 실행 방법

### 1. 프로젝트 설치
```bash
# 의존성 설치
npm install

# Tailwind CSS 빌드
npm run build:css
```

### 2. Firebase 설정
```bash
# src/firebase/config.ts 파일에서 Firebase 설정 업데이트
# Project ID: emotra-9ebdb
```

### 3. 개발 서버 실행
```bash
npm start
```

### 4. 프로덕션 빌드
```bash
npm run build
```

## 📁 프로젝트 구조

```
src/
├── components/          # React 컴포넌트
│   ├── auth/           # 인증 관련 컴포넌트
│   ├── common/         # 공통 컴포넌트
│   ├── dashboard/      # 대시보드 컴포넌트
│   ├── portfolio/      # 포트폴리오 컴포넌트
│   └── membership/     # 멤버십 컴포넌트
├── contexts/           # React Context
├── firebase/           # Firebase 설정
├── pages/             # 페이지 컴포넌트
├── types/             # TypeScript 타입
└── App.tsx            # 메인 앱 컴포넌트
```

## 🔥 주요 특징

### 🎯 실시간 시그널
- **신뢰도 85% 이상** 고품질 시그널만 제공
- **10분 이내 진입**, **30분 이내 청산** 최적 타이밍
- **레버리지 3-5배** 추천으로 수익 극대화

### 🤖 AI 기반 분석
- **Claude API** 감정 분석
- **뉴스 + 소셜미디어** 통합 분석
- **기술적 지표** 복합 검증

### 📱 모바일 최적화
- **터치 친화적** 인터페이스
- **빠른 로딩** 성능 최적화
- **오프라인** 캐싱 지원

### 🔒 보안
- **Firebase 보안 규칙** 적용
- **HTTPS** 통신
- **개인정보보호법** 준수

## 💡 향후 계획

### Phase 2
- [ ] 소셜 트레이딩 기능
- [ ] 복사 거래 (Copy Trading)
- [ ] 고급 차트 분석

### Phase 3
- [ ] 네이티브 앱 (React Native)
- [ ] AI 챗봇 지원
- [ ] 암호화폐 선물 거래

## 📞 지원

- **이메일**: support@tradecoin.kr
- **FAQ**: 인앱 자주 묻는 질문
- **실시간 채팅**: Premium 이상 제공

## 📄 라이선스

이 프로젝트는 상용 라이선스 하에 있습니다. 무단 복제나 배포를 금지합니다.

---

🚀 **TradeCoin으로 스마트한 암호화폐 투자를 시작하세요!**
