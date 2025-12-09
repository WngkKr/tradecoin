import React, { ReactNode, useState } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import BottomNavigation from './BottomNavigation';

interface LayoutProps {
  children: ReactNode;
}

export default function Layout({ children }: LayoutProps) {
  const { user, signOut } = useAuth();
  const [showUserMenu, setShowUserMenu] = useState(false);

  const handleSignOut = async () => {
    try {
      await signOut();
    } catch (error) {
      console.error('Sign out error:', error);
    }
  };


  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-gray-900 to-zinc-900">
      {/* Futuristic Header */}
      <header className="relative bg-gradient-to-r from-indigo-600/20 via-purple-600/20 to-pink-600/20 backdrop-blur-xl border-b border-cyan-400/20 sticky top-0 z-50">
        <div className="absolute inset-0 bg-gradient-to-r from-transparent via-cyan-500/10 to-transparent"></div>
        <div className="relative px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-20">
            {/* Futuristic Logo */}
            <div className="flex items-center space-x-4">
              <div className="relative">
                <div className="w-12 h-12 bg-gradient-to-br from-cyan-400 to-blue-600 rounded-xl flex items-center justify-center shadow-lg shadow-cyan-500/25">
                  <div className="w-8 h-8 bg-gradient-to-br from-white to-cyan-100 rounded-lg flex items-center justify-center">
                    <span className="text-blue-900 text-lg font-black tracking-wider">TC</span>
                  </div>
                </div>
                <div className="absolute -top-1 -right-1 w-3 h-3 bg-green-400 rounded-full animate-pulse"></div>
              </div>
              <div className="hidden sm:block">
                <div className="text-xl font-bold bg-gradient-to-r from-cyan-400 to-blue-400 bg-clip-text text-transparent">
                  TradeCoin
                </div>
                <div className="text-xs text-cyan-300/80 font-medium tracking-wide uppercase">
                  AI Trading Platform
                </div>
              </div>
            </div>

            {/* Status & Actions */}
            <div className="flex items-center space-x-6">
              {/* Market Status */}
              <div className="hidden md:flex items-center space-x-2 px-4 py-2 bg-green-500/10 rounded-full border border-green-400/20">
                <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
                <span className="text-green-400 text-sm font-medium">Market Open</span>
              </div>
              
              {user && (
                <div className="flex items-center space-x-4">
                  {/* Notifications */}
                  <button className="relative p-3 hover:bg-white/10 rounded-xl transition-all duration-300 group">
                    <svg className="w-6 h-6 text-cyan-400 group-hover:text-cyan-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} 
                            d="M15 17h5l-3-3V9a6 6 0 10-12 0v5l-3 3h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/>
                    </svg>
                    <div className="absolute top-1 right-1 w-3 h-3 bg-red-500 rounded-full animate-bounce"></div>
                  </button>

                  {/* User Profile */}
                  <div className="relative">
                    <button
                      onClick={() => setShowUserMenu(!showUserMenu)}
                      className="flex items-center space-x-3 px-4 py-2 bg-gradient-to-r from-purple-600/20 to-pink-600/20 rounded-xl border border-purple-400/30 hover:border-purple-400/50 transition-all duration-300"
                    >
                      {user.photoURL ? (
                        <img
                          src={user.photoURL}
                          alt="Profile"
                          className="w-8 h-8 rounded-full ring-2 ring-purple-400/50"
                        />
                      ) : (
                        <div className="w-8 h-8 rounded-full bg-gradient-to-br from-purple-500 to-pink-500 flex items-center justify-center">
                          <span className="text-white font-bold text-sm">
                            {user.displayName?.charAt(0) || user.email?.charAt(0)?.toUpperCase() || 'U'}
                          </span>
                        </div>
                      )}
                      <div className="hidden sm:block text-left">
                        <div className="text-sm font-semibold text-white">
                          {user.displayName || 'User'}
                        </div>
                        <div className="text-xs text-purple-300">Premium Member</div>
                      </div>
                      <svg className="w-4 h-4 text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                      </svg>
                    </button>

                    {/* Futuristic Dropdown */}
                    {showUserMenu && (
                      <div className="absolute right-0 mt-2 w-64 bg-slate-800/90 backdrop-blur-xl rounded-2xl border border-cyan-400/20 shadow-2xl shadow-cyan-500/10 py-2 z-50">
                        <div className="px-4 py-3 border-b border-cyan-400/20">
                          <div className="text-sm font-medium text-white">{user.displayName || 'User'}</div>
                          <div className="text-xs text-cyan-400">{user.email}</div>
                        </div>
                        <button className="flex items-center w-full px-4 py-3 text-sm text-white hover:bg-cyan-500/10 transition-colors">
                          <svg className="w-5 h-5 mr-3 text-cyan-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                          </svg>
                          내 프로필
                        </button>
                        <button className="flex items-center w-full px-4 py-3 text-sm text-white hover:bg-cyan-500/10 transition-colors">
                          <svg className="w-5 h-5 mr-3 text-cyan-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                          </svg>
                          설정
                        </button>
                        <hr className="my-2 border-cyan-400/20" />
                        <button 
                          onClick={handleSignOut}
                          className="flex items-center w-full px-4 py-3 text-sm text-red-400 hover:bg-red-500/10 transition-colors"
                        >
                          <svg className="w-5 h-5 mr-3 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                          </svg>
                          로그아웃
                        </button>
                      </div>
                    )}
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
        
        {/* Animated border */}
        <div className="absolute bottom-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-cyan-400 to-transparent opacity-60"></div>
      </header>

      {/* Main Content */}
      <main className="flex-1">
        {children}
      </main>

      {/* Bottom Navigation (Mobile) */}
      <BottomNavigation />

      {/* Click outside to close menu */}
      {showUserMenu && (
        <div 
          className="fixed inset-0 z-40"
          onClick={() => setShowUserMenu(false)}
        />
      )}
    </div>
  );
}