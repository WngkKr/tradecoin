import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/user_model.dart';
import '../../../core/services/api_service.dart';

// Enhanced Auth State Notifier with DB Integration
class EnhancedAuthNotifier extends StateNotifier<AuthState> {
  EnhancedAuthNotifier(this._apiService) : super(const AuthState.loading()) {
    _initializeAuth();
  }

  final ApiService _apiService;
  static const String _userDataKey = 'user_data';
  static const String _authTokenKey = 'auth_token';

  // 인증 상태 초기화
  Future<void> _initializeAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString(_userDataKey);
      final authToken = prefs.getString(_authTokenKey);

      if (userDataJson != null && authToken != null) {
        // 로컬 저장된 데이터가 있으면 로드
        final userData = TradeCoinUser.fromJson(json.decode(userDataJson));
        state = AuthState.authenticated(userData);

        // 백그라운드에서 최신 프로필 정보 동기화
        _syncUserProfile(userData.uid);
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      print('Auth initialization error: $e');
      state = const AuthState.unauthenticated();
    }
  }

  // 사용자 프로필 동기화
  Future<void> _syncUserProfile(String userId) async {
    try {
      final response = await _apiService.getUserProfile(userId);
      if (response.success) {
        final updatedUser = _mapApiDataToUserModel(response.data);
        state = AuthState.authenticated(updatedUser);
        await _saveUserData(updatedUser);
      }
    } catch (e) {
      print('Profile sync error: $e');
      // 동기화 실패해도 로컬 데이터 유지
    }
  }

  // API 데이터를 User 모델로 변환
  TradeCoinUser _mapApiDataToUserModel(UserProfileData apiData) {
    return TradeCoinUser(
      uid: apiData.uid,
      email: apiData.email,
      displayName: apiData.displayName,
      photoURL: apiData.photoURL,
      createdAt: apiData.createdAt,
      updatedAt: apiData.updatedAt,
      subscription: UserSubscription(
        tier: apiData.subscriptionTier,
        status: apiData.subscriptionStatus,
        autoRenew: true, // API에서 추가 정보 필요
      ),
      profile: UserProfile(
        experienceLevel: apiData.experienceLevel,
        riskTolerance: apiData.riskTolerance,
        preferredCoins: apiData.preferredCoins,
        investmentGoal: apiData.investmentGoal,
        monthlyBudget: apiData.monthlyBudget,
      ),
    );
  }

  // 로그인 (API 연동)
  Future<void> loginWithCredentials(String email, String password) async {
    state = const AuthState.loading();

    try {
      final response = await _apiService.authenticateUser(email, password);
      if (response.success) {
        final userData = _mapApiDataToUserModel(response.data.user);
        await _saveUserData(userData);
        await _saveAuthToken(response.data.token);
        state = AuthState.authenticated(userData);
      } else {
        state = const AuthState.error('로그인에 실패했습니다');
      }
    } catch (e) {
      print('Login error: $e');
      state = AuthState.error('로그인 오류: $e');
    }
  }

  // Mock 로그인 (기존 호환성)
  void loginWithMockUser(String email) {
    final mockUsers = _getMockUsers();
    final userData = mockUsers[email];

    if (userData != null) {
      state = AuthState.authenticated(userData);
      _saveUserData(userData);
    } else {
      state = const AuthState.error('사용자를 찾을 수 없습니다');
    }
  }

  // 사용자 등록
  Future<void> registerUser({
    required String email,
    required String displayName,
    String? password,
    UserProfile? profile,
  }) async {
    state = const AuthState.loading();

    try {
      final response = await _apiService.registerUser(
        email: email,
        displayName: displayName,
        password: password,
        profileData: profile?.toJson(),
      );

      if (response.success) {
        final userData = _mapApiDataToUserModel(response.data.user);
        await _saveUserData(userData);
        state = AuthState.authenticated(userData);
      } else {
        state = const AuthState.error('회원가입에 실패했습니다');
      }
    } catch (e) {
      print('Registration error: $e');
      state = AuthState.error('회원가입 오류: $e');
    }
  }

  // 프로필 업데이트
  Future<void> updateProfile(Map<String, dynamic> profileData) async {
    final currentUser = state.userData;
    if (currentUser == null) return;

    try {
      final response = await _apiService.updateUserProfile(
        userId: currentUser.uid,
        profileData: profileData,
      );

      if (response.success) {
        final updatedUser = _mapApiDataToUserModel(response.data);
        await _saveUserData(updatedUser);
        state = AuthState.authenticated(updatedUser);
      }
    } catch (e) {
      print('Profile update error: $e');
      // 실패해도 현재 상태 유지
    }
  }

  // 로그아웃
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
    await prefs.remove(_authTokenKey);
    state = const AuthState.unauthenticated();
  }

  // 사용자 데이터 로컬 저장
  Future<void> _saveUserData(TradeCoinUser userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = json.encode(userData.toJson());
      await prefs.setString(_userDataKey, userDataJson);
    } catch (e) {
      print('Save user data error: $e');
    }
  }

  // 인증 토큰 저장
  Future<void> _saveAuthToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_authTokenKey, token);
    } catch (e) {
      print('Save auth token error: $e');
    }
  }

  // Mock 사용자 데이터 (기존 호환성을 위해 유지)
  Map<String, TradeCoinUser> _getMockUsers() {
    return {
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
    };
  }
}

// Enhanced Auth Provider
final enhancedAuthProvider = StateNotifierProvider<EnhancedAuthNotifier, AuthState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return EnhancedAuthNotifier(apiService);
});

// 사용자 프로필 전용 Provider
final userProfileProvider = FutureProvider<UserProfileResponse?>((ref) async {
  final authState = ref.watch(enhancedAuthProvider);
  if (authState.userData?.uid == null) return null;

  final apiService = ref.watch(apiServiceProvider);
  try {
    return await apiService.getUserProfile(authState.userData!.uid);
  } catch (e) {
    print('Failed to load user profile: $e');
    return null;
  }
});

// Auth State Class (기존 유지)
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