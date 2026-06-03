import axios from 'axios';
import { CognitoUserSession } from '../types';

const USER_POOL_ID = import.meta.env.VITE_USER_POOL_ID || '';
const CLIENT_ID = import.meta.env.VITE_CLIENT_ID || '';

// Helper to determine region from standard Cognito pool ID, e.g., us-east-1_xxxxxxxx
const getCognitoRegion = (poolId: string) => {
  if (!poolId || !poolId.includes('_')) return 'us-east-1';
  return poolId.split('_')[0];
};

const COGNITO_REGION = getCognitoRegion(USER_POOL_ID);
const COGNITO_ENDPOINT = `https://cognito-idp.${COGNITO_REGION}.amazonaws.com/`;

export const authService = {
  /**
   * Performs standard USER_PASSWORD_AUTH authentication against AWS Cognito User Pool.
   * If credentials are not present or custom test flags apply, fallback can occur.
   */
  login: async (username: string, password: string): Promise<CognitoUserSession> => {
    // If Cognito setup is missing, we operate in Demo mode with useful client-side mock
    const isMockMode = !USER_POOL_ID || !CLIENT_ID;

    if (isMockMode) {
      // Simulate real Cognito network delay
      await new Promise((resolve) => setTimeout(resolve, 800));

      if (username && password.length >= 6) {
        const mockSession: CognitoUserSession = {
          username: username,
          idToken: 'mock_id_token_jwt_' + Math.random().toString(36).substr(2, 9),
          accessToken: 'mock_access_token_jwt_' + Math.random().toString(36).substr(2, 9),
          refreshToken: 'mock_refresh_token_jwt_etc',
          email: username.includes('@') ? username : `${username}@example.com`,
        };

        // Cache session credentials
        localStorage.setItem('cognito_session', JSON.stringify(mockSession));
        localStorage.setItem('id_token', mockSession.idToken);
        localStorage.setItem('access_token', mockSession.accessToken);
        return mockSession;
      } else {
        throw new Error('Authentication failed (Cognito Demo Mode: Password must be at least 6 characters).');
      }
    }

    try {
      // Make real POST requests directly to Amazon Cognito Service Endpoint
      const response = await axios.post(
        COGNITO_ENDPOINT,
        {
          AuthFlow: 'USER_PASSWORD_AUTH',
          ClientId: CLIENT_ID,
          AuthParameters: {
            USERNAME: username,
            PASSWORD: password,
          },
        },
        {
          headers: {
            'Content-Type': 'application/x-amz-json-1.1',
            'X-Amz-Target': 'AWSCognitoIdentityProviderService.InitiateAuth',
          },
        }
      );

      const authResult = response.data.AuthenticationResult;
      if (!authResult) {
        throw new Error('Invalid Cognito authentication response from Cognito service.');
      }

      const session: CognitoUserSession = {
        username: username,
        idToken: authResult.IdToken,
        accessToken: authResult.AccessToken,
        refreshToken: authResult.RefreshToken,
        email: username,
      };

      // Set user session info
      localStorage.setItem('cognito_session', JSON.stringify(session));
      localStorage.setItem('id_token', session.idToken);
      localStorage.setItem('access_token', session.accessToken);

      return session;
    } catch (error: any) {
      console.error('Cognito Authentication Error:', error);
      const serverMessage = error.response?.data?.message || error.message;
      throw new Error(serverMessage || 'Failed to authenticate against Cognito.');
    }
  },

  /**
   * Simple user sign up against Cognito User Pool
   */
  signUp: async (username: string, email: string, password: string): Promise<boolean> => {
    const isMockMode = !USER_POOL_ID || !CLIENT_ID;

    if (isMockMode) {
      await new Promise((resolve) => setTimeout(resolve, 800));
      return true;
    }

    try {
      await axios.post(
        COGNITO_ENDPOINT,
        {
          ClientId: CLIENT_ID,
          Username: username,
          Password: password,
          UserAttributes: [
            {
              Name: 'email',
              Value: email,
            },
          ],
        },
        {
          headers: {
            'Content-Type': 'application/x-amz-json-1.1',
            'X-Amz-Target': 'AWSCognitoIdentityProviderService.SignUp',
          },
        }
      );
      return true;
    } catch (error: any) {
      console.error('Cognito SignUp Error:', error);
      const serverMessage = error.response?.data?.message || error.message;
      throw new Error(serverMessage || 'Failed to sign up with AWS Cognito.');
    }
  },

  /**
   * Log out active user session
   */
  logout: () => {
    localStorage.removeItem('cognito_session');
    localStorage.removeItem('id_token');
    localStorage.removeItem('access_token');
  },

  /**
   * Retrieves active user session from local cache
   */
  getCurrentUser: (): CognitoUserSession | null => {
    const cached = localStorage.getItem('cognito_session');
    if (!cached) return null;
    try {
      return JSON.parse(cached);
    } catch {
      return null;
    }
  },

  /**
   * Checks if Cognito is running in live versus demo integration
   */
  isConfigured: (): boolean => {
    return Boolean(USER_POOL_ID && CLIENT_ID);
  },

  getConfigDetails: () => {
    return {
      userPoolId: USER_POOL_ID,
      clientId: CLIENT_ID,
      apiGatewayUrl: import.meta.env.VITE_API_URL || '',
      region: COGNITO_REGION,
    };
  }
};
