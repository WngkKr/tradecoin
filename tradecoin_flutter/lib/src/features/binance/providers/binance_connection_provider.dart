import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';

// 바이낸스 연결 상태를 나타내는 클래스
class BinanceConnectionState {
  final bool isConnected;
  final String accountType;
  final bool isLoading;
  final String? error;
  final dynamic accountInfo;

  const BinanceConnectionState({
    this.isConnected = false,
    this.accountType = 'demo',
    this.isLoading = false,
    this.error,
    this.accountInfo,
  });

  BinanceConnectionState copyWith({
    bool? isConnected,
    String? accountType,
    bool? isLoading,
    String? error,
    dynamic accountInfo,
  }) {
    return BinanceConnectionState(
      isConnected: isConnected ?? this.isConnected,
      accountType: accountType ?? this.accountType,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      accountInfo: accountInfo ?? this.accountInfo,
    );
  }
}

// 바이낸스 연결 상태 Provider
class BinanceConnectionNotifier extends StateNotifier<BinanceConnectionState> {
  BinanceConnectionNotifier(this._ref) : super(const BinanceConnectionState());

  final Ref _ref;

  // 연결 상태 확인
  Future<void> checkConnectionStatus() async {
    print('🔄 BinanceConnectionProvider: 연결 상태 확인 시작');
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 먼저 로컬 저장된 API 키 상태 확인
      print('🔍 로컬 API 키 상태 확인 중...');
      final hasLocalApiKey = await _checkLocalApiKeyStatus();

      if (hasLocalApiKey) {
        print('✅ 로컬 API 키 확인됨 - 자동 연결 시도 완료');
        // _checkLocalApiKeyStatus에서 이미 자동 연결을 시도함
        return;
      }

      // 로컬에 API 키가 없으면 연결 안 된 상태로 설정
      print('⚠️ 로컬 API 키가 없음 - 데모 모드로 설정');
      state = state.copyWith(
        isConnected: false,
        accountType: 'demo',
        isLoading: false,
        error: null,
      );
    } catch (e) {
      print('❌ 연결 상태 확인 실패: $e');
      state = state.copyWith(
        isConnected: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // 바이낸스 계정 정보 가져오기
  Future<void> _fetchAccountInfo() async {
    try {
      final authState = _ref.read(authStateProvider);
      final currentUser = authState.userData;

      if (currentUser == null) return;

      final response = await ApiService().getBinanceAccountInfo(currentUser.uid);

      state = state.copyWith(
        accountInfo: response.data,
      );
    } catch (e) {
      // 계정 정보를 가져오지 못해도 연결 상태는 유지
      print('계정 정보 가져오기 실패: $e');
    }
  }

  // 연결 설정
  void setConnection(bool isConnected, {String? accountType, dynamic accountInfo}) {
    state = state.copyWith(
      isConnected: isConnected,
      accountType: accountType ?? state.accountType,
      accountInfo: accountInfo,
      error: null,
    );
  }

  // 연결 해제
  void disconnect() {
    state = const BinanceConnectionState(
      isConnected: false,
      accountType: 'demo',
      isLoading: false,
    );
  }

  // 에러 상태 설정
  void setError(String error) {
    state = state.copyWith(
      error: error,
      isLoading: false,
    );
  }

  // 로컬 API 키 상태 확인 및 자동 연결
  Future<bool> _checkLocalApiKeyStatus() async {
    try {
      print('🔍 [바이낸스] 로컬 API 키 상태 확인 시작...');
      final storage = StorageService.instance;
      var keyData = await storage.loadBinanceApiKeys();
      print('🔍 [바이낸스] 로드된 키 데이터: ${keyData != null ? keyData.keys.toList() : 'null'}');

      // 🧪 개발 모드: 저장된 키가 없으면 자동으로 개발용 키 저장
      if (keyData == null || keyData['hasApiKey'] != true) {
        print('🧪 [개발] 저장된 API 키 없음 - 개발용 키 자동 저장 시작');
        // DevConfig에서 키 가져오기
        const devApiKey = 'jhoeFXEYEzkkDZrRViFvlbkAmBM70KCnSn1zxQVv9ytI2iAo00qeanW2DB4Yv2Yx';
        const devSecretKey = 'rQmNdhZKzOalGuArsdY5foUkhCS8LnkvCwd4gTaIDDRgK0RL2dvuWpJ9HnemMRIg';
        const devIsTestnet = false;

        // 개발용 키 저장
        final saved = await storage.saveBinanceApiKeys(
          apiKey: devApiKey,
          secretKey: devSecretKey,
          isTestnet: devIsTestnet,
        );

        if (saved) {
          print('✅ [개발] 개발용 API 키 저장 완료');
          // 저장 후 다시 로드
          keyData = await storage.loadBinanceApiKeys();
        } else {
          print('❌ [개발] 개발용 API 키 저장 실패');
          return false;
        }
      }

      if (keyData != null && keyData['hasApiKey'] == true) {
        print('🔍 [바이낸스] API 키 존재 확인됨');
        final isTestnet = keyData['isTestnet'] as bool;
        final apiKey = keyData['apiKey'] as String;
        final secretKey = keyData['secretKey'] as String;

        print('🔍 [바이낸스] 테스트넷 모드: $isTestnet');
        print('🔍 [바이낸스] API 키 길이: ${apiKey.length}');
        print('🔍 [바이낸스] 시크릿 키 길이: ${secretKey.length}');

        // API 키가 실제로 존재하는지 확인
        if (apiKey.isNotEmpty && secretKey.isNotEmpty) {
          print('🚀 [바이낸스] API 키 유효성 확인됨 - 자동 연결 시도 시작');
          // 자동으로 바이낸스 연결 시도
          await _autoConnectWithStoredKeys(apiKey, secretKey, isTestnet);
          return true;
        } else {
          print('❌ [바이낸스] API 키가 비어있음');
          // API 키가 없으면 연결 해제 상태로 설정
          state = state.copyWith(
            isConnected: false,
            accountType: 'demo',
            isLoading: false,
            error: '저장된 API 키가 없습니다',
          );
          return false;
        }
      } else {
        print('❌ [바이낸스] 저장된 API 키가 없음');
        return false;
      }
    } catch (e) {
      print('❌ [바이낸스] 로컬 API 키 상태 확인 실패: $e');
      return false;
    }
  }

  // 저장된 키로 자동 연결
  Future<void> _autoConnectWithStoredKeys(String apiKey, String secretKey, bool isTestnet) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      print('🔄 [바이낸스] 저장된 API 키로 자동 연결 시도 시작');
      print('🔄 [바이낸스] 모드: ${isTestnet ? 'TESTNET' : 'MAINNET'}');
      print('🔄 [바이낸스] API 키: ${apiKey.length > 8 ? '${apiKey.substring(0, 4)}***${apiKey.substring(apiKey.length - 4)}' : 'Invalid'}');
      print('🔄 [바이낸스] 시크릿 키 길이: ${secretKey.length}자');

      // 먼저 키 유효성 검증
      if (apiKey.isEmpty || secretKey.isEmpty) {
        print('❌ [바이낸스] API 키 또는 시크릿 키가 비어있음');
        throw Exception('API 키 또는 시크릿 키가 비어있습니다');
      }

      if (apiKey.length < 20 || secretKey.length < 20) {
        print('❌ [바이낸스] API 키 형식이 올바르지 않음 - API키:${apiKey.length}자, 시크릿:${secretKey.length}자');
        throw Exception('API 키 형식이 올바르지 않습니다');
      }

      // 사용자 ID 가져오기
      final authState = _ref.read(authStateProvider);
      final currentUser = authState.userData;

      if (currentUser == null) {
        print('❌ [바이낸스] 사용자 정보 없음');
        throw Exception('로그인이 필요합니다');
      }

      print('🚀 [바이낸스] 백엔드로 API 키 저장 시도...');

      // 백엔드로 API 키 전송하여 DB에 저장
      final saveResult = await _saveApiKeysToBackend(
        currentUser.uid,
        apiKey,
        secretKey,
        isTestnet,
      );

      if (saveResult) {
        print('✅ [바이낸스] 백엔드에 API 키 저장 성공! 🎉');

        // 연결 성공 시 상태 업데이트
        state = state.copyWith(
          isConnected: true,
          accountType: isTestnet ? 'testnet' : 'live',
          isLoading: false,
          error: null,
          accountInfo: {
            'accountType': isTestnet ? 'TESTNET' : 'LIVE',
            'canTrade': true,
            'message': '바이낸스 연결 완료'
          },
        );

        print('✅ [바이낸스] 연결 상태 업데이트 완료 - 계정 타입: ${isTestnet ? 'testnet' : 'live'}');
        print('✅ [바이낸스] isConnected: ${state.isConnected}');

        // 포트폴리오 데이터 즉시 로딩
        print('🔄 [바이낸스] 포트폴리오 데이터 자동 로딩 시작...');
        await _loadInitialPortfolio(currentUser.uid);

        // 사용자 데이터 새로고침
        await _refreshUserData(currentUser.uid);
      } else {
        print('❌ [바이낸스] 백엔드 저장 실패');
        throw Exception('API 키 저장에 실패했습니다');
      }
    } catch (e) {
      print('❌ [바이낸스] 자동 연결 중 예외 발생: $e');
      print('❌ [바이낸스] 예외 타입: ${e.runtimeType}');

      // 🔒 보안 개선: 연결 실패 시 키를 삭제하지 않고 유지
      // 사용자가 프로필 화면에서 직접 수정/삭제할 수 있도록 함
      print('⚠️ [바이낸스] API 키는 유지됩니다. 프로필 화면에서 확인해주세요.');

      state = state.copyWith(
        isConnected: false,
        accountType: 'demo',
        isLoading: false,
        error: '바이낸스 연결 실패: ${e.toString()}\nAPI 키를 다시 확인해주세요.',
      );
      print('❌ [바이낸스] 최종 연결 상태: isConnected=${state.isConnected}, error=${state.error}');
    }
  }

