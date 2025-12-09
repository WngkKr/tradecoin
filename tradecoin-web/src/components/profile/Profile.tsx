import React, { useState } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import Layout from '../common/Layout';

export default function Profile() {
  const { user, signOut } = useAuth();
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);

  const handleSignOut = async () => {
    try {
      await signOut();
    } catch (error) {
      console.error('Sign out error:', error);
    }
  };

  const getTierIcon = (tier: string) => {
    switch (tier) {
      case 'free': return '🆓';
      case 'premium': return '💎';
      case 'pro': return '👑';
      case 'enterprise': return '🏆';
      default: return '🆓';
    }
  };

  const getTierColor = (tier: string) => {
    switch (tier) {
      case 'free': return 'text-gray-600';
      case 'premium': return 'text-purple-600';
      case 'pro': return 'text-orange-600';
      case 'enterprise': return 'text-green-600';
      default: return 'text-gray-600';
    }
  };

  const formatDate = (date: Date | string) => {
    const dateObj = date instanceof Date ? date : new Date(date);
    return dateObj.toLocaleDateString('ko-KR', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  };

  if (!user) return null;

  return (
    <Layout>
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 pb-20 md:pb-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-2xl font-bold text-text-primary mb-2 flex items-center">
            <span className="mr-2">👤</span>
            내 프로필
          </h1>
          <p className="text-text-secondary">계정 정보와 설정을 관리하세요</p>
        </div>

        {/* Profile Card */}
        <div className="signal-card p-8 mb-8 animate-fade-in">
          <div className="flex items-center space-x-6 mb-6">
            {user.photoURL ? (
              <img
                src={user.photoURL}
                alt="Profile"
                className="w-20 h-20 rounded-2xl border-4 border-primary-blue/20"
              />
            ) : (
              <div className="w-20 h-20 rounded-2xl bg-gradient-to-br from-primary-blue to-purple-600 flex items-center justify-center text-white text-2xl font-bold">
                {user.displayName?.charAt(0) || user.email?.charAt(0)?.toUpperCase() || 'U'}
              </div>
            )}
            
            <div className="flex-1">
              <h2 className="text-2xl font-bold text-text-primary mb-2">{user.displayName}</h2>
              <p className="text-text-secondary mb-3">{user.email}</p>
              
              <div className={`tier-badge tier-${user.subscription?.tier || 'free'}`}>
                <span>{getTierIcon(user.subscription?.tier || 'free')}</span>
                <span>{(user.subscription?.tier || 'free').toUpperCase()}</span>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="text-center p-4 bg-surface-alt rounded-xl">
              <div className="text-2xl font-bold text-primary-blue mb-1">{user.stats.signalsUsed}</div>
              <div className="text-sm text-text-secondary">사용한 시그널</div>
            </div>
            
            <div className="text-center p-4 bg-surface-alt rounded-xl">
              <div className="text-2xl font-bold text-success-green mb-1">{user.stats.tradesExecuted}</div>
              <div className="text-sm text-text-secondary">실행한 거래</div>
            </div>
            
            <div className="text-center p-4 bg-surface-alt rounded-xl">
              <div className={`text-2xl font-bold mb-1 ${user.stats.totalPnL >= 0 ? 'text-success-green' : 'text-danger-red'}`}>
                {user.stats.totalPnL >= 0 ? '+' : ''}${user.stats.totalPnL.toFixed(2)}
              </div>
              <div className="text-sm text-text-secondary">총 수익</div>
            </div>
          </div>
        </div>

        {/* Account Info */}
        <div className="signal-card p-8 mb-8 animate-slide-up">
          <h3 className="text-xl font-bold text-text-primary mb-6 flex items-center">
            <span className="mr-2">📋</span>
            계정 정보
          </h3>
          
          <div className="space-y-4">
            <div className="flex justify-between items-center py-3 border-b border-border-light">
              <span className="text-text-secondary">가입일</span>
              <span className="text-text-primary font-medium">{formatDate(user.createdAt)}</span>
            </div>
            
            <div className="flex justify-between items-center py-3 border-b border-border-light">
              <span className="text-text-secondary">멤버십</span>
              <span className={`font-bold ${getTierColor(user.subscription?.tier || 'free')}`}>
                {getTierIcon(user.subscription?.tier || 'free')} {(user.subscription?.tier || 'free').toUpperCase()}
              </span>
            </div>
            
            <div className="flex justify-between items-center py-3 border-b border-border-light">
              <span className="text-text-secondary">승률</span>
              <span className="text-text-primary font-medium">{user.stats.winRate}%</span>
            </div>
            
            <div className="flex justify-between items-center py-3">
              <span className="text-text-secondary">마지막 로그인</span>
              <span className="text-text-primary font-medium">{formatDate(user.stats.lastLogin)}</span>
            </div>
          </div>
        </div>

        {/* Settings & Actions */}
        <div className="signal-card p-8 animate-scale-in">
          <h3 className="text-xl font-bold text-text-primary mb-6 flex items-center">
            <span className="mr-2">⚙️</span>
            설정 및 관리
          </h3>
          
          <div className="space-y-4">
            <button className="w-full flex items-center justify-between p-4 rounded-xl border border-border hover:bg-surface-alt transition-colors">
              <div className="flex items-center space-x-3">
                <span className="text-xl">🔔</span>
                <span className="text-text-primary font-medium">알림 설정</span>
              </div>
              <span className="text-text-secondary">›</span>
            </button>
            
            <button className="w-full flex items-center justify-between p-4 rounded-xl border border-border hover:bg-surface-alt transition-colors">
              <div className="flex items-center space-x-3">
                <span className="text-xl">🔒</span>
                <span className="text-text-primary font-medium">보안 설정</span>
              </div>
              <span className="text-text-secondary">›</span>
            </button>
            
            <button className="w-full flex items-center justify-between p-4 rounded-xl border border-border hover:bg-surface-alt transition-colors">
              <div className="flex items-center space-x-3">
                <span className="text-xl">💎</span>
                <span className="text-text-primary font-medium">멤버십 관리</span>
              </div>
              <span className="text-text-secondary">›</span>
            </button>
            
            <div className="pt-4 border-t border-border-light">
              <button 
                onClick={() => setShowLogoutConfirm(true)}
                className="w-full flex items-center justify-center space-x-3 p-4 rounded-xl bg-danger-red/5 border border-danger-red/30 text-danger-red hover:bg-danger-red/10 transition-all duration-200"
              >
                <span className="text-xl">🚪</span>
                <span className="font-semibold">로그아웃</span>
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Logout Confirmation Modal */}
      {showLogoutConfirm && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl p-8 max-w-sm w-full animate-scale-in">
            <div className="text-center">
              <div className="text-6xl mb-4">👋</div>
              <h2 className="text-xl font-bold text-text-primary mb-3">
                로그아웃 하시겠습니까?
              </h2>
              <p className="text-text-secondary mb-6">
                현재 세션에서 로그아웃됩니다.
              </p>
              
              <div className="flex space-x-3">
                <button
                  onClick={() => setShowLogoutConfirm(false)}
                  className="flex-1 btn-secondary"
                >
                  취소
                </button>
                <button
                  onClick={handleSignOut}
                  className="flex-1 bg-danger-red text-white px-6 py-3 rounded-xl hover:bg-danger-red/90 transition-colors font-semibold"
                >
                  로그아웃
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </Layout>
  );
}