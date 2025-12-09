import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/services/storage_service.dart';
import 'dart:ui';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/widgets/cyberpunk_header.dart';
import '../../auth/providers/auth_provider.dart';
import '../../binance/providers/binance_connection_provider.dart';
import '../../settings/screens/notification_settings_screen.dart';
import '../../debug/screens/api_test_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _apiSecretController = TextEditingController();
  bool _isTestnet = true;
  bool _showApiSecret = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();

    // 중복 바이낸스 연결 확인 제거 - MainScaffold에서 이미 처리됨
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('👤 ProfileScreen: API 키 로드만 수행 (바이낸스 연결은 MainScaffold에서 처리)');
      _loadApiKeys();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _apiKeyController.dispose();
    _apiSecretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      appBar: const CyberpunkHeader(),
      body: Container(
        decoration: BoxDecoration(
          gradient: themeState.isDarkMode
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E1B4B),
                  Color(0xFF312E81),
                  Color(0xFF3730A3),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8FAFC),
                  Color(0xFFE2E8F0),
                  Color(0xFFCBD5E1),
                ],
              ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 프로필 헤더
                _buildProfileHeader(),
                const SizedBox(height: 24),
                
                // 계정 정보
                _buildAccountInfo(),
                const SizedBox(height: 24),

                // 바이낸스 연결 정보
                _buildBinanceInfo(),
                const SizedBox(height: 24),

                // 설정 옵션
                _buildSettings(),
                const SizedBox(height: 24),
                
                // 보안 설정
                _buildSecuritySettings(),
                const SizedBox(height: 24),
                
                // 로그아웃 버튼
                _buildLogoutButton(),
                
                const SizedBox(height: 100), // 하단 네비게이션 공간
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassmorphism(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Column(
            children: [
              // 프로필 이미지
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    colors: [
                      AppTheme.accentBlue,
                      AppTheme.primaryBlue,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentBlue.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 16),
              
              // 사용자 정보
              Consumer(
                builder: (context, ref, child) {
                  final authState = ref.watch(authStateProvider);
                  final userData = authState.userData;

                  return Column(
                    children: [
                      Text(
                        userData?.displayName ?? 'TradeCoin User',
                        style: AppTheme.headingMedium.copyWith(
                          color: AppTheme.accentBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        userData?.email ?? 'user@tradecoin.ai',
                        style: AppTheme.bodyMedium,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // 가입 정보
              Consumer(
                builder: (context, ref, child) {
                  final authState = ref.watch(authStateProvider);
                  final userData = authState.userData;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildProfileStat(
                        '가입일',
                        DateFormat('yyyy.MM.dd').format(userData?.createdAt ?? DateTime.now()),
                        AppTheme.accentBlue
                      ),
                      _buildProfileStat(
                        '등급',
                        _getMembershipDisplayName(userData?.subscription.tier ?? 'free').replaceAll(RegExp(r'[🆓💎👑🏆]'), '').trim().toUpperCase(),
                        AppTheme.primaryBlue
                      ),
                      _buildProfileStat(
                        '거래횟수',
                        (userData?.stats?.tradesExecuted ?? 0).toString(),
                        AppTheme.successGreen
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildAccountInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassmorphism(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '계정 정보',
                    style: AppTheme.headingMedium.copyWith(
                      color: AppTheme.neutralGray,
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/profile-edit'),
                    icon: const Icon(Icons.edit_outlined),
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    ),
                    tooltip: '프로필 편집',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  final authState = ref.watch(authStateProvider);
                  final userData = authState.userData;

                  return Column(
                    children: [
                      _buildInfoItem(
                        '이름',
                        userData?.displayName ?? 'TradeCoin User',
                        Icons.person_outline,
                      ),
                      _buildInfoItem(
                        '이메일',
                        userData?.email ?? 'user@tradecoin.ai',
                        Icons.email_outlined,
                      ),
                      _buildInfoItem(
                        '멤버십',
                        _getMembershipDisplayName(userData?.subscription.tier ?? 'free'),
                        Icons.diamond_outlined,
                      ),
                      _buildInfoItem(
                        '투자 성향',
                        _getRiskToleranceDisplayName(userData?.profile.riskTolerance ?? 'conservative'),
                        Icons.trending_up_outlined,
                      ),
                      _buildInfoItem(
                        '투자 경험',
                        _getExperienceLevelDisplayName(userData?.profile.experienceLevel ?? 'beginner'),
                        Icons.military_tech_outlined,
                      ),
                      _buildInfoItem(
                        '관심 코인',
                        userData?.profile.preferredCoins.isEmpty == true
                          ? '선택안함'
                          : (userData?.profile.preferredCoins.take(3).join(', ') ?? 'BTC, ETH'),
                        Icons.currency_bitcoin,
                      ),
                      _buildInfoItem(
                        '가입일',
                        DateFormat('yyyy년 MM월 dd일').format(userData?.createdAt ?? DateTime.now()),
                        Icons.calendar_today_outlined,
                      ),
                      _buildInfoItem(
                        '최근 업데이트',
                        DateFormat('yyyy년 MM월 dd일 HH:mm').format(userData?.updatedAt ?? DateTime.now()),
                        Icons.access_time_outlined,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1A1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x331E293B)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.accentBlue,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: AppTheme.accentBlue,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildBinanceInfo() {
    return Consumer(
      builder: (context, ref, child) {
        final connectionState = ref.watch(binanceConnectionProvider);
        final authState = ref.watch(authStateProvider);
        final userData = authState.userData;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.glassmorphism(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.currency_bitcoin,
                        color: AppTheme.accentBlue,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Binance 연결 정보',
                        style: AppTheme.headingMedium.copyWith(
                          color: AppTheme.neutralGray,
                        ),
                      ),
                      const Spacer(),
                      _buildConnectionStatus(connectionState.isConnected),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (!connectionState.isConnected) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.warningOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.warningOrange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppTheme.warningOrange,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Binance API가 연결되지 않았습니다.\n포트폴리오에서 연결을 설정해주세요.',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.warningOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    _buildInfoItem(
                      '계정 타입',
                      connectionState.accountType == 'demo' ? 'Testnet (데모)' : 'Live (실계정)',
                      Icons.account_balance,
                    ),
                    if (connectionState.accountInfo != null) ...[
                      _buildInfoItem(
                        '총 잔고',
                        '${connectionState.accountInfo['totalWalletBalance']?.toString() ?? '0'} USDT',
                        Icons.account_balance_wallet,
                      ),
                      _buildInfoItem(
                        '거래 권한',
                        connectionState.accountInfo['canTrade'] == true ? '활성화' : '비활성화',
                        Icons.swap_horiz,
                      ),
                      _buildInfoItem(
                        '연결 시간',
                        '방금 전',
                        Icons.access_time,
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          // 바이낸스 연결 해제
                          ref.read(binanceConnectionProvider.notifier).disconnect();

                          // 로컬 저장된 API 키 상태도 초기화
                          await _clearApiKeyState();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Binance 연결이 해제되었습니다.'),
                              backgroundColor: AppTheme.warningOrange,
                            ),
                          );
                        },
                        icon: const Icon(Icons.link_off),
                        label: const Text('연결 해제'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.dangerRed,
                          side: BorderSide(color: AppTheme.dangerRed),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectionStatus(bool isConnected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isConnected ? AppTheme.successGreen.withOpacity(0.2) : AppTheme.dangerRed.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected ? AppTheme.successGreen : AppTheme.dangerRed,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isConnected ? AppTheme.successGreen : AppTheme.dangerRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isConnected ? '연결됨' : '미연결',
            style: AppTheme.bodySmall.copyWith(
              color: isConnected ? AppTheme.successGreen : AppTheme.dangerRed,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassmorphism(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '설정',
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 16),
              _buildSettingItem('알림 설정', '트레이딩 신호 및 뉴스 알림', Icons.notifications_outlined, AppTheme.accentBlue, () {
                _navigateToNotificationSettings();
              }),
              _buildSettingItem('언어 설정', '한국어', Icons.language_outlined, AppTheme.successGreen, () {
                _showLanguageDialog();
              }),
              _buildSettingItem('테마 설정', '사이버펑크 다크', Icons.palette_outlined, AppTheme.primaryBlue, () {
                _showThemeDialog();
              }),
              _buildSettingItem('바이낸스 API 설정', 'API 키 및 시크릿 관리', Icons.api_outlined, AppTheme.primaryBlue, () {
                _navigateToBinanceApiSettings();
              }),
              _buildSettingItem('API 테스트', '연결 상태 및 기능 테스트', Icons.bug_report_outlined, AppTheme.accentBlue, () {
                _navigateToApiTest();
              }),
              _buildSettingItem('거래 설정', '리스크 관리 및 자동 거래', Icons.settings_outlined, AppTheme.neutralGray, () {
                _navigateToTradingSettings();
              }),
              _buildSettingItem('백업 및 복원', '지갑 백업 및 데이터 복원', Icons.backup_outlined, AppTheme.dangerRed, () {
                _showBackupDialog();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x1A1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassmorphism(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '보안 설정',
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.dangerRed,
                ),
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  final authState = ref.watch(authStateProvider);
                  final userData = authState.userData;

                  return Column(
                    children: [
                      _buildSecurityItem(
                        '비밀번호 변경',
                        '마지막 변경: ${DateFormat('yyyy.MM.dd').format(userData?.updatedAt ?? DateTime.now())}',
                        Icons.lock_outline,
                        true,
                      ),
                      _buildSecurityItem(
                        '2단계 인증',
                        userData?.settings?.notifications.email == true ? '활성화됨 (Email)' : '비활성화',
                        Icons.security_outlined,
                        userData?.settings?.notifications.email == true,
                      ),
                      _buildSecurityItem(
                        '지문/Face ID',
                        '비활성화 (지원 예정)',
                        Icons.fingerprint_outlined,
                        false,
                      ),
                      _buildSecurityItem(
                        '로그인 기록',
                        '최근 로그인: ${DateFormat('MM월 dd일 HH:mm').format(userData?.stats?.lastLogin ?? DateTime.now())}',
                        Icons.history_outlined,
                        false,
                      ),
                      _buildSecurityItem(
                        '연결된 기기',
                        '1개 기기 연결됨 (현재 기기)',
                        Icons.devices_outlined,
                        false,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push('/security');
                  },
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('보안 설정 관리'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityItem(String title, String subtitle, IconData icon, bool isEnabled) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1A1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dangerRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.dangerRed.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppTheme.dangerRed,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (isEnabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '활성화',
                style: TextStyle(
                  color: AppTheme.accentBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Icon(
              Icons.chevron_right,
              color: AppTheme.dangerRed,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassmorphism(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    _showLogoutDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        '로그아웃',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  final authState = ref.watch(authStateProvider);
                  final userData = authState.userData;

                  return Column(
                    children: [
                      Text(
                        'TradeCoin v1.0.0',
                        style: AppTheme.bodySmall,
                      ),
                      if (userData != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '사용자 ID: ${userData.uid.substring(0, 8)}...',
                          style: AppTheme.bodySmall.copyWith(
                            fontSize: 10,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '로그아웃',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            '정말 로그아웃하시겠습니까?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                '취소',
                style: TextStyle(color: AppTheme.accentBlue),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout();
              },
              child: const Text(
                '로그아웃',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _performLogout() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('로그아웃되었습니다.'),
        backgroundColor: AppTheme.accentBlue,
      ),
    );

    // 로그인 화면으로 이동
    context.go('/login');
  }

  // 설정 관련 메서드들
  void _navigateToNotificationSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsScreen(),
      ),
    );
  }

  void _navigateToBinanceApiSettings() {
    _showBinanceApiDialog();
  }

  void _navigateToTradingSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('거래 설정 기능이 백엔드 API와 연동되었습니다. 화면 구현은 다음 단계에서 진행됩니다.'),
        backgroundColor: AppTheme.successGreen,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '언어 설정',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Text('🇰🇷', style: TextStyle(fontSize: 24)),
                title: const Text('한국어', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context).pop(),
              ),
              ListTile(
                leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
                title: const Text('English', style: TextStyle(color: Colors.white70)),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '테마 설정',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.dark_mode, color: AppTheme.accentBlue),
                title: const Text('사이버펑크 다크', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context).pop(),
              ),
              ListTile(
                leading: const Icon(Icons.light_mode, color: Colors.white70),
                title: const Text('라이트 모드', style: TextStyle(color: Colors.white70)),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToApiTest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ApiTestScreen(),
      ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '백업 및 복원',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            '지갑 백업 기능은 곧 출시될 예정입니다.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '확인',
                style: TextStyle(color: AppTheme.accentBlue),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showBinanceApiDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.api,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '바이낸스 API 설정',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // 설명 텍스트
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppTheme.primaryBlue,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'API 키 설정 안내',
                                style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• 바이낸스 계정에서 API 키를 생성하세요\n• Spot & Margin Trading 권한을 활성화하세요\n• 테스트넷에서 먼저 테스트해보시기 바랍니다',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 테스트넷 스위치
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '테스트넷 모드',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Switch(
                          value: _isTestnet,
                          onChanged: (value) {
                            setState(() {
                              _isTestnet = value;
                            });
                          },
                          activeColor: AppTheme.successGreen,
                          inactiveThumbColor: AppTheme.dangerRed,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // API Key 입력
                    const Text(
                      'API Key',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _apiKeyController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 1,
                      decoration: InputDecoration(
                        hintText: 'API 키를 입력하세요',
                        hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                        filled: true,
                        fillColor: const Color(0x1A1E293B),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // API Secret 입력
                    const Text(
                      'API Secret',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _apiSecretController,
                      obscureText: !_showApiSecret,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 1,
                      decoration: InputDecoration(
                        hintText: 'API 시크릿을 입력하세요',
                        hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                        filled: true,
                        fillColor: const Color(0x1A1E293B),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showApiSecret ? Icons.visibility_off : Icons.visibility,
                            color: AppTheme.primaryBlue,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _showApiSecret = !_showApiSecret;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 보안 경고
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.dangerRed.withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.security,
                            color: AppTheme.dangerRed,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'API 키는 안전하게 암호화되어 저장되며, 절대 제3자와 공유하지 마세요.',
                              style: TextStyle(
                                color: AppTheme.dangerRed,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    '취소',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _testConnection();
                  },
                  child: const Text(
                    '연결 테스트',
                    style: TextStyle(color: AppTheme.primaryBlue),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _saveApiKeys();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 🧪 연결 테스트 (저장 없이 입력된 키로 테스트)
  void _testConnection() async {
    // 1️⃣ 기본 검증
    if (_apiKeyController.text.isEmpty || _apiSecretController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API 키와 시크릿을 입력해주세요.'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
      return;
    }

    // 2️⃣ 사용자 인증 확인
    final authState = ref.read(authStateProvider);
    final currentUser = authState.userData;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인이 필요합니다.'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
      return;
    }

    // 3️⃣ 입력된 키 가져오기
    String apiKey = _apiKeyController.text.trim();
    String secretKey = _apiSecretController.text.trim();

    // 4️⃣ 마스킹된 키 확인 → 저장소에서 실제 키 로드
    if (apiKey.contains('*') || secretKey.contains('*')) {
      print('🔑 [연결테스트] 마스킹된 키 → 저장소에서 실제 키 로드');
      final storage = StorageService.instance;
      final keyData = await storage.loadBinanceApiKeys();

      if (keyData != null && keyData['hasApiKey'] == true) {
        final storedApiKey = keyData['apiKey'] as String? ?? '';
        final storedSecretKey = keyData['secretKey'] as String? ?? '';

        if (storedApiKey.isNotEmpty && storedSecretKey.isNotEmpty) {
          apiKey = storedApiKey;
          secretKey = storedSecretKey;
          print('✅ 저장된 실제 키로 테스트');
        } else {
          print('❌ 저장소에 실제 키 없음');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('저장된 API 키를 찾을 수 없습니다.\n실제 키를 입력해주세요.'),
              backgroundColor: AppTheme.dangerRed,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }
      } else {
        print('❌ 저장된 키 데이터 없음');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('저장된 API 키를 찾을 수 없습니다.\n실제 키를 입력해주세요.'),
            backgroundColor: AppTheme.dangerRed,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    } else {
      print('✅ [연결테스트] 새로 입력된 키로 테스트 (저장 전)');
    }

    // 5️⃣ 로딩 메시지
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 바이낸스 연결 테스트 중...'),
        backgroundColor: AppTheme.primaryBlue,
        duration: Duration(seconds: 2),
      ),
    );

    // 6️⃣ 실제 연결 테스트
    try {
      final apiService = ref.read(apiServiceProvider);
      print('📡 연결 테스트 시작 - userId: ${currentUser.uid}, testnet: $_isTestnet');

      final response = await apiService.testBinanceConnection(
        apiKey: apiKey,
        secretKey: secretKey,
        userId: currentUser.uid,
        isTestnet: _isTestnet,
      );

      if (response.success) {
        print('✅ 연결 성공!');

        // 임시로 연결 상태 업데이트 (저장 후 최종 연결)
        ref.read(binanceConnectionProvider.notifier).setConnection(
          true,
          accountType: _isTestnet ? 'testnet' : 'live',
          accountInfo: response.data.accountInfo,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${_isTestnet ? '테스트넷' : '메인넷'} 연결 성공!\n${response.data.message}\n\n💾 저장 버튼을 눌러 설정을 저장하세요.',
            ),
            backgroundColor: AppTheme.successGreen,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        print('❌ 연결 실패');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ 연결 실패: API 키를 확인해주세요'),
            backgroundColor: AppTheme.dangerRed,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('❌ 연결 테스트 예외: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 연결 테스트 실패: ${e.toString()}'),
          backgroundColor: AppTheme.dangerRed,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _saveApiKeys() async {
    if (_apiKeyController.text.isEmpty || _apiSecretController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API 키와 시크릿을 입력해주세요.'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('API 키를 저장하는 중... (${_isTestnet ? "테스트넷" : "라이브"} 모드)'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );

    try {
      // 먼저 로컬에 API 키 저장
      final storage = StorageService.instance;
      final apiKey = _apiKeyController.text.trim();
      final secretKey = _apiSecretController.text.trim();

      final success = await storage.saveBinanceApiKeys(
        apiKey: apiKey,
        secretKey: secretKey,
        isTestnet: _isTestnet,
      );

      if (!success) {
        throw Exception('로컬 저장소에 API 키 저장 실패');
      }

      // 중복 바이낸스 연결 확인 제거 - MainScaffold에서 이미 처리됨
      print('💾 ProfileScreen: API 키 저장 완료 (연결 확인은 MainScaffold에서 처리)');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'API 키가 성공적으로 저장되었습니다!\n${_isTestnet ? "테스트넷" : "라이브"} 모드로 설정됨',
          ),
          backgroundColor: AppTheme.successGreen,
          duration: const Duration(seconds: 3),
        ),
      );

      // 백그라운드에서 서버 연결 시도 (실패해도 무시)
      _tryServerConnection(apiKey, secretKey);

    } catch (e) {
      print('❌ API 키 저장 중 에러 발생: $e');
      print('❌ 에러 스택 트레이스: ${e.runtimeType}');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API 키 저장 실패: ${e.toString()}'),
          backgroundColor: AppTheme.dangerRed,
          duration: const Duration(seconds: 4),
        ),
      );
    }

    // API 키 표시 상태 복원
    await _loadApiKeys();
  }

  // 백그라운드에서 서버 연결 시도 (옵셔널)
  void _tryServerConnection(String apiKey, String secretKey) async {
    try {
      print('🔄 백그라운드 서버 연결 시도 시작...');
      final apiService = ref.read(apiServiceProvider);
      final authState = ref.read(authStateProvider);
      final currentUser = authState.userData;

      if (currentUser != null) {
        print('🔑 사용자 정보 확인됨: ${currentUser.uid}');
        final response = await apiService.updateBinanceKeys(
          userId: currentUser.uid,
          apiKey: apiKey,
          secretKey: secretKey,
          isTestnet: _isTestnet,
        );
        print('✅ 서버 연결 성공');

        // ✅ 연결 성공 시 binanceConnectionProvider 상태 업데이트
        if (response.success) {
          ref.read(binanceConnectionProvider.notifier).setConnection(
            true,
            accountType: _isTestnet ? 'testnet' : 'live',
            accountInfo: response.data.accountInfo,
          );
          print('✅ 바이낸스 연결 상태 업데이트 완료');
        }
      } else {
        print('⚠️ 사용자 정보 없음, 서버 연결 생략');
      }
    } catch (e) {
      print('⚠️ 서버 연결 실패 (로컬 저장은 성공): $e');
      print('⚠️ 서버 연결 에러 타입: ${e.runtimeType}');
    }
  }


  // 헬퍼 메소드들
  String _getMembershipDisplayName(String tier) {
    switch (tier) {
      case 'free':
        return '🆓 무료';
      case 'premium':
        return '💎 프리미엄';
      case 'pro':
        return '👑 프로';
      case 'enterprise':
        return '🏆 엔터프라이즈';
      default:
        return '🆓 무료';
    }
  }

  String _getRiskToleranceDisplayName(String riskTolerance) {
    switch (riskTolerance) {
      case 'conservative':
        return '🛡️ 안전 추구형';
      case 'moderate':
        return '⚖️ 균형 추구형';
      case 'aggressive':
        return '🚀 수익 추구형';
      default:
        return '🛡️ 안전 추구형';
    }
  }

  String _getExperienceLevelDisplayName(String experienceLevel) {
    switch (experienceLevel) {
      case 'beginner':
        return '🔰 초보자';
      case 'intermediate':
        return '📈 중급자';
      case 'advanced':
      case 'expert':
        return '🎯 고급자';
      default:
        return '🔰 초보자';
    }
  }

  // API 키 로컬 저장 및 로드 메소드들
  Future<void> _loadApiKeys() async {
    try {
      final storage = StorageService.instance;
      final keyData = await storage.loadBinanceApiKeys();

      if (keyData != null && keyData['hasApiKey'] == true) {
        final apiKey = keyData['apiKey'] as String? ?? '';
        final secretKey = keyData['secretKey'] as String? ?? '';
        final savedTestnet = keyData['isTestnet'] as bool? ?? true;
        final maskedKey = keyData['maskedApiKey'] as String? ?? '';
        final maskedSecret = keyData['maskedSecretKey'] as String? ?? '';

        // 실제 API 키가 있으면 자동 연결 시도
        if (apiKey.isNotEmpty && secretKey.isNotEmpty) {
          // UI에는 마스킹된 키 표시 (보안상 안전)
          if (maskedKey.isNotEmpty && maskedSecret.isNotEmpty) {
            _apiKeyController.text = maskedKey;
            _apiSecretController.text = maskedSecret;
          } else {
            // 마스킹된 키가 없으면 실제 키의 일부만 표시
            _apiKeyController.text = _maskApiKey(apiKey);
            _apiSecretController.text = _maskApiKey(secretKey);
          }

          setState(() {
            _isTestnet = savedTestnet;
          });

          // 중복 바이낸스 연결 확인 제거 - MainScaffold에서 이미 처리됨
          print('🔄 저장된 API 키 감지됨 (연결 확인은 MainScaffold에서 처리)');

          print('✅ 저장된 API 키를 성공적으로 로드했습니다');
        } else if (maskedKey.isNotEmpty && maskedSecret.isNotEmpty) {
          // 마스킹된 키만 있는 경우 (표시용)
          _apiKeyController.text = maskedKey;
          _apiSecretController.text = maskedSecret;
          setState(() {
            _isTestnet = savedTestnet;
          });
          print('⚠️ 마스킹된 API 키만 로드됨 (재입력 필요)');
        }
      } else {
        print('💡 저장된 API 키가 없습니다');
      }
    } catch (e) {
      print('❌ API 키 로드 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('API 키 로드 실패: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // API 키 마스킹 헬퍼 메서드
  String _maskApiKey(String key) {
    if (key.length <= 8) return key;
    return '${key.substring(0, 4)}${'*' * (key.length - 8)}${key.substring(key.length - 4)}';
  }

  // 연결 해제 시 로컬 API 키 상태 초기화
  Future<void> _clearApiKeyState() async {
    try {
      final storage = StorageService.instance;
      await storage.clearBinanceApiKeys();

      _apiKeyController.clear();
      _apiSecretController.clear();
      setState(() {
        _isTestnet = true;
      });

      print('✅ API 키 상태 초기화 완료');
    } catch (e) {
      print('❌ API 키 상태 초기화 실패: $e');
    }
  }
}