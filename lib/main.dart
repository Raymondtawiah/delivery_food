import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';

import 'pages/home_page.dart';
import 'pages/menu_page.dart' as menu;
import 'pages/sign_in_page.dart';
import 'pages/profile_setup_page.dart';
import 'pages/account_page.dart';
import 'pages/customization_page.dart';
import 'pages/cart_page.dart';
import 'widgets/navbar.dart';
import 'widgets/floating_cart_button.dart';
import 'services/cart_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CartService(),
      child: MaterialApp(
        title: 'Foodie',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  User? _user;
  String? _userName;
  String? _enteredEmail;
  bool _isLoggedIn = false;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _user = user;
        _isLoggedIn = user != null;
      });
      if (user != null) {
        _checkUserProfile(user);
      } else {
        setState(() {
          _userName = null;
        });
      }
    });
  }

  Future<void> _checkUserProfile(User user) async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref('users/${user.uid}').get();
      if (snapshot.exists) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);
          final fullName = data['name'] ?? '';
          final firstName = fullName.split(' ').first;
          setState(() {
            _userName = firstName;
          });
        _goToHome();
      } else {
        _goToProfileSetup('');
      }
    } catch (e) {
      _goToHome();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _goToMenu() {
    setState(() {
      _currentIndex = 1;
    });
  }

  void _goToHome() {
    setState(() {
      _currentIndex = 0;
    });
  }

  void _goToProfileSetup(String email) {
    setState(() {
      _enteredEmail = email;
      _currentIndex = 3;
    });
  }

  void _goToAccount() {
    setState(() {
      _currentIndex = 4;
    });
  }

  void _goToSignIn() {
    setState(() {
      _currentIndex = 2;
    });
  }

  void _handleUserIconTap() {
    if (_userName != null && _isLoggedIn) {
      _goToAccount();
    } else {
      _goToSignIn();
    }
  }

  void _onEmailVerified(User user, String email) {
    setState(() {
      _user = user;
      _isLoggedIn = true;
      _enteredEmail = email;
    });
    _goToProfileSetup(email);
  }

  void _onProfileSetupComplete() {
    _fetchUserName();
    _goToHome();
  }

  Future<void> _fetchUserName() async {
    if (_user != null) {
      try {
        final snapshot = await FirebaseDatabase.instance.ref('users/${_user!.uid}').get();
        if (snapshot.exists) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);
          final fullName = data['name'] ?? '';
          final firstName = fullName.split(' ').first;
          setState(() {
            _userName = firstName;
          });
        }
      } catch (e) {
        // Ignore
      }
    }
  }

  void _onSignOut() {
    context.read<CartService>().clearCart();
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    setState(() {
      _user = null;
      _userName = null;
      _enteredEmail = null;
      _isLoggedIn = false;
      _currentIndex = 0;
    });
  }

  void _onDeleteAccount() {
    setState(() {
      _user = null;
      _userName = null;
      _enteredEmail = null;
      _isLoggedIn = false;
      _currentIndex = 0;
    });
  }

  void _handleAddToCart(dynamic item) {
    if (!_isLoggedIn) {
      _goToSignIn();
      return;
    }

    if (item.name != null && item.price != null && item.imageAsset != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomizationPage(
            name: item.name,
            price: item.price,
            imageAsset: item.imageAsset,
            addons: item.addons ?? [],
          ),
        ),
      );
    }
  }

  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePage(onNavigateToMenu: _goToMenu, onAddToCart: _handleAddToCart),
          menu.MenuPage(onAddToCart: _handleAddToCart),
          SignInPage(onSkip: _goToHome, onEmailVerified: _onEmailVerified),
          if (_user != null && _enteredEmail != null)
            ProfileSetupPage(
              user: _user!,
              email: _enteredEmail!,
              onSetupComplete: _onProfileSetupComplete,
            ),
          AccountPage(
            onSignOut: _onSignOut,
            onDeleteAccount: _onDeleteAccount,
          ),
          const CartPage(),
        ],
      ),
      floatingActionButton: FloatingCartButton(
        onCartTap: _navigateToCart,
        isLoggedIn: _isLoggedIn,
      ),
      bottomNavigationBar: Navbar(
        currentIndex: _currentIndex > 2 ? 2 : _currentIndex,
        userName: _userName,
        isLoggedIn: _isLoggedIn,
        onTap: (index) {
          if (index == 2) {
            _handleUserIconTap();
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
      ),
    );
  }
}