import { Restaurant } from '../types';

export const mockRestaurants: Restaurant[] = [
  {
    id: 'rest_1',
    name: 'Bella Italia Artisanal Pizza',
    description: 'Fresh wood-fired neapolitan pizzas and classic slow-cooked handmade pastas made by genuine Italian chefs.',
    cuisine: 'Italian, Pizza & Pasta',
    rating: 4.8,
    deliveryTime: '25-35 min',
    deliveryFee: 2.99,
    image: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600&auto=format&fit=crop&q=80',
    products: [
      {
        id: 'prod_1_1',
        name: 'Margherita DOC Pizza',
        description: 'San Marzano tomatoes, fresh buffalo mozzarella, fragrant wild basil, and a generous drizzle of organic extra virgin olive oil.',
        price: 14.99,
        image: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=500&auto=format&fit=crop&q=80',
        category: 'Pizzas'
      },
      {
        id: 'prod_1_2',
        name: 'Diavola Spicy Salami Pizza',
        description: 'Crushed spiced tomatoes, hand-stretched mozzarella, authentic spicy Calabrian salami, red pepper flakes, and hot honey.',
        price: 16.50,
        image: 'https://images.unsplash.com/photo-1534308983496-4fabb1a015ee?w=500&auto=format&fit=crop&q=80',
        category: 'Pizzas'
      },
      {
        id: 'prod_1_3',
        name: 'Truffle Mushroom Fettuccine',
        description: 'Fettuccine tossed in a rich, creamy black summer truffle butter sauce, chanterelle mushrooms, and aged Parmigiano-Reggiano.',
        price: 18.00,
        image: 'https://images.unsplash.com/photo-1645112411341-6c4fd023714a?w=500&auto=format&fit=crop&q=80',
        category: 'Pastas'
      },
      {
        id: 'prod_1_4',
        name: 'Handcrafted Tiramisu',
        description: 'Layers of espresso-soaked ladyfingers, velvety whipped sweet mascarpone cream, and dark cocoa dust.',
        price: 7.99,
        image: 'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=500&auto=format&fit=crop&q=80',
        category: 'Desserts'
      }
    ]
  },
  {
    id: 'rest_2',
    name: 'Sizzle & Bun Craft Burgers',
    description: 'Juicy, certified black angus beef patties smashed on a burning flat-top, nestled in soft, pillowy brioche buns.',
    cuisine: 'Burgers, American',
    rating: 4.7,
    deliveryTime: '20-30 min',
    deliveryFee: 1.99,
    image: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&auto=format&fit=crop&q=80',
    products: [
      {
        id: 'prod_2_1',
        name: 'The Ultimate Sizzle Burger',
        description: 'Double smashed grass-fed beef patty, melted cheddar cheese, crispy maple bacon, caramelized onions, and house burger glaze.',
        price: 12.99,
        image: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500&auto=format&fit=crop&q=80',
        category: 'Burgers'
      },
      {
        id: 'prod_2_2',
        name: 'Smoky BBQ Pecan Burger',
        description: 'Smashed patty with deep smoky hickory BBQ sauce, melting monterey jack, crispy beer-battered onion rings, and chipotle mayo.',
        price: 13.50,
        image: 'https://images.unsplash.com/photo-1521305916504-4a1121188589?w=500&auto=format&fit=crop&q=80',
        category: 'Burgers'
      },
      {
        id: 'prod_2_3',
        name: 'Loaded Sweet Potato Wedges',
        description: 'Crispy cut sweet potatoes smothered in hot local cheese sauce, sliced pickled jalapenos, and spring onions.',
        price: 6.99,
        image: 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=500&auto=format&fit=crop&q=80',
        category: 'Sides'
      },
      {
        id: 'prod_2_4',
        name: 'Salted Caramel Milkshake',
        description: 'Thick, premium vanilla bean ice cream spun with slow-melted sea-salt caramel sauce, whipped cream, and toffee bites.',
        price: 5.99,
        image: 'https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=500&auto=format&fit=crop&q=80',
        category: 'Shakes'
      }
    ]
  },
  {
    id: 'rest_3',
    name: 'Sakura Zen Premium Sushi',
    description: 'Expertly sliced premium-grade sashimi, hand-rolled maki, and high-quality warm vinegar-balanced sushi rice.',
    cuisine: 'Japanese, Sushi, Seafood',
    rating: 4.9,
    deliveryTime: '30-40 min',
    deliveryFee: 3.99,
    image: 'https://images.unsplash.com/photo-1611143669185-af224c5e3252?w=600&auto=format&fit=crop&q=80',
    products: [
      {
        id: 'prod_3_1',
        name: 'Signature Dragon Roll (8pcs)',
        description: 'Crispy king prawn tempura and organic cucumber, draped with delicate avocado slices, unagi sweet soy glaze, and spicy mayo.',
        price: 15.99,
        image: 'https://images.unsplash.com/photo-1617196034796-73dfa7b1fd56?w=500&auto=format&fit=crop&q=80',
        category: 'Sushi Rolls'
      },
      {
        id: 'prod_3_2',
        name: 'Aki Miyabi Sashimi Selection',
        description: 'Nine thick slices of sustainably harvested bluefin tuna, fresh Atlantic salmon, and premium sea bass sashimi served with authentic wasabi root.',
        price: 22.00,
        image: 'https://images.unsplash.com/photo-1534482421-64566f976cfa?w=500&auto=format&fit=crop&q=80',
        category: 'Sashimi'
      },
      {
        id: 'prod_3_3',
        name: 'Vegetarian Zen Roll',
        description: 'Crispy sweet potato tempura, pickled asparagus, fresh avocado, and organic cucumber topped with a light sesame soy drizzle.',
        price: 11.50,
        image: 'https://images.unsplash.com/photo-1553621042-f6e147245754?w=500&auto=format&fit=crop&q=80',
        category: 'Sushi Rolls'
      },
      {
        id: 'prod_3_4',
        name: 'Uji Matcha Lava Fondant',
        description: 'A decadent warm green tea cake with a warm flowing white-chocolate-matcha lava core, served with toasted sesame.',
        price: 8.50,
        image: 'https://images.unsplash.com/photo-1536680465769-2365207b035e?w=500&auto=format&fit=crop&q=80',
        category: 'Desserts'
      }
    ]
  }
];
