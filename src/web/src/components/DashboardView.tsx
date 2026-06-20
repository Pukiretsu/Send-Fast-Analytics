import React, { useMemo, useState } from 'react';
import {
  AlertTriangle,
  CheckCircle,
  Clock,
  LogOut,
  Minus,
  Plus,
  RefreshCw,
  Send,
  ShoppingBag,
  Truck,
  Users,
} from 'lucide-react';
import { CityZone, CognitoUserSession, Order, PaymentMethod } from '../types';
import { cityZones, mockRestaurants, paymentMethods } from '../data/mockData';
import { useOrderController } from '../hooks/useOrderController';

interface DashboardViewProps {
  userSession: CognitoUserSession;
  onLogout: () => void;
}

const cop = new Intl.NumberFormat('es-CO', {
  style: 'currency',
  currency: 'COP',
  maximumFractionDigits: 0,
});

export default function DashboardView({ userSession, onLogout }: DashboardViewProps) {
  const {
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
  } = useOrderController();

  const [ciudadZona, setCiudadZona] = useState<CityZone>('Bogota-Centro');
  const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>('NEQUI');
  const [selectedRestaurantId, setSelectedRestaurantId] = useState(mockRestaurants[0]?.id || '');

  const selectedRestaurant = useMemo(
    () => mockRestaurants.find((restaurant) => restaurant.id === selectedRestaurantId) || null,
    [selectedRestaurantId]
  );

  const handleRestaurantChange = (restaurantId: string) => {
    setSelectedRestaurantId(restaurantId);
    const restaurant = mockRestaurants.find((item) => item.id === restaurantId);
    if (restaurant) selectRestaurant(restaurant);
  };

  const handleOrderSubmission = async (e: React.FormEvent) => {
    e.preventDefault();

    if (selectedRestaurant && activeRestaurant?.id !== selectedRestaurant.id) {
      selectRestaurant(selectedRestaurant);
    }

    await submitOrder(ciudadZona, paymentMethod);
  };

  const getStatusDetails = (status: Order['status']) => {
    switch (status) {
      case 'PENDING':
        return 'Pendiente';
      case 'ACCEPTED':
        return 'Aceptada';
      case 'PREPARING':
        return 'Preparando';
      case 'OUT_FOR_DELIVERY':
        return 'En camino';
      case 'DELIVERED':
        return 'Entregada';
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col font-sans">
      <header className="sticky top-0 z-40 bg-white border-b border-slate-200 py-4 px-6 flex justify-between items-center shadow-sm">
        <div className="flex items-center gap-3">
          <div className="h-11 w-11 bg-indigo-600 rounded-xl flex items-center justify-center">
            <ShoppingBag className="text-white h-5 w-5" />
          </div>
          <div>
            <span className="text-[10px] uppercase tracking-widest font-extrabold text-indigo-600 block">
              SendFast Analytics
            </span>
            <h1 className="text-lg font-extrabold text-slate-800">
              Demo de Ventas de Domicilios
            </h1>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <span className="hidden sm:flex text-xs font-semibold text-slate-700 items-center gap-2 bg-slate-50 border border-slate-200 px-3 py-1.5 rounded-full">
            <Users className="h-4 w-4 text-slate-500" />
            {userSession.email || userSession.username}
          </span>

          <button
            onClick={onLogout}
            className="flex items-center gap-2 bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold px-3 py-2 rounded-full"
          >
            <LogOut className="h-4 w-4" />
            Salir
          </button>
        </div>
      </header>

      <main className="flex-1 w-full max-w-7xl mx-auto px-4 md:px-6 py-6 grid grid-cols-1 lg:grid-cols-12 gap-6">
        <section className="lg:col-span-7 space-y-6">
          <div className="bg-white border border-slate-200 p-5 rounded-2xl shadow-sm">
            <h2 className="text-sm font-extrabold text-slate-800 mb-4">
              1. Selecciona restaurante y productos mock
            </h2>

            <label className="block text-[11px] font-bold uppercase tracking-wider text-slate-500 mb-2">
              Restaurante
            </label>
            <select
              value={selectedRestaurantId}
              onChange={(e) => handleRestaurantChange(e.target.value)}
              className="w-full bg-slate-50 border border-slate-200 rounded-xl py-3 px-3 text-sm font-semibold text-slate-900 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              {mockRestaurants.map((restaurant) => (
                <option key={restaurant.id} value={restaurant.id}>
                  {restaurant.name} - {restaurant.cuisine}
                </option>
              ))}
            </select>
          </div>

          {selectedRestaurant && (
            <div className="space-y-4">
              <div className="bg-white border border-slate-200 p-5 rounded-2xl flex justify-between items-center">
                <div>
                  <p className="text-xs text-indigo-600 font-extrabold uppercase tracking-widest">
                    Menú activo
                  </p>
                  <h3 className="text-lg font-extrabold text-slate-900">
                    {selectedRestaurant.name}
                  </h3>
                  <p className="text-xs text-slate-500 mt-1">
                    Tiempo estimado mock: {selectedRestaurant.deliveryTime}
                  </p>
                </div>
                <div className="text-right text-xs text-slate-500">
                  Domicilio
                  <p className="text-sm font-extrabold text-indigo-600">
                    {cop.format(selectedRestaurant.deliveryFee)}
                  </p>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {selectedRestaurant.products.map((product) => (
                  <div
                    key={product.id}
                    className="bg-white border border-slate-200 p-4 rounded-2xl shadow-sm flex gap-4"
                  >
                    <img
                      src={product.image}
                      alt={product.name}
                      className="h-20 w-20 rounded-xl object-cover bg-slate-100"
                      referrerPolicy="no-referrer"
                    />

                    <div className="flex-1 min-w-0">
                      <div className="flex justify-between gap-2">
                        <h4 className="text-sm font-bold text-slate-900 truncate">
                          {product.name}
                        </h4>
                        <span className="text-xs font-extrabold text-indigo-600">
                          {cop.format(product.price)}
                        </span>
                      </div>

                      <p className="text-xs text-slate-500 line-clamp-2 mt-1">
                        {product.description}
                      </p>

                      <button
                        onClick={() => addToCart(product)}
                        className="mt-3 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg px-3 py-1.5 text-xs font-bold flex items-center gap-1"
                      >
                        <Plus className="h-3.5 w-3.5" />
                        Agregar
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </section>

        <section className="lg:col-span-5 space-y-6">
          <div className="bg-white border border-slate-200 p-5 rounded-3xl shadow-sm">
            <div className="flex justify-between items-center border-b border-slate-100 pb-4 mb-4">
              <div>
                <p className="text-[10px] font-extrabold uppercase tracking-widest text-indigo-600">
                  Payload API Gateway
                </p>
                <h3 className="text-base font-extrabold text-slate-800">
                  Crear venta
                </h3>
              </div>

              {cart.length > 0 && (
                <button onClick={clearCart} className="text-xs text-rose-600 font-bold">
                  Limpiar
                </button>
              )}
            </div>

            {validationError && (
              <div className="bg-rose-50 border border-rose-200 text-rose-700 p-3 rounded-xl flex items-start gap-2 text-xs mb-4">
                <AlertTriangle className="h-4 w-4 shrink-0 mt-0.5" />
                <span>{validationError}</span>
              </div>
            )}

            {successMessage && (
              <div className="bg-emerald-50 border border-emerald-200 text-emerald-800 p-3 rounded-xl flex items-start gap-2 text-xs mb-4">
                <CheckCircle className="h-4 w-4 shrink-0 mt-0.5" />
                <span>{successMessage}</span>
              </div>
            )}

            <form onSubmit={handleOrderSubmission} className="space-y-4">
              <div>
                <label className="block text-[11px] font-bold uppercase tracking-wider text-slate-500 mb-2">
                  Ciudad / Zona
                </label>
                <select
                  value={ciudadZona}
                  onChange={(e) => setCiudadZona(e.target.value as CityZone)}
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl py-3 px-3 text-sm font-semibold text-slate-900 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                >
                  {cityZones.map((zone) => (
                    <option key={zone} value={zone}>
                      {zone}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-[11px] font-bold uppercase tracking-wider text-slate-500 mb-2">
                  Método de pago
                </label>
                <select
                  value={paymentMethod}
                  onChange={(e) => setPaymentMethod(e.target.value as PaymentMethod)}
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl py-3 px-3 text-sm font-semibold text-slate-900 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                >
                  {paymentMethods.map((method) => (
                    <option key={method} value={method}>
                      {method}
                    </option>
                  ))}
                </select>
              </div>

              <div className="space-y-2 max-h-52 overflow-y-auto">
                {cart.length === 0 ? (
                  <div className="text-center py-8 text-slate-400">
                    <ShoppingBag className="h-8 w-8 mx-auto mb-2 text-slate-300" />
                    <p className="text-xs font-bold">No hay productos agregados.</p>
                  </div>
                ) : (
                  cart.map((item) => (
                    <div
                      key={item.product.id}
                      className="flex justify-between items-center bg-slate-50 border border-slate-100 p-3 rounded-xl"
                    >
                      <div>
                        <p className="text-xs font-bold text-slate-900">
                          {item.product.name}
                        </p>
                        <p className="text-[11px] text-slate-500">
                          {cop.format(item.product.price)} x {item.quantity}
                        </p>
                      </div>

                      <div className="flex items-center gap-2">
                        <button
                          type="button"
                          onClick={() => removeFromCart(item.product.id)}
                          className="h-7 w-7 bg-white border border-slate-200 rounded-md flex items-center justify-center"
                        >
                          <Minus className="h-3.5 w-3.5" />
                        </button>
                        <span className="text-xs font-bold w-5 text-center">
                          {item.quantity}
                        </span>
                        <button
                          type="button"
                          onClick={() => addToCart(item.product)}
                          className="h-7 w-7 bg-white border border-slate-200 rounded-md flex items-center justify-center"
                        >
                          <Plus className="h-3.5 w-3.5" />
                        </button>
                      </div>
                    </div>
                  ))
                )}
              </div>

              <div className="bg-slate-50 rounded-xl p-4 space-y-2 border border-slate-100">
                <div className="flex justify-between text-xs text-slate-500">
                  <span>Subtotal:</span>
                  <span className="font-bold text-slate-800">{cop.format(subtotal)}</span>
                </div>
                <div className="flex justify-between text-xs text-slate-500">
                  <span>Domicilio:</span>
                  <span className="font-bold text-slate-800">{cop.format(deliveryFee)}</span>
                </div>
                <div className="flex justify-between text-sm font-extrabold text-indigo-700 border-t border-slate-200 pt-2">
                  <span>Monto enviado:</span>
                  <span>{cop.format(total)}</span>
                </div>
                <p className="text-[10px] text-slate-400">
                  El campo <strong>tiempo_entrega</strong> se genera aleatoriamente entre 15 y 55 minutos.
                </p>
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full bg-indigo-600 text-white rounded-xl py-3.5 font-bold text-sm flex justify-center items-center gap-2 hover:bg-indigo-700 transition disabled:opacity-50"
              >
                {loading ? (
                  <>
                    <RefreshCw className="animate-spin h-4 w-4" />
                    Enviando venta...
                  </>
                ) : (
                  <>
                    <Send className="h-4 w-4" />
                    Enviar JSON con JWT
                  </>
                )}
              </button>
            </form>

            {lastPayload && (
              <div className="mt-4">
                <p className="text-[10px] font-extrabold uppercase tracking-widest text-slate-500 mb-2">
                  Último JSON enviado
                </p>
                <pre className="bg-slate-900 text-emerald-300 text-[11px] rounded-xl p-4 overflow-auto">
                  {JSON.stringify(lastPayload, null, 2)}
                </pre>
              </div>
            )}
          </div>

          <div className="bg-white border border-slate-200 p-5 rounded-3xl shadow-sm">
            <h3 className="text-sm font-extrabold text-slate-800 mb-4 flex justify-between">
              <span>Ventas enviadas</span>
              <span className="text-xs bg-slate-100 px-2 py-0.5 rounded-full">
                {orders.length}
              </span>
            </h3>

            {orders.length === 0 ? (
              <div className="text-center py-6 text-slate-400">
                <Truck className="h-8 w-8 text-slate-300 mx-auto mb-2" />
                <p className="text-xs font-bold">Aún no hay ventas enviadas.</p>
              </div>
            ) : (
              <div className="space-y-3 max-h-72 overflow-y-auto">
                {orders.map((order) => (
                  <div key={order.id} className="border border-slate-100 p-4 rounded-2xl bg-slate-50">
                    <div className="flex justify-between gap-2">
                      <div>
                        <p className="text-[10px] font-mono font-bold text-slate-500">
                          {order.orderId}
                        </p>
                        <h4 className="text-xs font-bold text-slate-900">
                          {order.restaurantName}
                        </h4>
                      </div>
                      <span className="text-[10px] bg-indigo-100 text-indigo-700 font-bold px-2 py-1 rounded-full h-fit">
                        {getStatusDetails(order.status)}
                      </span>
                    </div>

                    <div className="mt-2 text-[11px] text-slate-500 space-y-1">
                      <p>Zona: {order.ciudad_zona}</p>
                      <p>Pago: {order.metodo_pago}</p>
                      <p>Tiempo entrega: {order.tiempo_entrega} min</p>
                      <p className="font-bold text-slate-800">Monto: {cop.format(order.monto)}</p>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </section>
      </main>
    </div>
  );
}
