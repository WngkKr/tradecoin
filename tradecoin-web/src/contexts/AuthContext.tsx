import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { 
  signInWithEmailAndPassword, 
  createUserWithEmailAndPassword,
  signOut as firebaseSignOut,
  onAuthStateChanged,
  User as FirebaseUser,
  updateProfile
} from 'firebase/auth';
import { doc, setDoc, getDoc } from 'firebase/firestore';
import { auth, db } from '../firebase/config';
import { User } from '../types';

interface AuthContextType {
  user: User | null;
  loading: boolean;
  signUp: (email: string, password: string, displayName: string) => Promise<any>;
  signIn: (email: string, password: string) => Promise<any>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}

interface AuthProviderProps {
  children: ReactNode;
}

export function AuthProvider({ children }: AuthProviderProps) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    console.log('🔥 Initializing Firebase Auth listener...');
    
    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser: FirebaseUser | null) => {
      console.log('🔥 Auth state changed:', firebaseUser?.email || 'No user');
      
      if (firebaseUser) {
        try {
          // Fetch user data from Firestore
          const userDoc = await getDoc(doc(db, 'users', firebaseUser.uid));
          
          if (userDoc.exists()) {
            const userData = userDoc.data();
            console.log('✅ User data found in Firestore');
            setUser({ 
              uid: firebaseUser.uid, 
              ...userData,
              // Convert Firestore timestamps to Date objects
              createdAt: userData.createdAt?.toDate ? userData.createdAt.toDate() : new Date(userData.createdAt),
              updatedAt: userData.updatedAt?.toDate ? userData.updatedAt.toDate() : new Date(userData.updatedAt),
              stats: {
                signalsUsed: 0,
                tradesExecuted: 0,
                totalPnL: 0,
                winRate: 0,
                ...userData.stats,
                lastLogin: userData.stats?.lastLogin?.toDate ? userData.stats.lastLogin.toDate() : new Date(userData.stats?.lastLogin || Date.now())
              },
              subscription: {
                tier: 'free',
                status: 'active',
                autoRenew: false,
                ...userData.subscription,
                startDate: userData.subscription?.startDate?.toDate ? userData.subscription.startDate.toDate() : new Date(userData.subscription?.startDate || Date.now()),
                endDate: userData.subscription?.endDate?.toDate ? userData.subscription.endDate.toDate() : new Date(userData.subscription?.endDate || Date.now() + 365 * 24 * 60 * 60 * 1000)
              }
            } as User);
          } else {
            // Create new user document
            console.log('⚠️ No user data found, creating new user document');
            const newUser: Omit<User, 'uid'> = {
              email: firebaseUser.email!,
              displayName: firebaseUser.displayName || firebaseUser.email!.split('@')[0],
              photoURL: firebaseUser.photoURL || undefined,
              subscription: {
                tier: 'free',
                status: 'active',
                startDate: new Date(),
                endDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
                autoRenew: false
              },
              profile: {
                experienceLevel: 'beginner',
                riskTolerance: 'conservative',
                preferredCoins: ['BTC', 'ETH']
              },
              settings: {
                notifications: {
                  push: true,
                  email: true,
                  sms: false,
                  signalThreshold: 75
                },
                trading: {
                  autoTrading: false,
                  maxPositions: 2,
                  maxLeverage: 5,
                  stopLoss: 0.03,
                  takeProfit: 0.1
                }
              },
              stats: {
                signalsUsed: 0,
                tradesExecuted: 0,
                totalPnL: 0,
                winRate: 0,
                lastLogin: new Date()
              },
              createdAt: new Date(),
              updatedAt: new Date(),
              isActive: true
            };

            await setDoc(doc(db, 'users', firebaseUser.uid), newUser);
            setUser({ ...newUser, uid: firebaseUser.uid } as User);
            console.log('✅ New user document created');
          }
        } catch (error) {
          console.error('❌ Error fetching user data:', error);
          setUser(null);
        }
      } else {
        setUser(null);
      }
      
      setLoading(false);
    });

    return unsubscribe;
  }, []);

  const signIn = async (email: string, password: string) => {
    setLoading(true);
    try {
      const result = await signInWithEmailAndPassword(auth, email, password);
      
      // Update last login time
      if (result.user) {
        const userRef = doc(db, 'users', result.user.uid);
        await setDoc(userRef, {
          'stats.lastLogin': new Date(),
          updatedAt: new Date()
        }, { merge: true });
      }
      
      console.log('✅ Firebase signin successful:', result.user.email);
      setLoading(false);
      return result.user;
    } catch (error: any) {
      console.error('❌ Sign in error:', error);
      setLoading(false);
      
      // Provide user-friendly error messages
      let errorMessage = '로그인 중 오류가 발생했습니다.';
      if (error.code === 'auth/user-not-found') {
        errorMessage = '등록되지 않은 이메일입니다.';
      } else if (error.code === 'auth/wrong-password') {
        errorMessage = '비밀번호가 올바르지 않습니다.';
      } else if (error.code === 'auth/invalid-email') {
        errorMessage = '유효하지 않은 이메일 형식입니다.';
      }
      
      throw new Error(errorMessage);
    }
  };

  const signUp = async (email: string, password: string, displayName: string) => {
    setLoading(true);
    try {
      const result = await createUserWithEmailAndPassword(auth, email, password);
      
      // Update Firebase Auth profile
      await updateProfile(result.user, {
        displayName: displayName
      });
      
      // Create user document in Firestore (will be handled by onAuthStateChanged)
      console.log('✅ Firebase signup successful:', result.user.email);
      setLoading(false);
      return result.user;
    } catch (error: any) {
      console.error('❌ Sign up error:', error);
      setLoading(false);
      
      // Provide user-friendly error messages
      let errorMessage = '회원가입 중 오류가 발생했습니다.';
      if (error.code === 'auth/email-already-in-use') {
        errorMessage = '이미 사용 중인 이메일입니다.';
      } else if (error.code === 'auth/weak-password') {
        errorMessage = '비밀번호가 너무 간단합니다. 6자 이상으로 설정해주세요.';
      } else if (error.code === 'auth/invalid-email') {
        errorMessage = '유효하지 않은 이메일 형식입니다.';
      }
      
      throw new Error(errorMessage);
    }
  };

  const signOut = async () => {
    try {
      await firebaseSignOut(auth);
      setUser(null);
      console.log('✅ Successfully signed out');
    } catch (error) {
      console.error('❌ Sign out error:', error);
      throw error;
    }
  };

  const value: AuthContextType = {
    user,
    loading,
    signUp,
    signIn,
    signOut
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}