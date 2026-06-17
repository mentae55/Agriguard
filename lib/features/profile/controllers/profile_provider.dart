import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
        // Fallback Mode: Do not break UI, set safe defaults
        _userProfile = UserProfile(
          uid: 'fallback_uid',
          firstName: 'User',
          lastName: '',
          username: '@user',
          email: 'user@example.com',
          phone: '',
          profileImageUrl: 'assets/app_images/icons/logo.svg',
        );
      } else {
        _userProfile = await _profileService.getUserProfile(user.uid);
        // If profile doesn't exist in Firestore, create default using Firebase Auth data
        if (_userProfile == null) {
          final displayName = user.displayName ?? '';
          final nameParts = displayName.trim().split(' ');
          final firstName = nameParts.isNotEmpty ? nameParts.first : 'New';
          final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : 'User';

          _userProfile = UserProfile(
            uid: user.uid,
            firstName: firstName,
            lastName: lastName,
            username: '@user_${user.uid.substring(0, 5)}',
            email: user.email ?? '',
            phone: user.phoneNumber ?? '',
            profileImageUrl: 'assets/app_images/icons/logo.svg',
          );
          await _profileService.updateUserProfile(_userProfile!);
        }
      }

      // Load profile picture path from SharedPreferences (persisting across restarts)
      if (_userProfile != null) {
        final prefs = await SharedPreferences.getInstance();
        final localImagePath = prefs.getString('profile_image_${_userProfile!.uid}');
        if (localImagePath != null && localImagePath.isNotEmpty) {
          _userProfile = _userProfile!.copyWith(profileImageUrl: localImagePath);
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
        // Save selected local image path to SharedPreferences instead of uploading to Firebase Storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_${_userProfile!.uid}', newImage.path);
        imageUrl = newImage.path;
      }

      final updatedProfile = _userProfile!.copyWith(
        firstName: firstName,
        lastName: lastName,
        username: username,
        phone: phone,
        profileImageUrl: imageUrl,
      );

      // Successfully write and update Firestore using the authenticated user's real UID
      if (_userProfile!.uid != 'fallback_uid') {
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
