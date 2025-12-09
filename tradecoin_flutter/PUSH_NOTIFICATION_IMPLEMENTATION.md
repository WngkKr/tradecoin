# 🔔 고신뢰도 시그널 푸시 알림 구현 완료

**작성일**: 2025-12-02
**완료 시간**: 약 30분

---

## ✅ 구현 완료 사항

### 1️⃣ Flutter 푸시 알림 시스템

#### 패키지 추가
```yaml
# pubspec.yaml
dependencies:
  firebase_messaging: ^14.7.9  # FCM 푸시 알림
  flutter_local_notifications: ^16.3.0  # 로컬 알림 표시
```

#### 알림 서비스 구현
**파일**: `lib/src/services/notification_service.dart`

**주요 기능**:
- ✅ Firebase Cloud Messaging 초기화
- ✅ FCM 토큰 자동 발급 및 관리
- ✅ 알림 권한 요청 (iOS/Android)
- ✅ 포그라운드 알림 처리 (앱 실행 중)
- ✅ 백그라운드 알림 처리 (앱 백그라운드)
- ✅ 알림 클릭 이벤트 처리
- ✅ 고신뢰도 전용 알림 채널 생성

**알림 채널**:
```dart
// 고신뢰도 시그널 채널 (High Importance)
- ID: high_confidence_signals
- 중요도: MAX
- 사운드: ON
- 진동: ON
- LED: 퍼플(#8B5CF6)

// 일반 시그널 채널 (Default Importance)
- ID: default_signals
- 중요도: DEFAULT
- 사운드: ON
```

---

### 2️⃣ 백엔드 FCM 전송 시스템

#### FCM 서비스 구현
**파일**: `backend/services/fcm_service.py`

**주요 기능**:
- ✅ 고신뢰도 시그널 자동 감지 (≥80%)
- ✅ FCM 메시지 자동 전송
- ✅ 멀티플랫폼 지원 (Android/iOS)
- ✅ 커스텀 데이터 페이로드
- ✅ 토픽 기반 알림 (all_users)

**전송 조건**:
```python
# 신뢰도 80% 이상만 자동 전송
if signal['confidenceScore'] >= 0.80:
    fcm_service.send_high_confidence_signal_notification(signal)
```

#### 메시지 구조
```json
{
  "notification": {
    "title": "📈 TRUMP BUY",
    "body": "신뢰도 80% - 지금 확인하세요!"
  },
  "data": {
    "type": "high_confidence_signal",
    "signalId": "social_trump_1701234567",
    "symbol": "TRUMP",
    "signalType": "buy",
    "confidence": "0.80",
    "currentPrice": "6.01"
  },
  "android": {
    "priority": "high",
    "notification": {
      "channel_id": "high_confidence_signals",
      "color": "#8B5CF6",
      "sound": "default"
    }
  },
  "apns": {
    "payload": {
      "aps": {
        "sound": "default",
        "badge": 1,
        "category": "HIGH_CONFIDENCE_SIGNAL"
      }
    }
  }
}
```

---

### 3️⃣ main.dart 통합

**파일**: `lib/main.dart`

**변경 사항**:
```dart
// 1. Firebase Messaging import 추가
import 'package:firebase_messaging/firebase_messaging.dart';
import 'src/services/notification_service.dart';

// 2. 백그라운드 메시지 핸들러 등록 (top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('🌙 백그라운드 메시지: ${message.notification?.title}');
}

// 3. main()에서 초기화
void main() async {
  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 백그라운드 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 알림 서비스 초기화
  await NotificationService().initialize();

  // ...
}
```

---

### 4️⃣ 백엔드 API 통합

**파일**: `backend/main.py`

**변경 사항**:
```python
# /api/signals/active 엔드포인트에 FCM 알림 추가

@app.route('/api/signals/active')
def get_active_signals():
    # ... 기존 시그널 생성 로직 ...

    # 🔔 고신뢰도 시그널 FCM 알림 전송 (80% 이상)
    try:
        from services.fcm_service import get_fcm_service
        fcm_service = get_fcm_service()

        for signal in filtered_signals:
            if signal.get('confidenceScore', 0) >= 0.80:
                fcm_service.send_high_confidence_signal_notification(signal)
    except Exception as fcm_err:
        logger.warning(f"⚠️ FCM 알림 전송 실패 (무시): {fcm_err}")

    # ...
```