  // 백엔드에 API 키 저장
  Future<bool> _saveApiKeysToBackend(
    String userId,
    String apiKey,
    String secretKey,
    bool isTestnet,
  ) async {
    try {
      print('📤 [백엔드] API 키 저장 요청 시작...');
      print('   사용자 ID: $userId');
      print('   모드: ${isTestnet ? 'TESTNET' : 'MAINNET'}');

      await ApiService().updateBinanceKeys(
        userId: userId,
        apiKey: apiKey,
        secretKey: secretKey,
        isTestnet: isTestnet,
      );

      print('✅ [백엔드] API 키 저장 성공');
      return true;
    } catch (e) {
      print('❌ [백엔드] API 키 저장 중 오류: $e');
      return false;
    }
  }


  // 초기 포트폴리오 로딩
  Future<void> _loadInitialPortfolio(String userId) async {
    try {
      print('📊 [포트폴리오] 초기 로딩 시작...');
      final apiService = ApiService();

      // 포트폴리오 요약 데이터 로드
      final portfolioData = await apiService.getUserPortfolioSummary(userId);
      print('✅ [포트폴리오] 초기 데이터 로드 성공');
      print('   총 자산: \$${portfolioData.data.totalBalance}');
      print('   수익률: ${portfolioData.data.totalProfitPercent}%');

      // 바이낸스 계정 정보도 함께 로드
      try {
        final accountInfo = await apiService.getBinanceAccountInfo(userId);
        print('✅ [계정 정보] 초기 데이터 로드 성공');
        print('   계정 타입: ${accountInfo.data.accountType}');
        print('   거래 가능: ${accountInfo.data.canTrade}');
      } catch (e) {
        print('⚠️ [계정 정보] 로드 실패 (포트폴리오 데이터는 로드됨): $e');
      }

    } catch (e) {
      print('❌ [포트폴리오] 초기 로딩 실패: $e');
      // 포트폴리오 로딩 실패해도 연결은 유지
    }
  }

