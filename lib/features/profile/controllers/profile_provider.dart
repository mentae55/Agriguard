import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile_model.dart';
import '../services/profile_service.dart';

class ProfileProvider with ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ProfileProvider() {
    loadProfile();
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        // Mock user when not logged in
        if (_userProfile == null) {
          _userProfile = UserProfile(
            uid: 'mock_uid_123',
            firstName: 'Sabrina',
            lastName: 'Aryan',
            username: '@Sabrina',
            email: 'SabrinaAry208@gmail.com',
            phone: '+234 123 4567',
            profileImageUrl: '', // Empty uses placeholder
          );
        }
      } else {
        _userProfile = await _profileService.getUserProfile(user.uid);
        // If profile doesn't exist in Firestore, create default
        if (_userProfile == null) {
          _userProfile = UserProfile(
            uid: user.uid,
            firstName: user.displayName?.split(' ').first ?? 'New',
            lastName: user.displayName?.split(' ').skip(1).join(' ') ?? 'User',
            username: '@user_${user.uid.substring(0, 5)}',
            email: user.email ?? '',
            phone: user.phoneNumber ?? '',
            profileImageUrl: user.photoURL ?? '',
          );
          await _profileService.updateUserProfile(_userProfile!);
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String username,
    required String phone,
    File? newImage,
  }) async {
    if (_userProfile == null) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String imageUrl = _userProfile!.profileImageUrl;

      if (newImage != null) {
        if (_userProfile!.uid == 'mock_uid_123') {
           // For mock user, just use local file path as string (mock behavior)
           imageUrl = newImage.path;
        } else {
           imageUrl = await _profileService.uploadProfileImage(_userProfile!.uid, newImage);
        }
      }

      final updatedProfile = _userProfile!.copyWith(
        firstName: firstName,
        lastName: lastName,
        username: username,
        phone: phone,
        profileImageUrl: imageUrl,
      );

      if (_userProfile!.uid != 'mock_uid_123') {
        await _profileService.updateUserProfile(updatedProfile);
      }
      _userProfile = updatedProfile;
    } catch (e) {
      _errorMessage = e.toString();
      throw Exception(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
