import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_service.dart';

// 거래 설정 데이터 모델
class TradingSettings {
  final double maxLeverage;
  final bool dynamicLeverage;
  final double stopLossPercentage;
  final double takeProfitPercentage;
  final bool trailingStopEnabled;
  final double positionSizePercentage;
  final int maxConcurrentPositions;
  final bool autoPositionSizing;
  final bool autoTradingEnabled;
  final double minConfidenceThreshold;
  final bool nightTradingEnabled;

  const TradingSettings({
    required this.maxLeverage,
    required this.dynamicLeverage,
    required this.stopLossPercentage,
    required this.takeProfitPercentage,
    required this.trailingStopEnabled,
    required this.positionSizePercentage,
    required this.maxConcurrentPositions,
    required this.autoPositionSizing,
    required this.autoTradingEnabled,
    required this.minConfidenceThreshold,
    required this.nightTradingEnabled,
  });

  TradingSettings copyWith({
    double? maxLeverage,
    bool? dynamicLeverage,
    double? stopLossPercentage,
    double? takeProfitPercentage,
    bool? trailingStopEnabled,
    double? positionSizePercentage,
    int? maxConcurrentPositions,
    bool? autoPositionSizing,
    bool? autoTradingEnabled,
    double? minConfidenceThreshold,
    bool? nightTradingEnabled,
  }) {
    return TradingSettings(
      maxLeverage: maxLeverage ?? this.maxLeverage,
      dynamicLeverage: dynamicLeverage ?? this.dynamicLeverage,
      stopLossPercentage: stopLossPercentage ?? this.stopLossPercentage,
      takeProfitPercentage: takeProfitPercentage ?? this.takeProfitPercentage,
      trailingStopEnabled: trailingStopEnabled ?? this.trailingStopEnabled,
      positionSizePercentage: positionSizePercentage ?? this.positionSizePercentage,
      maxConcurrentPositions: maxConcurrentPositions ?? this.maxConcurrentPositions,
      autoPositionSizing: autoPositionSizing ?? this.autoPositionSizing,
      autoTradingEnabled: autoTradingEnabled ?? this.autoTradingEnabled,
      minConfidenceThreshold: minConfidenceThreshold ?? this.minConfidenceThreshold,
      nightTradingEnabled: nightTradingEnabled ?? this.nightTradingEnabled,
    );
  }

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'maxLeverage': maxLeverage,
      'dynamicLeverage': dynamicLeverage,
      'stopLossPercentage': stopLossPercentage,
      'takeProfitPercentage': takeProfitPercentage,
      'trailingStopEnabled': trailingStopEnabled,
      'positionSizePercentage': positionSizePercentage,
      'maxConcurrentPositions': maxConcurrentPositions,
      'autoPositionSizing': autoPositionSizing,
      'autoTradingEnabled': autoTradingEnabled,
      'minConfidenceThreshold': minConfidenceThreshold,
      'nightTradingEnabled': nightTradingEnabled,
    };
  }

  // JSON 역직렬화
  factory TradingSettings.fromJson(Map<String, dynamic> json) {
    return TradingSettings(
      maxLeverage: (json['maxLeverage'] as num?)?.toDouble() ?? 5.0,
      dynamicLeverage: json['dynamicLeverage'] as bool? ?? false,
      stopLossPercentage: (json['stopLossPercentage'] as num?)?.toDouble() ?? 5.0,
      takeProfitPercentage: (json['takeProfitPercentage'] as num?)?.toDouble() ?? 15.0,
      trailingStopEnabled: json['trailingStopEnabled'] as bool? ?? false,
      positionSizePercentage: (json['positionSizePercentage'] as num?)?.toDouble() ?? 5.0,
      maxConcurrentPositions: json['maxConcurrentPositions'] as int? ?? 3,
      autoPositionSizing: json['autoPositionSizing'] as bool? ?? false,
      autoTradingEnabled: json['autoTradingEnabled'] as bool? ?? false,
      minConfidenceThreshold: (json['minConfidenceThreshold'] as num?)?.toDouble() ?? 75.0,
      nightTradingEnabled: json['nightTradingEnabled'] as bool? ?? false,
    );
  }

  // 기본값
  static const TradingSettings defaultSettings = TradingSettings(
    maxLeverage: 5.0,
    dynamicLeverage: false,
    stopLossPercentage: 5.0,
    takeProfitPercentage: 15.0,
    trailingStopEnabled: false,
    positionSizePercentage: 5.0,
    maxConcurrentPositions: 3,
    autoPositionSizing: false,
    autoTradingEnabled: false,
    minConfidenceThreshold: 75.0,
    nightTradingEnabled: false,
  );
}

// 거래 설정 관리 클래스
class TradingSettingsNotifier extends StateNotifier<TradingSettings> {
  TradingSettingsNotifier(this._apiService) : super(TradingSettings.defaultSettings) {
    _loadSettings();
  }

  final ApiService _apiService;
  static const String _storageKey = 'trading_settings';
  static const String _currentUserId = 'user_001'; // TODO: 실제 사용자 ID 연동

