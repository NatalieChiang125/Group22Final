import 'types.dart';

final BudgetData initialBudgetData = BudgetData(
  monthlyLimit: 15000,
  history: [
    BudgetPeriod(period: 'Mar 2024', spent: 12400, limit: 15000, type: 'monthly'),
    BudgetPeriod(period: 'Feb 2024', spent: 16200, limit: 14000, type: 'monthly'),
    BudgetPeriod(period: 'Jan 2024', spent: 11000, limit: 14000, type: 'monthly'),
    BudgetPeriod(period: 'Week 13', spent: 2800, limit: 3500, type: 'weekly'),
    BudgetPeriod(period: 'Week 14', spent: 4100, limit: 3500, type: 'weekly'),
    BudgetPeriod(period: 'Week 15', spent: 3200, limit: 3500, type: 'weekly'),
  ],
);

final UserPreferences initialUserPreferences = UserPreferences(
  allergies: [],
  eatBreakfast: true,
  priorityOrder: ['health', 'distance', 'price', 'rating'],
  dietaryPreference: [],
);

final List<Category> categoriesData = [
  Category(id: '1', name: 'Recommend', icon: '✨'),
  Category(id: '2', name: 'Healthy', icon: '🥗'),
  Category(id: '3', name: 'Distance', icon: '📍'),
  Category(id: '4', name: 'Rating', icon: '⭐'),
];

final UserStats initialUserStats = UserStats(
  goals: Nutrients(calories: 2000, protein: 120, carbs: 240, fat: 65, fiber: 30, fruit: 2),
  current: Nutrients(calories: 450, protein: 20, carbs: 50, fat: 10, fiber: 8, fruit: 0),
  remaining: Nutrients(calories: 1550, protein: 100, carbs: 190, fat: 55, fiber: 22, fruit: 2),
);

final List<Restaurant> restaurantsData = [
  Restaurant(
    id: 'r1',
    name: 'Artisan Woodfire Pizza',
    image: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=800&auto=format&fit=crop',
    rating: 4.8,
    distance: '0.8km',
    wiseScore: 92,
    wiseReason: 'Decent protein source, but slightly high in fats for your current progress. Great if you skip the extra cheese.',
    nutritionalHighlights: ['Protein Rich'],
    warnings: ['High Sat. Fat'],
    deliveryTime: '20 min',
    categories: ['Pizza', 'Italian'],
    priceRange: '\$\$',
    menuUrl: 'https://www.google.com/maps/search/Artisan+Woodfire+Pizza+menu',
    menuPhotos: [
      'https://images.unsplash.com/photo-1594007654729-407eedc4be65?q=80&w=800&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?q=80&w=800&auto=format&fit=crop'
    ],
    menuItems: [
      MenuCategory(
        category: 'Signature Pizzas',
        items: [
          MenuItem(name: 'Truffle Mushroom', price: '\$18.50', description: 'Wild mushrooms, truffle oil, fresh mozzarella, and thyme.', calories: 850),
          MenuItem(name: 'Spicy Salami', price: '\$17.00', description: 'Calabrese salami, honey, chili flakes, and San Marzano tomatoes.', calories: 920),
          MenuItem(name: 'Garden Veggie', price: '\$16.00', description: 'Roasted peppers, artichokes, olives, and vegan pesto.', calories: 740),
        ],
      ),
      MenuCategory(
        category: 'Starters',
        items: [
          MenuItem(name: 'Garlic Knots', price: '\$6.50', description: 'Olive oil, roasted garlic, and parmesan dip.', calories: 450),
        ],
      )
    ],
    isHealthy: false,
  ),
  Restaurant(
    id: 'r2',
    name: 'Green & Fresh Co.',
    image: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=800&auto=format&fit=crop',
    rating: 4.7,
    distance: '0.5km',
    wiseScore: 95,
    wiseReason: 'Perfectly matches your fiber goals for today. High protein salad base helps you reach your 120g target.',
    nutritionalHighlights: ['High Fiber', 'Vegan Options'],
    deliveryTime: '15 min',
    categories: ['Salad', 'Healthy'],
    priceRange: '\$',
    menuUrl: 'https://www.google.com/maps/search/Green+%26+Fresh+Co.+menu',
    menuPhotos: [
      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=800&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=800&auto=format&fit=crop'
    ],
    menuItems: [
      MenuCategory(
        category: 'Power Bowls',
        items: [
          MenuItem(name: 'Quinoa & Avocado Bowl', price: '\$12.00', description: 'Organic quinoa, kale, cherry tomatoes, and lemon-tahini dressing.', calories: 420),
          MenuItem(name: 'Roasted Salmon Bowl', price: '\$15.50', description: 'Wild-caught salmon, brown rice, edamame, and pickled ginger.', calories: 580),
        ],
      )
    ],
    isHealthy: true,
  ),
  Restaurant(
    id: 'r3',
    name: 'Kyoto Sushi Bar',
    image: 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?q=80&w=800&auto=format&fit=crop',
    rating: 4.9,
    distance: '1.2km',
    wiseScore: 85,
    wiseReason: 'High quality proteins, but higher carb count from rice might exceed your daily limit if ordered with rolls.',
    nutritionalHighlights: ['Omega-3', 'Lean Protein'],
    warnings: ['High Carb (Rice)'],
    deliveryTime: '30 min',
    categories: ['Sushi', 'Japanese'],
    priceRange: '\$\$\$',
    menuUrl: 'https://www.google.com/maps/search/Kyoto+Sushi+Bar+menu',
    menuPhotos: [
      'https://images.unsplash.com/photo-1553621042-f6e147245754?q=80&w=800&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?q=80&w=800&auto=format&fit=crop'
    ],
    menuItems: [
      MenuCategory(
        category: 'Special Rolls',
        items: [
          MenuItem(name: 'Dragon Roll', price: '\$16.00', description: 'Shrimp tempura, eel, avocado, and unagi sauce.', calories: 520),
          MenuItem(name: 'Rainbow Roll', price: '\$18.00', description: 'Crab meat, cucumber, topped with tuna, salmon, and yellowtail.', calories: 480),
        ],
      )
    ],
    isHealthy: true,
  ),
  Restaurant(
    id: 'r4',
    name: 'Mamma Mia Trattoria',
    image: 'https://images.unsplash.com/photo-1473093226795-af9932fe5856?q=80&w=800&auto=format&fit=crop',
    rating: 4.6,
    distance: '0.9km',
    wiseScore: 80,
    wiseReason: 'Decent pasta choices, but generally high in simple carbs. Recommended only if you need a high carb load before an intensive study session.',
    nutritionalHighlights: ['Energy Boost'],
    warnings: ['High Simple Carbs'],
    deliveryTime: '25 min',
    categories: ['Pasta', 'Italian'],
    priceRange: '\$\$',
    menuUrl: 'https://www.google.com/maps/search/Mamma+Mia+Trattoria+menu',
    menuPhotos: [
      'https://images.unsplash.com/photo-1473093226795-af9932fe5856?q=80&w=800&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1551183053-bf91a1d81141?q=80&w=800&auto=format&fit=crop'
    ],
    menuItems: [
      MenuCategory(
        category: 'Handmade Pasta',
        items: [
          MenuItem(name: 'Pappardelle Bolognese', price: '\$21.00', description: 'Slow-cooked beef ragu with fresh wide-cut egg pasta.', calories: 880),
          MenuItem(name: 'Truffle Carbonara', price: '\$23.00', description: 'Guanciale, pecorino romano, egg yolk, and freshly shaved black truffle.', calories: 950),
        ],
      )
    ],
    isHealthy: false,
  ),
];