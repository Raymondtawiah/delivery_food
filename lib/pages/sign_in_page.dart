import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/flash_overlay.dart';

class SignInPage extends StatefulWidget {
  final VoidCallback? onSkip;
  final Function(User user, String email)? onEmailVerified;

  const SignInPage({super.key, this.onSkip, this.onEmailVerified});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool? _showResult;
  bool _showOverlay = false;
  String? _enteredEmail;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      _enteredEmail = _emailController.text.trim();
      setState(() => _isLoading = true);
      try {
        await FirebaseAuth.instance.signInAnonymously();
        
        setState(() {
          _isLoading = false;
          _showOverlay = true;
          _showResult = true;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _showOverlay = true;
          _showResult = false;
        });
        debugPrint('Sign in error: $e');
      }
    }
  }

  void _onFlashComplete() {
    setState(() => _showOverlay = false);
    if (_showResult == true && FirebaseAuth.instance.currentUser != null) {
      widget.onEmailVerified?.call(FirebaseAuth.instance.currentUser!, _enteredEmail ?? '');
    } else {
      setState(() => _showOverlay = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  const Icon(
                    Icons.restaurant_menu,
                    size: 80,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your email to continue',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Verifying',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              LoadingDots(),
                            ],
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      widget.onSkip?.call();
                    },
                    child: const Text('Continue as Guest'),
                  ),
                ],
              ),
            ),
          ),
          if (_showOverlay)
            FlashOverlay(
              isLoading: _isLoading,
              isSuccess: _showResult,
              onComplete: _onFlashComplete,
            ),
        ],
      ),
    );
  }
}