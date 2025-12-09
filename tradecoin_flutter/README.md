# 🚀 TradeCoin Flutter - AI Trading Platform

React에서 Flutter로 완전 마이그레이션된 TradeCoin AI 트레이딩 플랫폼입니다.

## ✨ 주요 특징

### 🎨 사이버펑크 디자인 시스템
- **네온 글로우 효과**: 각 UI 요소별 고유 네온 컬러
- **글래스모피즘**: 반투명 백드롭 필터 효과
- **미래형 그라디언트**: 다크 테마 + 사이버네틱 컬러 팔레트
- **애니메이션**: 부드러운 트랜지션과 인터랙티브 효과

### 🔥 핵심 기능 (React에서 동일하게 유지)
- **Firebase 인증**: 이메일/소셜 로그인
- **실시간 포트폴리오**: 자산 추적 및 분석
- **AI 트레이딩 시그널**: 머신러닝 기반 매매 신호
- **암호화폐 뉴스**: 실시간 마켓 뉴스
- **사용자 프로필**: 멤버십 관리

## 🛠️ 기술 스택

### Frontend (Flutter)
```yaml
dependencies:
  flutter: sdk
  flutter_riverpod: ^2.4.9     # 상태 관리
  go_router: ^12.1.3           # 라우팅
  firebase_core: ^2.24.2       # Firebase 코어
  firebase_auth: ^4.15.3       # 인증
  cloud_firestore: ^4.13.6     # 데이터베이스
  google_fonts: ^6.1.0         # 폰트
  fl_chart: ^0.65.0            # 차트
  dio: ^5.4.0                  # HTTP 클라이언트
  lottie: ^2.7.0               # 애니메이션
```

### Architecture
```
lib/
├── main.dart                 # 앱 진입점
├── src/
│   ├── core/                # 코어 설정
│   │   ├── theme/           # 사이버펑크 테마
│   │   ├── router/          # 라우팅 설정
│   │   └── constants/       # 앱 상수
│   ├── features/            # 기능별 모듈
│   │   ├── auth/           # 인증
│   │   ├── dashboard/      # 대시보드
│   │   ├── portfolio/      # 포트폴리오
│   │   ├── signals/        # 시그널
│   │   ├── news/           # 뉴스
│   │   └── profile/        # 프로필
│   └── shared/             # 공통 컴포넌트
│       └── widgets/        # 재사용 위젯
```

## 🚀 시작하기

### Prerequisites
```bash
# Flutter 설치
flutter --version

# Firebase CLI 설치
npm install -g firebase-tools
```

### 설치 및 실행
```bash
# 의존성 설치
flutter pub get

# iOS 시뮬레이터에서 실행
flutter run -d ios

# Android 에뮬레이터에서 실행
flutter run -d android

# 웹에서 실행
flutter run -d web-server --web-port 3000
```

### Firebase 설정
```bash
# Firebase 프로젝트 설정
firebase init

# FlutterFire CLI 설정
flutter pub global activate flutterfire_cli
flutterfire configure --project=emotra-9ebdb
```

## 📱 스크린샷

### 🎯 사이버펑크 헤더
- **미래형 TC 로고** with 온라인 상태 표시
- **Market Open 상태** with 펄스 애니메이션
- **그라디언트 배경** + 백드롭 블러 효과

### ⚡ 네온 네비게이션
- **5개 탭**: 홈(cyan), 포트폴리오(emerald), 시그널(yellow), 뉴스(purple), 프로필(pink)
- **글로우 효과**: 활성화시 네온 컬러별 글로우
- **인터랙티브**: 호버/탭시 스케일 + 컬러 애니메이션

### 🌟 대시보드
- **포트폴리오 카드**: 실시간 잔고 + P&L 표시
- **마켓 개요**: BTC/ETH 가격 추적
- **빠른 액션**: 매수/매도 버튼
- **최근 활동**: 거래 히스토리

## 🔧 개발 도구

### State Management
```dart
// Riverpod 사용 예시
final authStateProvider = StreamProvider<AuthState>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
```

### 네온 테마 시스템
```dart
class AppTheme {
  static const Color cyberCyan = Color(0xFF22D3EE);
  static const Color cyberPurple = Color(0xFFA855F7);
  static const Color cyberPink = Color(0xFFEC4899);
  
  static BoxShadow neonGlow(Color color) {
    return BoxShadow(
      color: color.withOpacity(0.8),
      blurRadius: 8,
      spreadRadius: 0,
    );
  }
}
```

### 애니메이션 시스템
```dart
AnimatedBuilder(
  animation: _pulseController,
  builder: (context, child) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          AppTheme.neonGlow(AppTheme.cyberCyan)
        ],
      ),
    );
  },
);
```

## 🌐 React vs Flutter 비교

### React (기존)
```typescript
// React Hook 기반
const { user, signOut } = useAuth();
const [loading, setLoading] = useState(true);

// JSX + Tailwind CSS
<div className="bg-gradient-to-br from-purple-900">
  <Header />
  <BottomNavigation />
</div>
```

### Flutter (현재)
```dart
// Riverpod 기반 상태 관리
final authState = ref.watch(authStateProvider);
final loading = useState(true);

// Widget + Material Design
Container(
  decoration: BoxDecoration(
    gradient: AppTheme.backgroundGradient,
  ),
  child: Column(
    children: [
      CyberpunkHeader(),
      NeonBottomNavigation(),
    ],
  ),
)
```

## 📊 성능 개선사항

### React → Flutter 장점
- **네이티브 성능**: 60fps 부드러운 애니메이션
- **작은 번들 크기**: AOT 컴파일로 최적화
- **플랫폼 일관성**: iOS/Android 동일한 UI
- **Hot Reload**: 빠른 개발 사이클

### 기능 호환성
- ✅ **Firebase 인증**: 100% 호환
- ✅ **Firestore 데이터**: 동일한 스키마
- ✅ **상태 관리**: Provider → Riverpod
- ✅ **라우팅**: React Router → GoRouter
- ✅ **애니메이션**: CSS → Flutter Animations

## 🔮 향후 계획

### Phase 1: Core Migration ✅
- [x] 프로젝트 구조 설정
- [x] Firebase 연동
- [x] 사이버펑크 테마 시스템
- [x] 네온 네비게이션
- [x] 대시보드 화면

### Phase 2: Feature Parity
- [ ] 로그인/회원가입 화면
- [ ] 포트폴리오 상세 화면  
- [ ] 시그널 상세 화면
- [ ] 뉴스 피드 구현
- [ ] 프로필 설정 화면

### Phase 3: Enhancement
- [ ] 다국어 지원
- [ ] 푸시 알림
- [ ] 오프라인 모드
- [ ] 성능 최적화

## 👥 기여하기

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 라이선스

MIT License - [LICENSE](LICENSE) 파일 참조

---

**🚀 TradeCoin Flutter - The Future of AI Trading is Here!**