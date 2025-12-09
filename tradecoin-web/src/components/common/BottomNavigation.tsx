import React from 'react';
import { useLocation, useNavigate } from 'react-router-dom';

// Futuristic Neon Icons
const HomeIcon = ({ active }: { active: boolean }) => (
  <div className="relative">
    <svg 
      className={`w-7 h-7 transition-all duration-300 ${
        active 
          ? 'text-cyan-400 drop-shadow-[0_0_8px_rgba(34,211,238,0.8)]' 
          : 'text-slate-400 hover:text-cyan-300'
      }`} 
      fill={active ? 'currentColor' : 'none'} 
      stroke={active ? 'none' : 'currentColor'} 
      viewBox="0 0 24 24"
    >
      {active ? (
        <path d="m19.681 10.406-7.09-6.179a.924.924 0 0 0-1.214.002l-7.06 6.179c-.642.561-.244 1.618.608 1.618.51 0 .924.414.924.924v5.395c0 .51.414.924.924.924h3.213V14.2c0-.51.414-.924.924-.924h2.338c.51 0 .924.414.924.924v5.069h3.213c.51 0 .924-.414.924-.924v-5.395c0-.51.414-.924.924-.924.852 0 1.25-1.057.608-1.618Z"/>
      ) : (
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} 
              d="m2.25 12 8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25" />
      )}
    </svg>
    {active && <div className="absolute inset-0 w-7 h-7 bg-cyan-400/20 rounded-lg blur animate-pulse"></div>}
  </div>
);

const PortfolioIcon = ({ active }: { active: boolean }) => (
  <div className="relative">
    <svg 
      className={`w-7 h-7 transition-all duration-300 ${
        active 
          ? 'text-emerald-400 drop-shadow-[0_0_8px_rgba(52,211,153,0.8)]' 
          : 'text-slate-400 hover:text-emerald-300'
      }`} 
      fill={active ? 'currentColor' : 'none'} 
      stroke={active ? 'none' : 'currentColor'} 
      viewBox="0 0 24 24"
    >
      {active ? (
        <path d="M3 4.5A1.5 1.5 0 0 1 4.5 3h15A1.5 1.5 0 0 1 21 4.5v15a1.5 1.5 0 0 1-1.5 1.5h-15A1.5 1.5 0 0 1 3 19.5V4.5ZM6 7.5h12v1.5H6V7.5Zm0 3h12v1.5H6v-1.5Zm0 3h7.5v1.5H6v-1.5Z"/>
      ) : (
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} 
              d="M9 12h3.75M9 15h3.75M9 18h3.75m3 .75H18a2.25 2.25 0 0 0 2.25-2.25V6.108c0-1.135-.845-2.098-1.976-2.192a48.424 48.424 0 0 0-1.123-.08m-5.801 0c-.065.21-.1.433-.1.664 0 .414.336.75.75.75h4.5a.75.75 0 0 0 .75-.75 2.25 2.25 0 0 0-.1-.664m-5.8 0A2.251 2.251 0 0 1 13.5 2.25H15c1.012 0 1.867.668 2.15 1.586m-5.8 0c-.376.023-.75.05-1.124.08C9.095 4.01 8.25 4.973 8.25 6.108V8.25m0 0H4.875c-.621 0-1.125.504-1.125 1.125v11.25c0 .621.504 1.125 1.125 1.125h9.75c.621 0 1.125-.504 1.125-1.125V9.375c0-.621-.504-1.125-1.125-1.125H8.25ZM6.75 12h.008v.008H6.75V12Zm0 3h.008v.008H6.75V15Zm0 3h.008v.008H6.75V18Z" />
      )}
    </svg>
    {active && <div className="absolute inset-0 w-7 h-7 bg-emerald-400/20 rounded-lg blur animate-pulse"></div>}
  </div>
);

const SignalIcon = ({ active }: { active: boolean }) => (
  <div className="relative">
    <svg 
      className={`w-7 h-7 transition-all duration-300 ${
        active 
          ? 'text-yellow-400 drop-shadow-[0_0_8px_rgba(250,204,21,0.8)]' 
          : 'text-slate-400 hover:text-yellow-300'
      }`} 
      fill={active ? 'currentColor' : 'none'} 
      stroke={active ? 'none' : 'currentColor'} 
      viewBox="0 0 24 24"
    >
      {active ? (
        <path d="M11.47 1.72a.75.75 0 0 1 1.06 0l3 3a.75.75 0 0 1-1.06 1.06L12 3.31 9.53 5.78a.75.75 0 0 1-1.06-1.06l3-3ZM11.25 3.5v7.94l-2.72 2.72a.75.75 0 0 0 1.06 1.06L12 12.81l2.41 2.41a.75.75 0 0 0 1.06-1.06L12.75 11.44V3.5h-1.5ZM12 16.5a3.75 3.75 0 1 0 0 7.5 3.75 3.75 0 0 0 0-7.5Z"/>
      ) : (
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} 
              d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75Z" />
      )}
    </svg>
    {active && <div className="absolute inset-0 w-7 h-7 bg-yellow-400/20 rounded-lg blur animate-pulse"></div>}
  </div>
);

