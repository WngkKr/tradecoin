# 🚀 TradeCoin Firebase Functions 배포 가이드

**작성일**: 2025-12-04
**프로젝트**: TradeCoin (emotra-9ebdb)
**배포 방식**: Firebase Functions 2nd Generation

---

## 📋 목차

1. [사전 준비](#1-사전-준비)
2. [환경 변수 설정](#2-환경-변수-설정)
3. [Firebase Functions 배포](#3-firebase-functions-배포)
4. [배포 확인](#4-배포-확인)
5. [Flutter 앱 연동](#5-flutter-앱-연동)
6. [트러블슈팅](#6-트러블슈팅)

---

## 1. 사전 준비

### 1.1 필수 도구 확인

```bash
# Firebase CLI (이미 설치됨 ✅)
firebase --version

# Python 3.11
python3 --version
```

### 1.2 Firebase 로그인

```bash
# Firebase 계정 로그인
firebase login

# 프로젝트 확인
firebase projects:list

# emotra-9ebdb 확인
cat .firebaserc
```

---

## 2. 환경 변수 설정

```bash
cd tradecoin_flutter

# Anthropic API Key (Claude AI)
firebase functions:secrets:set ANTHROPIC_API_KEY

# Stripe API Key
firebase functions:secrets:set STRIPE_SECRET_KEY
firebase functions:secrets:set STRIPE_WEBHOOK_SECRET

# 환경 변수 확인
firebase functions:secrets:access ANTHROPIC_API_KEY
```

---

## 3. Firebase Functions 배포

```bash
cd tradecoin_flutter

# Functions만 배포 (권장)
firebase deploy --only functions

# 전체 배포
firebase deploy
```

**예상 배포 시간**: 3-5분

**배포 완료 시 출력되는 URL**:
```
https://asia-northeast3-emotra-9ebdb.cloudfunctions.net/tradecoin_api
```

---

## 4. 배포 확인

```bash
# 함수 목록 확인
firebase functions:list

# API 테스트
curl https://asia-northeast3-emotra-9ebdb.cloudfunctions.net/tradecoin_api/health

# 시그널 API 테스트
curl https://asia-northeast3-emotra-9ebdb.cloudfunctions.net/tradecoin_api/api/signals
```

---

## 5. Flutter 앱 연동

**파일**: `lib/src/core/constants/app_constants.dart`

```dart
class AppConstants {
  static const String apiBaseUrl =
    'https://asia-northeast3-emotra-9ebdb.cloudfunctions.net/tradecoin_api';
}
```

**앱 재빌드**:
```bash
flutter run -d <device_id>
```

---

## 6. 트러블슈팅

### Cold Start 지연 문제

**해결책**: Cloud Scheduler로 주기적 호출

```bash
# Firebase 콘솔 → Cloud Scheduler
# 매 5분마다 /health 호출
```

### 환경 변수 접근 오류

```bash
# 재설정
firebase functions:secrets:set ANTHROPIC_API_KEY

# 재배포
firebase deploy --only functions

# 로그 확인
firebase functions:log --only tradecoin_api
```

---

## 7. 비용 정보

**무료 할당량 (월간)**:
- ✅ 호출: 200만 건
- ✅ 컴퓨팅: 40만 GB초
- ✅ 네트워크: 5GB

**예상 비용**: $0 (무료 범위 내)

---

## 8. 모니터링

```bash
# 실시간 로그
firebase functions:log --only tradecoin_api --follow

# Firebase 콘솔
https://console.firebase.google.com/project/emotra-9ebdb/functions
```

---

## ✅ 배포 완료 체크리스트

- [ ] Firebase CLI 로그인 완료
- [ ] 환경 변수 설정 완료
- [ ] `firebase deploy --only functions` 실행
- [ ] 함수 URL 확인 및 API 테스트 성공
- [ ] Flutter 앱 API URL 업데이트
- [ ] 실기기 테스트 성공

---

**배포 완료!** 🚀

다음 단계:
- ⏭️ 결제 시스템 구현
- ⏭️ 온보딩 화면 구현
- ⏭️ 멤버십 관리 화면
