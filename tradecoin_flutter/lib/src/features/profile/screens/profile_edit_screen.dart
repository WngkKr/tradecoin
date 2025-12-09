import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../auth/providers/enhanced_auth_provider.dart';
import '../../auth/models/user_model.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late TextEditingController _displayNameController;
  late TextEditingController _investmentGoalController;
  late TextEditingController _monthlyBudgetController;

  String _selectedExperienceLevel = 'beginner';
  String _selectedRiskTolerance = 'conservative';
  List<String> _selectedCoins = [];

  bool _isLoading = false;

  final List<String> _availableCoins = [
    'BTC', 'ETH', 'BNB', 'ADA', 'DOT', 'LINK', 'XRP', 'LTC',
    'DOGE', 'SHIB', 'FLOKI', 'TRUMP', 'MAGA', 'SOL', 'AVAX'
  ];

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _investmentGoalController = TextEditingController();
    _monthlyBudgetController = TextEditingController();

    // 현재 사용자 정보로 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(enhancedAuthProvider);
      final userData = authState.userData;

      if (userData != null) {
        _displayNameController.text = userData.displayName ?? '';
        _selectedExperienceLevel = userData.profile.experienceLevel;
        _selectedRiskTolerance = userData.profile.riskTolerance;
        _selectedCoins = List.from(userData.profile.preferredCoins);
        _investmentGoalController.text = userData.profile.investmentGoal ?? '';
        _monthlyBudgetController.text = userData.profile.monthlyBudget?.toString() ?? '';
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _investmentGoalController.dispose();
    _monthlyBudgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final localeState = ref.watch(localeProvider);
    final isKorean = localeState.currentLanguage == AppLanguage.korean;

    return Scaffold(
      appBar: AppBar(
        title: Text(isKorean ? '프로필 편집' : 'Edit Profile'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    isKorean ? '저장' : 'Save',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 기본 정보
              _buildBasicInfoSection(isKorean),
              const SizedBox(height: 24),

              // 투자 프로필
              _buildInvestmentProfileSection(isKorean),
              const SizedBox(height: 24),

              // 관심 코인
              _buildPreferredCoinsSection(isKorean),
              const SizedBox(height: 24),

              // 투자 목표 및 예산
              _buildInvestmentGoalSection(isKorean),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(bool isKorean) {
    return _buildSection(
      title: isKorean ? '기본 정보' : 'Basic Information',
      children: [
        _buildTextField(
          controller: _displayNameController,
          label: isKorean ? '닉네임' : 'Display Name',
          icon: Icons.person_outline,
        ),
      ],
    );
  }

  Widget _buildInvestmentProfileSection(bool isKorean) {
    return _buildSection(
      title: isKorean ? '투자 프로필' : 'Investment Profile',
      children: [
        _buildDropdownField(
          label: isKorean ? '투자 경험' : 'Experience Level',
          value: _selectedExperienceLevel,
          items: {
            'beginner': isKorean ? '초보자 (1년 미만)' : 'Beginner (< 1 year)',
            'intermediate': isKorean ? '중급자 (1-3년)' : 'Intermediate (1-3 years)',
            'advanced': isKorean ? '고급자 (3년 이상)' : 'Advanced (3+ years)',
            'expert': isKorean ? '전문가 (5년 이상)' : 'Expert (5+ years)',
          },
          onChanged: (value) {
            setState(() {
              _selectedExperienceLevel = value!;
            });
          },
          icon: Icons.military_tech_outlined,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: isKorean ? '위험 성향' : 'Risk Tolerance',
          value: _selectedRiskTolerance,
          items: {
            'conservative': isKorean ? '안전 추구형' : 'Conservative',
            'moderate': isKorean ? '균형 추구형' : 'Moderate',
            'aggressive': isKorean ? '수익 추구형' : 'Aggressive',
          },
          onChanged: (value) {
            setState(() {
              _selectedRiskTolerance = value!;
            });
          },
          icon: Icons.trending_up_outlined,
        ),
      ],
    );
  }

  Widget _buildPreferredCoinsSection(bool isKorean) {
    return _buildSection(
      title: isKorean ? '관심 코인 (최대 5개)' : 'Preferred Coins (Max 5)',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableCoins.map((coin) {
            final isSelected = _selectedCoins.contains(coin);
            return FilterChip(
              label: Text(coin),
              selected: isSelected,
              onSelected: _selectedCoins.length >= 5 && !isSelected
                  ? null
                  : (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCoins.add(coin);
                        } else {
                          _selectedCoins.remove(coin);
                        }
                      });
                    },
              selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            );
          }).toList(),
        ),
        if (_selectedCoins.length >= 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              isKorean ? '최대 5개까지 선택 가능합니다' : 'Maximum 5 coins can be selected',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.orange,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInvestmentGoalSection(bool isKorean) {
    return _buildSection(
      title: isKorean ? '투자 목표 및 예산' : 'Investment Goals & Budget',
      children: [
        _buildTextField(
          controller: _investmentGoalController,
          label: isKorean ? '투자 목표' : 'Investment Goal',
          icon: Icons.flag_outlined,
          maxLines: 3,
          hintText: isKorean
              ? '예: 장기 자산 증식, 단기 수익 창출 등'
              : 'e.g., Long-term wealth building, Short-term profit, etc.',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _monthlyBudgetController,
          label: isKorean ? '월 투자 예산 (USD)' : 'Monthly Budget (USD)',
          icon: Icons.attach_money,
          keyboardType: TextInputType.number,
          hintText: isKorean ? '예: 1000' : 'e.g., 1000',
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor.withValues(alpha: 0.5),
      ),
      items: items.entries.map((entry) {
        return DropdownMenuItem<T>(
          value: entry.key,
          child: Text(entry.value),
        );
      }).toList(),
    );
  }

  Future<void> _saveProfile() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authNotifier = ref.read(enhancedAuthProvider.notifier);

      final profileData = {
        'display_name': _displayNameController.text.trim(),
        'experience_level': _selectedExperienceLevel,
        'risk_tolerance': _selectedRiskTolerance,
        'preferred_coins': _selectedCoins,
        'investment_goal': _investmentGoalController.text.trim(),
        'monthly_budget': _monthlyBudgetController.text.isNotEmpty
            ? double.tryParse(_monthlyBudgetController.text)
            : null,
      };

      await authNotifier.updateProfile(profileData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필이 성공적으로 업데이트되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 업데이트 실패: $e'),
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
}