  // 설정 로드 (API 우선, 로컬 백업)
  Future<void> _loadSettings() async {
    try {
      // 먼저 API에서 설정 로드 시도
      final response = await _apiService.getTradingSettings(_currentUserId);
      if (response.success) {
        state = _mapFromApiData(response.data);
        await _saveSettingsLocal(); // API 데이터를 로컬에 백업
        return;
      }
    } catch (e) {
      print('API에서 거래 설정 로드 실패, 로컬 설정 사용: $e');
    }

    // API 실패 시 로컬 설정 로드
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_storageKey);

      if (settingsJson != null) {
        // JSON 문자열을 Map으로 파싱하는 더 안전한 방법
        final Map<String, dynamic> settingsMap = {};
        final lines = settingsJson.split(',');

        for (final line in lines) {
          final parts = line.split(':');
          if (parts.length == 2) {
            final key = parts[0].trim().replaceAll('"', '');
            final value = parts[1].trim().replaceAll('"', '');

            // 타입별로 파싱
            if (key == 'maxLeverage' || key == 'stopLossPercentage' ||
                key == 'takeProfitPercentage' || key == 'positionSizePercentage' ||
                key == 'minConfidenceThreshold') {
              settingsMap[key] = double.tryParse(value) ?? 0.0;
            } else if (key == 'maxConcurrentPositions') {
              settingsMap[key] = int.tryParse(value) ?? 3;
            } else if (key == 'dynamicLeverage' || key == 'trailingStopEnabled' ||
                       key == 'autoPositionSizing' || key == 'autoTradingEnabled' ||
                       key == 'nightTradingEnabled') {
              settingsMap[key] = value.toLowerCase() == 'true';
            }
          }
        }

        state = TradingSettings.fromJson(settingsMap);
      }
    } catch (e) {
      print('로컬 거래 설정 로드 실패: $e');
      state = TradingSettings.defaultSettings;
    }
  }

  // API 데이터를 로컬 모델로 변환
  TradingSettings _mapFromApiData(TradingSettingsData apiData) {
    return TradingSettings(
      maxLeverage: apiData.maxLeverage,
      dynamicLeverage: apiData.dynamicLeverage,
      stopLossPercentage: apiData.stopLossPercentage,
      takeProfitPercentage: apiData.takeProfitPercentage,
      trailingStopEnabled: apiData.trailingStopEnabled,
      positionSizePercentage: apiData.positionSizePercentage,
      maxConcurrentPositions: apiData.maxConcurrentPositions,
      autoPositionSizing: apiData.autoPositionSizing,
      autoTradingEnabled: apiData.autoTradingEnabled,
      minConfidenceThreshold: apiData.minConfidenceThreshold,
      nightTradingEnabled: apiData.nightTradingEnabled,
    );
  }

  // 설정 저장 (API 우선, 로컬 백업)
  Future<void> _saveSettings() async {
    // API 저장 시도
    try {
      await _apiService.updateTradingSettings(
        userId: _currentUserId,
        settings: state.toJson(),
      );
    } catch (e) {
      print('API 거래 설정 저장 실패: $e');
    }

    // 로컬 저장 (백업)
    await _saveSettingsLocal();
  }

  // 로컬 설정 저장
  Future<void> _saveSettingsLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = _mapToSimpleString(state.toJson());
      await prefs.setString(_storageKey, settingsJson);
    } catch (e) {
      print('로컬 거래 설정 저장 실패: $e');
    }
  }

  // Map을 간단한 문자열로 변환 (JSON 라이브러리 없이)
  String _mapToSimpleString(Map<String, dynamic> map) {
    final buffer = StringBuffer();
    map.forEach((key, value) {
      if (buffer.isNotEmpty) buffer.write(',');
      buffer.write('"$key":"$value"');
    });
    return buffer.toString();
  }

  // 레버리지 설정 업데이트
  Future<void> updateMaxLeverage(double leverage) async {
    state = state.copyWith(maxLeverage: leverage);
    await _saveSettings();
  }

  // 동적 레버리지 토글
  Future<void> toggleDynamicLeverage(bool enabled) async {
    state = state.copyWith(dynamicLeverage: enabled);
    await _saveSettings();
  }

  // 손절매 비율 업데이트
  Future<void> updateStopLoss(double percentage) async {
    state = state.copyWith(stopLossPercentage: percentage);
    await _saveSettings();
  }

  // 익절 비율 업데이트
  Future<void> updateTakeProfit(double percentage) async {
    state = state.copyWith(takeProfitPercentage: percentage);
    await _saveSettings();
  }

  // 트레일링 스톱 토글
  Future<void> toggleTrailingStop(bool enabled) async {
    state = state.copyWith(trailingStopEnabled: enabled);
    await _saveSettings();
  }

  // 포지션 크기 업데이트
  Future<void> updatePositionSize(double percentage) async {
    state = state.copyWith(positionSizePercentage: percentage);
    await _saveSettings();
  }

  // 최대 포지션 수 업데이트
  Future<void> updateMaxPositions(int maxPositions) async {
    state = state.copyWith(maxConcurrentPositions: maxPositions);
    await _saveSettings();
  }

  // 자동 포지션 사이징 토글
  Future<void> toggleAutoPositionSizing(bool enabled) async {
    state = state.copyWith(autoPositionSizing: enabled);
    await _saveSettings();
  }

  // 자동 거래 토글
  Future<void> toggleAutoTrading(bool enabled) async {
    state = state.copyWith(autoTradingEnabled: enabled);
    await _saveSettings();
  }

  // 신뢰도 임계값 업데이트
  Future<void> updateConfidenceThreshold(double threshold) async {
    state = state.copyWith(minConfidenceThreshold: threshold);
    await _saveSettings();
  }

  // 야간 거래 토글
  Future<void> toggleNightTrading(bool enabled) async {
    state = state.copyWith(nightTradingEnabled: enabled);
    await _saveSettings();
  }

  // 모든 설정을 기본값으로 리셋
  Future<void> resetToDefaults() async {
    state = TradingSettings.defaultSettings;
    await _saveSettings();
  }

  // 리스크 레벨 계산 (낮음/중간/높음)
  String getRiskLevel() {
    int riskScore = 0;

    // 레버리지 점수 (20점 만점)
    if (state.maxLeverage >= 15) riskScore += 20;
    else if (state.maxLeverage >= 10) riskScore += 15;
    else if (state.maxLeverage >= 5) riskScore += 10;
    else riskScore += 5;

    // 손절매 점수 (20점 만점, 역산)
    if (state.stopLossPercentage <= 3) riskScore += 20;
    else if (state.stopLossPercentage <= 5) riskScore += 15;
    else if (state.stopLossPercentage <= 8) riskScore += 10;
    else riskScore += 5;

    // 포지션 크기 점수 (20점 만점)
    if (state.positionSizePercentage >= 20) riskScore += 20;
    else if (state.positionSizePercentage >= 15) riskScore += 15;
    else if (state.positionSizePercentage >= 10) riskScore += 10;
    else riskScore += 5;

    // 자동 거래 점수 (20점 만점)
    if (state.autoTradingEnabled) {
      if (state.minConfidenceThreshold <= 60) riskScore += 20;
      else if (state.minConfidenceThreshold <= 70) riskScore += 15;
      else if (state.minConfidenceThreshold <= 80) riskScore += 10;
      else riskScore += 5;
    } else {
      riskScore += 5;
    }

    // 기타 설정 점수 (20점 만점)
    if (state.nightTradingEnabled) riskScore += 5;
    if (!state.trailingStopEnabled) riskScore += 5;
    if (state.maxConcurrentPositions >= 7) riskScore += 10;
    else if (state.maxConcurrentPositions >= 5) riskScore += 5;

    // 총점에 따른 리스크 레벨 결정 (100점 만점)
    if (riskScore >= 70) return 'High';
    else if (riskScore >= 40) return 'Medium';
    else return 'Low';
  }

  // 예상 일일 최대 손실 계산
  double getEstimatedMaxDailyLoss() {
    return state.positionSizePercentage *
           state.maxConcurrentPositions *
           state.stopLossPercentage / 100;
  }

  // 예상 일일 최대 수익 계산
  double getEstimatedMaxDailyProfit() {
    return state.positionSizePercentage *
           state.maxConcurrentPositions *
           state.takeProfitPercentage / 100;
  }
}

