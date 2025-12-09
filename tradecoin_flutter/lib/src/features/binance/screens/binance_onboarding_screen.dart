import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:url_launcher/url_launcher.dart'; // Package not available, using placeholder
import '../../../core/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/binance_connection_provider.dart';

class BinanceOnboardingScreen extends ConsumerStatefulWidget {
  const BinanceOnboardingScreen({super.key});

  @override
  ConsumerState<BinanceOnboardingScreen> createState() => _BinanceOnboardingScreenState();
}

class _BinanceOnboardingScreenState extends ConsumerState<BinanceOnboardingScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  late PageController _pageController;
  late AnimationController _progressController;

  final _apiKeyController = TextEditingController();
  final _secretKeyController = TextEditingController();
  bool _isTestnet = false;  // ✅ 실거래 모드가 기본값
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _apiKeyController.dispose();
    _secretKeyController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _progressController.animateTo((_currentStep + 1) / 5);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _progressController.animateTo((_currentStep + 1) / 5);
    }
  }

  Future<void> _launchUrl(String url) async {
    // Placeholder for URL launcher functionality
    // In a real implementation, you would use url_launcher package
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('새 창에서 열기: $url')),
      );
    }
  }

  Future<void> _testConnection() async {
    if (_apiKeyController.text.isEmpty || _secretKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API 키와 시크릿 키를 모두 입력해주세요')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 사용자 ID 가져오기
      final authState = ref.read(authStateProvider);
      final currentUser = authState.userData;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다');
      }

      final apiService = ApiService();
      final response = await apiService.testBinanceConnection(
        apiKey: _apiKeyController.text.trim(),
        secretKey: _secretKeyController.text.trim(),
        userId: currentUser.uid,
        isTestnet: _isTestnet,
      );

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data.message),
            backgroundColor: Colors.green,
          ),
        );
        _nextStep();
      } else {
        throw Exception('연결 테스트 실패');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('연결 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveKeys() async {
    final authState = ref.read(authStateProvider);
    final currentUser = authState.userData;

    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인이 필요합니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.updateBinanceKeys(
        apiKey: _apiKeyController.text.trim(),
        secretKey: _secretKeyController.text.trim(),
        userId: currentUser.uid,
        isTestnet: _isTestnet,
      );

      if (response.success) {
        // 글로벌 상태 업데이트
        ref.read(binanceConnectionProvider.notifier).setConnection(
          true,
          accountType: _isTestnet ? 'demo' : 'live',
          accountInfo: response.data.accountInfo,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data.message),
              backgroundColor: Colors.green,
            ),
          );
        }
        _nextStep();
      } else {
        throw Exception('키 저장 실패');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('바이낸스 연결 설정'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size(double.infinity, 60.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: _progressController.value,
                  backgroundColor: Colors.grey.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B46C1)),
                );
              },
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E1B4B),
              Color(0xFF312E81),
              Color(0xFF3730A3),
            ],
          ),
        ),
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildWelcomeStep(),
            _buildAccountStep(),
            _buildAPIKeyGenerationStep(),
            _buildKeyInputStep(),
            _buildCompleteStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B46C1), Color(0xFF8B5CF6)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B46C1).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.account_balance,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            '바이낸스 연결을 시작합니다',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'TradeCoin과 바이낸스 계정을 안전하게 연결하여\n실시간 거래 기능을 활용하세요.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildFeatureList(),
          const SizedBox(height: 40),
          _buildActionButton(
            text: '시작하기',
            onPressed: _nextStep,
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(
            Icons.person_add,
            size: 80,
            color: Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 32),
          const Text(
            '바이낸스 계정이 필요합니다',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            '바이낸스 계정이 없으시다면 먼저 가입을 진행해주세요.\n이미 계정이 있으시다면 다음 단계로 이동하세요.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildSecurityTips(),
          const SizedBox(height: 40),
          _buildActionButton(
            text: '바이낸스 가입하기',
            onPressed: () => _launchUrl('https://www.binance.com/ko/register'),
            isPrimary: false,
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            text: '이미 계정이 있습니다',
            onPressed: _nextStep,
            isPrimary: true,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _previousStep,
            child: const Text(
              '이전 단계',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAPIKeyGenerationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(
            Icons.vpn_key,
            size: 80,
            color: Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 32),
          const Text(
            'API 키 생성 가이드',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            '바이낸스에서 API 키를 생성하는 방법을 안내드립니다.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildStepGuide(),
          const SizedBox(height: 32),
          _buildActionButton(
            text: 'API 키 생성하러 가기',
            onPressed: () => _launchUrl('https://www.binance.com/ko/my/settings/api-management'),
            isPrimary: false,
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            text: 'API 키가 준비되었습니다',
            onPressed: _nextStep,
            isPrimary: true,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _previousStep,
            child: const Text(
              '이전 단계',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyInputStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(
            Icons.security,
            size: 80,
            color: Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 32),
          const Text(
            'API 키 입력',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            '생성한 API 키와 시크릿 키를 입력해주세요.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildKeyInputForm(),
          const SizedBox(height: 32),
          if (_isLoading)
            const CircularProgressIndicator(color: Color(0xFF8B5CF6))
          else ...[
            _buildActionButton(
              text: '연결 테스트',
              onPressed: _testConnection,
              isPrimary: false,
            ),
            const SizedBox(height: 16),
          ],
          TextButton(
            onPressed: _previousStep,
            child: const Text(
              '이전 단계',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF34D399)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            '연결이 완료되었습니다!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            '바이낸스 계정이 성공적으로 연결되었습니다.\n이제 실시간 거래 기능을 사용할 수 있습니다.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildCompletionFeatures(),
          const SizedBox(height: 40),
          _buildActionButton(
            text: '대시보드로 이동',
            onPressed: () => Navigator.of(context).pop(),
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList() {
    final features = [
      {'icon': Icons.trending_up, 'title': '실시간 거래', 'desc': '바이낸스에서 직접 거래 실행'},
      {'icon': Icons.account_balance_wallet, 'title': '포트폴리오 동기화', 'desc': '실제 잔고와 포지션 확인'},
      {'icon': Icons.notifications_active, 'title': '스마트 알림', 'desc': 'AI 기반 거래 기회 알림'},
    ];

    return Column(
      children: features.map((feature) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B46C1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                feature['icon'] as IconData,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature['title'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feature['desc'] as String,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildSecurityTips() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: const Color(0xFFF59E0B),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                '보안 주의사항',
                style: TextStyle(
                  color: Color(0xFFF59E0B),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '• 2단계 인증(2FA)을 반드시 활성화하세요\n'
            '• API 키에는 출금 권한을 부여하지 마세요\n'
            '• 정기적으로 API 키를 업데이트하세요\n'
            '• 의심스러운 활동이 있다면 즉시 키를 삭제하세요',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepGuide() {
    final steps = [
      '바이낸스 로그인 후 계정 관리 페이지 접속',
      'API 관리 메뉴에서 "API 키 생성" 클릭',
      'API 키 라벨 입력 (예: TradeCoin)',
      '권한 설정: "현물 및 마진거래" 체크',
      '⚠️ "출금 활성화"는 체크하지 마세요',
      '생성된 API 키와 Secret Key 복사',
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        int index = entry.key;
        String step = entry.value;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  step,
                  style: TextStyle(
                    color: step.startsWith('⚠️') ? const Color(0xFFF59E0B) : Colors.white,
                    fontSize: 14,
                    fontWeight: step.startsWith('⚠️') ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeyInputForm() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              // 테스트넷/실거래 선택 - 반응형 레이아웃
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '환경 선택:',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // 화면 너비가 좁으면 세로로, 넓으면 가로로 배치
                      if (constraints.maxWidth < 300) {
                        return Column(
                          children: [
                            _buildEnvironmentButton(
                              label: '테스트넷',
                              icon: Icons.science,
                              isSelected: _isTestnet,
                              onTap: () => setState(() => _isTestnet = true),
                            ),
                            const SizedBox(height: 8),
                            _buildEnvironmentButton(
                              label: '실거래',
                              icon: Icons.account_balance,
                              isSelected: !_isTestnet,
                              onTap: () => setState(() => _isTestnet = false),
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          children: [
                            Expanded(
                              child: _buildEnvironmentButton(
                                label: '테스트넷',
                                icon: Icons.science,
                                isSelected: _isTestnet,
                                onTap: () => setState(() => _isTestnet = true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildEnvironmentButton(
                                label: '실거래',
                                icon: Icons.account_balance,
                                isSelected: !_isTestnet,
                                onTap: () => setState(() => _isTestnet = false),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // API 키 입력 - 반응형 처리
              LayoutBuilder(
                builder: (context, constraints) {
                  return TextField(
                    controller: _apiKeyController,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                      ),
                      suffixIcon: constraints.maxWidth > 200 ? IconButton(
                        icon: const Icon(Icons.paste, color: Colors.white70),
                        onPressed: () async {
                          final data = await Clipboard.getData(Clipboard.kTextPlain);
                          if (data?.text != null) {
                            _apiKeyController.text = data!.text!;
                          }
                        },
                      ) : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    style: const TextStyle(color: Colors.white),
                    maxLines: 1,
                    scrollPadding: const EdgeInsets.all(0),
                  );
                },
              ),
              const SizedBox(height: 16),

              // 시크릿 키 입력 - 반응형 처리
              LayoutBuilder(
                builder: (context, constraints) {
                  return TextField(
                    controller: _secretKeyController,
                    decoration: InputDecoration(
                      labelText: 'Secret Key',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                      ),
                      suffixIcon: constraints.maxWidth > 200 ? IconButton(
                        icon: const Icon(Icons.paste, color: Colors.white70),
                        onPressed: () async {
                          final data = await Clipboard.getData(Clipboard.kTextPlain);
                          if (data?.text != null) {
                            _secretKeyController.text = data!.text!;
                          }
                        },
                      ) : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    style: const TextStyle(color: Colors.white),
                    obscureText: true,
                    maxLines: 1,
                    scrollPadding: const EdgeInsets.all(0),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionFeatures() {
    final features = [
      {'icon': Icons.check_circle, 'title': '계정 연결 완료'},
      {'icon': Icons.security, 'title': '보안 연결 확립'},
      {'icon': Icons.sync, 'title': '실시간 데이터 동기화'},
    ];

    return Column(
      children: features.map((feature) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              feature['icon'] as IconData,
              color: const Color(0xFF10B981),
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              feature['title'] as String,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildEnvironmentButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8B5CF6).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8B5CF6)
                : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF8B5CF6) : Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF8B5CF6) : Colors.white70,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? const Color(0xFF6B46C1)
              : Colors.white.withValues(alpha: 0.1),
          foregroundColor: isPrimary ? Colors.white : Colors.white70,
          elevation: isPrimary ? 8 : 0,
          shadowColor: isPrimary
              ? const Color(0xFF6B46C1).withValues(alpha: 0.4)
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isPrimary
                ? BorderSide.none
                : BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}