import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/models/user_model.dart';

/// Firestore 데이터베이스 서비스
/// 모든 Firestore 작업을 중앙에서 관리
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton 패턴
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  /// 현재 사용자 UID
  String? get currentUserId => _auth.currentUser?.uid;

  // ========================================
  // Collection 참조
  // ========================================

  /// 사용자 컬렉션
  CollectionReference<Map<String, dynamic>> get usersCollection =>
      _firestore.collection('users');

  /// 시그널 컬렉션
  CollectionReference<Map<String, dynamic>> get signalsCollection =>
      _firestore.collection('signals');

  /// 사용자별 포트폴리오 컬렉션
  CollectionReference<Map<String, dynamic>> userPortfolioCollection(
          String userId) =>
      _firestore.collection('userPortfolios/$userId/assets');

  /// 사용자별 거래 내역 컬렉션
  CollectionReference<Map<String, dynamic>> userTradesCollection(
          String userId) =>
      _firestore.collection('userTrades/$userId/trades');

  // ========================================
  // 사용자 데이터 관리
  // ========================================

  /// 사용자 프로필 생성
  Future<void> createUserProfile({
    required String userId,
    required String email,
    String? displayName,
    String? photoURL,
  }) async {
    try {
      await usersCollection.doc(userId).set({
        'uid': userId,
        'email': email,
        'displayName': displayName ?? email.split('@')[0],
        'photoURL': photoURL,

        // 멤버십 정보
        'subscription': {
          'tier': 'free',
          'status': 'active',
          'startDate': FieldValue.serverTimestamp(),
          'endDate': null,
          'autoRenew': false,
        },

        // 투자 프로필
        'profile': {
          'experienceLevel': 'beginner',
          'riskTolerance': 'moderate',
          'preferredCoins': ['BTC', 'ETH'],
          'investmentGoal': '',
          'monthlyBudget': 0,
        },

        // 설정
        'settings': {
          'notifications': {
            'push': true,
            'email': true,
            'sms': false,
            'signalThreshold': 70,
          },
          'trading': {
            'autoTrading': false,
            'maxPositions': 2,
            'maxLeverage': 5,
            'stopLoss': 3,
            'takeProfit': 10,
          },
        },

        // 통계
        'stats': {
          'signalsUsed': 0,
          'tradesExecuted': 0,
          'totalPnL': 0.0,
          'winRate': 0.0,
          'lastLogin': FieldValue.serverTimestamp(),
        },

        // 메타데이터
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'version': 1,
      });

      print('✅ Firestore: 사용자 프로필 생성 완료 ($email)');
    } catch (e) {
      print('❌ Firestore: 사용자 프로필 생성 실패 - $e');
      rethrow;
    }
  }

  /// 사용자 프로필 조회
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await usersCollection.doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('❌ Firestore: 사용자 프로필 조회 실패 - $e');
      return null;
    }
  }

  /// 사용자 프로필 업데이트
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await usersCollection.doc(userId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Firestore: 사용자 프로필 업데이트 완료');
    } catch (e) {
      print('❌ Firestore: 사용자 프로필 업데이트 실패 - $e');
      rethrow;
    }
  }

  /// 사용자 프로필 실시간 스트림
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUserProfile(
      String userId) {
    return usersCollection.doc(userId).snapshots();
  }

  // ========================================
  // 시그널 데이터 관리
  // ========================================

  /// 시그널 생성
  Future<String> createSignal(Map<String, dynamic> signalData) async {
    try {
      final docRef = await signalsCollection.add({
        ...signalData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Firestore: 시그널 생성 완료 (${docRef.id})');
      return docRef.id;
    } catch (e) {
      print('❌ Firestore: 시그널 생성 실패 - $e');
      rethrow;
    }
  }

  /// 최신 시그널 조회 (신뢰도순)
  Future<List<Map<String, dynamic>>> getRecentSignals({
    int limit = 20,
    double minConfidence = 0,
  }) async {
    try {
      Query<Map<String, dynamic>> query = signalsCollection
          .where('confidence', isGreaterThanOrEqualTo: minConfidence)
          .orderBy('confidence', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      print('❌ Firestore: 시그널 조회 실패 - $e');
      return [];
    }
  }

  /// 특정 코인 시그널 조회
  Future<List<Map<String, dynamic>>> getSignalsByCoin(String coinSymbol) async {
    try {
      final snapshot = await signalsCollection
          .where('coinSymbol', isEqualTo: coinSymbol)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      print('❌ Firestore: 코인별 시그널 조회 실패 - $e');
      return [];
    }
  }

  /// 시그널 실시간 스트림
  Stream<QuerySnapshot<Map<String, dynamic>>> watchSignals({
    double minConfidence = 70,
  }) {
    return signalsCollection
        .where('confidence', isGreaterThanOrEqualTo: minConfidence)
        .orderBy('confidence', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();
  }

  // ========================================
  // 포트폴리오 관리
  // ========================================

  /// 포트폴리오에 자산 추가
  Future<void> addPortfolioAsset({
    required String userId,
    required String symbol,
    required String name,
    required double amount,
    required double averagePrice,
  }) async {
    try {
      await userPortfolioCollection(userId).doc(symbol).set({
        'symbol': symbol,
        'name': name,
        'amount': amount,
        'averagePrice': averagePrice,
        'currentPrice': averagePrice,
        'pnl': 0.0,
        'pnlPercent': 0.0,
        'addedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Firestore: 포트폴리오 자산 추가 ($symbol)');
    } catch (e) {
      print('❌ Firestore: 포트폴리오 자산 추가 실패 - $e');
      rethrow;
    }
  }

  /// 포트폴리오 자산 업데이트
  Future<void> updatePortfolioAsset({
    required String userId,
    required String symbol,
    required Map<String, dynamic> data,
  }) async {
    try {
      await userPortfolioCollection(userId).doc(symbol).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Firestore: 포트폴리오 자산 업데이트 ($symbol)');
    } catch (e) {
      print('❌ Firestore: 포트폴리오 자산 업데이트 실패 - $e');
      rethrow;
    }
  }

  /// 포트폴리오 자산 삭제
  Future<void> removePortfolioAsset({
    required String userId,
    required String symbol,
  }) async {
    try {
      await userPortfolioCollection(userId).doc(symbol).delete();
      print('✅ Firestore: 포트폴리오 자산 삭제 ($symbol)');
    } catch (e) {
      print('❌ Firestore: 포트폴리오 자산 삭제 실패 - $e');
      rethrow;
    }
  }

  /// 포트폴리오 조회
  Future<List<Map<String, dynamic>>> getPortfolio(String userId) async {
    try {
      final snapshot = await userPortfolioCollection(userId).get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      print('❌ Firestore: 포트폴리오 조회 실패 - $e');
      return [];
    }
  }

  /// 포트폴리오 실시간 스트림
  Stream<QuerySnapshot<Map<String, dynamic>>> watchPortfolio(String userId) {
    return userPortfolioCollection(userId).snapshots();
  }

  // ========================================
  // 거래 내역 관리
  // ========================================

  /// 거래 내역 추가
  Future<String> addTrade({
    required String userId,
    required Map<String, dynamic> tradeData,
  }) async {
    try {
      final docRef = await userTradesCollection(userId).add({
        ...tradeData,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Firestore: 거래 내역 추가 (${docRef.id})');
      return docRef.id;
    } catch (e) {
      print('❌ Firestore: 거래 내역 추가 실패 - $e');
      rethrow;
    }
  }

  /// 거래 내역 조회
  Future<List<Map<String, dynamic>>> getTrades(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await userTradesCollection(userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      print('❌ Firestore: 거래 내역 조회 실패 - $e');
      return [];
    }
  }

  // ========================================
  // 배치 작업
  // ========================================

  /// 여러 문서를 한 번에 업데이트 (Batch Write)
  Future<void> batchUpdate(List<Map<String, dynamic>> updates) async {
    try {
      final batch = _firestore.batch();

      for (final update in updates) {
        final docRef = update['docRef'] as DocumentReference;
        final data = update['data'] as Map<String, dynamic>;
        batch.update(docRef, data);
      }

      await batch.commit();
      print('✅ Firestore: 배치 업데이트 완료 (${updates.length}개)');
    } catch (e) {
      print('❌ Firestore: 배치 업데이트 실패 - $e');
      rethrow;
    }
  }
}
