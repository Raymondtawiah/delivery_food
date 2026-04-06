import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';

import 'pages/splash_screen.dart';
import 'pages/home_page.dart';
import 'pages/menu_page.dart' as menu;
import 'pages/sign_in_page.dart';
import 'pages/profile_setup_page.dart';
import 'pages/account_page.dart';
import 'pages/customization_page.dart';
import 'pages/cart_page.dart';
import 'widgets/custom_navbar.dart';
import 'widgets/floating_cart_button.dart';
import 'services/cart_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class AppColors {
  static const Color burntOrange = Color(0xFFCC5500);
  static const Color tomatoRed = Color(0xFFFF6347);
  static const Color freshGreen = Color(0xFF228B22);
  static const Color lightGreen = Color(0xFF90EE90);
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
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.burntOrange,
            primary: AppColors.burntOrange,
            secondary: AppColors.tomatoRed,
            tertiary: AppColors.freshGreen,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.burntOrange,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.burntOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.burntOrange,
              side: const BorderSide(color: AppColors.burntOrange),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.burntOrange,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.burntOrange),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.burntOrange.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.burntOrange, width: 2),
            ),
            labelStyle: const TextStyle(color: AppColors.burntOrange),
            prefixIconColor: AppColors.burntOrange,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          checkboxTheme: CheckboxThemeData(
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.burntOrange;
              }
              return null;
            }),
          ),
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const AnimatedSplashScreen(nextScreen: MainScreen()),
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
  String? _userId;
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
    debugPrint('_goToAccount called, setting _currentIndex = 4');
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
    debugPrint('_handleUserIconTap: _currentIndex=$_currentIndex, _userName=$_userName, _isLoggedIn=$_isLoggedIn');
    if (_currentIndex == 4) return;
    
    if (_userName != null && _isLoggedIn) {
      setState(() {
        _currentIndex = 4;
      });
    } else {
      setState(() {
        _currentIndex = 2;
      });
    }
  }

  void _onVerificationComplete(dynamic user, String email) {
    final uid = user is User ? user.uid : (user.uid?.toString() ?? email.hashCode.toString());
    setState(() {
      _user = user is User ? user : null;
      _userId = uid;
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
      MaterialPageRoute(
        builder: (_) => CartPage(
          userId: _userId,
          email: _enteredEmail,
        ),
      ),
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
          SignInPage(onSkip: _goToHome, onVerificationComplete: _onVerificationComplete),
          if (_enteredEmail != null)
            ProfileSetupPage(
              user: _user,
              userId: _userId,
              email: _enteredEmail!,
              onSetupComplete: _onProfileSetupComplete,
            ),
          AccountPage(
            userId: _userId,
            email: _enteredEmail,
            onSignOut: _onSignOut,
            onDeleteAccount: _onDeleteAccount,
          ),
          CartPage(
            userId: _userId,
            email: _enteredEmail,
          ),
        ],
      ),
      floatingActionButton: FloatingCartButton(
        onCartTap: _navigateToCart,
        isLoggedIn: _isLoggedIn,
      ),
      bottomNavigationBar: CustomNavbar(
        currentIndex: _currentIndex > 2 ? 2 : _currentIndex,
        userName: _userName,
        onItemTapped: (index) {
          debugPrint('Navbar tapped: index=$index, _currentIndex=$_currentIndex');
          if (index == 2) {
            _handleUserIconTap();
          } else if (index != _currentIndex) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
      ),
    );
  }
}
