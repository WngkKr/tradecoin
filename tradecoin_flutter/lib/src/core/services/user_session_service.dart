import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/models/user_model.dart';

class UserSessionService {
  static const String _keyCurrentUser = 'current_user';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyLastLoginTime = 'last_login_time';
  static const String _keyUserList = 'user_list';

  static UserSessionService? _instance;
  static UserSessionService get instance {
    _instance ??= UserSessionService._internal();
    return _instance!;
  }

  UserSessionService._internal();

  /// 현재 로그인된 사용자 저장
  Future<void> saveCurrentUser(TradeCoinUser user) async {
    final prefs = await SharedPreferences.getInstance();

    // 사용자 정보 저장
    await prefs.setString(_keyCurrentUser, jsonEncode(user.toJson()));
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyLastLoginTime, DateTime.now().toIso8601String());

    // 사용자 목록에도 추가 (중복 방지)
    await _addToUserList(user);

    print('💾 [세션] 사용자 로그인 상태 저장: ${user.displayName}');
  }

  /// 현재 로그인된 사용자 불러오기
  Future<TradeCoinUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();

    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    if (!isLoggedIn) {
      print('💾 [세션] 로그인 상태 없음');
      return null;
    }

    final userJsonString = prefs.getString(_keyCurrentUser);
    if (userJsonString == null) {
      print('💾 [세션] 저장된 사용자 데이터 없음');
      return null;
    }

    try {
      final userJson = jsonDecode(userJsonString) as Map<String, dynamic>;
      final user = TradeCoinUser.fromJson(userJson);

      print('💾 [세션] 사용자 로그인 상태 복원: ${user.displayName}');
      return user;
    } catch (e) {
      print('❌ [세션] 사용자 데이터 파싱 실패: $e');
      await clearSession();
      return null;
    }
  }

  /// 로그인 상태 확인
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// 세션 정리 (로그아웃)
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_keyCurrentUser);
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.remove(_keyLastLoginTime);

    print('💾 [세션] 로그인 세션 정리 완료');
  }

  /// 새 사용자를 로컬 사용자 목록에 추가
  Future<void> _addToUserList(TradeCoinUser user) async {
    final prefs = await SharedPreferences.getInstance();

    // 기존 사용자 목록 불러오기
    final userListString = prefs.getString(_keyUserList) ?? '[]';
    final List<dynamic> userList = jsonDecode(userListString);

    // 중복 확인 (이메일 기준)
    final existingIndex = userList.indexWhere((userData) =>
        userData['email'] == user.email);

    if (existingIndex != -1) {
      // 기존 사용자 정보 업데이트
      userList[existingIndex] = user.toJson();
      print('💾 [세션] 기존 사용자 정보 업데이트: ${user.email}');
    } else {
      // 새 사용자 추가
      userList.add(user.toJson());
      print('💾 [세션] 새 사용자 추가: ${user.email}');
    }

    // 사용자 목록 저장
    await prefs.setString(_keyUserList, jsonEncode(userList));
  }

  /// 로컬에 저장된 사용자 목록 불러오기
  Future<List<TradeCoinUser>> getLocalUsers() async {
    final prefs = await SharedPreferences.getInstance();

    final userListString = prefs.getString(_keyUserList) ?? '[]';
    final List<dynamic> userList = jsonDecode(userListString);

    return userList.map((userData) =>
        TradeCoinUser.fromJson(userData as Map<String, dynamic>)).toList();
  }

  /// 이메일로 로컬 사용자 찾기
  Future<TradeCoinUser?> findUserByEmail(String email) async {
    final users = await getLocalUsers();

    try {
      return users.firstWhere((user) => user.email == email);
    } catch (e) {
      return null;
    }
  }

  /// 새 사용자 회원가입 및 저장
  Future<TradeCoinUser> registerNewUser({
    required String email,
    required String password,
    required String displayName,
  }) async {
    // 중복 이메일 확인
    final existingUser = await findUserByEmail(email);
    if (existingUser != null) {
      throw Exception('이미 등록된 이메일입니다: $email');
    }

    // 새 사용자 생성
    final newUser = TradeCoinUser(
      uid: 'local_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: displayName,
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
    );

    // 사용자 목록에 추가
    await _addToUserList(newUser);

    // 비밀번호는 별도로 저장 (실제 앱에서는 암호화 필요)
    await _saveUserPassword(email, password);

    print('💾 [세션] 새 사용자 회원가입 완료: $email');
    return newUser;
  }

  /// 이메일/비밀번호로 로그인 시도
  Future<TradeCoinUser?> loginWithEmailPassword(String email, String password) async {
    // 로컬 사용자 찾기
    final user = await findUserByEmail(email);
    if (user == null) {
      print('❌ [세션] 사용자를 찾을 수 없음: $email');
      return null;
    }

    // 비밀번호 확인
    final savedPassword = await _getUserPassword(email);
    if (savedPassword != password) {
      print('❌ [세션] 비밀번호 불일치: $email');
      return null;
    }

    // 로그인 성공 - 세션 저장
    await saveCurrentUser(user);

    print('✅ [세션] 로그인 성공: $email');
    return user;
  }

  /// 사용자 비밀번호 저장 (실제로는 해시 처리 필요)
  Future<void> _saveUserPassword(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('password_$email', password);
  }

  /// 사용자 비밀번호 불러오기
  Future<String?> _getUserPassword(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('password_$email');
  }

  /// 마지막 로그인 시간 불러오기
  Future<DateTime?> getLastLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(_keyLastLoginTime);

    if (timeString != null) {
      try {
        return DateTime.parse(timeString);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// 세션 유효성 검사 (예: 30일 후 만료)
  Future<bool> isSessionValid() async {
    final lastLoginTime = await getLastLoginTime();
    if (lastLoginTime == null) return false;

    final sessionDuration = DateTime.now().difference(lastLoginTime);
    const maxSessionDays = 30;

    if (sessionDuration.inDays > maxSessionDays) {
      print('⚠️ [세션] 세션 만료됨 (${sessionDuration.inDays}일 경과)');
      await clearSession();
      return false;
    }

    return true;
  }

  /// 모든 로컬 데이터 삭제 (앱 초기화)
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();

    // 사용자 관련 모든 키 삭제
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('password_') ||
          key == _keyCurrentUser ||
          key == _keyIsLoggedIn ||
          key == _keyLastLoginTime ||
          key == _keyUserList) {
        await prefs.remove(key);
      }
    }

    print('🗑️ [세션] 모든 로컬 데이터 삭제 완료');
  }

  /// 테스트용 유희남 계정 직접 생성 및 로그인
  Future<TradeCoinUser> createTestUserYuhenam() async {
    try {
      print('🧪 [테스트] 유희남 계정 생성 시작...');

      // 기존 계정이 있는지 확인
      final existingUser = await findUserByEmail('wngk7001@gmail.com');
      if (existingUser != null) {
        print('💾 [테스트] 기존 유희남 계정 발견 - 로그인 처리');
        await saveCurrentUser(existingUser);
        return existingUser;
      }

      // 새로운 유희남 계정 생성
      final testUser = TradeCoinUser(
        uid: 'local_yuhenam_${DateTime.now().millisecondsSinceEpoch}',
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
      );

      // 사용자 목록에 추가
      await _addToUserList(testUser);

      // 비밀번호 저장
      await _saveUserPassword('wngk7001@gmail.com', 'wngk7001');

      // 현재 사용자로 설정 (자동 로그인)
      await saveCurrentUser(testUser);

      print('✅ [테스트] 유희남 계정 생성 및 로그인 완료!');
      print('📧 이메일: wngk7001@gmail.com');
      print('🔒 비밀번호: wngk7001');
      print('👤 이름: 유희남');

      return testUser;

    } catch (e) {
      print('❌ [테스트] 유희남 계정 생성 실패: $e');
      rethrow;
    }
  }
}