// Provider 정의
final tradingSettingsProvider = StateNotifierProvider<TradingSettingsNotifier, TradingSettings>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return TradingSettingsNotifier(apiService);
});

// 거래 리스크 분석 프로바이더
final tradingRiskAnalysisProvider = FutureProvider<TradingRiskAnalysisResponse>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getTradingRiskAnalysis('user_001'); // TODO: 실제 사용자 ID
});

// 거래 성과 분석 프로바이더
final tradingPerformanceProvider = FutureProvider<TradingPerformanceResponse>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getTradingPerformance('user_001'); // TODO: 실제 사용자 ID
});

// 개별 설정값에 쉽게 접근할 수 있는 Provider들
final maxLeverageProvider = Provider<double>((ref) {
  return ref.watch(tradingSettingsProvider).maxLeverage;
});

final stopLossProvider = Provider<double>((ref) {
  return ref.watch(tradingSettingsProvider).stopLossPercentage;
});

final takeProfitProvider = Provider<double>((ref) {
  return ref.watch(tradingSettingsProvider).takeProfitPercentage;
});

final autoTradingEnabledProvider = Provider<bool>((ref) {
  return ref.watch(tradingSettingsProvider).autoTradingEnabled;
});

final riskLevelProvider = Provider<String>((ref) {
  return ref.read(tradingSettingsProvider.notifier).getRiskLevel();
});

final estimatedMaxDailyLossProvider = Provider<double>((ref) {
  return ref.read(tradingSettingsProvider.notifier).getEstimatedMaxDailyLoss();
});

final estimatedMaxDailyProfitProvider = Provider<double>((ref) {
  return ref.read(tradingSettingsProvider.notifier).getEstimatedMaxDailyProfit();
});