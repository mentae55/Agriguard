import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../model/user_model.dart';
import '../services/auth_services.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool isLoading = false;
  String? errorMessage;
  UserModel? currentUser;

  Future<void> login(String email, String password) async {
    _setState(loading: true);
    try {
      final result = await _authService.login(email, password);
      currentUser = UserModel.fromFirebase(result.user);
      errorMessage = null;
    } on FirebaseAuthException catch (e) {
      errorMessage = _mapFirebaseError(e.code);
    } catch (e) {
      errorMessage = 'Login failed. Please try again.';
    }
    _setState(loading: false);
  }

  Future<void> register(String email, String password, String name) async {
    _setState(loading: true);
    try {
      final result = await _authService.register(email, password, name);
      currentUser = UserModel.fromFirebase(result.user);
      errorMessage = null;
    } on FirebaseAuthException catch (e) {
      errorMessage = _mapFirebaseError(e.code);
    } catch (e) {
      errorMessage = 'Registration failed. Please try again.';
    }
    _setState(loading: false);
  }

  // ===== Google Sign In (Fixed) =====
  Future<bool> signInWithGoogle() async {
    _setState(loading: true);
    errorMessage = null;

    try {
      final result = await _authService.signInWithGoogle();

      if (result == null) {
        // المستخدم لغى العملية — مش error
        _setState(loading: false);
        return false;
      }

      currentUser = UserModel.fromFirebase(result.user);
      errorMessage = null;
      _setState(loading: false);
      return true;

    } on FirebaseAuthException catch (e) {
      errorMessage = _mapFirebaseError(e.code);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('network')) {
        errorMessage = 'No internet connection.';
      } else if (msg.contains('canceled') || msg.contains('cancelled')) {
        errorMessage = null; // المستخدم لغى — مش error
      } else {
        errorMessage = 'Google Sign-In failed. Please try again.';
      }
    }

    _setState(loading: false);
    return false;
  }

  Future<void> resetPassword(String email) async {
    _setState(loading: true);
    try {
      await _authService.resetPassword(email);
      errorMessage = null;
    } on FirebaseAuthException catch (e) {
      errorMessage = _mapFirebaseError(e.code);
    } catch (e) {
      errorMessage = 'Failed to send reset email.';
    }
    _setState(loading: false);
  }

  void _setState({required bool loading}) {
    isLoading = loading;
    notifyListeners();
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  Stream<User?> get authStateChanges => FirebaseAuth.instance.authStateChanges();
}