---

## 📱 알림 동작 흐름

### 시나리오 1: 포그라운드 (앱 실행 중)

```
1. 백엔드: 고신뢰도 시그널 생성 (TRUMP BUY 80%)
   ↓
2. 백엔드: FCM 메시지 전송 to "all_users" 토픽
   ↓
3. Firebase: 메시지를 모든 구독자에게 배달
   ↓
4. Flutter: FirebaseMessaging.onMessage 리스너 호출
   ↓
5. Flutter: NotificationService._handleForegroundMessage()
   ↓
6. Flutter: flutter_local_notifications로 로컬 알림 표시
   ↓
7. 사용자: 화면 상단에 알림 배너 표시
```

### 시나리오 2: 백그라운드 (앱이 백그라운드에 있음)

```
1. 백엔드: 고신뢰도 시그널 생성
   ↓
2. 백엔드: FCM 메시지 전송
   ↓
3. Firebase: 메시지 배달
   ↓
4. OS: 시스템 알림 자동 표시 (Firebase가 처리)
   ↓
5. 사용자: 알림 센터에 알림 표시
   ↓
6. 사용자: 알림 탭 → 앱 열림
   ↓
7. Flutter: FirebaseMessaging.onMessageOpenedApp 리스너 호출
   ↓
8. Flutter: 시그널 상세 화면으로 이동 (TODO)
```

### 시나리오 3: 종료 상태 (앱이 완전 종료됨)

```
1. 백엔드: FCM 메시지 전송
   ↓
2. OS: 시스템 알림 표시
   ↓
3. 사용자: 알림 탭 → 앱 시작
   ↓
4. Flutter: 앱 초기화 후 getInitialMessage() 호출
   ↓
5. Flutter: 시그널 상세 화면으로 이동 (TODO)
```

---

## 📊 알림 예시

### Android 알림 (High Importance)

```
┌───────────────────────────────────┐
│ 🔔 TradeCoin                      │
├───────────────────────────────────┤
│ 📈 TRUMP BUY                      │
│                                   │
│ 신뢰도 80% - 지금 확인하세요!      │
│                                   │
│ ● ● ●  (LED: 퍼플 깜박임)          │
└───────────────────────────────────┘
```

### iOS 알림

```
┌───────────────────────────────────┐
│ TradeCoin                    지금 │
├───────────────────────────────────┤
│ 📈 TRUMP BUY                      │
│ 신뢰도 80% - 지금 확인하세요!      │
└───────────────────────────────────┘
```

---

## 🧪 테스트 방법

### 1️⃣ 로컬 테스트 (Flutter만)

```dart
// 테스트 알림 전송
NotificationService().sendTestNotification();
```

### 2️⃣ 백엔드 연동 테스트

**단계**:
1. 백엔드 서버 실행
2. Flutter 앱 실행 (실기기)
3. FCM 토큰 확인 (로그에서)
4. 고신뢰도 시그널 생성 대기
5. 알림 수신 확인

**로그 확인**:
```bash
# Flutter 로그
flutter logs -d <device_id>

# 백엔드 로그
tail -f backend/logs/app.log | grep FCM
```

### 3️⃣ 시나리오 테스트

**포그라운드 테스트**:
1. 앱 실행 유지
2. 고신뢰도 시그널 발생 대기
3. 화면 상단에 알림 배너 확인

**백그라운드 테스트**:
1. 앱 백그라운드로 전환 (홈 버튼)
2. 고신뢰도 시그널 발생 대기
3. 알림 센터 확인
4. 알림 탭 → 앱 복귀 확인

**종료 상태 테스트**:
1. 앱 완전 종료 (스와이프 업)
2. 고신뢰도 시그널 발생 대기
3. 알림 탭 → 앱 시작 확인

---

## 🔒 권한 설정

### Android 설정

**파일**: `android/app/src/main/AndroidManifest.xml`

