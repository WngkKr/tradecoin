import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/cyberpunk_header.dart';
import '../../../core/providers/locale_provider.dart';

class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeState = ref.watch(localeProvider);
    final localeNotifier = ref.read(localeProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: const CyberpunkHeader(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),

            // 현재 설정 상태
            _buildCurrentStatusCard(localeState),
            const SizedBox(height: 20),

            // 언어 설정
            _buildLanguageSection(context, ref, localeState, localeNotifier),
            const SizedBox(height: 20),

            // 통화 설정
            _buildCurrencySection(context, ref, localeState, localeNotifier),
            const SizedBox(height: 20),

            // 추천 설정
            _buildRecommendedSettingsSection(context, ref, localeState, localeNotifier),
            const SizedBox(height: 20),

            // 시스템 설정
            _buildSystemSettingsSection(context, ref, localeNotifier),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: Icon(Icons.arrow_back, color: AppTheme.accentBlue),
            ),
            const SizedBox(width: 8),
            Text(
              '언어 및 지역 설정',
              style: AppTheme.headingLarge.copyWith(
                color: AppTheme.accentBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 56),
          child: Text(
            '앱의 언어와 통화 단위를 설정하세요',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.neutralGray,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStatusCard(LocaleState localeState) {
    final currencyInfo = getCurrencyInfo(localeState.currency);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassmorphism(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.accentBlue, size: 24),
              const SizedBox(width: 12),
              Text(
                '현재 설정',
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.accentBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatusItem(
                  '언어',
                  localeState.currentLanguage.displayName,
                  Icons.language,
                ),
              ),
              Expanded(
                child: _buildStatusItem(
                  '통화',
                  '${currencyInfo.symbol} ${currencyInfo.code}',
                  Icons.attach_money,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.successGreen, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '설정이 앱 전체에 즉시 적용됩니다',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.successGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.neutralGray, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.neutralGray,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.bodyLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSection(
    BuildContext context,
    WidgetRef ref,
    LocaleState localeState,
    LocaleNotifier localeNotifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassmorphism(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.language, color: AppTheme.accentBlue, size: 24),
              const SizedBox(width: 12),
              Text(
                '언어 선택',
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.accentBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...AppLanguage.values.map((language) => _buildLanguageOption(
            language,
            localeState.currentLanguage == language,
            () async {
              await localeNotifier.setLanguage(language);
            },
          )),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    AppLanguage language,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
              ? AppTheme.accentBlue.withValues(alpha: 0.2)
              : AppTheme.surfaceDark.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                ? AppTheme.accentBlue
                : AppTheme.surfaceDark.withValues(alpha: 0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    _getLanguageFlag(language),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.displayName,
                      style: AppTheme.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    Text(
                      '${language.languageCode.toUpperCase()} • ${language.countryCode}',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.neutralGray,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '선택됨',
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.neutralGray,
                  size: 16,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getLanguageFlag(AppLanguage language) {
    switch (language) {
      case AppLanguage.korean:
        return '🇰🇷';
      case AppLanguage.english:
        return '🇺🇸';
      case AppLanguage.japanese:
        return '🇯🇵';
      case AppLanguage.chinese:
        return '🇨🇳';
      default:
        return '🌍';
    }
  }

  Widget _buildCurrencySection(
    BuildContext context,
    WidgetRef ref,
    LocaleState localeState,
    LocaleNotifier localeNotifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassmorphism(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money, color: AppTheme.accentBlue, size: 24),
              const SizedBox(width: 12),
              Text(
                '통화 단위 선택',
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.accentBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '가격 표시에 사용될 통화를 선택하세요',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.neutralGray,
            ),
          ),
          const SizedBox(height: 16),

          // 주요 통화들을 그리드로 표시
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.5,
            ),
            itemCount: supportedCurrencies.length,
            itemBuilder: (context, index) {
              final currency = supportedCurrencies[index];
              final isSelected = localeState.currency == currency.code;

              return InkWell(
                onTap: () async {
                  await localeNotifier.setCurrency(currency.code);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                      ? AppTheme.accentBlue.withValues(alpha: 0.2)
                      : AppTheme.surfaceDark.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                        ? AppTheme.accentBlue
                        : AppTheme.surfaceDark.withValues(alpha: 0.5),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currency.symbol,
                        style: AppTheme.bodyLarge.copyWith(
                          color: isSelected ? AppTheme.accentBlue : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currency.code,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.neutralGray,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedSettingsSection(
    BuildContext context,
    WidgetRef ref,
    LocaleState localeState,
    LocaleNotifier localeNotifier,
  ) {
    final recommendedCurrencies = getRecommendedCurrencies(localeState.currentLanguage);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassmorphism(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.recommend, color: AppTheme.accentBlue, size: 24),
              const SizedBox(width: 12),
              Text(
                '추천 설정',
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.accentBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '현재 언어에 맞는 추천 통화입니다',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.neutralGray,
            ),
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recommendedCurrencies.map((currencyCode) {
              final currency = getCurrencyInfo(currencyCode);
              final isCurrentCurrency = localeState.currency == currencyCode;

              return InkWell(
                onTap: isCurrentCurrency ? null : () async {
                  await localeNotifier.setCurrency(currencyCode);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCurrentCurrency
                      ? AppTheme.successGreen.withValues(alpha: 0.2)
                      : AppTheme.accentBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCurrentCurrency
                        ? AppTheme.successGreen
                        : AppTheme.accentBlue,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCurrentCurrency)
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.successGreen,
                          size: 16,
                        )
                      else
                        Text(
                          currency.symbol,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.accentBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const SizedBox(width: 6),
                      Text(
                        currency.code,
                        style: AppTheme.bodySmall.copyWith(
                          color: isCurrentCurrency
                            ? AppTheme.successGreen
                            : AppTheme.accentBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemSettingsSection(
    BuildContext context,
    WidgetRef ref,
    LocaleNotifier localeNotifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassmorphism(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings_system_daydream, color: AppTheme.accentBlue, size: 24),
              const SizedBox(width: 12),
              Text(
                '시스템 설정',
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.accentBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          InkWell(
            onTap: () async {
              await localeNotifier.setSystemLanguage();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.smartphone, color: AppTheme.accentBlue),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '시스템 언어 사용',
                          style: AppTheme.bodyLarge.copyWith(color: Colors.white),
                        ),
                        Text(
                          '기기의 언어 설정을 따라갑니다',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.neutralGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.accentBlue.withValues(alpha: 0.7),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}