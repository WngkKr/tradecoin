import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'src/features/auth/models/user_model.dart';

/// 테스트 사용자 직접 생성 함수
class TestUserCreation {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 유희남 계정 직접 생성
  static Future<void> createYuHeeNamAccount() async {
    try {
      print('🚀 [테스트] 유희남 계정 생성 시작...');

      // 1. Firebase Auth 사용자 생성
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: 'wngk7001@gmail.com',
        password: 'wngk7001',
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Firebase Auth 사용자 생성 실패');
      }

      print('✅ [테스트] Firebase Auth 사용자 생성 완료: ${user.uid}');

      // 2. 사용자 프로필을 Firestore에 저장
      final newUserData = TradeCoinUser(
        uid: user.uid,
        email: 'wngk7001@gmail.com',
        displayName: '유희남',
        photoURL: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),

        // 기본 무료 구독
        subscription: const UserSubscription(
          tier: 'free',
          status: 'active',
          autoRenew: false,
        ),

        // 초보자 투자 프로필
        profile: const UserProfile(
          experienceLevel: 'beginner',
          riskTolerance: 'conservative',
          preferredCoins: ['BTC', 'ETH'],
        ),

        // 기본 설정
        settings: const UserSettings(
          notifications: UserNotificationSettings(
            push: true,
            email: true,
            sms: false,
            signalThreshold: 75,
          ),
          trading: UserTradingSettings(
            autoTrading: false,
            maxPositions: 2,
            maxLeverage: 5,
            stopLoss: 3,
            takeProfit: 10,
          ),
        ),

        // 초기 통계
        stats: const UserStats(
          signalsUsed: 0,
          tradesExecuted: 0,
          totalPnL: 0,
          winRate: 0,
        ),

        // 메타데이터
        isActive: true,
        version: 1,
      );

      await _firestore.collection('users').doc(user.uid).set(newUserData.toMap());

      print('✅ [테스트] Firestore 사용자 프로필 저장 완료');
      print('📧 이메일: ${newUserData.email}');
      print('👤 이름: ${newUserData.displayName}');
      print('🆔 UID: ${newUserData.uid}');
      print('🎯 멤버십: ${newUserData.subscription.tier}');

      // 3. 이메일 인증 전송
      if (!user.emailVerified) {
        await user.sendEmailVerification();
        print('📧 [테스트] 이메일 인증 전송 완료');
      }

      print('🎉 [테스트] 유희남 계정 생성 및 설정 완료!');

    } catch (e) {
      print('❌ [테스트] 계정 생성 실패: $e');

      // 에러 타입별 처리
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            print('⚠️ 이미 사용 중인 이메일입니다');
            break;
          case 'weak-password':
            print('⚠️ 비밀번호가 너무 약합니다');
            break;
          case 'invalid-email':
            print('⚠️ 이메일 형식이 올바르지 않습니다');
            break;
          default:
            print('⚠️ Firebase Auth 에러: ${e.message}');
        }
      }

      rethrow;
    }
  }

  /// 테스트 사용자 로그인
  static Future<User?> loginTestUser() async {
    try {
      print('🔐 [테스트] 유희남 계정 로그인 시도...');

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: 'wngk7001@gmail.com',
        password: 'wngk7001',
      );

      final user = userCredential.user;
      if (user != null) {
        print('✅ [테스트] 로그인 성공: ${user.email}');

        // Firestore에서 사용자 데이터 확인
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final userData = doc.data()!;
          print('📊 [테스트] Firestore 데이터 확인:');
          print('   - 이름: ${userData['displayName']}');
          print('   - 멤버십: ${userData['subscription']?['tier']}');
          print('   - 가입일: ${userData['createdAt']}');
        } else {
          print('⚠️ [테스트] Firestore에 사용자 데이터가 없습니다');
        }
      }

      return user;
    } catch (e) {
      print('❌ [테스트] 로그인 실패: $e');
      return null;
    }
  }

  /// 테스트 사용자 데이터 확인
  static Future<void> checkTestUserData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('⚠️ [테스트] 로그인된 사용자가 없습니다');
        return;
      }

      print('🔍 [테스트] 사용자 데이터 확인 중...');

      final doc = await _firestore.collection('users').doc(currentUser.uid).get();

      if (doc.exists) {
        final userData = doc.data()!;
        print('✅ [테스트] Firestore 데이터 존재');
        print('📊 사용자 정보:');
        print('   - UID: ${currentUser.uid}');
        print('   - 이메일: ${userData['email']}');
        print('   - 이름: ${userData['displayName']}');
        print('   - 멤버십: ${userData['subscription']?['tier']}');
        print('   - 투자경험: ${userData['profile']?['experienceLevel']}');
        print('   - 위험성향: ${userData['profile']?['riskTolerance']}');
        print('   - 관심코인: ${userData['profile']?['preferredCoins']}');
        print('   - 활성상태: ${userData['isActive']}');
        print('   - 생성일: ${userData['createdAt']}');
      } else {
        print('❌ [테스트] Firestore에 사용자 데이터가 없습니다');
      }
    } catch (e) {
      print('❌ [테스트] 데이터 확인 실패: $e');
    }
  }
}

/// 테스트 실행 함수
Future<void> runUserCreationTest() async {
  print('=' * 50);
  print('🧪 TradeCoin 사용자 생성 테스트 시작');
  print('=' * 50);

  try {
    // 1. 계정 생성
    await TestUserCreation.createYuHeeNamAccount();

    // 2. 잠시 대기
    await Future.delayed(const Duration(seconds: 2));

    // 3. 로그인 테스트
    final user = await TestUserCreation.loginTestUser();

    if (user != null) {
      // 4. 데이터 확인
      await TestUserCreation.checkTestUserData();
    }

    print('=' * 50);
    print('✅ 모든 테스트 완료');
    print('=' * 50);

  } catch (e) {
    print('=' * 50);
    print('❌ 테스트 실패: $e');
    print('=' * 50);
  }
}