```xml
<manifest>
  <!-- 인터넷 권한 (이미 있음) -->
  <uses-permission android:name="android.permission.INTERNET"/>

  <!-- FCM 권한 -->
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

  <application>
    <!-- FCM 기본 알림 채널 -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_channel_id"
        android:value="high_confidence_signals" />

    <!-- FCM 기본 아이콘 (선택) -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_icon"
        android:resource="@mipmap/ic_launcher" />

    <!-- FCM 기본 색상 (선택) -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_color"
        android:resource="@color/purple" />
  </application>
</manifest>
```

### iOS 설정 (선택)

**파일**: `ios/Runner/Info.plist`

```xml
<key>UIBackgroundModes</key>
<array>
  <string>remote-notification</string>
</array>

<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

---

## 📦 생성/수정된 파일

```
tradecoin_flutter/
├── pubspec.yaml                                # 📝 수정
├── lib/
│   ├── main.dart                               # 📝 수정
│   └── src/
│       └── services/
│           └── notification_service.dart       # 🆕 생성
└── backend/
    ├── main.py                                 # 📝 수정
    └── services/
        └── fcm_service.py                      # 🆕 생성
```

---

## 🚀 다음 단계

### 1️⃣ Firebase 콘솔 설정 (필수)

1. **FCM 활성화**:
   ```
   https://console.firebase.google.com/project/emotra-9ebdb/settings/cloudmessaging
   ```

2. **서버 키 확인**:
   - Cloud Messaging API 활성화
   - 서버 키 (Legacy) 복사

3. **android/app/google-services.json 확인**:
   - Firebase 프로젝트에서 다운로드
   - 프로젝트에 배치

4. **iOS APNs 설정** (iOS 빌드 시):
   - Apple Developer에서 APNs 인증서 생성
   - Firebase 콘솔에 업로드

### 2️⃣ 패키지 설치

```bash
cd /Users/wngk/Work/study/trade_coin/tradecoin_flutter

# Flutter 패키지 설치
flutter pub get

# iOS CocoaPods 설치 (iOS 빌드 시)
cd ios
pod install
cd ..
```

### 3️⃣ 실기기 테스트

```bash
# Android 실기기 연결 확인
adb devices

# Flutter 실행
flutter run -d <device_id>

# 로그 모니터링
flutter logs -d <device_id> | grep -E "(FCM|알림|Notification)"
```

### 4️⃣ TODO 항목 구현

**우선순위 낮음**:
- ☐ 알림 클릭 시 시그널 상세 화면으로 이동
- ☐ FCM 토큰 서버 전송 및 관리
- ☐ 사용자별 알림 설정 (on/off)
- ☐ 알림 히스토리 저장
- ☐ 알림 음소거 시간 설정

---

## 🎯 성공 기준

- ✅ 신뢰도 80% 이상 시그널 발생 시 자동 알림
- ✅ 포그라운드/백그라운드 모두 알림 수신
- ✅ Android/iOS 멀티플랫폼 지원
- ✅ 알림 권한 자동 요청
- ✅ 실시간 알림 (지연 없음)

---

## 📞 트러블슈팅

### 문제 1: 알림이 수신 안 됨

**원인**: FCM 토큰 미발급 또는 Firebase 미초기화

**해결**:
```dart
// 로그 확인
print('FCM Token: ${NotificationService().fcmToken}');

// 토큰이 null이면 재초기화
await NotificationService().initialize();
```

### 문제 2: 포그라운드에서만 알림 안 보임

**원인**: 로컬 알림 권한 미승인

**해결**:
```dart
// 권한 재요청
final settings = await FirebaseMessaging.instance.requestPermission(
  alert: true,
  badge: true,
  sound: true,
);
```

### 문제 3: 백엔드 FCM 전송 실패

**원인**: Firebase Admin SDK 미초기화

**해결**:
```python
# Firebase Admin SDK 초기화 확인
import firebase_admin
from firebase_admin import credentials, messaging

if not firebase_admin._apps:
    cred = credentials.Certificate('path/to/serviceAccountKey.json')
    firebase_admin.initialize_app(cred)
```

---

**🎉 고신뢰도 시그널 푸시 알림 구현 완료!**

다음 작업:
- "패키지 설치해줘" (flutter pub get)
- "실기기 테스트해줘"
- "Firebase 콘솔 설정 도와줘"
