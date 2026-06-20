import { useCallback, useEffect, useState } from 'react';
import {
  CartItem,
  CityZone,
  Order,
  PaymentMethod,
  Product,
  Restaurant,
  SendFastOrderPayload,
} from '../types';
import { apiGatewayService } from '../services/api';

const randomDeliveryTime = () => Math.floor(Math.random() * (55 - 15 + 1)) + 15;

export function useOrderController() {
  const [activeRestaurant, setActiveRestaurant] = useState<Restaurant | null>(null);
  const [cart, setCart] = useState<CartItem[]>([]);
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(false);
  const [validationError, setValidationError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [lastPayload, setLastPayload] = useState<SendFastOrderPayload | null>(null);

  useEffect(() => {
    const savedOrders = localStorage.getItem('submitted_orders');
    if (savedOrders) {
      try {
        setOrders(JSON.parse(savedOrders));
      } catch {
        localStorage.removeItem('submitted_orders');
      }
    }
  }, []);

  const persistOrders = useCallback((updatedOrders: Order[]) => {
    setOrders(updatedOrders);
    localStorage.setItem('submitted_orders', JSON.stringify(updatedOrders));
  }, []);

  useEffect(() => {
    const activeInterval = setInterval(() => {
      let changed = false;

      const updated = orders.map((order) => {
        if (order.status === 'DELIVERED') return order;

        changed = true;

        let nextStatus = order.status;
        if (order.status === 'PENDING') nextStatus = 'ACCEPTED';
        else if (order.status === 'ACCEPTED') nextStatus = 'PREPARING';
        else if (order.status === 'PREPARING') nextStatus = 'OUT_FOR_DELIVERY';
        else if (order.status === 'OUT_FOR_DELIVERY') nextStatus = 'DELIVERED';

        return { ...order, status: nextStatus };
      });

      if (changed) {
        persistOrders(updated);
      }
    }, 15000);

    return () => clearInterval(activeInterval);
  }, [orders, persistOrders]);

  const selectRestaurant = useCallback(
    (restaurant: Restaurant) => {
      setValidationError(null);
      setSuccessMessage(null);

      if (activeRestaurant && activeRestaurant.id !== restaurant.id && cart.length > 0) {
        setCart([]);
      }

      setActiveRestaurant(restaurant);
    },
    [activeRestaurant, cart]
  );

  const addToCart = useCallback((product: Product) => {
    setValidationError(null);
    setSuccessMessage(null);

    setCart((prevCart) => {
      const matchIndex = prevCart.findIndex((item) => item.product.id === product.id);

      if (matchIndex > -1) {
        const nextCart = [...prevCart];
        nextCart[matchIndex] = {
          ...nextCart[matchIndex],
          quantity: nextCart[matchIndex].quantity + 1,
        };
        return nextCart;
      }

      return [...prevCart, { product, quantity: 1 }];
    });
  }, []);

  const removeFromCart = useCallback((productId: string) => {
    setValidationError(null);

    setCart((prevCart) => {
      const matchIndex = prevCart.findIndex((item) => item.product.id === productId);
      if (matchIndex === -1) return prevCart;

      const nextCart = [...prevCart];

      if (nextCart[matchIndex].quantity > 1) {
        nextCart[matchIndex] = {
          ...nextCart[matchIndex],
          quantity: nextCart[matchIndex].quantity - 1,
        };
        return nextCart;
      }

      return nextCart.filter((item) => item.product.id !== productId);
    });
  }, []);

  const clearCart = useCallback(() => {
    setCart([]);
    setValidationError(null);
  }, []);

  const subtotal = cart.reduce((sum, item) => sum + item.product.price * item.quantity, 0);
  const deliveryFee = activeRestaurant ? activeRestaurant.deliveryFee : 0;
  const total = subtotal > 0 ? subtotal + deliveryFee : 0;

  const submitOrder = async (
    ciudadZona: CityZone,
    paymentMethod: PaymentMethod
  ): Promise<Order | null> => {
    setValidationError(null);
    setSuccessMessage(null);

    if (!activeRestaurant) {
      setValidationError('Selecciona un restaurante para continuar.');
      return null;
    }

    if (cart.length === 0) {
      setValidationError('El carrito está vacío. Agrega productos para generar la venta.');
      return null;
    }

    const nowIso = new Date().toISOString();
    const orderId = crypto.randomUUID();
    const tiempoEntrega = randomDeliveryTime();

    const payload: SendFastOrderPayload = {
      orderId,
      timestamp: nowIso,
      ciudad_zona: ciudadZona,
      estado_pedido: 'ENTREGADO',
      monto: Number(total.toFixed(0)),
      tiempo_entrega: tiempoEntrega,
      metodo_pago: paymentMethod,
    };

    setLoading(true);
    setLastPayload(payload);

    try {
      await apiGatewayService.createDeliveryOrder(payload);

      const resultOrder: Order = {
        id: orderId,
        orderId,
        ciudad_zona: ciudadZona,
        metodo_pago: paymentMethod,
        monto: payload.monto,
        tiempo_entrega: tiempoEntrega,
        status: 'PENDING',
        createdAt: nowIso,
        restaurantName: activeRestaurant.name,
        items: cart.map((item) => ({
          productId: item.product.id,
          productName: item.product.name,
          price: item.product.price,
          quantity: item.quantity,
        })),
      };

      persistOrders([resultOrder, ...orders]);
      setCart([]);
      setSuccessMessage(`Venta enviada correctamente. OrderId: ${orderId}`);
      return resultOrder;
    } catch (err: any) {
      setValidationError(
        err.response?.data?.error ||
          err.message ||
          'No fue posible enviar la venta al API Gateway.'
      );
      return null;
    } finally {
      setLoading(false);
    }
  };

  return {
    cart,
    activeRestaurant,
    orders,
    loading,
    validationError,
    successMessage,
    subtotal,
    deliveryFee,
    total,
    lastPayload,
    selectRestaurant,
    addToCart,
    removeFromCart,
    clearCart,
    submitOrder,
  };
}
