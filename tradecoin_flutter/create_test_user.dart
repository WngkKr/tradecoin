// 간단한 테스트 사용자 생성 스크립트
// firebase_admin이나 웹 콘솔 없이 클라이언트에서 직접 실행 가능

import 'dart:io';

void main() async {
  print('🧪 TradeCoin 테스트 사용자 생성 스크립트');
  print('=' * 50);

  // 유희남 계정 정보
  final userInfo = {
    'name': '유희남',
    'email': 'wngk7001@gmail.com',
    'password': 'wngk7001',
    'uid': 'test_user_${DateTime.now().millisecondsSinceEpoch}',
  };

  print('📋 생성할 사용자 정보:');
  print('   - 이름: ${userInfo['name']}');
  print('   - 이메일: ${userInfo['email']}');
  print('   - 비밀번호: ${userInfo['password']}');
  print('   - UID: ${userInfo['uid']}');

  print('\n🔥 Firebase 데이터 구조:');

  final firestoreData = {
    'uid': userInfo['uid'],
    'email': userInfo['email'],
    'displayName': userInfo['name'],
    'photoURL': null,
    'createdAt': DateTime.now().toIso8601String(),
    'updatedAt': DateTime.now().toIso8601String(),

    'subscription': {
      'tier': 'free',
      'status': 'active',
      'autoRenew': false,
      'startDate': null,
      'endDate': null
    },

    'profile': {
      'experienceLevel': 'beginner',
      'riskTolerance': 'conservative',
      'preferredCoins': ['BTC', 'ETH'],
      'investmentGoal': null,
      'monthlyBudget': null
    },

    'settings': {
      'notifications': {
        'push': true,
        'email': true,
        'sms': false,
        'signalThreshold': 75
      },
      'trading': {
        'autoTrading': false,
        'maxPositions': 2,
        'maxLeverage': 5,
        'stopLoss': 3.0,
        'takeProfit': 10.0
      }
    },

    'stats': {
      'signalsUsed': 0,
      'tradesExecuted': 0,
      'totalPnL': 0.0,
      'winRate': 0.0,
      'lastLogin': DateTime.now().toIso8601String()
    },

    'isActive': true,
    'version': 1
  };

  print('\n📝 Firestore 문서 구조:');
  print('Collection: users');
  print('Document ID: ${userInfo['uid']}');
  print('Data: ${_prettyPrintJson(firestoreData)}');

  print('\n🔧 수동 생성 방법:');
  print('1. Firebase Console (https://console.firebase.google.com)');
  print('2. 프로젝트: emotra-9ebdb');
  print('3. Firestore Database');
  print('4. 컬렉션 "users" 생성');
  print('5. 문서 ID: ${userInfo['uid']}');
  print('6. 위의 데이터 구조 복사하여 입력');

  print('\n🚀 앱에서 로그인 테스트:');
  print('   이메일: ${userInfo['email']}');
  print('   비밀번호: ${userInfo['password']}');

  print('\n=' * 50);
  print('✅ 테스트 사용자 정보 생성 완료');
}

String _prettyPrintJson(Map<String, dynamic> json) {
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(json);
}

class JsonEncoder {
  final String? indent;

  const JsonEncoder.withIndent(this.indent);

  String convert(Map<String, dynamic> object) {
    return _encodeMap(object, 0);
  }

  String _encodeMap(Map<String, dynamic> map, int indentLevel) {
    if (map.isEmpty) return '{}';

    final indent = (this.indent ?? '') * indentLevel;
    final nextIndent = (this.indent ?? '') * (indentLevel + 1);

    final entries = map.entries.map((entry) {
      final key = '"${entry.key}"';
      final value = _encodeValue(entry.value, indentLevel + 1);
      return '$nextIndent$key: $value';
    }).join(',\n');

    return '{\n$entries\n$indent}';
  }

  String _encodeValue(dynamic value, int indentLevel) {
    if (value == null) return 'null';
    if (value is String) return '"$value"';
    if (value is num) return value.toString();
    if (value is bool) return value.toString();
    if (value is Map<String, dynamic>) return _encodeMap(value, indentLevel);
    if (value is List) return _encodeList(value, indentLevel);
    return '"$value"';
  }

  String _encodeList(List list, int indentLevel) {
    if (list.isEmpty) return '[]';

    final indent = (this.indent ?? '') * indentLevel;
    final nextIndent = (this.indent ?? '') * (indentLevel + 1);

    final items = list.map((item) {
      final value = _encodeValue(item, indentLevel + 1);
      return '$nextIndent$value';
    }).join(',\n');

    return '[\n$items\n$indent]';
  }
}