import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { UserProfile } from '../../types';

const EXPERIENCE_LEVELS = [
  {
    value: 'beginner' as const,
    label: '초보자 (1년 미만)',
    description: '기본 전략 추천, 상세한 가이드 제공',
    icon: '🔰'
  },
  {
    value: 'intermediate' as const,
    label: '중급자 (1-3년)',
    description: '균형잡힌 포트폴리오, 중급 분석 도구',
    icon: '📈'
  },
  {
    value: 'advanced' as const,
    label: '고급자 (3년 이상)',
    description: '고급 전략 및 도구, 맞춤형 알고리즘',
    icon: '🎯'
  }
];

const RISK_LEVELS = [
  {
    value: 'conservative' as const,
    label: '안전 추구형 (저위험)',
    description: '안정적인 수익 추구, 낮은 변동성',
    icon: '🛡️'
  },
  {
    value: 'moderate' as const,
    label: '균형 추구형 (중위험)',
    description: '적절한 위험과 수익의 균형',
    icon: '⚖️'
  },
  {
    value: 'aggressive' as const,
    label: '수익 추구형 (고위험)',
    description: '높은 수익 기대, 높은 변동성 감수',
    icon: '🚀'
  }
];

const SUPPORTED_COINS = [
  { symbol: 'BTC', name: 'Bitcoin', icon: '₿' },
  { symbol: 'ETH', name: 'Ethereum', icon: 'Ξ' },
  { symbol: 'DOGE', name: 'Dogecoin', icon: '🐕' },
  { symbol: 'SHIB', name: 'Shiba Inu', icon: '🐶' },
  { symbol: 'FLOKI', name: 'Floki', icon: '🐺' },
  { symbol: 'TRUMP', name: 'Trump Token', icon: '🇺🇸' },
  { symbol: 'MAGA', name: 'MAGA Token', icon: '🦅' }
];

