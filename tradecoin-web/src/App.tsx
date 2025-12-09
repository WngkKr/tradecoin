import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './contexts/AuthContext';

// Components
import AuthPage from './pages/AuthPage';
import OnboardingFlow from './components/auth/OnboardingFlow';
import Dashboard from './components/dashboard/Dashboard';
import Portfolio from './components/portfolio/Portfolio';
import Membership from './components/membership/Membership';
import Profile from './components/profile/Profile';
import Signals from './components/signals/Signals';
import News from './components/news/News';

// Loading Component
function LoadingScreen() {
  return (
    <div className="min-h-screen bg-background flex items-center justify-center">
      <div className="text-center">
        <div className="h-16 w-16 bg-gradient-to-r from-primary-blue to-purple-600 rounded-2xl flex items-center justify-center mb-6 mx-auto animate-pulse-soft">
          <span className="text-2xl">🚀</span>
        </div>
        <h1 className="text-2xl font-bold text-text-primary mb-2">TradeCoin</h1>
        <p className="text-text-secondary">로딩 중...</p>
        <div className="mt-4">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-blue mx-auto"></div>
        </div>
      </div>
    </div>
  );
}

// Protected Route Component
function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth();
  
  if (loading) {
    return <LoadingScreen />;
  }
  
  if (!user) {
    return <Navigate to="/auth" replace />;
  }
  
  return <>{children}</>;
}

// Public Route Component (redirect if already authenticated)
function PublicRoute({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth();
  
  if (loading) {
    return <LoadingScreen />;
  }
  
  if (user) {
    return <Navigate to="/dashboard" replace />;
  }
  
  return <>{children}</>;
}

// Main App Content
function AppContent() {
  return (
    <Router>
      <div className="App">
        <Routes>
          {/* Public Routes */}
          <Route 
            path="/auth" 
            element={
              <PublicRoute>
                <AuthPage />
              </PublicRoute>
            } 
          />
          
          {/* Protected Routes */}
          <Route 
            path="/onboarding" 
            element={
              <ProtectedRoute>
                <OnboardingFlow />
              </ProtectedRoute>
            } 
          />
          
          <Route 
            path="/dashboard" 
            element={
              <ProtectedRoute>
                <Dashboard />
              </ProtectedRoute>
            } 
          />
          
          <Route 
            path="/portfolio" 
            element={
              <ProtectedRoute>
                <Portfolio />
              </ProtectedRoute>
            } 
          />
          
          <Route 
            path="/membership" 
            element={
              <ProtectedRoute>
                <Membership />
              </ProtectedRoute>
            } 
          />
          
          <Route 
            path="/profile" 
            element={
              <ProtectedRoute>
                <Profile />
              </ProtectedRoute>
            } 
          />

          <Route 
            path="/signals" 
            element={
              <ProtectedRoute>
                <Signals />
              </ProtectedRoute>
            } 
          />

          <Route 
            path="/news" 
            element={
              <ProtectedRoute>
                <News />
              </ProtectedRoute>
            } 
          />
          
          {/* Default Route */}
          <Route 
            path="/" 
            element={<Navigate to="/dashboard" replace />} 
          />
          
          {/* 404 Route */}
          <Route 
            path="*" 
            element={
              <div className="min-h-screen bg-background flex items-center justify-center">
                <div className="text-center">
                  <div className="text-6xl mb-4">🤖</div>
                  <h1 className="text-2xl font-bold text-text-primary mb-2">
                    404 - 페이지를 찾을 수 없습니다
                  </h1>
                  <p className="text-text-secondary mb-6">
                    요청하신 페이지가 존재하지 않습니다.
                  </p>
                  <button 
                    onClick={() => window.location.href = '/dashboard'}
                    className="action-button"
                  >
                    홈으로 돌아가기
                  </button>
                </div>
              </div>
            } 
          />
        </Routes>
      </div>
    </Router>
  );
}

// Main App Component with Providers
function App() {
  return (
    <AuthProvider>
      <AppContent />
    </AuthProvider>
  );
}

export default App;
