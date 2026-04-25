import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_services.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  StreamSubscription<User?>? _authSubscription;

  AuthCubit(this._authService) : super(AuthInitial()) {
    // ← استمع لتغييرات الـ auth تلقائي
    _authSubscription = _authService.authStateChanges.listen((user) {
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }

  // ===== Getters =====
  User? get currentUser =>
      state is AuthAuthenticated ? (state as AuthAuthenticated).user : null;

  bool get isAuthenticated => state is AuthAuthenticated;

  // ===== Login =====
  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      await _authService.login(email, password);
      // الـ authStateChanges stream هيعمل emit لـ AuthAuthenticated تلقائي
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseError(e.code)));
    } catch (e) {
      emit(AuthError('Login failed. Please try again.'));
    }
  }

  // ===== Register =====
  Future<void> register(String email, String password, String name) async {
    emit(AuthLoading());
    try {
      await _authService.register(email, password, name);
      // الـ authStateChanges stream هيعمل emit لـ AuthAuthenticated تلقائي
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseError(e.code)));
    } catch (e) {
      emit(AuthError('Registration failed. Please try again.'));
    }
  }

  // ===== Google Sign In =====
  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      final result = await _authService.signInWithGoogle();
      if (result == null) {
        // المستخدم لغى العملية
        emit(AuthUnauthenticated());
      }
      // لو نجح → الـ authStateChanges stream هيعمل emit لـ AuthAuthenticated
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseError(e.code)));
    } catch (e) {
      emit(AuthError('Google Sign-In failed. Please try again.'));
    }
  }

  // ===== Reset Password =====
  Future<void> resetPassword(String email) async {
    emit(AuthLoading());
    try {
      await _authService.resetPassword(email);
      emit(AuthUnauthenticated()); // أو emit state تاني لو عندك
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseError(e.code)));
    } catch (e) {
      emit(AuthError('Failed to send reset email.'));
    }
  }

  // ===== Logout =====
  Future<void> logout() async {
    await _authService.logout();
    // الـ authStateChanges stream هيعمل emit لـ AuthUnauthenticated تلقائي
  }

  // ===== Map Firebase Errors =====
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}