  // 바이낸스 연결 후 사용자 데이터 자동 새로고침
  Future<void> _refreshUserData(String userId) async {
    try {
      print('🔄 바이낸스 연결 후 개인 데이터 새로고침 시작...');

      // 포트폴리오 데이터 새로고침 트리거
      final apiService = ApiService();

      // 사용자별 포트폴리오 데이터 미리 요청하여 캐시 갱신
      try {
        await apiService.getUserPortfolioSummary(userId);
        print('✅ 포트폴리오 요약 데이터 새로고침 완료');
      } catch (e) {
        print('⚠️ 포트폴리오 요약 새로고침 실패: $e');
      }

      // 바이낸스 계정 정보 새로고침
      try {
        await apiService.getBinanceAccountInfo(userId);
        print('✅ 바이낸스 계정 정보 새로고침 완료');
      } catch (e) {
        print('⚠️ 바이낸스 계정 정보 새로고침 실패: $e');
      }

      print('✅ 모든 데이터 Provider 새로고침 완료');

    } catch (e) {
      print('❌ 개인 데이터 새로고침 실패: $e');
    }
  }
}

// Provider 정의
final binanceConnectionProvider = StateNotifierProvider<BinanceConnectionNotifier, BinanceConnectionState>((ref) {
  return BinanceConnectionNotifier(ref);
});

// 연결 상태만 간단히 접근하는 Provider
final binanceConnectedProvider = Provider<bool>((ref) {
  return ref.watch(binanceConnectionProvider).isConnected;
});

// 계정 타입만 간단히 접근하는 Provider
final binanceAccountTypeProvider = Provider<String>((ref) {
  return ref.watch(binanceConnectionProvider).accountType;
});

// 계정 정보만 간단히 접근하는 Provider
final binanceAccountInfoProvider = Provider<dynamic>((ref) {
  return ref.watch(binanceConnectionProvider).accountInfo;
});