import { useState, useEffect, useCallback } from 'react';
import { CartItem, Restaurant, Order, Product } from '../types';
import { apiGatewayService } from '../services/api';

export function useOrderController() {
  const [activeRestaurant, setActiveRestaurant] = useState<Restaurant | null>(null);
  const [cart, setCart] = useState<CartItem[]>([]);
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(false);
  const [validationError, setValidationError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  // Initialize order list from localStorage if user is returning
  useEffect(() => {
    const savedOrders = localStorage.getItem('submitted_orders');
    if (savedOrders) {
      try {
        setOrders(JSON.parse(savedOrders));
      } catch {
        // Safe bypass
      }
    }
  }, []);

  // Persist orders to localStorage as backup
  const persistOrders = useCallback((updatedOrders: Order[]) => {
    setOrders(updatedOrders);
    localStorage.setItem('submitted_orders', JSON.stringify(updatedOrders));
  }, []);

  /**
   * Status transitions simulation to demonstrate MVC reactivity
   */
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
    }, 15000); // Transitions status every 15 seconds for realistic simulation

    return () => clearInterval(activeInterval);
  }, [orders, persistOrders]);

  /**
   * Restaurant selection controls
   * If user switches restaurants, warn them/clear their current cart
   */
  const selectRestaurant = useCallback((restaurant: Restaurant) => {
    setValidationError(null);
    setSuccessMessage(null);
    if (activeRestaurant && activeRestaurant.id !== restaurant.id && cart.length > 0) {
      // In a real app we might ask. We'll elegantly transition the restaurant & clear state.
      setCart([]);
    }
    setActiveRestaurant(restaurant);
  }, [activeRestaurant, cart]);

  /**
   * Add a single product unit to Cart
   */
  const addToCart = useCallback((product: Product, restaurantId: string, restaurantName: string) => {
    setValidationError(null);
    setSuccessMessage(null);
    
    // Ensure we are operating with the active restaurant corresponding to this selection
    if (activeRestaurant && activeRestaurant.id !== restaurantId) {
      // Automatic protection logic
      setCart([{ product, quantity: 1 }]);
      return;
    }

    setCart((prevCart) => {
      const matchIndex = prevCart.findIndex((item) => item.product.id === product.id);
      if (matchIndex > -1) {
        const nextCart = [...prevCart];
        nextCart[matchIndex] = {
          ...nextCart[matchIndex],
          quantity: nextCart[matchIndex].quantity + 1,
        };
        return nextCart;
      } else {
        return [...prevCart, { product, quantity: 1 }];
      }
    });
  }, [activeRestaurant]);

  /**
   * Remove or decrement quantity
   */
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
      } else {
        return nextCart.filter((item) => item.product.id !== productId);
      }
    });
  }, []);

  /**
   * Explicitly set specific cart quantities
   */
  const updateQuantity = useCallback((productId: string, quantity: number) => {
    setValidationError(null);
    if (quantity <= 0) {
      setCart((prev) => prev.filter((item) => item.product.id !== productId));
      return;
    }
    setCart((prev) =>
      prev.map((item) => (item.product.id === productId ? { ...item, quantity } : item))
    );
  }, []);

  const clearCart = useCallback(() => {
    setCart([]);
    setValidationError(null);
  }, []);

  /**
   * Computation calculations
   */
  const subtotal = cart.reduce((sum, item) => sum + item.product.price * item.quantity, 0);
  const deliveryFee = activeRestaurant ? activeRestaurant.deliveryFee : 0;
  const tax = subtotal * 0.0825; // 8.25% standard sales tax
  const total = subtotal > 0 ? subtotal + deliveryFee + tax : 0;

  /**
   * Processes Order Form submission and relays request to the model database.
   */
  const submitOrder = async (
    deliveryAddress: string,
    additionalInstructions: string = '',
    paymentMethod: string = 'CARD'
  ): Promise<Order | null> => {
    setValidationError(null);
    setSuccessMessage(null);

    // Dynamic validations
    if (!activeRestaurant) {
      setValidationError('Please select a restaurant to complete your order.');
      return null;
    }
    if (cart.length === 0) {
      setValidationError('Your shopping cart is empty. Please add items to order.');
      return null;
    }
    if (!deliveryAddress.trim()) {
      setValidationError('Delivery address is a required field.');
      return null;
    }

    setLoading(true);
    try {
      const orderPayload = {
        restaurantId: activeRestaurant.id,
        restaurantName: activeRestaurant.name,
        items: cart.map((item) => ({
          productId: item.product.id,
          productName: item.product.name,
          price: item.product.price,
          quantity: item.quantity,
        })),
        subtotal: Number(subtotal.toFixed(2)),
        deliveryFee: Number(deliveryFee.toFixed(2)),
        tax: Number(tax.toFixed(2)),
        total: Number(total.toFixed(2)),
      };

      // Communicate directly with the model gateway API
      const resultOrder = await apiGatewayService.createOrder(orderPayload);
      
      // Update local storage and view cache
      const freshOrdersList = [resultOrder, ...orders];
      persistOrders(freshOrdersList);

      // Empties transaction buffer
      setCart([]);
      setSuccessMessage(`Order #${resultOrder.id.replace('ord_', '')} placed successfully! Standard delivery in ${activeRestaurant.deliveryTime}.`);
      return resultOrder;
    } catch (err: any) {
      setValidationError(err.message || 'System encountered an unexpected error processing your order.');
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
    tax,
    total,
    selectRestaurant,
    addToCart,
    removeFromCart,
    updateQuantity,
    clearCart,
    submitOrder,
  };
}
