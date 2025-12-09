import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import LoginForm from '../components/auth/LoginForm';
import SignUpForm from '../components/auth/SignUpForm';

export default function AuthPage() {
  const [mode, setMode] = useState<'login' | 'signup'>('login');
  const navigate = useNavigate();

  const toggleMode = () => {
    setMode(mode === 'login' ? 'signup' : 'login');
  };

  const handleSignUpSuccess = () => {
    navigate('/onboarding');
  };

  return (
    <>
      {mode === 'login' ? (
        <LoginForm onToggleMode={toggleMode} />
      ) : (
        <SignUpForm onToggleMode={toggleMode} onSuccess={handleSignUpSuccess} />
      )}
    </>
  );
}