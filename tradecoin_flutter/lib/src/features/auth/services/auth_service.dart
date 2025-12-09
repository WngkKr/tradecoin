import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // 현재 사용자
  User? get currentUser => _auth.currentUser;
  
  // 인증 상태 변경 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // 이메일/패스워드로 로그인
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw AuthException('로그인에 실패했습니다: ${e.toString()}');
    }
  }
  
  // 이메일/패스워드로 회원가입
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw AuthException('회원가입에 실패했습니다: ${e.toString()}');
    }
  }
  
  // 로그아웃
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException('로그아웃에 실패했습니다: ${e.toString()}');
    }
  }
  
  // 비밀번호 재설정
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw AuthException('비밀번호 재설정 이메일 전송에 실패했습니다: ${e.toString()}');
    }
  }
  
  // 이메일 인증
  Future<void> sendEmailVerification() async {
    final user = currentUser;
    if (user != null && !user.emailVerified) {
      try {
        await user.sendEmailVerification();
      } catch (e) {
        throw AuthException('이메일 인증 전송에 실패했습니다: ${e.toString()}');
      }
    }
  }
}

class AuthException implements Exception {
  final String message;
  
  const AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
}