import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { 
  Users, LogOut, Search, MapPin, Clock, Star, 
  Plus, Minus, ShoppingBag, Send, Notebook, 
  CheckCircle, Truck, Utensils, AlertTriangle, RefreshCw
} from 'lucide-react';
import { Restaurant, Product, CognitoUserSession, Order } from '../types';
import { mockRestaurants } from '../data/mockData';
import { useOrderController } from '../hooks/useOrderController';
import { authService } from '../services/auth';

interface DashboardViewProps {
  userSession: CognitoUserSession;
  onLogout: () => void;
}

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
    tax,
    total,
    selectRestaurant,
    addToCart,
    removeFromCart,
    updateQuantity,
    clearCart,
    submitOrder,
  } = useOrderController();

  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCuisine, setSelectedCuisine] = useState<string | null>(null);
  const [deliveryAddress, setDeliveryAddress] = useState('');
  const [specialInstructions, setSpecialInstructions] = useState('');

  // Extract unique cuisines
  const cuisines = ['All', 'Italian', 'Pizza', 'Burgers', 'American', 'Japanese', 'Sushi'];

  // Filter restaurants
  const filteredRestaurants = mockRestaurants.filter((rest) => {
    const matchesSearch = rest.name.toLowerCase().includes(searchQuery.toLowerCase()) || 
                          rest.cuisine.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesCuisine = !selectedCuisine || selectedCuisine === 'All' || 
                           rest.cuisine.toLowerCase().includes(selectedCuisine.toLowerCase());
    return matchesSearch && matchesCuisine;
  });

  const handleOrderSubmission = async (e: React.FormEvent) => {
    e.preventDefault();
    const result = await submitOrder(deliveryAddress, specialInstructions);
    if (result) {
      setDeliveryAddress('');
      setSpecialInstructions('');
    }
  };

  // Status mapping to color styles
  const getStatusDetails = (status: Order['status']) => {
    switch (status) {
      case 'PENDING':
        return { text: 'Pending Confirmation', bg: 'bg-amber-100 text-amber-800', border: 'border-amber-300', dot: 'bg-amber-500' };
      case 'ACCEPTED':
        return { text: 'Order Accepted', bg: 'bg-blue-100 text-blue-800', border: 'border-blue-300', dot: 'bg-blue-500' };
      case 'PREPARING':
        return { text: 'Food Preparing', bg: 'bg-indigo-100 text-indigo-800', border: 'border-indigo-300', dot: 'bg-indigo-500' };
      case 'OUT_FOR_DELIVERY':
        return { text: 'Out for Delivery', bg: 'bg-purple-100 text-purple-800', border: 'border-purple-300', dot: 'bg-purple-500' };
      case 'DELIVERED':
        return { text: 'Delivered', bg: 'bg-emerald-100 text-emerald-800', border: 'border-emerald-300', dot: 'bg-emerald-500' };
    }
  };

  const getStatusPercentage = (status: Order['status']) => {
    switch (status) {
      case 'PENDING': return 15;
      case 'ACCEPTED': return 40;
      case 'PREPARING': return 65;
      case 'OUT_FOR_DELIVERY': return 88;
      case 'DELIVERED': return 100;
    }
  };

  return (
    <div id="dashboard-layout" className="min-h-screen bg-slate-50/50 flex flex-col font-sans">
      
      {/* 1. Header Area */}
      <header className="sticky top-0 z-40 bg-white/95 backdrop-blur-md border-b border-slate-200/80 py-3.5 px-6 flex justify-between items-center shadow-xs">
        <div className="flex items-center gap-2.5">
          <div className="h-10 w-10 bg-indigo-600 rounded-xl flex items-center justify-center shadow-lg shadow-indigo-100/60">
            <ShoppingBag className="text-white h-5 w-5" />
          </div>
          <div>
            <span className="text-[10px] uppercase tracking-widest font-extrabold text-indigo-600 block">S3 STATIC SECURE</span>
            <h1 className="text-lg font-extrabold text-slate-800 tracking-tight">FeastFlow<span className="text-indigo-600">Dash</span></h1>
          </div>
        </div>

        {/* User Badge - Cognitor Profile and Logout */}
        <div className="flex items-center gap-3.5">
          <div className="hidden sm:flex flex-col items-end text-right">
            <span className="text-xs font-semibold text-slate-800 flex items-center gap-1.5 bg-slate-50 border border-slate-100 px-3 py-1 rounded-full">
              <Users className="h-3.5 w-3.5 text-slate-500" />
              {userSession.email || userSession.username}
            </span>
          </div>
          
          <button
            id="logout-button"
            onClick={onLogout}
            className="flex items-center gap-1.5 bg-slate-50 hover:bg-slate-100 text-slate-700 hover:text-slate-900 text-xs font-medium px-3.5 py-1.5 rounded-full border border-slate-200/60 transition-all cursor-pointer"
            title="Log out of Secure Session"
          >
            <LogOut className="h-4 w-4" />
            <span className="hidden xs:inline">Sign Out</span>
          </button>
        </div>
      </header>

      {/* 2. Main Content Grid */}
      <main className="flex-1 w-full max-w-[1400px] mx-auto px-4 md:px-6 py-6 grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        
        {/* Left Side: Store Finder & Menus (Spans 7 columns on large build) */}
        <div className="lg:col-span-7 flex flex-col gap-6">
          
          {/* Search, Filter Section */}
          <div className="bg-white border border-slate-100 p-5 rounded-2xl shadow-xs">
            <div className="flex flex-col md:flex-row gap-3.5 mb-4Item">
              <div className="relative flex-1">
                <Search className="absolute left-3.5 top-3.5 h-4 w-4 text-slate-400" />
                <input
                  type="text"
                  placeholder="Query restaurants or favorite food pairings..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl py-3 pl-11 pr-4 text-xs font-semibold text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition"
                />
              </div>

              {/* Reset filter button */}
              {(searchQuery || selectedCuisine) && (
                <button
                  onClick={() => {
                    setSearchQuery('');
                    setSelectedCuisine(null);
                  }}
                  className="px-4 py-2.5 bg-slate-100 rounded-xl text-xs font-semibold text-slate-500 hover:bg-slate-200 transition-colors cursor-pointer"
                >
                  Clear Filters
                </button>
              )}
            </div>

            {/* Quick Cuisine Filters */}
            <div className="flex flex-wrap gap-2 mt-4.5">
              {cuisines.map((cuisine) => (
                <button
                  key={cuisine}
                  onClick={() => setSelectedCuisine(cuisine === 'All' ? null : cuisine)}
                  className={`px-3.5 py-1.5 rounded-xl text-xs font-bold transition cursor-pointer ${
                    (cuisine === 'All' && !selectedCuisine) || selectedCuisine === cuisine
                      ? 'bg-indigo-600 text-white shadow-md shadow-indigo-100'
                      : 'bg-slate-50 text-slate-600 border border-slate-200/50 hover:bg-slate-100'
                  }`}
                >
                  {cuisine}
                </button>
              ))}
            </div>
          </div>

          {/* Restaurant Selector Row */}
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <h2 className="text-sm font-extrabold uppercase tracking-widest text-slate-400">Available Partners</h2>
              <span className="text-xs text-slate-500 font-semibold">{filteredRestaurants.length} active stores</span>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
              {filteredRestaurants.map((restaurant) => {
                const isSelected = activeRestaurant?.id === restaurant.id;
                return (
                  <motion.div
                    key={restaurant.id}
                    onClick={() => selectRestaurant(restaurant)}
                    whileHover={{ y: -3, scale: 1.01 }}
                    className={`bg-white border rounded-2xl overflow-hidden shadow-xs cursor-pointer transition-all flex flex-col h-full ${
                      isSelected ? 'ring-2 ring-indigo-500 border-transparent shadow-md' : 'border-slate-100 hover:border-slate-300'
                    }`}
                  >
                    <div className="relative h-28 w-full bg-slate-100">
                      <img 
                        src={restaurant.image} 
                        alt={restaurant.name} 
                        referrerPolicy="no-referrer"
                        className="w-full h-full object-cover"
                      />
                      <div className="absolute top-2.5 right-2.5 bg-white px-2 py-0.5 rounded-md text-[10px] font-bold text-slate-800 flex items-center gap-0.5 shadow-sm">
                        <Star className="h-3 w-3 text-amber-500 fill-amber-500" />
                        {restaurant.rating}
                      </div>
                    </div>
                    
                    <div className="p-4 flex-1 flex flex-col justify-between">
                      <div>
                        <h3 className="text-xs font-bold text-slate-900 mb-1 leading-snug line-clamp-1">{restaurant.name}</h3>
                        <p className="text-[10px] text-slate-400 font-medium mb-2.5">{restaurant.cuisine}</p>
                        <p className="text-[10px] text-slate-500 line-clamp-2 leading-relaxed mb-3">{restaurant.description}</p>
                      </div>

                      <div className="flex items-center justify-between text-[10px] font-semibold text-slate-600 border-t border-slate-50 pt-2.5 mt-auto">
                        <span className="flex items-center gap-1"><Clock className="h-3 w-3 text-indigo-600" /> {restaurant.deliveryTime}</span>
                        <span className="text-slate-800">Fee: ${restaurant.deliveryFee.toFixed(2)}</span>
                      </div>
                    </div>
                  </motion.div>
                );
              })}
            </div>
          </div>

          {/* Connected Menu Display (Triggers on select) */}
          {activeRestaurant ? (
            <div className="space-y-4">
              <div className="flex items-center justify-between bg-white border border-slate-100 p-4 rounded-xl">
                <div>
                  <span className="text-[9px] uppercase tracking-widest font-extrabold text-indigo-600">Active Menu</span>
                  <p className="text-sm font-extrabold text-slate-900">{activeRestaurant.name}</p>
                </div>
                <div className="text-right">
                  <span className="text-[10px] text-slate-400 block font-semibold">Standard Delivery</span>
                  <span className="text-xs font-bold text-indigo-600">{activeRestaurant.deliveryTime}</span>
                </div>
              </div>

              {/* Products Grid */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {activeRestaurant.products.map((product) => {
                  return (
                    <motion.div
                      key={product.id}
                      initial={{ opacity: 0, scale: 0.98 }}
                      animate={{ opacity: 1, scale: 1 }}
                      className="bg-white border border-slate-100 p-4 rounded-2xl shadow-xs hover:border-indigo-200/80 transition-colors flex gap-4"
                    >
                      <div className="h-20 w-20 bg-slate-50 border border-slate-105 rounded-xl overflow-hidden shrink-0">
                        <img 
                          src={product.image} 
                          alt={product.name} 
                          referrerPolicy="no-referrer"
                          className="w-full h-full object-cover"
                        />
                      </div>

                      <div className="flex-1 flex flex-col justify-between min-w-0">
                        <div>
                          <div className="flex justify-between items-start gap-1">
                            <h4 className="text-xs font-bold text-slate-900 truncate">{product.name}</h4>
                            <span className="text-xs font-extrabold text-indigo-600 shrink-0">${product.price.toFixed(2)}</span>
                          </div>
                          <p className="text-[10px] text-slate-400 line-clamp-2 mt-1 leading-relaxed">
                            {product.description}
                          </p>
                        </div>

                        <div className="flex justify-between items-center mt-3">
                          <span className="bg-slate-50 border border-slate-100 text-[9px] text-slate-500 px-2 py-0.5 rounded-md font-semibold">
                            {product.category}
                          </span>

                          <button
                            onClick={() => addToCart(product, activeRestaurant.id, activeRestaurant.name)}
                            className="bg-indigo-600 text-white rounded-lg p-1 px-2.5 text-xs font-bold flex items-center gap-1 select-none hover:bg-indigo-700 transition cursor-pointer shadow-xs shadow-indigo-100"
                          >
                            <Plus className="h-3 w-3" /> Add To Order
                          </button>
                        </div>
                      </div>
                    </motion.div>
                  );
                })}
              </div>
            </div>
          ) : (
            <div className="bg-white border border-dashed border-slate-200 p-12 text-center rounded-2xl flex flex-col items-center justify-center">
              <div className="h-12 w-12 rounded-full bg-slate-50 flex items-center justify-center mb-3">
                <Utensils className="h-6 w-6 text-slate-400" />
              </div>
              <p className="text-sm font-bold text-slate-700">No Restaurant Selected</p>
              <p className="text-xs text-slate-400 max-w-sm mt-1 leading-relaxed">
                Click on any of the active partner stores above to load their real-time menu and begin configuring your delivery draft.
              </p>
            </div>
          )}

        </div>

        {/* Right Side: Interactive 'Create Order' Form & Cart (Spans 5 columns) */}
        <div className="lg:col-span-5 flex flex-col gap-6">

          {/* Create Order Form */}
          <div className="bg-white border border-slate-200/80 p-5 rounded-3xl shadow-xs flex flex-col">
            <div className="flex justify-between items-center border-b border-slate-150 pb-3 mb-4">
              <div className="flex items-center gap-2">
                <ShoppingBag className="h-4.5 w-4.5 text-indigo-600" />
                <h3 className="text-sm font-extrabold text-slate-800">Create Order</h3>
              </div>
              {cart.length > 0 && (
                <button
                  onClick={clearCart}
                  className="text-[10px] text-rose-500 font-bold hover:underline bg-transparent border-0 cursor-pointer"
                >
                  Clear All
                </button>
              )}
            </div>

            {/* Validation & Success feedbacks */}
            {validationError && (
              <div className="bg-rose-50 border border-rose-150 text-rose-700 p-3 rounded-xl flex items-start gap-2.5 text-[11px] mb-4">
                <AlertTriangle className="h-4 w-4 shrink-0 mt-0.5" />
                <span>{validationError}</span>
              </div>
            )}

            {successMessage && (
              <div className="bg-emerald-50 border border-emerald-150 text-emerald-800 p-3 rounded-xl flex items-start gap-2.5 text-[11px] mb-4">
                <CheckCircle className="h-4 w-4 shrink-0 mt-0.5" />
                <span>{successMessage}</span>
              </div>
            )}

            {/* Sub-item configuration list */}
            {cart.length > 0 ? (
              <div className="space-y-4">
                
                {/* Selected items wrapper */}
                <div className="space-y-2 max-h-56 overflow-y-auto pr-1">
                  <AnimatePresence>
                    {cart.map((item) => (
                      <motion.div
                        key={item.product.id}
                        layout
                        initial={{ opacity: 0, x: -10 }}
                        animate={{ opacity: 1, x: 0 }}
                        exit={{ opacity: 0, x: 10 }}
                        className="flex justify-between items-center bg-slate-50 border border-slate-100 p-2.5 rounded-xl"
                      >
                        <div className="min-w-0 pr-2">
                          <p className="text-xs font-bold text-slate-900 truncate">{item.product.name}</p>
                          <span className="text-[10px] font-medium text-slate-500">${item.product.price.toFixed(2)} each</span>
                        </div>

                        {/* Adjust quantities */}
                        <div className="flex items-center gap-2 shrink-0">
                          <button
                            onClick={() => removeFromCart(item.product.id)}
                            className="h-6 w-6 bg-white border border-slate-200 text-slate-600 rounded-md flex items-center justify-center hover:bg-slate-100 transition text-xs cursor-pointer"
                          >
                            <Minus className="h-3.5 w-3.5" />
                          </button>
                          <span className="text-xs font-bold text-slate-800 px-1 w-4 text-center">{item.quantity}</span>
                          <button
                            onClick={() => addToCart(item.product, activeRestaurant!.id, activeRestaurant!.name)}
                            className="h-6 w-6 bg-white border border-slate-200 text-slate-600 rounded-md flex items-center justify-center hover:bg-slate-100 transition text-xs cursor-pointer"
                          >
                            <Plus className="h-3.5 w-3.5" />
                          </button>
                        </div>
                      </motion.div>
                    ))}
                  </AnimatePresence>
                </div>

                {/* Form fields for actual execution (Address and Instructions) */}
                <form onSubmit={handleOrderSubmission} className="space-y-4 pt-2.5 border-t border-slate-100">
                  <div>
                    <label className="block text-[10px] font-bold uppercase tracking-wider text-slate-500 mb-1.5" htmlFor="address">
                      Delivery Address
                    </label>
                    <div className="relative">
                      <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                        <MapPin className="h-4 w-4 text-slate-400" />
                      </div>
                      <input
                        id="address"
                        type="text"
                        required
                        placeholder="123 Operational Lane, Cloud Run Floor"
                        value={deliveryAddress}
                        onChange={(e) => setDeliveryAddress(e.target.value)}
                        className="block w-full pl-9 pr-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 text-xs focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-[10px] font-bold uppercase tracking-wider text-slate-500 mb-1.5" htmlFor="instructions">
                      Special Courier Instructions (Optional)
                    </label>
                    <div className="relative">
                      <div className="absolute inset-y-0 left-0 pl-3 pt-2.5 pointer-events-none">
                        <Notebook className="h-4 w-4 text-slate-400" />
                      </div>
                      <textarea
                        id="instructions"
                        rows={2}
                        placeholder="Ring buzzer #4, leave at third shelf desk..."
                        value={specialInstructions}
                        onChange={(e) => setSpecialInstructions(e.target.value)}
                        className="block w-full pl-9 pr-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 text-xs focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition resize-none"
                      />
                    </div>
                  </div>

                  {/* Summary math table */}
                  <div className="bg-slate-50 rounded-xl p-3.5 space-y-2 border border-slate-100 font-medium">
                    <div className="flex justify-between text-[11px] text-slate-500">
                      <span>Items Subtotal:</span>
                      <span className="text-slate-800">${subtotal.toFixed(2)}</span>
                    </div>
                    <div className="flex justify-between text-[11px] text-slate-500">
                      <span>Delivery Surcharge:</span>
                      <span className="text-slate-800">${deliveryFee.toFixed(2)}</span>
                    </div>
                    <div className="flex justify-between text-[11px] text-slate-500">
                      <span>Estimated Sales Tax (8.25%):</span>
                      <span className="text-slate-800">${tax.toFixed(2)}</span>
                    </div>
                    <div className="flex justify-between text-xs font-extrabold text-slate-900 border-t border-slate-200/70 pt-2">
                      <span className="text-indigo-700">Total Price:</span>
                      <span className="text-indigo-700">${total.toFixed(2)}</span>
                    </div>
                  </div>

                  {/* Submit buttons */}
                  <button
                    id="order-checkout-button"
                    type="submit"
                    disabled={loading}
                    className="w-full bg-indigo-600 text-white rounded-xl py-3.5 font-bold text-xs flex justify-center items-center gap-2 hover:bg-indigo-700 transition disabled:opacity-50 cursor-pointer shadow-lg shadow-indigo-100"
                  >
                    {loading ? (
                      <span className="flex items-center gap-1.5">
                        <RefreshCw className="animate-spin h-3.5 w-3.5 text-white" />
                        Transmitting to API Gateway...
                      </span>
                    ) : (
                      <span className="flex items-center gap-1.5">
                        <Send className="h-3.5 w-3.5" />
                        Confirm & Transmit Order
                      </span>
                    )}
                  </button>
                </form>
              </div>
            ) : (
              <div className="text-center py-10 px-4 h-full flex flex-col items-center justify-center">
                <div className="h-10 w-10 rounded-full bg-slate-50 flex items-center justify-center mb-2">
                  <ShoppingBag className="h-5 w-5 text-slate-400" />
                </div>
                <p className="text-xs font-bold text-slate-500">Draft Order is Empty</p>
                <p className="text-[10px] text-slate-400 leading-relaxed mt-1 max-w-xs">
                  Choose a restaurant from the available partners list of partners, and insert savory items to format calculations.
                </p>
              </div>
            )}
          </div>

          {/* Dynamic Active Tracker (Reactivity demonstration) */}
          <div className="bg-white border border-slate-100 p-5 rounded-3xl shadow-xs">
            <h3 className="text-sm font-extrabold text-slate-800 border-b border-slate-50 pb-2.5 mb-4 uppercase tracking-wider text-[11px] text-slate-400 flex justify-between items-center">
              <span>Operational Dispatch Registry</span>
              <span className="bg-slate-100 text-slate-700 text-[10px] px-2 py-0.5 rounded-md lowercase normal-case">{orders.length} events logged</span>
            </h3>

            {orders.length > 0 ? (
              <div className="space-y-4 max-h-72 overflow-y-auto pr-1">
                {orders.map((order) => {
                  const statusInfo = getStatusDetails(order.status);
                  const progressPct = getStatusPercentage(order.status);
                  return (
                    <motion.div
                      key={order.id}
                      layout
                      className="border border-slate-100 p-4 rounded-2xl space-y-3 shadow-xs bg-slate-50/30"
                    >
                      <div className="flex justify-between items-start">
                        <div>
                          <span className="text-[10px] font-mono font-bold bg-slate-200 text-slate-700 px-2 py-0.5 rounded">
                            #{order.id.replace('ord_', '')}
                          </span>
                          <h4 className="text-xs font-bold text-slate-950 mt-1.5 leading-snug">{order.restaurantName}</h4>
                        </div>
                        <span className={`text-[10px] font-extrabold px-2 py-0.5 rounded-full border ${statusInfo.bg} ${statusInfo.border}`}>
                          {statusInfo.text}
                        </span>
                      </div>

                      {/* Items details summary list */}
                      <div className="text-[10px] space-y-0.5 text-slate-500 bg-white p-2 rounded-lg border border-slate-100/50">
                        {order.items.map((it, idx) => (
                          <div key={idx} className="flex justify-between">
                            <span>{it.quantity}x {it.productName}</span>
                            <span>${(it.price * it.quantity).toFixed(2)}</span>
                          </div>
                        ))}
                        <div className="border-t border-slate-100 pt-1 mt-1 flex justify-between font-bold text-slate-800">
                          <span>Total Invoiced</span>
                          <span>${order.total.toFixed(2)}</span>
                        </div>
                      </div>

                      {/* Line Tracker */}
                      <div className="space-y-1.5 pt-1">
                        <div className="flex justify-between text-[9px] text-slate-400 font-semibold font-mono">
                          <span>TRANSMITTED</span>
                          <span>DISPATCHED</span>
                          <span>COMPLETED</span>
                        </div>
                        <div className="w-full bg-slate-100 h-1.5 rounded-full overflow-hidden">
                          <motion.div 
                            className="bg-indigo-600 h-full rounded-full"
                            initial={{ width: '0%' }}
                            animate={{ width: `${progressPct}%` }}
                            transition={{ duration: 1, ease: 'easeInOut' }}
                          />
                        </div>
                      </div>
                    </motion.div>
                  );
                })}
              </div>
            ) : (
              <div className="text-center py-6 text-slate-400 flex flex-col items-center justify-center">
                <Truck className="h-8 w-8 text-slate-300 mb-2" />
                <p className="text-xs font-bold">No active dispatches monitored</p>
                <p className="text-[10px] text-slate-400 max-w-xs mt-1">
                  Once your configuration checkout processes successfully, live operational telemetry logs will generate in real-time here.
                </p>
              </div>
            )}
          </div>

        </div>

      </main>
    </div>
  );
}
