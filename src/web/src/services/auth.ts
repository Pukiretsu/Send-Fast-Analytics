import axios from 'axios';
import { CognitoUserSession } from '../types';

const USER_POOL_ID = import.meta.env.VITE_USER_POOL_ID || '';
const CLIENT_ID = import.meta.env.VITE_CLIENT_ID || '';
const API_GATEWAY_URL = import.meta.env.VITE_API_URL || '';

const getCognitoRegion = (poolId: string) => {
  if (!poolId || !poolId.includes('_')) return 'us-east-1';
  return poolId.split('_')[0];
};

const COGNITO_REGION = getCognitoRegion(USER_POOL_ID);
const COGNITO_ENDPOINT = `https://cognito-idp.${COGNITO_REGION}.amazonaws.com/`;

export const authService = {
  login: async (username: string, password: string): Promise<CognitoUserSession> => {
    const isMockMode = !USER_POOL_ID || !CLIENT_ID;

    if (isMockMode) {
      await new Promise((resolve) => setTimeout(resolve, 800));

      if (username && password.length >= 6) {
        const mockSession: CognitoUserSession = {
          username,
          idToken: 'mock_id_token_' + crypto.randomUUID(),
          accessToken: 'mock_access_token_' + crypto.randomUUID(),
          refreshToken: 'mock_refresh_token_' + crypto.randomUUID(),
          email: username.includes('@') ? username : `${username}@example.com`,
        };

        localStorage.setItem('cognito_session', JSON.stringify(mockSession));
        localStorage.setItem('id_token', mockSession.idToken);
        localStorage.setItem('access_token', mockSession.accessToken);

        return mockSession;
      }

      throw new Error('Password must be at least 6 characters.');
    }

    try {
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
        throw new Error('Invalid Cognito authentication response.');
      }

      const session: CognitoUserSession = {
        username,
        idToken: authResult.IdToken,
        accessToken: authResult.AccessToken,
        refreshToken: authResult.RefreshToken,
        email: username,
      };

      localStorage.setItem('cognito_session', JSON.stringify(session));
      localStorage.setItem('id_token', session.idToken);
      localStorage.setItem('access_token', session.accessToken);

      return session;
    } catch (error: any) {
      const serverMessage = error.response?.data?.message || error.message;
      throw new Error(serverMessage || 'Failed to authenticate against Cognito.');
    }
  },

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
      const serverMessage = error.response?.data?.message || error.message;
      throw new Error(serverMessage || 'Failed to sign up with AWS Cognito.');
    }
  },

  logout: () => {
    localStorage.removeItem('cognito_session');
    localStorage.removeItem('id_token');
    localStorage.removeItem('access_token');
  },

  getCurrentUser: (): CognitoUserSession | null => {
    const cached = localStorage.getItem('cognito_session');
    if (!cached) return null;

    try {
      return JSON.parse(cached);
    } catch {
      return null;
    }
  },

  isConfigured: (): boolean => Boolean(USER_POOL_ID && CLIENT_ID),

  getConfigDetails: () => ({
    userPoolId: USER_POOL_ID,
    clientId: CLIENT_ID,
    apiGatewayUrl: API_GATEWAY_URL,
    region: COGNITO_REGION,
  }),
};
