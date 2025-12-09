import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../../../core/services/user_session_service.dart';
import '../../../core/services/firestore_service.dart';

// Firebase Auth State Notifier (실제 Firebase 연동)
class FirebaseAuthNotifier extends StateNotifier<AuthState> {
  FirebaseAuthNotifier(this._authService) : super(const AuthState.loading()) {
    _authStateSubscription = _authService.authStateChanges.listen(_onAuthStateChanged);
    _checkInitialAuthState();
  }

  final AuthService _authService;
  late final StreamSubscription<User?> _authStateSubscription;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  // 초기 인증 상태 확인
  Future<void> _checkInitialAuthState() async {
    final user = _authService.currentUser;
    if (user != null) {
      await _loadUserProfile(user);
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  // Firebase Auth 상태 변경 감지
  void _onAuthStateChanged(User? user) async {
    if (user != null) {
      await _loadUserProfile(user);
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  // 사용자 프로필 로드
  Future<void> _loadUserProfile(User user) async {
    try {
      state = const AuthState.loading();

      final userProfileData = await _firestoreService.getUserProfile(user.uid);

      if (userProfileData != null) {
        // 기존 사용자
        final tradeCoinUser = TradeCoinUser.fromFirestore(userProfileData, user.uid);
        state = AuthState.authenticated(tradeCoinUser);
      } else {
        // 새 사용자 - 프로필 생성 필요
        state = const AuthState.needsProfile();
      }
    } catch (e) {
      print('사용자 프로필 로드 실패: $e');
      state = AuthState.error('프로필 로드에 실패했습니다: ${e.toString()}');
    }
  }

  // 이메일/패스워드로 회원가입
  Future<void> signUpWithEmailAndPassword(String email, String password, {
    String? displayName,
  }) async {
    try {
      state = const AuthState.loading();

      final userCredential = await _authService.createUserWithEmailAndPassword(email, password);
      final user = userCredential.user;

      if (user != null) {
        // 사용자 프로필을 Firestore에 생성
        await _firestoreService.createUserProfile(
          userId: user.uid,
          email: email,
          displayName: displayName ?? email.split('@').first,
          photoURL: user.photoURL,
        );

        // 이메일 인증 보내기
        if (!user.emailVerified) {
          await _authService.sendEmailVerification();
        }

        // 생성된 프로필 로드
        await _loadUserProfile(user);
      }
    } catch (e) {
      print('회원가입 실패: $e');
      state = AuthState.error('회원가입에 실패했습니다: ${e.toString()}');
    }
  }

  // 이메일/패스워드로 로그인
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      state = const AuthState.loading();

      await _authService.signInWithEmailAndPassword(email, password);
      // _onAuthStateChanged에서 사용자 프로필을 자동으로 로드합니다

    } catch (e) {
      print('로그인 실패: $e');
      state = AuthState.error('로그인에 실패했습니다: ${e.toString()}');
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      // _onAuthStateChanged에서 상태가 자동으로 업데이트됩니다
    } catch (e) {
      print('로그아웃 실패: $e');
      state = AuthState.error('로그아웃에 실패했습니다: ${e.toString()}');
    }
  }

  // 비밀번호 재설정
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      print('비밀번호 재설정 실패: $e');
      throw AuthException('비밀번호 재설정에 실패했습니다: ${e.toString()}');
    }
  }

  // 사용자 프로필 업데이트
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
    UserProfile? profile,
    UserSubscription? subscription,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null || state.userData == null) return;

      final updates = <String, dynamic>{};

      if (displayName != null) updates['displayName'] = displayName;
      if (photoURL != null) updates['photoURL'] = photoURL;
      if (profile != null) updates['profile'] = profile.toMap();
      if (subscription != null) updates['subscription'] = subscription.toMap();

      await _firestoreService.updateUserProfile(currentUser.uid, updates);

      // 로컬 상태 업데이트
      final updatedUser = state.userData!.copyWith(
        displayName: displayName,
        photoURL: photoURL,
        profile: profile,
        subscription: subscription,
        updatedAt: DateTime.now(),
      );

      state = AuthState.authenticated(updatedUser);

    } catch (e) {
      print('프로필 업데이트 실패: $e');
      state = AuthState.error('프로필 업데이트에 실패했습니다: ${e.toString()}');
    }
  }

  // Mock 데이터와의 호환성을 위한 메소드 (점진적 이전용)
  void loginWithMockUser(String email) {
    // 테스트용 Mock 사용자 생성
    final mockUser = TradeCoinUser(
      uid: 'mock_${email.hashCode}',
      email: email,
      displayName: email.split('@').first,
      photoURL: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      subscription: const UserSubscription(
        tier: 'free',
        status: 'active',
        autoRenew: false,
      ),
      profile: const UserProfile(
        experienceLevel: 'beginner',
        riskTolerance: 'conservative',
        preferredCoins: ['BTC', 'ETH'],
      ),
    );

    state = AuthState.authenticated(mockUser);
  }
}

