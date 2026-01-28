# FindMe - Firebase 푸시 알림 설정 가이드

## 개요

멘티가 QR을 스캔하면 멘토에게 푸시 알림을 보내기 위해 Firebase를 사용합니다.

```
┌─────────────────────────────────────────────────────────┐
│  흐름:                                                   │
│                                                         │
│  1. 멘토 앱에서 FCM 토큰 생성                             │
│  2. QR 코드에 토큰 포함                                   │
│  3. 멘티가 QR 스캔 → App Clip 실행                       │
│  4. App Clip → Cloud Function 호출                      │
│  5. Cloud Function → 멘토에게 푸시 알림                   │
└─────────────────────────────────────────────────────────┘
```

## 1. Firebase 프로젝트 설정

### 1.1 Firebase Console
1. https://console.firebase.google.com 접속
2. "프로젝트 추가" 클릭
3. 프로젝트 이름: `findme-app` (또는 원하는 이름)
4. Google Analytics는 선택사항

### 1.2 iOS 앱 등록
1. 프로젝트 설정 → 앱 추가 → iOS
2. Bundle ID: `com.leeo.FindMe`
3. `GoogleService-Info.plist` 다운로드
4. Xcode 프로젝트에 추가

### 1.3 Cloud Messaging 설정
1. 프로젝트 설정 → Cloud Messaging
2. APNs 인증 키 업로드 (Apple Developer에서 생성)

## 2. Cloud Function 배포

### 2.1 Firebase CLI 설치
```bash
npm install -g firebase-tools
firebase login
```

### 2.2 함수 초기화
```bash
mkdir findme-functions
cd findme-functions
firebase init functions
```

### 2.3 함수 코드 (index.js)

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * 위치 확인 시 푸시 알림 전송
 */
exports.sendViewNotification = functions.https.onRequest(async (req, res) => {
  // CORS 헤더
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST');
  res.set('Access-Control-Allow-Headers', 'Content-Type');
  
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }
  
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }
  
  const { token, locationName, viewerName, timestamp } = req.body;
  
  if (!token) {
    res.status(400).send('Missing token');
    return;
  }
  
  // 알림 메시지 구성
  const title = '📍 위치 확인됨';
  const body = viewerName 
    ? `${viewerName}님이 '${locationName}' 위치를 확인했습니다`
    : `누군가 '${locationName}' 위치를 확인했습니다`;
  
  const message = {
    token: token,
    notification: {
      title: title,
      body: body,
    },
    data: {
      locationName: locationName || '',
      viewerName: viewerName || '',
      timestamp: timestamp || new Date().toISOString(),
      type: 'location_view',
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
        },
      },
    },
  };
  
  try {
    const response = await admin.messaging().send(message);
    console.log('Successfully sent message:', response);
    res.status(200).json({ success: true, messageId: response });
  } catch (error) {
    console.error('Error sending message:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});
```

### 2.4 배포
```bash
firebase deploy --only functions
```

배포 후 URL 예시:
```
https://us-central1-findme-app.cloudfunctions.net/sendViewNotification
```

## 3. iOS 앱 설정

### 3.1 Firebase SDK 설치 (SPM)
1. Xcode → File → Add Packages
2. URL: `https://github.com/firebase/firebase-ios-sdk`
3. 선택: `FirebaseMessaging`

### 3.2 코드 수정

**NotificationService.swift** 에서 URL 수정:
```swift
let functionURL = "https://us-central1-YOUR_PROJECT.cloudfunctions.net/sendViewNotification"
// ↓ 실제 URL로 변경
let functionURL = "https://us-central1-findme-app.cloudfunctions.net/sendViewNotification"
```

### 3.3 Firebase 초기화 (선택사항)

실제 FCM 토큰을 사용하려면 `FindMeApp.swift`에 추가:

```swift
import Firebase
import FirebaseMessaging

@main
struct FindMeApp: App {
    init() {
        FirebaseApp.configure()
    }
    // ...
}
```

## 4. 테스트

### 4.1 로컬 테스트 (서버 없이)
앱 내 "테스트" 버튼으로 로컬 알림 시뮬레이션

### 4.2 실제 테스트
1. 메인 앱에서 QR 생성
2. 다른 기기에서 QR 스캔
3. 메인 앱에 푸시 알림 수신 확인

## 5. 비용

Firebase 무료 티어:
- Cloud Functions: 월 200만 회 호출
- Cloud Messaging: 무제한 무료

일반적인 사용량으로는 무료 범위 내에서 충분히 운영 가능

## 6. 대안 (서버리스)

Firebase 대신 다른 옵션:

### Cloudflare Workers
```javascript
// 무료 티어: 일 10만 요청
export default {
  async fetch(request) {
    // APNs 직접 호출
  }
}
```

### Vercel Edge Functions
```typescript
// 무료 티어: 월 100GB 대역폭
export const config = { runtime: 'edge' };
export default async function handler(req) {
  // ...
}
```

## 7. 보안 고려사항

1. **토큰 노출**: QR에 토큰이 포함되므로, 악의적 사용자가 스팸 알림을 보낼 수 있음
   - 해결: Rate limiting, 토큰 로테이션

2. **함수 보호**: Cloud Function에 인증 추가 권장
   - 해결: API Key 또는 Firebase App Check

3. **개인정보**: 위치 정보는 QR에만 있고 서버에 저장되지 않음 ✓
