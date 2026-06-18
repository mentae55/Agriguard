import 'package:flutter/material.dart';

class AppLocalizations {
  static String tr(BuildContext context, String key) {
    final Map<String, String> translations = {
      'edit_profile': 'Edit Profile',
      'profile_updated': 'Profile Updated',
      'error_occurred': 'An Error Occurred',
      'first_name': 'First Name',
      'required_field': 'Required field',
      'last_name': 'Last Name',
      'username': 'Username',
      'email': 'Email',
      'phone_number': 'Phone Number',
      'invalid_phone': 'Invalid Phone',
      'save_changes': 'Save Changes',
      'logout_message': 'Are you sure you want to log out?',
      'yes': 'Yes',
      'no': 'No',
      'my_profile': 'My Profile',
      'history': 'History',
      'dark_mode': 'Dark Mode',
      'alert_history': 'Alert History',
      'log_out': 'Log Out',
    };
    return translations[key] ?? key;
  }
}
