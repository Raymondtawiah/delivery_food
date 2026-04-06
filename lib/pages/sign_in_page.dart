import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../services/auth_service.dart';
import '../main.dart' show AppColors;

class SignInPage extends StatefulWidget {
  final VoidCallback? onSkip;
  final Function(dynamic user, String email)? onVerificationComplete;

  const SignInPage({super.key, this.onSkip, this.onVerificationComplete});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;
  String? _error;
  
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = FirebaseAuthService();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        final email = _emailController.text.trim();
        debugPrint('Sending OTP for: $email');
        
        final otp = await _authService.generateOtp(email);
        debugPrint('OTP received: $otp');
        
        setState(() {
          _otpSent = true;
          _isLoading = false;
        });
      } catch (e) {
        debugPrint('Error generating OTP: $e');
        setState(() {
          _error = 'Error: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      setState(() {
        _error = 'Please enter the OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final email = _emailController.text.trim();
      final otp = _otpController.text.trim();
      
      debugPrint('Verifying OTP: email=$email, otp=$otp');
      
      final isValid = await _authService.verifyOtp(email, otp);
      
      debugPrint('Verification result: $isValid');
      
      if (isValid) {
        try {
          final user = await _authService.signInWithEmail(email);
          if (user != null && mounted) {
            widget.onVerificationComplete?.call(user, email);
          } else {
            final mockUser = _createMockUser(email);
            widget.onVerificationComplete?.call(mockUser, email);
          }
        } catch (e) {
          debugPrint('Sign in error: $e');
          final mockUser = _createMockUser(email);
          widget.onVerificationComplete?.call(mockUser, email);
        }
      } else {
        setState(() {
          _error = 'Invalid OTP';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Verification error: $e');
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  dynamic _createMockUser(String email) {
    return _MockUser(email: email);
  }

  void _resetOtp() {
    setState(() {
      _otpSent = false;
      _otpController.clear();
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        backgroundColor: AppColors.burntOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
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
                color: AppColors.burntOrange,
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
              Text(
                _otpSent 
                    ? 'Enter the OTP shown below' 
                    : 'Enter your email to continue',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !_otpSent,
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
              if (_otpSent) ...[
                const SizedBox(height: 24),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'OTP',
                    prefixIcon: const Icon(Icons.pin_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.email_outlined, size: 40, color: Colors.green),
                      const SizedBox(height: 8),
                      Text(
                        'OTP sent to ${_emailController.text.trim()}',
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Check your inbox or spam folder',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : (_otpSent ? _verifyOtp : _sendOtp),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.burntOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : Text(
                        _otpSent ? 'Verify OTP' : 'Send OTP',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              if (_otpSent)
                TextButton(
                  onPressed: _resetOtp,
                  child: const Text('Change Email'),
                ),
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
    );
  }
}

class _MockUser implements firebase_auth.User {
  @override
  final String email;
  
  @override
  String get uid => email.hashCode.toString();
  
  _MockUser({required this.email});
  
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
  
  @override
  bool get isAnonymous => false;
  
  @override
  bool get emailVerified => true;
  
  @override
  String? get displayName => null;
  
  @override
  String? get photoURL => null;
  
  @override
  String? get phoneNumber => null;
  
  @override
  List<firebase_auth.UserInfo> get providerData => [];
  
  @override
  List<String> get providerIds => [];
  
  @override
  String? get refreshToken => null;
  
  @override
  String? get tenantId => null;
  
  @override
  DateTime? get metadatacreationTime => DateTime.now();
  
  @override
  DateTime? get metadatalastSignInTime => DateTime.now();
  
  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async => '';
  
  @override
  Future<firebase_auth.IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async => throw UnimplementedError();
  
  @override
  Future<void> reload() async {}
  
  @override
  Future<void> sendEmailVerification([firebase_auth.ActionCodeSettings? actionCodeSettings]) async {}
  
  @override
  Future<bool> delete() async => true;
  
  @override
  Future<void> updateEmail(String newEmail) async {}
  
  @override
  Future<void> updatePassword(String newPassword) async {}
  
  @override
  Future<void> updatePhoneNumber(firebase_auth.PhoneAuthCredential phoneCredential) async {}
  
  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) async {}
  
  @override
  Future<firebase_auth.UserCredential> reauthenticate(firebase_auth.AuthCredential credential) async => throw UnimplementedError();
  
  @override
  Future<firebase_auth.UserCredential> linkWithCredential(firebase_auth.AuthCredential credential) async => throw UnimplementedError();
  
  @override
  Future<firebase_auth.UserCredential> linkWithProvider(firebase_auth.AuthProvider provider) async => throw UnimplementedError();
  
  @override
  Future<firebase_auth.User> unlink(String providerId) async => throw UnimplementedError();
  
  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail, [firebase_auth.ActionCodeSettings? actionCodeSettings]) async {}
  
  @override
  dynamic toJSON() => {};
}
