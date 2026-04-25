part of 'auth_cubit.dart';

abstract class AuthState {}

/// الحالة الابتدائية
class AuthInitial extends AuthState {}

/// جاري التحقق
class AuthLoading extends AuthState {}

/// اليوزر متسجل دخول
class AuthAuthenticated extends AuthState {
  final User user;
  AuthAuthenticated(this.user);
}

/// مش متسجل دخول
class AuthUnauthenticated extends AuthState {}

/// حصل error
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}