import React, { useState } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import Layout from '../common/Layout';

const MEMBERSHIP_TIERS = [
  {
    id: 'free',
    name: 'Free',
    icon: '🆓',
    price: 0,
    period: '',
    color: 'tier-free',
    features: [
      '기본 시그널 조회 (일 3개 제한)',
      '뉴스 피드 접근',
      '기본 포트폴리오 추적',
      '광고 표시'
    ],
    limitations: [
      '제한된 시그널 개수',
      '기본 분석 도구만 제공',
      '알림 기능 없음'
    ]
  },
  {
    id: 'premium',
    name: 'Premium',
    icon: '💎',
    price: 29.99,
    period: '/월',
    color: 'tier-premium',
    popular: true,
    features: [
      '무제한 시그널 접근',
      '실시간 알림 (푸시, 이메일)',
      '고급 기술 분석 도구',
      '자동 거래 연동 (기본)',
      '월간 성과 리포트',
      '광고 제거'
    ],
    limitations: []
  },
  {
    id: 'pro',
    name: 'Pro',
    icon: '👑',
    price: 99.99,
    period: '/월',
    color: 'tier-pro',
    features: [
      'Premium 모든 기능',
      'AI 맞춤형 전략 추천',
      '고급 자동거래 설정',
      '1:1 전담 지원',
      'API 접근 권한',
      '백테스팅 도구',
      '우선순위 신규 기능 접근'
    ],
    limitations: []
  },
  {
    id: 'enterprise',
    name: 'Enterprise',
    icon: '🏆',
    price: 299.99,
    period: '/월',
    color: 'tier-enterprise',
    features: [
      'Pro 모든 기능',
      '무제한 API 호출',
      '커스텀 알고리즘 개발 지원',
      '전용 서버 자원',
      '실시간 컨설팅',
      '맞춤형 대시보드'
    ],
    limitations: []
  }
];