// Mock Auth State Notifier (기존 코드 - 호환성 유지)
class MockAuthNotifier extends StateNotifier<AuthState> {
  MockAuthNotifier() : super(const AuthState.unauthenticated());
  
  // 테스트 사용자 데이터
  static final Map<String, TradeCoinUser> _mockUsers = {
    'admin@tradecoin.ai': TradeCoinUser(
      uid: 'admin_001',
      email: 'admin@tradecoin.ai',
      displayName: '관리자',
      photoURL: null,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
      subscription: const UserSubscription(
        tier: 'premium',
        status: 'active',
        autoRenew: true,
      ),
      profile: const UserProfile(
        experienceLevel: 'expert',
        riskTolerance: 'aggressive',
        preferredCoins: ['BTC', 'ETH', 'BNB'],
      ),
    ),
    'test@tradecoin.ai': TradeCoinUser(
      uid: 'test_001',
      email: 'test@tradecoin.ai',
      displayName: '테스터',
      photoURL: null,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now(),
      subscription: const UserSubscription(
        tier: 'basic',
        status: 'active',
        autoRenew: false,
      ),
      profile: const UserProfile(
        experienceLevel: 'intermediate',
        riskTolerance: 'moderate',
        preferredCoins: ['BTC', 'ETH'],
      ),
    ),
    'demo@tradecoin.ai': TradeCoinUser(
      uid: 'demo_001',
      email: 'demo@tradecoin.ai',
      displayName: '데모 사용자',
      photoURL: null,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now(),
      subscription: const UserSubscription(
        tier: 'free',
        status: 'active',
        autoRenew: false,
      ),
      profile: const UserProfile(
        experienceLevel: 'beginner',
        riskTolerance: 'conservative',
        preferredCoins: ['BTC'],
      ),
    ),
    'user@tradecoin.ai': TradeCoinUser(
      uid: 'user_001',
      email: 'user@tradecoin.ai',
      displayName: '일반 사용자',
      photoURL: null,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now(),
      subscription: const UserSubscription(
        tier: 'basic',
        status: 'active',
        autoRenew: true,
      ),
      profile: const UserProfile(
        experienceLevel: 'beginner',
        riskTolerance: 'conservative',
        preferredCoins: ['BTC', 'ETH'],
      ),
    ),
    // 회원가입한 사용자 추가
    'wngk@debrix.co.kr': TradeCoinUser(
      uid: 'wngk_001',
      email: 'wngk@debrix.co.kr',
      displayName: 'wngk',
      photoURL: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      subscription: const UserSubscription(
        tier: 'free',
        status: 'active',
        autoRenew: false,
      ),
      profile: const UserProfile(
        experienceLevel: 'beginner',
        riskTolerance: 'moderate',
        preferredCoins: ['BTC', 'ETH'],
      ),
    ),
    // 유희남 테스트 계정
    'wngk7001@gmail.com': TradeCoinUser(
      uid: 'yuhenam_001',
      email: 'wngk7001@gmail.com',
      displayName: '유희남',
      photoURL: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      subscription: const UserSubscription(
        tier: 'free',
        status: 'active',
        autoRenew: false,
      ),
      profile: const UserProfile(
        experienceLevel: 'beginner',
        riskTolerance: 'conservative',
        preferredCoins: ['BTC', 'ETH', 'DOGE'],
      ),
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
          stopLoss: 3.0,
          takeProfit: 10.0,
        ),
      ),
      stats: const UserStats(
        signalsUsed: 0,
        tradesExecuted: 0,
        totalPnL: 0.0,
        winRate: 0.0,
      ),
      isActive: true,
      version: 1,
    ),
  };
  
  void login(String email) {
    final userData = _mockUsers[email];
    if (userData != null) {
      state = AuthState.authenticated(userData);
    } else {
      state = const AuthState.error('사용자를 찾을 수 없습니다');
    }
  }

  void loginWithNewUser(String email) {
    // Firebase로 회원가입한 새로운 사용자를 위한 기본 프로필 생성
    final newUser = TradeCoinUser(
      uid: 'firebase_${email.hashCode}',
      email: email,
      displayName: email.split('@').first,
      photoURL: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      subscription: const UserSubscription(
        tier: 'free',
        status: 'active',
        autoRenew: false,
      ),
      profile: const UserProfile(
        experienceLevel: 'beginner',
        riskTolerance: 'conservative',
        preferredCoins: ['BTC', 'ETH'],
      ),
    );

    state = AuthState.authenticated(newUser);
  }
  
  void logout() {
    state = const AuthState.unauthenticated();
  }
}

// Local Session Auth State Notifier (로컬 세션 기반)
class LocalSessionAuthNotifier extends StateNotifier<AuthState> {
  LocalSessionAuthNotifier() : super(const AuthState.loading()) {
    _checkStoredSession();
  }

  final UserSessionService _sessionService = UserSessionService.instance;

