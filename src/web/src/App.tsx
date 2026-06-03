import { useState, useEffect } from 'react';
import LoginView from './components/LoginView';
import DashboardView from './components/DashboardView';
import { authService } from './services/auth';
import { CognitoUserSession } from './types';

export default function App() {
  const [session, setSession] = useState<CognitoUserSession | null>(null);
  const [appRestoring, setAppRestoring] = useState(true);

  // Read active Cognito credentials from local device storage on bootstrap
  useEffect(() => {
    const currentSession = authService.getCurrentUser();
    if (currentSession) {
      setSession(currentSession);
    }
    setAppRestoring(false);
  }, []);

  const handleLoginSuccess = (newSession: CognitoUserSession) => {
    setSession(newSession);
  };

  const handleLogout = () => {
    authService.logout();
    setSession(null);
  };

  if (appRestoring) {
    return (
      <div className="min-h-screen bg-slate-50 flex items-center justify-center font-sans">
        <div className="text-center space-y-3">
          <svg className="animate-spin h-8 w-8 text-emerald-600 mx-auto" fill="none" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
          </svg>
          <p className="text-xs font-semibold uppercase tracking-widest text-slate-400">Loading Delivery Operations Core...</p>
        </div>
      </div>
    );
  }

  return (
    <>
      {session ? (
        <DashboardView userSession={session} onLogout={handleLogout} />
      ) : (
        <LoginView onLoginSuccess={handleLoginSuccess} />
      )}
    </>
  );
}

