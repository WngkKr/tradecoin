import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getAnalytics } from 'firebase/analytics';

// Real Firebase project configuration
const firebaseConfig = {
  apiKey: "AIzaSyD5ZSuv5WSkgvH_JfhG-UCXrLjAr064S2A",
  authDomain: "emotra-9ebdb.firebaseapp.com",
  projectId: "emotra-9ebdb",
  storageBucket: "emotra-9ebdb.firebasestorage.app",
  messagingSenderId: "324977398952",
  appId: "1:324977398952:web:8693e08ec7edc8065f9e9d"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize Firebase Authentication and get a reference to the service
export const auth = getAuth(app);

// Initialize Cloud Firestore and get a reference to the service  
export const db = getFirestore(app);

// Connected to real Firebase project: emotra-9ebdb
console.log('🔥 Connected to Firebase project:', auth.app.options.projectId);

// Initialize Analytics (only in production)
export const analytics = typeof window !== 'undefined' && process.env.NODE_ENV === 'production' 
  ? getAnalytics(app) 
  : null;

export default app;