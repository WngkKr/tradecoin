import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../models/settings_model.dart';

class SettingsService {
  static final String _baseUrl = AppConstants.apiBaseUrl;

  // 알림 설정 가져오기
  Future<NotificationSettings> getNotificationSettings(String userId) async {
    try {
      print('🔔 [알림 설정] 조회 시작: $userId');

      final response = await http.get(
        Uri.parse('$_baseUrl/api/settings/notifications/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          print('✅ [알림 설정] 조회 성공');
          return NotificationSettings.fromJson(data['data']);
        } else {
          throw Exception(data['error'] ?? 'Unknown error');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ [알림 설정] 조회 실패: $e');
      // 기본 설정 반환
      return NotificationSettings.defaultSettings();
    }
  }

  // 알림 설정 업데이트
  Future<bool> updateNotificationSettings(String userId, NotificationSettings settings) async {
    try {
      print('🔔 [알림 설정] 업데이트 시작: $userId');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/settings/notifications/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(settings.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          print('✅ [알림 설정] 업데이트 성공');
          return true;
        } else {
          throw Exception(data['error'] ?? 'Unknown error');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ [알림 설정] 업데이트 실패: $e');
      return false;
    }
  }

  // 거래 설정 가져오기
  Future<TradingSettings> getTradingSettings(String userId) async {
    try {
      print('⚙️ [거래 설정] 조회 시작: $userId');

      final response = await http.get(
        Uri.parse('$_baseUrl/api/settings/auto-trading/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          print('✅ [거래 설정] 조회 성공');
          return TradingSettings.fromJson(data['data']);
        } else {
          throw Exception(data['error'] ?? 'Unknown error');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ [거래 설정] 조회 실패: $e');
      // 기본 설정 반환
      return TradingSettings.defaultSettings();
    }
  }

  // 거래 설정 업데이트
  Future<bool> updateTradingSettings(String userId, TradingSettings settings) async {
    try {
      print('⚙️ [거래 설정] 업데이트 시작: $userId');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/settings/auto-trading/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(settings.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          print('✅ [거래 설정] 업데이트 성공');
          return true;
        } else {
          throw Exception(data['error'] ?? 'Unknown error');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ [거래 설정] 업데이트 실패: $e');
      return false;
    }
  }

  // 리스크 관리 설정 가져오기
  Future<RiskManagementSettings> getRiskManagementSettings(String userId) async {
    try {
      print('⚠️ [리스크 관리] 조회 시작: $userId');

      final response = await http.get(
        Uri.parse('$_baseUrl/api/settings/risk-management/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          print('✅ [리스크 관리] 조회 성공');
          return RiskManagementSettings.fromJson(data['data']);
        } else {
          throw Exception(data['error'] ?? 'Unknown error');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ [리스크 관리] 조회 실패: $e');
      // 기본 설정 반환
      return RiskManagementSettings.defaultSettings();
    }
  }

  // 리스크 관리 설정 업데이트
  Future<bool> updateRiskManagementSettings(String userId, RiskManagementSettings settings) async {
    try {
      print('⚠️ [리스크 관리] 업데이트 시작: $userId');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/settings/risk-management/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(settings.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          print('✅ [리스크 관리] 업데이트 성공');
          return true;
        } else {
          throw Exception(data['error'] ?? 'Unknown error');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ [리스크 관리] 업데이트 실패: $e');
      return false;
    }
  }

  // 사용자 프로필 업데이트
  Future<bool> updateUserProfile(String userId, Map<String, dynamic> profileData) async {
    try {
      print('👤 [사용자 프로필] 업데이트 시작: $userId');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/user/profile/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(profileData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          print('✅ [사용자 프로필] 업데이트 성공');
          return true;
        } else {
          throw Exception(data['error'] ?? 'Unknown error');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ [사용자 프로필] 업데이트 실패: $e');
      return false;
    }
  }

  // 보안 설정 업데이트
  Future<bool> updateSecuritySettings(String userId, Map<String, dynamic> securityData) async {
    try {
      print('🔒 [보안 설정] 업데이트 시작: $userId');

      final response = await http.put(
        Uri.parse('$_baseUrl/api/user/$userId/security'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(securityData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          print('✅ [보안 설정] 업데이트 성공');
          return true;
        } else {
          throw Exception(data['error'] ?? 'Unknown error');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ [보안 설정] 업데이트 실패: $e');
      return false;
    }
  }
}