const NewsIcon = ({ active }: { active: boolean }) => (
  <div className="relative">
    <svg 
      className={`w-7 h-7 transition-all duration-300 ${
        active 
          ? 'text-purple-400 drop-shadow-[0_0_8px_rgba(168,85,247,0.8)]' 
          : 'text-slate-400 hover:text-purple-300'
      }`} 
      fill={active ? 'currentColor' : 'none'} 
      stroke={active ? 'none' : 'currentColor'} 
      viewBox="0 0 24 24"
    >
      {active ? (
        <path d="M4.5 3.75a3 3 0 0 0-3 3v10.5a3 3 0 0 0 3 3h15a3 3 0 0 0 3-3V6.75a3 3 0 0 0-3-3h-15ZM7.5 8.25a.75.75 0 0 1 .75-.75h7.5a.75.75 0 0 1 0 1.5h-7.5a.75.75 0 0 1-.75-.75ZM8.25 10.5a.75.75 0 0 0 0 1.5H12a.75.75 0 0 0 0-1.5H8.25ZM8.25 13.5a.75.75 0 0 0 0 1.5h7.5a.75.75 0 0 0 0-1.5h-7.5Z"/>
      ) : (
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} 
              d="M12 7.5h1.5m-1.5 3h1.5m-7.5 3h7.5m-7.5 3h7.5M5.25 5.25h13.5a3 3 0 0 1 3 3v10.5a3 3 0 0 1-3 3H5.25a3 3 0 0 1-3-3V8.25a3 3 0 0 1 3-3Z" />
      )}
    </svg>
    {active && <div className="absolute inset-0 w-7 h-7 bg-purple-400/20 rounded-lg blur animate-pulse"></div>}
  </div>
);

const ProfileIcon = ({ active }: { active: boolean }) => (
  <div className="relative">
    <div className={`w-7 h-7 rounded-xl transition-all duration-300 flex items-center justify-center ${
      active 
        ? 'bg-gradient-to-br from-pink-500 to-rose-500 shadow-lg shadow-pink-500/40' 
        : 'bg-slate-600 hover:bg-slate-500'
    }`}>
      <svg className={`w-4 h-4 ${active ? 'text-white' : 'text-slate-300'}`} fill="currentColor" viewBox="0 0 24 24">
        <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/>
      </svg>
    </div>
    {active && <div className="absolute inset-0 w-7 h-7 bg-pink-400/20 rounded-xl blur animate-pulse"></div>}
  </div>
);

const NAV_ITEMS = [
  {
    path: '/dashboard',
    icon: HomeIcon,
    label: '홈',
    color: 'cyan'
  },
  {
    path: '/portfolio',
    icon: PortfolioIcon,
    label: '포트폴리오',
    color: 'emerald'
  },
  {
    path: '/signals',
    icon: SignalIcon,
    label: '시그널',
    color: 'yellow'
  },
  {
    path: '/news',
    icon: NewsIcon,
    label: '뉴스',
    color: 'purple'
  },
  {
    path: '/profile',
    icon: ProfileIcon,
    label: '프로필',
    color: 'pink'
  }
];

export default function BottomNavigation() {
  const location = useLocation();
  const navigate = useNavigate();

  const isActive = (path: string) => {
    return location.pathname === path;
  };

  return (
    <nav className="md:hidden fixed bottom-0 left-0 right-0 z-50">
      {/* Glow effect background */}
      <div className="absolute inset-0 bg-gradient-to-t from-slate-900/95 via-slate-800/90 to-transparent backdrop-blur-xl"></div>
      
      {/* Main navigation container */}
      <div className="relative">
        {/* Top border with animated gradient */}
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-cyan-400/60 to-transparent"></div>
        
        {/* Navigation items */}
        <div className="flex justify-around items-center px-2 py-4">
          {NAV_ITEMS.map((item, index) => {
            const IconComponent = item.icon;
            const active = isActive(item.path);
            
            return (
              <button
                key={item.path}
                onClick={() => navigate(item.path)}
                className={`relative flex flex-col items-center justify-center p-2 rounded-2xl transition-all duration-300 min-w-[60px] group ${
                  active 
                    ? 'transform -translate-y-1' 
                    : 'hover:transform hover:-translate-y-0.5'
                }`}
              >
                {/* Background glow for active item */}
                {active && (
                  <div className={`absolute inset-0 rounded-2xl bg-gradient-to-br ${
                    item.color === 'cyan' ? 'from-cyan-500/20 to-blue-600/20' :
                    item.color === 'emerald' ? 'from-emerald-500/20 to-teal-600/20' :
                    item.color === 'yellow' ? 'from-yellow-500/20 to-orange-600/20' :
                    item.color === 'purple' ? 'from-purple-500/20 to-indigo-600/20' :
                    'from-pink-500/20 to-rose-600/20'
                  } blur-sm`}></div>
                )}
                
                {/* Icon container */}
                <div className="relative mb-1">
                  <IconComponent active={active} />
                </div>
                
                {/* Label */}
                <span className={`text-xs font-medium transition-colors duration-300 ${
                  active 
                    ? item.color === 'cyan' ? 'text-cyan-400' :
                      item.color === 'emerald' ? 'text-emerald-400' :
                      item.color === 'yellow' ? 'text-yellow-400' :
                      item.color === 'purple' ? 'text-purple-400' :
                      'text-pink-400'
                    : 'text-slate-400 group-hover:text-slate-300'
                }`}>
                  {item.label}
                </span>
                
                {/* Active indicator dot */}
                {active && (
                  <div className={`absolute -bottom-1 w-1 h-1 rounded-full ${
                    item.color === 'cyan' ? 'bg-cyan-400' :
                    item.color === 'emerald' ? 'bg-emerald-400' :
                    item.color === 'yellow' ? 'bg-yellow-400' :
                    item.color === 'purple' ? 'bg-purple-400' :
                    'bg-pink-400'
                  } animate-ping`}></div>
                )}
              </button>
            );
          })}
        </div>
        
        {/* Floating action indicator */}
        <div className="absolute bottom-0 left-1/2 transform -translate-x-1/2 w-12 h-1 bg-gradient-to-r from-transparent via-white/30 to-transparent rounded-full"></div>
      </div>
    </nav>
  );
}