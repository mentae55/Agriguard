// models/user_model.dart
class UserModel {
  final String id;
  final String email;
  final String? name;

  UserModel({required this.id, required this.email, this.name});

  factory UserModel.fromFirebase(dynamic fbUser) {
    return UserModel(
      id: fbUser.uid,
      email: fbUser.email ?? '',
      name: fbUser.displayName,
    );
  }
}