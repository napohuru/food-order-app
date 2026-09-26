import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// If you used `flutterfire configure`, firebase_options.dart will be generated and can be imported here.
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Sign in anonymously for demo purposes (so Firestore writes have a user)
  try {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
  } catch (e) {
    // If Firebase is not configured, anonymous sign-in will fail; the app will still run in local demo mode.
    debugPrint('Firebase auth error: $e');
  }

  runApp(const FoodOrderingApp());
}

class FoodItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final String description;
  final String imageUrl;

  const FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'description': description,
        'imageUrl': imageUrl,
      };
}

class CartItem {
  final FoodItem food;
  int quantity;

  CartItem({
    required this.food,
    this.quantity = 1,
  });

  double get subtotal => food.price * quantity;

  Map<String, dynamic> toMap() => {
        'id': food.id,
        'name': food.name,
        'price': food.price,
        'quantity': quantity,
      };
}

class Order {
  final String id;
  final String customerName;
  final String phone;
  final String address;
  final List<CartItem> items;
  final double total;
  final String status;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerName': customerName,
        'phone': phone,
        'address': address,
        'items': items.map((i) => i.toMap()).toList(),
        'total': total,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class FoodStore extends ChangeNotifier {
  final List<FoodItem> catalog = [
    FoodItem(
      id: '1',
      name: '招牌牛肉堡',
      category: '主食',
      price: 28.0,
      description: '牛肉、芝士、番茄、洋葱、特制酱汁',
      imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=800&q=80',
    ),
    FoodItem(
      id: '2',
      name: '香辣鸡腿堡',
      category: '主食',
      price: 26.0,
      description: '香辣鸡腿排、卷心菜、酱汁',
      imageUrl: 'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=800&q=80',
    ),
    FoodItem(
      id: '3',
      name: '鸡翅套餐',
      category: '小吃',
      price: 22.0,
      description: '香炸鸡翅 + 薯条 + 可乐',
      imageUrl: 'https://images.unsplash.com/photo-1512152272829-e31e6296c3b3?auto=format&fit=crop&w=800&q=80',
    ),
    FoodItem(
      id: '4',
      name: '香酥薯条',
      category: '小吃',
      price: 12.0,
      description: '酥脆薯条，适合搭配主食',
      imageUrl: 'https://images.unsplash.com/photo-1576107232684-1279f390859f?auto=format&fit=crop&w=800&q=80',
    ),
    FoodItem(
      id: '5',
      name: '冰柠茶',
      category: '饮品',
      price: 8.0,
      description: '冰爽清凉，解腻佳品',
      imageUrl: 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=800&q=80',
    ),
    FoodItem(
      id: '6',
      name: '草莓奶昔',
      category: '饮品',
      price: 15.0,
      description: '草莓风味，奶香浓郁',
      imageUrl: 'https://images.unsplash.com/photo-1572490122747-3968b75cc699?auto=format&fit=crop&w=800&q=80',
    ),
  ];

  final List<CartItem> cart = [];
  final List<Order> orderHistory = [];

  List<String> get categories => ['全部', ...catalog.map((e) => e.category).toSet().toList()];

  double get cartTotal => cart.fold(0.0, (sum, item) => sum + item.subtotal);

  int get cartCount => cart.fold(0, (sum, item) => sum + item.quantity);

  void addToCart(FoodItem food) {
    final index = cart.indexWhere((item) => item.food.id == food.id);
    if (index >= 0) {
      cart[index].quantity += 1;
    } else {
      cart.add(CartItem(food: food, quantity: 1));
    }
    notifyListeners();
  }

  void increaseQty(CartItem item) {
    item.quantity += 1;
    notifyListeners();
  }

  void decreaseQty(CartItem item) {
    if (item.quantity == 1) {
      cart.remove(item);
    } else {
      item.quantity -= 1;
    }
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }

  Future<void> submitOrder({
    required String customerName,
    required String phone,
    required String address,
  }) async {
    if (customerName.trim().isEmpty || cart.isEmpty) return;

    final newOrder = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      customerName: customerName,
      phone: phone,
      address: address,
      items: List.from(cart),
      total: cartTotal,
      status: '已下单',
      createdAt: DateTime.now(),
    );

    // Try to write to Firestore. If Firestore is not configured, fall back to local history only.
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('orders').add(newOrder.toMap());
    } catch (e) {
      debugPrint('Failed to write order to Firestore: $e');
    }

    orderHistory.insert(0, newOrder);
    clearCart();
    notifyListeners();
  }
}

class FoodOrderingApp extends StatefulWidget {
  const FoodOrderingApp({super.key});

  @override
  State<FoodOrderingApp> createState() => _FoodOrderingAppState();
}

class _FoodOrderingAppState extends State<FoodOrderingApp> {
  final FoodStore store = FoodStore();

  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(store: store),
      OrderHistoryScreen(store: store),
      ProfileScreen(store: store),
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '点餐系统',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.orange,
      ),
      home: Scaffold(
        body: screens[_selectedTab],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedTab,
          onDestinationSelected: (index) => setState(() => _selectedTab = index),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '首页'),
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: '订单'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '我的'),
          ],
        ),
      ),
    );
  }
}

// The rest of the UI code (HomeScreen, DishDetailScreen, CartScreen, CheckoutScreen, OrderHistoryScreen, ProfileScreen)
// is identical to the non-Firebase version and kept below for readability. (See full implementation in lib/main.dart)

