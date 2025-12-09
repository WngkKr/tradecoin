import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';

interface LoginFormProps {
  onToggleMode: () => void;
}

export default function LoginForm({ onToggleMode }: LoginFormProps) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  
  const { signIn } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!email || !password) {
      setError('이메일과 비밀번호를 입력해주세요.');
      return;
    }

    try {
      setError('');
      setLoading(true);
      await signIn(email, password);
      navigate('/dashboard');
    } catch (error: any) {
      console.error('Login error:', error);
      setError('로그인에 실패했습니다. 이메일과 비밀번호를 확인해주세요.');
    } finally {
      setLoading(false);
    }
  };

  const handleGoogleSignIn = async () => {
    setError('구글 로그인은 현재 지원되지 않습니다.');
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary-blue/5 to-purple-500/5 flex items-center justify-center px-4">
      <div className="max-w-md w-full space-y-8">
        {/* Header */}
        <div className="text-center">
          <div className="mx-auto h-16 w-16 bg-gradient-to-r from-primary-blue to-purple-600 rounded-2xl flex items-center justify-center mb-6">
            <span className="text-2xl">🚀</span>
          </div>
          <h1 className="text-3xl font-bold text-text-primary mb-2">TradeCoin</h1>
          <p className="text-text-secondary">AI 트레이딩 플랫폼</p>
        </div>

        {/* Form */}
        <div className="bg-white rounded-2xl shadow-card p-8">
          <form onSubmit={handleSubmit} className="space-y-6">
            {error && (
              <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg text-sm">
                {error}
              </div>
            )}
            
            <div>
              <label htmlFor="email" className="block text-sm font-medium text-text-primary mb-2">
                📧 이메일
              </label>
              <input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="example@email.com"
                className="w-full px-4 py-3 border border-border rounded-xl focus:outline-none focus:ring-2 focus:ring-primary-blue/20 focus:border-primary-blue transition-colors"
                disabled={loading}
              />
            </div>

            <div>
              <label htmlFor="password" className="block text-sm font-medium text-text-primary mb-2">
                🔒 비밀번호
              </label>
              <input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••••••••••••••••••••••"
                className="w-full px-4 py-3 border border-border rounded-xl focus:outline-none focus:ring-2 focus:ring-primary-blue/20 focus:border-primary-blue transition-colors"
                disabled={loading}
              />
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full action-button disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? (
                <div className="flex items-center justify-center">
                  <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-2"></div>
                  로그인 중...
                </div>
              ) : (
                '💎 로그인하기'
              )}
            </button>
          </form>

          {/* Divider */}
          <div className="my-6">
            <div className="relative">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-border"></div>
              </div>
              <div className="relative flex justify-center text-sm">
                <span className="px-2 bg-white text-text-secondary">또는</span>
              </div>
            </div>
          </div>

          {/* Social Login */}
          <div className="space-y-3">
            <button
              onClick={handleGoogleSignIn}
              disabled={loading}
              className="w-full flex items-center justify-center px-4 py-3 border border-border rounded-xl hover:bg-gray-50 transition-colors disabled:opacity-50"
            >
              <span className="mr-2">🔍</span>
              Google로 시작하기
            </button>
            
            <button
              disabled={loading}
              className="w-full flex items-center justify-center px-4 py-3 border border-border rounded-xl hover:bg-gray-50 transition-colors disabled:opacity-50"
            >
              <span className="mr-2">🍎</span>
              Apple로 시작하기
            </button>
            
            <button
              disabled={loading}
              className="w-full flex items-center justify-center px-4 py-3 border border-border rounded-xl hover:bg-gray-50 transition-colors disabled:opacity-50"
            >
              <span className="mr-2">💬</span>
              Kakao로 시작하기
            </button>
          </div>

          {/* Footer */}
          <div className="mt-6 text-center text-sm text-text-secondary">
            계정이 없으신가요?{' '}
            <button
              onClick={onToggleMode}
              className="text-primary-blue hover:text-primary-blue/80 font-medium"
            >
              회원가입하기
            </button>
          </div>
          
          <div className="mt-2 text-center">
            <Link 
              to="/forgot-password" 
              className="text-sm text-text-secondary hover:text-primary-blue"
            >
              비밀번호 찾기
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}