export default function OnboardingFlow() {
  const [currentStep, setCurrentStep] = useState(1);
  const [loading, setLoading] = useState(false);
  const [profile, setProfile] = useState<Partial<UserProfile>>({
    experienceLevel: 'beginner',
    riskTolerance: 'conservative',
    preferredCoins: ['BTC', 'ETH']
  });

  const { user } = useAuth();
  const navigate = useNavigate();

  const handleExperienceSelect = (level: UserProfile['experienceLevel']) => {
    setProfile(prev => ({ ...prev, experienceLevel: level }));
  };

  const handleRiskSelect = (risk: UserProfile['riskTolerance']) => {
    setProfile(prev => ({ ...prev, riskTolerance: risk }));
  };

  const handleCoinToggle = (coinSymbol: string) => {
    setProfile(prev => {
      const currentCoins = prev.preferredCoins || [];
      const isSelected = currentCoins.includes(coinSymbol);
      
      if (isSelected) {
        return {
          ...prev,
          preferredCoins: currentCoins.filter(coin => coin !== coinSymbol)
        };
      } else if (currentCoins.length < 5) {
        return {
          ...prev,
          preferredCoins: [...currentCoins, coinSymbol]
        };
      }
      return prev;
    });
  };

  const handleNext = () => {
    if (currentStep < 3) {
      setCurrentStep(currentStep + 1);
    } else {
      handleComplete();
    }
  };

  const handleSkip = () => {
    navigate('/dashboard');
  };

  const handleComplete = async () => {
    if (!user) return;

    try {
      setLoading(true);
      // TODO: Implement profile update with Firestore
      console.log('프로필 업데이트 기능은 추후 구현 예정:', profile);
      navigate('/dashboard');
    } catch (error) {
      console.error('Error updating profile:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary-blue/5 to-purple-500/5 flex items-center justify-center px-4">
      <div className="max-w-lg w-full">
        {/* Progress Bar */}
        <div className="mb-8">
          <div className="flex items-center justify-between mb-4">
            {[1, 2, 3].map((step) => (
              <div
                key={step}
                className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium ${
                  step <= currentStep
                    ? 'bg-primary-blue text-white'
                    : 'bg-gray-200 text-gray-500'
                }`}
              >
                {step < currentStep ? '✓' : step}
              </div>
            ))}
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2">
            <div
              className="bg-gradient-to-r from-primary-blue to-purple-600 h-2 rounded-full transition-all duration-500 ease-out"
              style={{ width: `${(currentStep / 3) * 100}%` }}
            ></div>
          </div>
        </div>

        {/* Step Content */}
        <div className="bg-white rounded-2xl shadow-card p-8">
          {currentStep === 1 && (
            <div className="text-center">
              <h2 className="text-2xl font-bold text-text-primary mb-2">투자 경험은 어느 정도인가요?</h2>
              <p className="text-text-secondary mb-8">경험에 맞는 맞춤형 서비스를 제공해드립니다</p>
              
              <div className="space-y-4">
                {EXPERIENCE_LEVELS.map((level) => (
                  <button
                    key={level.value}
                    onClick={() => handleExperienceSelect(level.value)}
                    className={`w-full p-6 rounded-xl border-2 transition-all ${
                      profile.experienceLevel === level.value
                        ? 'border-primary-blue bg-primary-blue/5'
                        : 'border-border hover:border-primary-blue/50'
                    }`}
                  >
                    <div className="flex items-center">
                      <span className="text-3xl mr-4">{level.icon}</span>
                      <div className="text-left">
                        <h3 className="font-semibold text-text-primary">{level.label}</h3>
                        <p className="text-sm text-text-secondary mt-1">{level.description}</p>
                      </div>
                    </div>
                  </button>
                ))}
              </div>
            </div>
          )}

          {currentStep === 2 && (
            <div className="text-center">
              <h2 className="text-2xl font-bold text-text-primary mb-2">선호하는 리스크 수준은?</h2>
              <p className="text-text-secondary mb-8">투자 성향에 맞는 전략을 추천해드립니다</p>
              
              <div className="space-y-4">
                {RISK_LEVELS.map((risk) => (
                  <button
                    key={risk.value}
                    onClick={() => handleRiskSelect(risk.value)}
                    className={`w-full p-6 rounded-xl border-2 transition-all ${
                      profile.riskTolerance === risk.value
                        ? 'border-primary-blue bg-primary-blue/5'
                        : 'border-border hover:border-primary-blue/50'
                    }`}
                  >
                    <div className="flex items-center">
                      <span className="text-3xl mr-4">{risk.icon}</span>
                      <div className="text-left">
                        <h3 className="font-semibold text-text-primary">{risk.label}</h3>
                        <p className="text-sm text-text-secondary mt-1">{risk.description}</p>
                      </div>
                    </div>
                  </button>
                ))}
              </div>
            </div>
          )}

          {currentStep === 3 && (
            <div className="text-center">
              <h2 className="text-2xl font-bold text-text-primary mb-2">주요 관심 코인 선택</h2>
              <p className="text-text-secondary mb-2">최대 5개까지 선택할 수 있습니다</p>
              <p className="text-sm text-text-secondary mb-8">
                선택한 코인: {profile.preferredCoins?.length || 0}/5
              </p>
              
              <div className="grid grid-cols-2 gap-4">
                {SUPPORTED_COINS.map((coin) => {
                  const isSelected = profile.preferredCoins?.includes(coin.symbol) || false;
                  const canSelect = (profile.preferredCoins?.length || 0) < 5;
                  
                  return (
                    <button
                      key={coin.symbol}
                      onClick={() => handleCoinToggle(coin.symbol)}
                      disabled={!isSelected && !canSelect}
                      className={`p-4 rounded-xl border-2 transition-all disabled:opacity-50 ${
                        isSelected
                          ? 'border-primary-blue bg-primary-blue/5'
                          : 'border-border hover:border-primary-blue/50'
                      }`}
                    >
                      <div className="text-center">
                        <span className="text-2xl block mb-2">{coin.icon}</span>
                        <h3 className="font-semibold text-text-primary">{coin.symbol}</h3>
                        <p className="text-xs text-text-secondary">{coin.name}</p>
                        {isSelected && (
                          <div className="mt-2">
                            <span className="inline-block bg-primary-blue text-white text-xs px-2 py-1 rounded-full">
                              ✓ 선택됨
                            </span>
                          </div>
                        )}
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {/* Buttons */}
          <div className="flex justify-between mt-8">
            <button
              onClick={handleSkip}
              className="px-6 py-3 text-text-secondary hover:text-text-primary transition-colors"
            >
              건너뛰기
            </button>
            
            <button
              onClick={handleNext}
              disabled={loading}
              className="action-button disabled:opacity-50"
            >
              {loading ? (
                <div className="flex items-center">
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                  완료 중...
                </div>
              ) : currentStep === 3 ? (
                '🎉 완료'
              ) : (
                '다음'
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}