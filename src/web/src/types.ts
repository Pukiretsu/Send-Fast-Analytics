export type PaymentMethod =
  | 'EFECTIVO'
  | 'NEQUI'
  | 'PSE'
  | 'TARJETA_CREDITO'
  | 'TARJETA_DEBITO'
  | 'DAVIPLATA'
  | 'TRANSFERENCIA'
  | 'BANCOLOMBIA';

export type CityZone =
  | 'Bogota-Norte'
  | 'Bogota-Centro'
  | 'Bogota-Sur'
  | 'Bogota-Occidente'
  | 'Bogota-Chapinero'
  | 'Bogota-Suba'
  | 'Medellin-ElPoblado'
  | 'Medellin-Laureles'
  | 'Cali-Norte'
  | 'Cali-Sur'
  | 'Barranquilla-Norte';

export interface Product {
  id: string;
  name: string;
  description: string;
  price: number;
  image: string;
  category: string;
}

export interface Restaurant {
  id: string;
  name: string;
  description: string;
  cuisine: string;
  rating: number;
  deliveryTime: string;
  deliveryFee: number;
  image: string;
  products: Product[];
}

export interface CartItem {
  product: Product;
  quantity: number;
}

export interface SendFastOrderPayload {
  orderId: string;
  timestamp: string;
  ciudad_zona: CityZone;
  estado_pedido: 'ENTREGADO' | 'PENDIENTE' | 'EN_PREPARACION' | 'EN_CAMINO' | 'CANCELADO';
  monto: number;
  tiempo_entrega: number;
  metodo_pago: PaymentMethod;
}

export interface ApiIngestaResponse {
  message?: string;
  orderId?: string;
  s3_key?: string;
  error?: string;
}

export interface Order {
  id: string;
  orderId: string;
  ciudad_zona: CityZone;
  metodo_pago: PaymentMethod;
  monto: number;
  tiempo_entrega: number;
  status: 'PENDING' | 'ACCEPTED' | 'PREPARING' | 'OUT_FOR_DELIVERY' | 'DELIVERED';
  createdAt: string;
  restaurantName: string;
  items: {
    productId: string;
    productName: string;
    price: number;
    quantity: number;
  }[];
}

export interface CognitoUserSession {
  username: string;
  idToken: string;
  accessToken: string;
  refreshToken?: string;
  email?: string;
}
