import React, { useState } from 'react';
import { useAuth } from '../../contexts/AuthContext';

interface SignUpFormProps {
  onToggleMode: () => void;
  onSuccess: () => void;
}

export default function SignUpForm({ onToggleMode, onSuccess }: SignUpFormProps) {
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    confirmPassword: '',
    displayName: '',
    agreeToTerms: false,
    agreeToPrivacy: false,
    agreeToMarketing: false
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  
  const { signUp } = useAuth();

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    // Validation
    if (!formData.email || !formData.password || !formData.displayName) {
      setError('모든 필수 항목을 입력해주세요.');
      return;
    }

    if (formData.password !== formData.confirmPassword) {
      setError('비밀번호가 일치하지 않습니다.');
      return;
    }

    if (formData.password.length < 6) {
      setError('비밀번호는 최소 6자리 이상이어야 합니다.');
      return;
    }

    if (!formData.agreeToTerms || !formData.agreeToPrivacy) {
      setError('필수 약관에 동의해주세요.');
      return;
    }

    try {
      setError('');
      setLoading(true);
      await signUp(formData.email, formData.password, formData.displayName);
      onSuccess();
    } catch (error: any) {
      console.error('Sign up error:', error);
      if (error.code === 'auth/email-already-in-use') {
        setError('이미 사용 중인 이메일입니다.');
      } else if (error.code === 'auth/weak-password') {
        setError('비밀번호가 너무 약합니다.');
      } else {
        setError('회원가입에 실패했습니다. 다시 시도해주세요.');
      }
    } finally {
      setLoading(false);
    }
  };

  const handleGoogleSignUp = async () => {
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
          <h1 className="text-3xl font-bold text-text-primary mb-2">TradeCoin에 오신 것을 환영합니다</h1>
          <p className="text-text-secondary">AI와 함께하는 스마트 트레이딩</p>
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
              <label htmlFor="displayName" className="block text-sm font-medium text-text-primary mb-2">
                👤 이름
              </label>
              <input
                id="displayName"
                name="displayName"
                type="text"
                value={formData.displayName}
                onChange={handleChange}
                placeholder="홍길동"
                className="w-full px-4 py-3 border border-border rounded-xl focus:outline-none focus:ring-2 focus:ring-primary-blue/20 focus:border-primary-blue transition-colors"
                disabled={loading}
              />
            </div>

            <div>
              <label htmlFor="email" className="block text-sm font-medium text-text-primary mb-2">
                📧 이메일
              </label>
              <input
                id="email"
                name="email"
                type="email"
                value={formData.email}
                onChange={handleChange}
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
                name="password"
                type="password"
                value={formData.password}
                onChange={handleChange}
                placeholder="최소 6자리 이상"
                className="w-full px-4 py-3 border border-border rounded-xl focus:outline-none focus:ring-2 focus:ring-primary-blue/20 focus:border-primary-blue transition-colors"
                disabled={loading}
              />
            </div>

            <div>
              <label htmlFor="confirmPassword" className="block text-sm font-medium text-text-primary mb-2">
                🔒 비밀번호 확인
              </label>
              <input
                id="confirmPassword"
                name="confirmPassword"
                type="password"
                value={formData.confirmPassword}
                onChange={handleChange}
                placeholder="비밀번호를 다시 입력하세요"
                className="w-full px-4 py-3 border border-border rounded-xl focus:outline-none focus:ring-2 focus:ring-primary-blue/20 focus:border-primary-blue transition-colors"
                disabled={loading}
              />
            </div>

            {/* Terms and Conditions */}
            <div className="space-y-3">
              <div className="flex items-center">
                <input
                  id="agreeToTerms"
                  name="agreeToTerms"
                  type="checkbox"
                  checked={formData.agreeToTerms}
                  onChange={handleChange}
                  className="h-4 w-4 text-primary-blue focus:ring-primary-blue border-border rounded"
                  disabled={loading}
                />
                <label htmlFor="agreeToTerms" className="ml-2 text-sm text-text-primary">
                  ✅ <span className="text-danger-red">*</span> 이용약관 동의
                </label>
              </div>

              <div className="flex items-center">
                <input
                  id="agreeToPrivacy"
                  name="agreeToPrivacy"
                  type="checkbox"
                  checked={formData.agreeToPrivacy}
                  onChange={handleChange}
                  className="h-4 w-4 text-primary-blue focus:ring-primary-blue border-border rounded"
                  disabled={loading}
                />
                <label htmlFor="agreeToPrivacy" className="ml-2 text-sm text-text-primary">
                  ✅ <span className="text-danger-red">*</span> 개인정보처리방침 동의
                </label>
              </div>

              <div className="flex items-center">
                <input
                  id="agreeToMarketing"
                  name="agreeToMarketing"
                  type="checkbox"
                  checked={formData.agreeToMarketing}
                  onChange={handleChange}
                  className="h-4 w-4 text-primary-blue focus:ring-primary-blue border-border rounded"
                  disabled={loading}
                />
                <label htmlFor="agreeToMarketing" className="ml-2 text-sm text-text-primary">
                  ⭕ 마케팅 수신 동의 (선택)
                </label>
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full action-button disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? (
                <div className="flex items-center justify-center">
                  <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-2"></div>
                  계정 생성 중...
                </div>
              ) : (
                '🎉 계정 만들기'
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

          {/* Social Sign Up */}
          <div className="space-y-3">
            <button
              onClick={handleGoogleSignUp}
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
            이미 계정이 있으신가요?{' '}
            <button
              onClick={onToggleMode}
              className="text-primary-blue hover:text-primary-blue/80 font-medium"
            >
              로그인하기
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}