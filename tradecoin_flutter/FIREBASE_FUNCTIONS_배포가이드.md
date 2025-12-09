# 🔥 Firebase Functions 백엔드 배포 가이드

## 📋 개요

TradeCoin 백엔드를 Firebase Functions (Python)로 배포하는 완전한 가이드입니다.

## 🎯 배포 후 엔드포인트

```
https://us-central1-emotra-9ebdb.cloudfunctions.net/tradecoin_api/api/signals
https://us-central1-emotra-9ebdb.cloudfunctions.net/tradecoin_api/api/market-data
https://us-central1-emotra-9ebdb.cloudfunctions.net/tradecoin_api/health
```

## 📦 사전 준비

### 1. Firebase CLI 설치 (이미 완료 ✅)
```bash
npm install -g firebase-tools
firebase --version  # 14.15.1 확인됨
```

### 2. Firebase 로그인
```bash
firebase login
```

### 3. Firebase Blaze 플랜 활성화 ⚠️ 중요
- Firebase Console (https://console.firebase.google.com) 접속
- `emotra-9ebdb` 프로젝트 선택
- 좌측 하단 **"Upgrade"** 클릭
- **Blaze (Pay as you go)** 플랜 선택
- 결제 정보 입력

**⚠️ Spark (무료) 플랜은 외부 API 호출 불가!**

## 🚀 배포 단계

### Step 1: 프로젝트 구조 확인
```
tradecoin_flutter/
├── .firebaserc          ✅ 생성 완료
├── firebase.json        ✅ 생성 완료
└── backend/
    ├── main.py          ✅ 기존 Flask 앱
    ├── firebase_main.py ✅ Functions 진입점
    ├── requirements.txt  ✅ 의존성 목록
    ├── binance_trader.py
    ├── social_signal_generator.py
    └── ... (기타 파일)
```

### Step 2: Firebase Functions 배포
```bash
cd /Users/wngk/Work/study/trade_coin/tradecoin_flutter

# 배포 실행
firebase deploy --only functions

# 특정 함수만 배포 (빠름)
firebase deploy --only functions:tradecoin_api
```

### Step 3: 배포 확인
배포가 완료되면 다음과 같은 URL이 출력됩니다:
```
✔  functions[tradecoin_api(us-central1)] Successful create operation.
Function URL (tradecoin_api(us-central1)):
https://us-central1-emotra-9ebdb.cloudfunctions.net/tradecoin_api
```

### Step 4: 엔드포인트 테스트
```bash
# Health check
curl https://us-central1-emotra-9ebdb.cloudfunctions.net/tradecoin_api/health

# 시그널 API 테스트
curl https://us-central1-emotra-9ebdb.cloudfunctions.net/tradecoin_api/api/signals
```

## 🔧 Flutter 앱 설정 업데이트

배포 완료 후, Flutter 앱의 API 엔드포인트를 업데이트하세요:

**파일**: `lib/src/core/constants/app_constants.dart`

```dart
// 프로덕션 환경 URL 업데이트
static const String _prodBaseUrl =
    'https://us-central1-emotra-9ebdb.cloudfunctions.net/tradecoin_api';
```

## ⚙️ 환경 변수 설정

Firebase Functions에 환경 변수를 설정해야 합니다:

```bash
# Binance API 키 설정
firebase functions:secrets:set BINANCE_API_KEY
firebase functions:secrets:set BINANCE_API_SECRET

# Firebase Service Account 설정
firebase functions:secrets:set GOOGLE_APPLICATION_CREDENTIALS
```

또는 Firebase Console에서 직접 설정:
1. Firebase Console → Functions
2. 좌측 메뉴에서 **"Secrets"** 클릭
3. 환경 변수 추가

## 🐛 문제 해결

### 1. 배포 오류: "Python runtime not supported"
**해결**: Firebase Blaze 플랜이 필요합니다.
```bash
firebase projects:list
# 현재 프로젝트의 플랜 확인
```

### 2. 배포 오류: "Cloud Build API not enabled"
**해결**:
```bash
gcloud services enable cloudbuild.googleapis.com --project=emotra-9ebdb
```

### 3. 함수 실행 오류: "Module not found"
**해결**: `requirements.txt`에 모든 의존성이 있는지 확인
```bash
cd backend
cat requirements.txt
```

### 4. 타임아웃 오류
**해결**: `firebase.json`에서 타임아웃 연장
```json
{
  "functions": [{
    "source": "backend",
    "runtime": "python311",
    "timeout": "300s"
  }]
}
```

## 📊 로그 확인

### 실시간 로그 보기
```bash
firebase functions:log --only tradecoin_api
```

### Firebase Console에서 로그 보기
1. Firebase Console → Functions
2. 함수명 클릭 (`tradecoin_api`)
3. **"Logs"** 탭 선택

## 💰 비용 예상 (Blaze 플랜)

### 무료 할당량 (매월)
- **호출 횟수**: 2,000,000회
- **컴퓨팅 시간**: 400,000 GB-초
- **네트워크 송신**: 5GB

### 초과 시 비용
- **호출**: $0.40 / 백만 호출
- **컴퓨팅**: $0.0000025 / GB-초
- **네트워크**: $0.12 / GB

**예상 월 비용**: $5 ~ $20 (트래픽에 따라)

## ⏱️ Cold Start 최적화

Python Functions는 첫 호출 시 cold start가 발생할 수 있습니다 (2~5초).

### 해결책: Minimum Instances 설정
```bash
firebase functions:config:set tradecoin_api.min_instances=1
```

Firebase Console에서도 설정 가능:
- Functions → tradecoin_api → **Edit** → **"Minimum number of instances"** = 1

**비용**: 항상 실행되는 인스턴스 1개 = 약 $10/월

## 🔄 업데이트 배포

코드 변경 후 재배포:
```bash
cd /Users/wngk/Work/study/trade_coin/tradecoin_flutter
firebase deploy --only functions
```

## ✅ 배포 체크리스트

- [ ] Firebase Blaze 플랜 활성화
- [ ] Firebase CLI 로그인
- [ ] Cloud Build API 활성화
- [ ] 환경 변수 설정 (API 키, Service Account)
- [ ] `firebase deploy --only functions` 실행
- [ ] 배포된 URL 확인
- [ ] 엔드포인트 테스트 (curl)
- [ ] Flutter 앱 `app_constants.dart` 업데이트
- [ ] Flutter 앱 재빌드 및 테스트

## 📝 주의사항

1. **ChromeDriver 이슈**: Firebase Functions에서는 Selenium/ChromeDriver를 사용할 수 없습니다.
   - 트위터 크롤링 기능은 **Cloud Run** 또는 **별도 VM**으로 분리 필요

2. **SQLite 이슈**: Firebase Functions는 stateless이므로 SQLite DB 대신 **Firestore** 사용 권장

3. **파일 시스템**: Functions는 `/tmp` 디렉토리만 쓰기 가능 (최대 512MB)

## 🔗 참고 링크

- [Firebase Functions Python 문서](https://firebase.google.com/docs/functions/python)
- [Firebase Pricing](https://firebase.google.com/pricing)
- [Functions Framework Python](https://github.com/GoogleCloudPlatform/functions-framework-python)

---

## 다음 단계

배포 완료 후:
1. Flutter 앱에서 실제 시그널 데이터 확인
2. 푸시 알림 테스트
3. 프로덕션 릴리즈 준비

**문제 발생 시**: Firebase Console의 Logs 탭에서 자세한 오류 메시지 확인!
