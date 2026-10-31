import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import '../services/product_service.dart';
import '../widgets/product_card.dart';
import '../widgets/async_state_view.dart';
import 'cart_screen.dart';
import 'wishlist_screen.dart';
import 'my_orders_screen.dart';
import 'profile_screen.dart';
import 'product_details_screen.dart';
import 'notifications_screen.dart';
import '../screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isLoggingIn = false;
  late final Stream<List<Product>> _productsStream =
      ProductService().getProducts();

  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'Default';

  List<Product>? _cachedAllProducts;
  String? _cachedSearchQuery;
  String? _cachedCategory;
  String? _cachedSortBy;
  List<Product>? _cachedFilteredProducts;

  final List<String> _categories = [
    'All',
    'Electronics',
    'Clothing',
    'Home',
    'Beauty',
    'Food',
    'General',
  ];

  final List<String> _sortOptions = [
    'Default',
    'Price: Low to High',
    'Price: High to Low',
    'Name: A to Z',
    'Stock: High to Low',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildProductGrid() {
    return StreamBuilder<List<Product>>(
      stream: _productsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AsyncStateView(error: snapshot.error);
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allProducts = snapshot.data ?? [];

        List<Product> filtered;
        if (_cachedAllProducts == allProducts &&
            _cachedSearchQuery == _searchQuery &&
            _cachedCategory == _selectedCategory &&
            _cachedSortBy == _sortBy &&
            _cachedFilteredProducts != null) {
          filtered = _cachedFilteredProducts!;
        } else {
          // 1. Filter by category
          filtered = _selectedCategory == 'All'
              ? allProducts
              : allProducts.where((p) => p.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();

          // 2. Filter by search query
          if (_searchQuery.trim().isNotEmpty) {
            final q = _searchQuery.trim().toLowerCase();
            filtered = filtered.where((p) =>
                p.productName.toLowerCase().contains(q) ||
                p.description.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q)).toList();
          }

          // 3. Sort
          if (_sortBy == 'Price: Low to High') {
            filtered.sort((a, b) => a.price.compareTo(b.price));
          } else if (_sortBy == 'Price: High to Low') {
            filtered.sort((a, b) => b.price.compareTo(a.price));
          } else if (_sortBy == 'Name: A to Z') {
            filtered.sort((a, b) => a.productName.compareTo(b.productName));
          } else if (_sortBy == 'Stock: High to Low') {
            filtered.sort((a, b) => b.stock.compareTo(a.stock));
          }

          _cachedAllProducts = allProducts;
          _cachedSearchQuery = _searchQuery;
          _cachedCategory = _selectedCategory;
          _cachedSortBy = _sortBy;
          _cachedFilteredProducts = filtered;
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              hintText: 'Search products...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _sortBy,
                              icon: const Icon(Icons.sort),
                              items: _sortOptions
                                  .map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s, style: const TextStyle(fontSize: 13)),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _sortBy = v);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final isSelected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              selectedColor: Colors.indigo.shade600,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (_) => setState(() => _selectedCategory = cat),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade800, Colors.indigo.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Special Collection',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Discover our exclusive curated items with best prices today.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_offer_outlined, color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            filtered.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No products found',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = filtered[index];
                          return ProductCard(
                            product: product,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailsScreen(product: product),
                              ),
                            ),
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user == null;

    final cartItemCount = isGuest ? 0 : context.select<CartProvider, int>((p) => p.items.length);
    final wishlistCount = isGuest ? 0 : context.select<WishlistProvider, int>((p) => p.items.length);

    const titles = ['Chopify', 'My Wishlist', 'My Shopping Cart', 'My Orders', 'My Profile'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isGuest ? 'Chopify (Guest)' : titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isGuest) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                icon: _isLoggingIn
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.login, size: 18),
                label: const Text('Log In / Register'),
                onPressed: _isLoggingIn
                    ? null
                    : () async {
                        setState(() => _isLoggingIn = true);
                        try {
                          await LoginScreen.showAsModal(context);
                        } finally {
                          if (mounted) setState(() => _isLoggingIn = false);
                        }
                      },
              ),
            ),
          ] else ...[
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: user.uid)
                  .where('isRead', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data?.docs.length ?? 0;

                return IconButton(
                  icon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text('$unreadCount'),
                    child: const Icon(Icons.notifications_outlined),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: isGuest
          ? _buildProductGrid()
          : (_currentIndex == 0
              ? _buildProductGrid()
              : _currentIndex == 1
                  ? const WishlistScreen()
                  : _currentIndex == 2
                      ? const CartScreen()
                      : _currentIndex == 3
                          ? const MyOrdersScreen()
                          : const ProfileScreen()),
      bottomNavigationBar: isGuest
          ? null
          : NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) => setState(() => _currentIndex = index),
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: wishlistCount > 0,
                    label: Text('$wishlistCount'),
                    child: const Icon(Icons.favorite_border),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: wishlistCount > 0,
                    label: Text('$wishlistCount'),
                    child: const Icon(Icons.favorite),
                  ),
                  label: 'Wishlist',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: cartItemCount > 0,
                    label: Text('$cartItemCount'),
                    child: const Icon(Icons.shopping_cart_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: cartItemCount > 0,
                    label: Text('$cartItemCount'),
                    child: const Icon(Icons.shopping_cart),
                  ),
                  label: 'Cart',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: 'Orders',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
    );
  }
}