  // 저장된 세션 확인
  Future<void> _checkStoredSession() async {
    try {
      final isSessionValid = await _sessionService.isSessionValid();
      if (!isSessionValid) {
        state = const AuthState.unauthenticated();
        return;
      }

      final currentUser = await _sessionService.getCurrentUser();
      if (currentUser != null) {
        state = AuthState.authenticated(currentUser);
        print('✅ [로컬세션] 자동 로그인 성공: ${currentUser.displayName}');
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      print('❌ [로컬세션] 세션 복원 실패: $e');
      state = const AuthState.unauthenticated();
    }
  }

  // 이메일/패스워드 회원가입
  Future<void> signUpWithEmailAndPassword(String email, String password, {
    String? displayName,
  }) async {
    try {
      state = const AuthState.loading();

      final newUser = await _sessionService.registerNewUser(
        email: email,
        password: password,
        displayName: displayName ?? email.split('@').first,
      );

      await _sessionService.saveCurrentUser(newUser);
      state = AuthState.authenticated(newUser);

      print('✅ [로컬세션] 회원가입 완료: $email');
    } catch (e) {
      print('❌ [로컬세션] 회원가입 실패: $e');
      state = AuthState.error('회원가입에 실패했습니다: ${e.toString()}');
    }
  }

  // 이메일/패스워드 로그인
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      state = const AuthState.loading();

      final user = await _sessionService.loginWithEmailPassword(email, password);
      if (user != null) {
        state = AuthState.authenticated(user);
        print('✅ [로컬세션] 로그인 성공: $email');
      } else {
        state = const AuthState.error('이메일 또는 비밀번호가 잘못되었습니다');
      }
    } catch (e) {
      print('❌ [로컬세션] 로그인 실패: $e');
      state = AuthState.error('로그인에 실패했습니다: ${e.toString()}');
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      await _sessionService.clearSession();
      state = const AuthState.unauthenticated();
      print('✅ [로컬세션] 로그아웃 완료');
    } catch (e) {
      print('❌ [로컬세션] 로그아웃 실패: $e');
      state = AuthState.error('로그아웃에 실패했습니다: ${e.toString()}');
    }
  }

  // 사용자 프로필 업데이트
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
    UserProfile? profile,
    UserSubscription? subscription,
    UserSettings? settings,
    UserStats? stats,
  }) async {
    try {
      final currentUser = state.userData;
      if (currentUser == null) return;

      final updatedUser = currentUser.copyWith(
        displayName: displayName,
        photoURL: photoURL,
        profile: profile,
        subscription: subscription,
        settings: settings,
        stats: stats,
        updatedAt: DateTime.now(),
      );

      await _sessionService.saveCurrentUser(updatedUser);
      state = AuthState.authenticated(updatedUser);

      print('✅ [로컬세션] 프로필 업데이트 완료');
    } catch (e) {
      print('❌ [로컬세션] 프로필 업데이트 실패: $e');
      state = AuthState.error('프로필 업데이트에 실패했습니다: ${e.toString()}');
    }
  }

  // 현재 사용자 정보 새로고침
  Future<void> refreshCurrentUser() async {
    try {
      final currentUser = await _sessionService.getCurrentUser();
      if (currentUser != null) {
        state = AuthState.authenticated(currentUser);
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      print('❌ [로컬세션] 사용자 정보 새로고침 실패: $e');
    }
  }

  // 로컬 데이터 초기화
  Future<void> clearAllLocalData() async {
    try {
      await _sessionService.clearAllData();
      state = const AuthState.unauthenticated();
      print('✅ [로컬세션] 모든 데이터 삭제 완료');
    } catch (e) {
      print('❌ [로컬세션] 데이터 삭제 실패: $e');
    }
  }
}

// Local Session Auth Provider (로컬 세션 기반 - 메인 사용)
final localSessionAuthProvider = StateNotifierProvider<LocalSessionAuthNotifier, AuthState>((ref) {
  return LocalSessionAuthNotifier();
});

// Mock Auth Provider (Legacy - 호환성 유지)
final legacyMockAuthProvider = StateNotifierProvider<MockAuthNotifier, AuthState>((ref) {
  return MockAuthNotifier();
});

// Auth Service Provider (기존 유지)
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Firebase Auth Provider (실제 Firebase 연동)
final firebaseAuthProvider = StateNotifierProvider<FirebaseAuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return FirebaseAuthNotifier(authService);
});

// Auth State Provider (Firebase 사용 - 메인)
final authStateProvider = StateNotifierProvider<FirebaseAuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return FirebaseAuthNotifier(authService);
});


// Auth State Class
class AuthState {
  final AuthStatus status;
  final TradeCoinUser? userData;
  final String? error;

  const AuthState._({
    required this.status,
    this.userData,
    this.error,
  });

  const AuthState.loading() : this._(status: AuthStatus.loading);
  const AuthState.unauthenticated() : this._(status: AuthStatus.unauthenticated);
  const AuthState.needsProfile() : this._(status: AuthStatus.needsProfile);
  const AuthState.authenticated(TradeCoinUser userData)
    : this._(status: AuthStatus.authenticated, userData: userData);
  const AuthState.error(String error) : this._(status: AuthStatus.error, error: error);
}

enum AuthStatus {
  loading,
  unauthenticated,
  needsProfile,
  authenticated,
  error,
}