export default function Membership() {
  const { user } = useAuth();
  const [loading, setLoading] = useState<string | null>(null);
  const [selectedTier, setSelectedTier] = useState<string | null>(null);

  const handleUpgrade = async (tierId: string) => {
    if (!user) return;
    
    setLoading(tierId);
    
    try {
      // Simulate payment processing
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // TODO: Implement actual subscription upgrade logic with Firebase
      console.log(`업그레이드 기능은 추후 구현 예정: ${tierId}`);
      
      // Show success message (you might want to use a toast library here)
      alert(`${MEMBERSHIP_TIERS.find(t => t.id === tierId)?.name} 플랜으로 성공적으로 업그레이드되었습니다!`);
      
    } catch (error) {
      console.error('Upgrade error:', error);
      alert('업그레이드 중 오류가 발생했습니다. 다시 시도해주세요.');
    } finally {
      setLoading(null);
    }
  };

  const handleStartFreeTrial = async (tierId: string) => {
    if (!user) return;
    
    setLoading(tierId);
    
    try {
      await new Promise(resolve => setTimeout(resolve, 1500));
      
      // TODO: Implement actual trial activation logic with Firebase
      console.log(`무료 체험 기능은 추후 구현 예정: ${tierId}`);
      
      alert('7일 무료 체험이 시작되었습니다!');
      
    } catch (error) {
      console.error('Trial error:', error);
      alert('무료 체험 신청 중 오류가 발생했습니다.');
    } finally {
      setLoading(null);
    }
  };

  const getCurrentTier = () => {
    return user?.subscription.tier || 'free';
  };

  const isCurrentTier = (tierId: string) => {
    return getCurrentTier() === tierId;
  };

  const canUpgrade = (tierId: string) => {
    const current = getCurrentTier();
    const tierOrder = ['free', 'premium', 'pro', 'enterprise'];
    return tierOrder.indexOf(tierId) > tierOrder.indexOf(current);
  };

  return (
    <Layout>
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 pb-20 md:pb-8">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-3xl font-bold text-text-primary mb-4 flex items-center justify-center">
            <span className="mr-3">👑</span>
            멤버십 플랜
          </h1>
          <p className="text-lg text-text-secondary max-w-2xl mx-auto">
            여러분의 투자 목표에 맞는 최적의 플랜을 선택하세요. 
            언제든지 업그레이드하거나 변경할 수 있습니다.
          </p>
        </div>

        {/* Current Plan Status */}
        {user && (
          <div className="mb-8">
            <div className="bg-white rounded-2xl shadow-card p-6">
              <h2 className="text-lg font-semibold text-text-primary mb-4 flex items-center">
                <span className="mr-2">📊</span>
                현재 멤버십 현황
              </h2>
              
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div>
                  <p className="text-sm text-text-secondary mb-1">현재 플랜</p>
                  <div className="flex items-center space-x-2">
                    <div className={`tier-badge ${MEMBERSHIP_TIERS.find(t => t.id === getCurrentTier())?.color}`}>
                      <span>{MEMBERSHIP_TIERS.find(t => t.id === getCurrentTier())?.icon}</span>
                      <span>{MEMBERSHIP_TIERS.find(t => t.id === getCurrentTier())?.name.toUpperCase()}</span>
                    </div>
                  </div>
                </div>
                
                <div>
                  <p className="text-sm text-text-secondary mb-1">상태</p>
                  <p className={`font-medium ${
                    user.subscription.status === 'active' ? 'text-success-green' :
                    user.subscription.status === 'cancelled' ? 'text-warning-orange' : 'text-danger-red'
                  }`}>
                    {user.subscription.status === 'active' ? '✅ 활성' :
                     user.subscription.status === 'cancelled' ? '⏳ 취소 예정' : '❌ 만료'}
                  </p>
                </div>
                
                {getCurrentTier() !== 'free' && (
                  <div>
                    <p className="text-sm text-text-secondary mb-1">다음 결제일</p>
                    <p className="font-medium text-text-primary">
                      {user.subscription.endDate.toLocaleDateString()}
                    </p>
                  </div>
                )}
              </div>
              
              {getCurrentTier() === 'free' && (
                <div className="mt-4 p-4 bg-primary-blue/5 border border-primary-blue/20 rounded-xl">
                  <div className="flex items-center text-primary-blue">
                    <span className="mr-2">💡</span>
                    <span className="font-medium">
                      Premium으로 업그레이드하여 무제한 시그널과 실시간 알림을 받아보세요!
                    </span>
                  </div>
                </div>
              )}
            </div>
          </div>
        )}

        {/* Membership Plans */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          {MEMBERSHIP_TIERS.map((tier) => (
            <div 
              key={tier.id} 
              className={`relative bg-white rounded-2xl shadow-card p-6 transition-all duration-300 ${
                selectedTier === tier.id ? 'ring-2 ring-primary-blue scale-105' : 'hover:scale-102'
              } ${isCurrentTier(tier.id) ? 'ring-2 ring-success-green' : ''}`}
              onClick={() => setSelectedTier(tier.id)}
            >
              {/* Popular Badge */}
              {tier.popular && (
                <div className="absolute -top-3 left-1/2 transform -translate-x-1/2">
                  <div className="bg-gradient-to-r from-primary-blue to-purple-600 text-white px-4 py-1 rounded-full text-xs font-semibold">
                    🔥 인기
                  </div>
                </div>
              )}
              
              {/* Current Plan Badge */}
              {isCurrentTier(tier.id) && (
                <div className="absolute -top-3 right-4">
                  <div className="bg-success-green text-white px-3 py-1 rounded-full text-xs font-semibold">
                    ✅ 현재 플랜
                  </div>
                </div>
              )}

              {/* Header */}
              <div className="text-center mb-6">
                <div className="text-4xl mb-3">{tier.icon}</div>
                <h3 className="text-xl font-bold text-text-primary mb-2">{tier.name}</h3>
                <div className="mb-4">
                  {tier.price === 0 ? (
                    <span className="text-3xl font-bold text-text-primary">무료</span>
                  ) : (
                    <>
                      <span className="text-3xl font-bold text-text-primary">${tier.price}</span>
                      <span className="text-text-secondary">{tier.period}</span>
                    </>
                  )}
                </div>
              </div>

              {/* Features */}
              <div className="space-y-3 mb-6">
                {tier.features.map((feature, index) => (
                  <div key={index} className="flex items-start space-x-2 text-sm">
                    <span className="text-success-green">✅</span>
                    <span className="text-text-primary">{feature}</span>
                  </div>
                ))}
                
                {tier.limitations.map((limitation, index) => (
                  <div key={index} className="flex items-start space-x-2 text-sm">
                    <span className="text-danger-red">❌</span>
                    <span className="text-text-secondary">{limitation}</span>
                  </div>
                ))}
              </div>

              {/* Action Button */}
              <div className="space-y-2">
                {isCurrentTier(tier.id) ? (
                  <button 
                    disabled
                    className="w-full py-3 px-4 bg-success-green/10 text-success-green border border-success-green/20 rounded-xl font-semibold"
                  >
                    ✅ 현재 이용 중
                  </button>
                ) : canUpgrade(tier.id) ? (
                  <>
                    <button
                      onClick={() => handleUpgrade(tier.id)}
                      disabled={loading === tier.id}
                      className="w-full action-button disabled:opacity-50"
                    >
                      {loading === tier.id ? (
                        <div className="flex items-center justify-center">
                          <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                          처리 중...
                        </div>
                      ) : (
                        `🚀 ${tier.name}으로 업그레이드`
                      )}
                    </button>
                    
                    {tier.id === 'premium' && getCurrentTier() === 'free' && (
                      <button
                        onClick={() => handleStartFreeTrial(tier.id)}
                        disabled={loading === tier.id}
                        className="w-full py-3 px-4 border border-primary-blue text-primary-blue rounded-xl hover:bg-primary-blue/5 transition-colors disabled:opacity-50"
                      >
                        🎁 7일 무료체험 시작
                      </button>
                    )}
                  </>
                ) : (
                  <button 
                    disabled
                    className="w-full py-3 px-4 bg-gray-100 text-gray-400 rounded-xl font-semibold cursor-not-allowed"
                  >
                    다운그레이드 불가
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>

        {/* FAQ Section */}
        <div className="bg-white rounded-2xl shadow-card p-8">
          <h2 className="text-xl font-bold text-text-primary mb-6 flex items-center">
            <span className="mr-2">❓</span>
            자주 묻는 질문
          </h2>
          
          <div className="space-y-6">
            <div>
              <h3 className="font-semibold text-text-primary mb-2">언제든지 플랜을 변경할 수 있나요?</h3>
              <p className="text-text-secondary">
                네, 언제든지 업그레이드하거나 취소할 수 있습니다. 업그레이드는 즉시 적용되며, 
                취소하는 경우 현재 결제 주기가 끝날 때까지 서비스를 계속 이용할 수 있습니다.
              </p>
            </div>
            
            <div>
              <h3 className="font-semibold text-text-primary mb-2">무료 체험 중 언제든 취소할 수 있나요?</h3>
              <p className="text-text-secondary">
                물론입니다. 무료 체험 기간 중 언제든지 취소할 수 있으며, 
                체험 기간이 끝나면 자동으로 Free 플랜으로 돌아갑니다.
              </p>
            </div>
            
            <div>
              <h3 className="font-semibold text-text-primary mb-2">결제는 어떻게 진행되나요?</h3>
              <p className="text-text-secondary">
                신용카드, PayPal, 국내 결제 시스템(이니시스, 토스페이 등)을 지원합니다. 
                모든 결제는 SSL 암호화로 안전하게 보호됩니다.
              </p>
            </div>
            
            <div>
              <h3 className="font-semibold text-text-primary mb-2">환불 정책은 어떻게 되나요?</h3>
              <p className="text-text-secondary">
                14일 무조건 환불 정책을 운영하며, 그 이후에는 사용 기간에 따른 비례 환불이 적용됩니다.
              </p>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  );
}