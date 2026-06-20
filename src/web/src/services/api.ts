import axios from 'axios';
import { ApiIngestaResponse, SendFastOrderPayload } from '../types';

const API_GATEWAY_URL = import.meta.env.VITE_API_URL || '';

export const apiInstance = axios.create({
  baseURL: API_GATEWAY_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

apiInstance.interceptors.request.use(
  (config) => {
    const idToken = localStorage.getItem('id_token');

    if (idToken) {
      config.headers.Authorization = `Bearer ${idToken}`;
    }

    return config;
  },
  (error) => Promise.reject(error)
);

export const apiGatewayService = {
  createDeliveryOrder: async (payload: SendFastOrderPayload): Promise<ApiIngestaResponse> => {
    if (!API_GATEWAY_URL) {
      throw new Error('VITE_API_URL no está configurada. Ejecuta Terraform y genera .env.production desde los outputs.');
    }

    const response = await apiInstance.post('', payload);
    return response.data as ApiIngestaResponse;
  },
};
