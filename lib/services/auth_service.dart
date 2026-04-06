import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'email_service.dart';

abstract class AuthService {
  Future<String> generateOtp(String email);
  Future<bool> verifyOtp(String email, String otp);
  Future<User?> signInWithEmail(String email);
  Future<void> signOut();
  User? get currentUser;
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService() {
    try {
      FirebaseDatabase.instance.goOnline();
    } catch (e) {
      debugPrint('GoOnline error: $e');
    }
  }
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DatabaseReference? _db;

  DatabaseReference get db {
    _db ??= FirebaseDatabase.instance.ref();
    return _db!;
  }

  String _encodeEmail(String email) {
    return email.trim().toLowerCase().replaceAll('.', '_dot_');
  }

  @override
  Future<String> generateOtp(String email) async {
    try {
      final otp = (Random().nextInt(900000) + 100000).toString();
      final encodedEmail = _encodeEmail(email);
      
      debugPrint('DB path: ${db.ref}');
      debugPrint('Generating OTP for: $encodedEmail');
      
      await db.child('verification_codes').child(encodedEmail).set({
        'code': otp,
        'createdAt': ServerValue.timestamp,
        'verified': false,
      }).timeout(const Duration(seconds: 10));
      
      debugPrint('OTP generated and stored: $otp');
      
      try {
        await EmailService().sendOtpEmail(email, otp);
        debugPrint('Email sent successfully');
      } catch (e) {
        debugPrint('Error sending email: $e');
      }
      
      return otp;
    } catch (e, stack) {
      debugPrint('Error generating OTP: $e');
      debugPrint('Stack: $stack');
      throw Exception('Failed to generate OTP: $e');
    }
  }

  @override
  Future<bool> verifyOtp(String email, String otp) async {
    try {
      final encodedEmail = _encodeEmail(email);
      debugPrint('Verifying OTP for: $encodedEmail, entered: $otp');
      
      final snapshot = await db.child('verification_codes').child(encodedEmail).get().timeout(const Duration(seconds: 10));
      
      if (!snapshot.exists) {
        debugPrint('No verification code found');
        return false;
      }
      
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final storedCode = data['code'] as String?;
      
      debugPrint('Stored code: $storedCode');
      
      if (storedCode != otp) {
        debugPrint('OTP mismatch');
        return false;
      }
      
      await db.child('verification_codes').child(encodedEmail).child('verified').set(true);
      debugPrint('OTP verified successfully');
      return true;
    } catch (e, stack) {
      debugPrint('Error verifying OTP: $e');
      debugPrint('Stack: $stack');
      return false;
    }
  }

  @override
  Future<User?> signInWithEmail(String email) async {
    try {
      final trimmedEmail = email.trim().toLowerCase();
      final tempPassword = 'verified_${DateTime.now().millisecondsSinceEpoch}';
      
      debugPrint('Signing in with email: $trimmedEmail');
      
      try {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: trimmedEmail,
          password: tempPassword,
        ).timeout(const Duration(seconds: 15));
        debugPrint('User created: ${credential.user?.uid}');
        return credential.user;
      } catch (e) {
        debugPrint('Sign in error: $e');
        if (e.toString().contains('email-already-in-use') || e.toString().contains('ERROR_EMAIL_ALREADY_IN_USE')) {
          return _auth.currentUser;
        }
        debugPrint('Re-throwing: $e');
        rethrow;
      }
    } catch (e) {
      debugPrint('Error in signInWithEmail: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  User? get currentUser => _auth.currentUser;
}
