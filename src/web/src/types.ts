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

export interface Order {
  id: string;
  restaurantId: string;
  restaurantName: string;
  items: {
    productId: string;
    productName: string;
    price: number;
    quantity: number;
  }[];
  subtotal: number;
  deliveryFee: number;
  tax: number;
  total: number;
  status: 'PENDING' | 'ACCEPTED' | 'PREPARING' | 'OUT_FOR_DELIVERY' | 'DELIVERED';
  createdAt: string;
}

export interface CognitoUserSession {
  username: string;
  idToken: string;
  accessToken: string;
  refreshToken?: string;
  email?: string;
}
