import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../../../core/services/user_session_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Firebase Auth 사용으로 변경됨 - 테스트 계정 자동 입력 제거
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      print('DEBUG: 로컬 세션 로그인 시도 - 이메일: "$email"');

      // 로컬 세션 기반 로그인
      await ref.read(authStateProvider.notifier).signInWithEmailAndPassword(email, password);

      if (mounted) {
        final authState = ref.read(authStateProvider);
        if (authState.status == AuthStatus.authenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('환영합니다! ${authState.userData?.displayName}님으로 로그인되었습니다.'),
              backgroundColor: AppTheme.successGreen,
              duration: const Duration(seconds: 2),
            ),
          );

          await Future.delayed(const Duration(milliseconds: 1000));
          context.go('/dashboard');
        } else if (authState.status == AuthStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authState.error ?? '로그인에 실패했습니다.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }

    } catch (e) {
      print('DEBUG: 로그인 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 테스트용 유희남 계정 생성 및 로그인
  Future<void> _createTestUser() async {
    setState(() => _isLoading = true);

    try {
      print('🧪 테스트 유희남 계정 생성 시작...');

      final sessionService = UserSessionService.instance;
      final testUser = await sessionService.createTestUserYuhenam();

      // auth provider 상태 업데이트
      ref.read(authStateProvider.notifier).state = AuthState.authenticated(testUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 유희남 계정이 생성되었습니다!\n이메일: wngk7001@gmail.com\n비밀번호: wngk7001'),
            backgroundColor: AppTheme.successGreen,
            duration: const Duration(seconds: 3),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 1500));
        context.go('/dashboard');
      }

    } catch (e) {
      print('❌ 테스트 계정 생성 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('테스트 계정 생성 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 로고 및 타이틀
                      _buildLogo(),
                      const SizedBox(height: 48),
                      
                      // 로그인 카드
                      _buildLoginCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // 로고 컨테이너
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    colors: [
                      AppTheme.accentBlue,
                      AppTheme.primaryBlue,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentBlue.withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.currency_bitcoin,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        
        // 타이틀
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Text(
              'TradeCoin',
              style: AppTheme.headingLarge.copyWith(
                shadows: [
                  Shadow(
                    color: AppTheme.accentBlue.withOpacity(_glowAnimation.value),
                    blurRadius: 10,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          'AI TRADING PLATFORM',
          style: AppTheme.bodyMedium.copyWith(
            letterSpacing: 2,
            color: AppTheme.accentBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.glassmorphism(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '로그인',
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.accentBlue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // 이메일 입력
              _buildTextField(
                controller: _emailController,
                label: '이메일',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이메일을 입력해주세요';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return '올바른 이메일 형식이 아닙니다';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // 비밀번호 입력
              _buildTextField(
                controller: _passwordController,
                label: '비밀번호',
                icon: Icons.lock_outlined,
                obscureText: !_isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: AppTheme.accentBlue,
                  ),
                  onPressed: () {
                    setState(() => _isPasswordVisible = !_isPasswordVisible);
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 입력해주세요';
                  }
                  if (value.length < 6) {
                    return '비밀번호는 6자 이상이어야 합니다';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              // 로그인 버튼
              _buildLoginButton(),
              const SizedBox(height: 24),

              // 회원가입 링크
              _buildSignupLink(),
              const SizedBox(height: 16),

              // 테스트 계정 생성 버튼
              _buildTestUserButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: AppTheme.accentBlue),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppTheme.surfaceDark.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.accentBlue),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentBlue,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AppTheme.accentBlue.withOpacity(0.8);
            }
            return AppTheme.accentBlue;
          }),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  strokeWidth: 2,
                ),
              )
            : const Text(
                '로그인',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }


  Widget _buildSignupLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '계정이 없으신가요? ',
          style: TextStyle(color: Colors.white70),
        ),
        TextButton(
          onPressed: () {
            context.go('/signup');
          },
          child: const Text(
            '회원가입',
            style: TextStyle(
              color: AppTheme.accentBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestUserButton() {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createTestUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : const Text(
                '🧪 테스트: 유희남 계정 생성',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}