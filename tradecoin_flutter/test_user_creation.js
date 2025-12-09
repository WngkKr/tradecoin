// Firebase Admin SDK를 사용한 사용자 생성 스크립트
const admin = require('firebase-admin');

// Firebase 서비스 계정 키 (실제 환경에서는 환경변수로 관리)
const serviceAccount = {
  "type": "service_account",
  "project_id": "emotra-9ebdb",
  // 실제 서비스 계정 키가 필요합니다
};

// Firebase Admin 초기화
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'emotra-9ebdb'
});

const auth = admin.auth();
const firestore = admin.firestore();

async function createTestUser() {
  try {
    console.log('🚀 테스트 사용자 생성 시작...');

    // 1. Firebase Auth 사용자 생성
    const userRecord = await auth.createUser({
      email: 'wngk7001@gmail.com',
      password: 'wngk7001',
      displayName: '유희남',
      emailVerified: true
    });

    console.log('✅ Firebase Auth 사용자 생성 완료:', userRecord.uid);

    // 2. Firestore에 사용자 프로필 저장
    const userData = {
      uid: userRecord.uid,
      email: 'wngk7001@gmail.com',
      displayName: '유희남',
      photoURL: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),

      // 구독 정보
      subscription: {
        tier: 'free',
        status: 'active',
        autoRenew: false,
        startDate: null,
        endDate: null
      },

      // 투자 프로필
      profile: {
        experienceLevel: 'beginner',
        riskTolerance: 'conservative',
        preferredCoins: ['BTC', 'ETH'],
        investmentGoal: '',
        monthlyBudget: null
      },

      // 설정
      settings: {
        notifications: {
          push: true,
          email: true,
          sms: false,
          signalThreshold: 75
        },
        trading: {
          autoTrading: false,
          maxPositions: 2,
          maxLeverage: 5,
          stopLoss: 3,
          takeProfit: 10
        }
      },

      // 통계
      stats: {
        signalsUsed: 0,
        tradesExecuted: 0,
        totalPnL: 0,
        winRate: 0,
        lastLogin: admin.firestore.FieldValue.serverTimestamp()
      },

      // 메타데이터
      isActive: true,
      version: 1
    };

    await firestore.collection('users').doc(userRecord.uid).set(userData);

    console.log('✅ Firestore 사용자 프로필 저장 완료');
    console.log('📧 이메일:', userData.email);
    console.log('👤 이름:', userData.displayName);
    console.log('🆔 UID:', userRecord.uid);
    console.log('🎯 멤버십:', userData.subscription.tier);

    return {
      uid: userRecord.uid,
      email: userData.email,
      displayName: userData.displayName
    };

  } catch (error) {
    console.error('❌ 사용자 생성 실패:', error);
    throw error;
  }
}

// 실행
if (require.main === module) {
  createTestUser()
    .then((result) => {
      console.log('🎉 테스트 사용자 생성 완료:', result);
      process.exit(0);
    })
    .catch((error) => {
      console.error('💥 실행 실패:', error);
      process.exit(1);
    });
}

module.exports = { createTestUser };