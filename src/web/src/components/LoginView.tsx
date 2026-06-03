import React, { useState } from 'react';
import { motion } from 'motion/react';
import { Shield, Key, Mail, Lock, CheckCircle, Smartphone, AlertCircle, Info } from 'lucide-react';
import { authService } from '../services/auth';
import { CognitoUserSession } from '../types';

interface LoginViewProps {
  onLoginSuccess: (session: CognitoUserSession) => void;
}

export default function LoginView({ onLoginSuccess }: LoginViewProps) {
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isSignUp, setIsSignUp] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  // Retrieve configuration details
  const config = authService.getConfigDetails();
  const isCognitoConfigured = authService.isConfigured();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSuccess(null);

    if (!username.trim() || !password) {
      setError('Username and password are required fields.');
      return;
    }

    if (isSignUp && !email.trim()) {
      setError('Email address is required for registration.');
      return;
    }

    if (password.length < 6) {
      setError('Password must contain at least 6 characters.');
      return;
    }

    setLoading(true);

    try {
      if (isSignUp) {
        // Sign-up flow
        await authService.signUp(username, email, password);
        setSuccess('Account registered successfully! You may now sign in using these credentials.');
        setIsSignUp(false);
        setPassword('');
      } else {
        // Sign-in flow
        const session = await authService.login(username, password);
        onLoginSuccess(session);
      }
    } catch (err: any) {
      setError(err.message || 'An authentication error occurred.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div id="login-container" className="min-h-screen bg-slate-50 flex flex-col justify-center py-12 px-4 sm:px-6 lg:px-8">
      <motion.div
        id="login-card-wrapper"
        initial={{ opacity: 0, y: 15 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, ease: 'easeOut' }}
        className="sm:mx-auto sm:w-full sm:max-w-md"
      >
        {/* Brand Header */}
        <div className="flex flex-col items-center">
          <div className="h-14 w-14 bg-indigo-600 rounded-2xl flex items-center justify-center shadow-lg shadow-indigo-100">
            <Shield className="h-7 w-7 text-white" />
          </div>
          <h2 className="mt-6 text-center text-3xl font-extrabold tracking-tight text-slate-800 font-sans">
            FeastFlow<span className="text-indigo-600">Dash</span>
          </h2>
          <p className="mt-2 text-center text-sm text-slate-500">
            Secure operator portal for food delivery dispatches
          </p>
        </div>

        {/* Card Form */}
        <div className="mt-8 bg-white py-8 px-4 shadow-xl border border-slate-200/60 rounded-2xl sm:px-10">
          <form className="space-y-6" onSubmit={handleSubmit}>
            {error && (
              <div id="login-error-banner" className="bg-rose-50 border border-rose-200 text-rose-700 p-3.5 rounded-xl flex items-start gap-2.5 text-xs">
                <AlertCircle className="h-4.5 w-4.5 shrink-0 mt-0.5" />
                <span>{error}</span>
              </div>
            )}

            {success && (
              <div id="login-success-banner" className="bg-indigo-50 border border-indigo-100 text-indigo-800 p-3.5 rounded-xl flex items-start gap-2.5 text-xs">
                <CheckCircle className="h-4.5 w-4.5 shrink-0 mt-0.5" />
                <span>{success}</span>
              </div>
            )}

            <div>
              <label className="block text-xs font-bold uppercase tracking-widest text-slate-500 mb-1.5" htmlFor="username">
                Username ({isSignUp ? 'New User' : 'Cognito User'})
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Key className="h-4 w-4 text-slate-400" />
                </div>
                <input
                  id="username"
                  name="username"
                  type="text"
                  required
                  placeholder="enter username"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  className="block w-full pl-10 pr-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 text-sm placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all"
                />
              </div>
            </div>

            {isSignUp && (
              <div>
                <label className="block text-xs font-bold uppercase tracking-widest text-slate-500 mb-1.5" htmlFor="email">
                  Email Address
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <Mail className="h-4 w-4 text-slate-400" />
                  </div>
                  <input
                    id="email"
                    name="email"
                    type="email"
                    required={isSignUp}
                    placeholder="email@example.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="block w-full pl-10 pr-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 text-sm placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all"
                  />
                </div>
              </div>
            )}

            <div>
              <label className="block text-xs font-bold uppercase tracking-widest text-slate-500 mb-1.5" htmlFor="password">
                Password
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Lock className="h-4 w-4 text-slate-400" />
                </div>
                <input
                  id="password"
                  name="password"
                  type="password"
                  required
                  placeholder="••••••••"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="block w-full pl-10 pr-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 text-sm placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all"
                />
              </div>
            </div>

            <div>
              <button
                id="submit-auth-btn"
                type="submit"
                disabled={loading}
                className="w-full flex justify-center py-3.5 px-4 border border-transparent rounded-xl shadow-lg shadow-indigo-100 text-sm font-bold text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-all cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {loading ? (
                  <span className="flex items-center gap-2">
                    <svg className="animate-spin h-5 w-5 text-white" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                    </svg>
                    Verifying Credentials...
                  </span>
                ) : isSignUp ? (
                  'Create Operator Profile'
                ) : (
                  'Secure Authorize'
                )}
              </button>
            </div>
          </form>

          {/* Switch Mode */}
          <div className="mt-6 text-center">
            <button
              id="switch-auth-mode-btn"
              type="button"
              onClick={() => {
                setIsSignUp(!isSignUp);
                setError(null);
                setSuccess(null);
              }}
              className="text-xs font-semibold text-slate-500 hover:text-indigo-600 transition-colors cursor-pointer"
            >
              {isSignUp ? 'Already registered? Complete Authorization' : 'New operator? Register Cognito Credential'}
            </button>
          </div>
        </div>

        {/* Integration Credentials Information */}
        <div className="mt-6 bg-white border border-slate-200 rounded-2xl p-5 text-xs text-slate-600 shadow-sm">
          <div className="flex items-center gap-2 mb-3">
            <Info className="h-4.5 w-4.5 text-indigo-500" />
            <h3 className="font-bold uppercase tracking-widest text-slate-700 text-[10px]">
              AWS Cognito Configuration Status
            </h3>
          </div>

          <div className="space-y-1.5 font-mono text-[11px]">
            <div className="flex justify-between border-b border-slate-100 pb-1.5">
              <span className="text-slate-400">STATUS:</span>
              <span className={`font-bold ${isCognitoConfigured ? 'text-indigo-600' : 'text-amber-600'}`}>
                {isCognitoConfigured ? '● AWS LIVE ROUTING' : '○ SIMULATED / DEMO MODE'}
              </span>
            </div>
            <div className="flex justify-between border-b border-slate-100 pb-1.5">
              <span className="text-slate-400">POOL ID:</span>
              <span className="text-slate-800">
                {config.userPoolId || 'VITE_USER_POOL_ID undefined (fallbacks active)'}
              </span>
            </div>
            <div className="flex justify-between border-b border-slate-100 pb-1.5">
              <span className="text-slate-400">CLIENT ID:</span>
              <span className="text-slate-800">
                {config.clientId || 'VITE_CLIENT_ID undefined'}
              </span>
            </div>
            <div className="flex justify-between border-b border-slate-100 pb-1.5">
              <span className="text-slate-400">API GATEWAY:</span>
              <span className="text-slate-800 break-all text-right max-w-[200px]">
                {config.apiGatewayUrl || 'VITE_API_URL undefined (offline simulation)'}
              </span>
            </div>
            {config.userPoolId && (
              <div className="flex justify-between">
                <span className="text-slate-400">AWS REGION:</span>
                <span className="text-slate-800">{config.region}</span>
              </div>
            )}
          </div>

          {!isCognitoConfigured && (
            <p className="mt-3 text-[10px] text-slate-400 leading-relaxed italic">
              * AWS standard parameters are undefined. You can authenticate instantly using any username and active password of at least 6 characters in our high-fidelity S3 Demo Sandbox.
            </p>
          )}
        </div>
      </motion.div>
    </div>
  );
}
