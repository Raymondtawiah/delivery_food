import 'dart:async';
import 'package:flutter/material.dart';

class MenuPage extends StatefulWidget {
  final Function(MenuItem item)? onAddToCart;

  const MenuPage({super.key, this.onAddToCart});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  Timer? _timer;
  List<MenuItem> _filteredItems = [];

  final List<HeroSlide> _heroSlides = [
    HeroSlide(
      imageAsset: 'assets/images/jollof.jpg',
      title: 'Jollof Rice',
      subtitle: 'Authentic Ghanaian Jollof',
    ),
    HeroSlide(
      imageAsset: 'assets/images/banku_and_tilipia.jpg',
      title: 'Banku & Tilapia',
      subtitle: 'Traditional Banku with grilled tilapia',
    ),
    HeroSlide(
      imageAsset: 'assets/images/Waakye.jpg',
      title: 'Waakye',
      subtitle: 'Ghanaian rice and beans',
    ),
    HeroSlide(
      imageAsset: 'assets/images/fufu_and_soup.jpg',
      title: 'Fufu with Soup',
      subtitle: 'Hand-pounded fufu with soup',
    ),
  ];

  final List<MenuItem> _menuItems = [
    MenuItem(name: 'Jollof Rice', price: '₵15.00', imageAsset: 'assets/images/jollof.jpg', addons: [
      {'name': 'Chicken', 'price': 5.0},
      {'name': 'Salad', 'price': 3.0},
      {'name': 'Drink', 'price': 4.0},
    ]),
    MenuItem(name: 'Banku & Tilapia', price: '₵25.00', imageAsset: 'assets/images/banku_and_tilipia.jpg', addons: [
      {'name': 'Extra Tilapia', 'price': 10.0},
      {'name': 'Pepper', 'price': 2.0},
    ]),
    MenuItem(name: 'Waakye', price: '₵12.00', imageAsset: 'assets/images/Waakye.jpg', addons: [
      {'name': 'Egg', 'price': 3.0},
      {'name': 'Spaghetti', 'price': 4.0},
    ]),
    MenuItem(name: 'Fufu with Soup', price: '₵18.00', imageAsset: 'assets/images/fufu_and_soup.jpg', addons: [
      {'name': 'Extra Meat', 'price': 8.0},
      {'name': 'Light Soup', 'price': 5.0},
    ]),
    MenuItem(name: 'Kenkey', price: '₵8.00', imageAsset: 'assets/images/kenkey.jpg', addons: [
      {'name': 'Fish', 'price': 5.0},
      {'name': 'Pepper', 'price': 2.0},
    ]),
    MenuItem(name: 'Fried Rice', price: '₵12.00', imageAsset: 'assets/images/fried_rice.jpg', addons: [
      {'name': 'Chicken', 'price': 5.0},
      {'name': 'Egg', 'price': 3.0},
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(_menuItems);
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _searchItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(_menuItems);
      } else {
        _filteredItems = _menuItems.where((item) =>
          item.name.toLowerCase().contains(query.toLowerCase())
        ).toList();
        if (_filteredItems.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No dishes found')),
          );
        }
      }
    });
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentPage < _heroSlides.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Our Menu'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _heroSlides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildHeroSlide(_heroSlides[index]);
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _heroSlides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.deepPurple
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for dishes...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              onChanged: _searchItems,
            ),
            const SizedBox(height: 24),
            const Text(
              'All Dishes',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                return _buildMenuCard(_filteredItems[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSlide(HeroSlide slide) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              slide.imageAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.deepPurple.shade100,
                  child: const Center(
                    child: Icon(
                      Icons.restaurant,
                      size: 64,
                      color: Colors.deepPurple,
                    ),
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slide.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    slide.subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(MenuItem item) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Image.asset(
              item.imageAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.restaurant,
                    size: 48,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.price,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        height: 32,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            widget.onAddToCart?.call(item);
                          },
                          icon: const Icon(Icons.add_shopping_cart, size: 16),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HeroSlide {
  final String imageAsset;
  final String title;
  final String subtitle;

  HeroSlide({
    required this.imageAsset,
    required this.title,
    required this.subtitle,
  });
}

class MenuItem {
  final String name;
  final String price;
  final String imageAsset;
  final List<Map<String, dynamic>> addons;

  MenuItem({
    required this.name,
    required this.price,
    required this.imageAsset,
    this.addons = const [],
  });
}