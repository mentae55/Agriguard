import 'package:flutter/material.dart';

class AppLocalizations {
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'my_profile': 'My Profile',
      'edit_profile': 'Edit Profile',
      'history': 'History',
      'dark_mode': 'Dark Mode',
      'languages': 'Languages',
      'log_out': 'Log out',
      'logout_message': 'Are you sure you want\nto log out?',
      'yes': 'Yes',
      'no': 'No',
      'save_changes': 'Save changes',
      'first_name': 'First Name',
      'last_name': 'Last Name',
      'username': 'Username',
      'email': 'Email',
      'phone_number': 'Phone Number',
      'profile_updated': 'Profile updated successfully',
      'error_occurred': 'An error occurred',
      'choose_image': 'Choose Image',
      'gallery': 'Gallery',
      'camera': 'Camera',
      'required_field': 'This field is required',
      'invalid_email': 'Please enter a valid email',
      'invalid_phone': 'Please enter a valid phone number',
    },
    'ar': {
      'my_profile': 'ملفي الشخصي',
      'edit_profile': 'تعديل الملف الشخصي',
      'history': 'السجل',
      'dark_mode': 'الوضع الداكن',
      'languages': 'اللغات',
      'log_out': 'تسجيل الخروج',
      'logout_message': 'هل أنت متأكد أنك تريد\nتسجيل الخروج؟',
      'yes': 'نعم',
      'no': 'لا',
      'save_changes': 'حفظ التغييرات',
      'first_name': 'الاسم الأول',
      'last_name': 'اسم العائلة',
      'username': 'اسم المستخدم',
      'email': 'البريد الإلكتروني',
      'phone_number': 'رقم الهاتف',
      'profile_updated': 'تم تحديث الملف الشخصي بنجاح',
      'error_occurred': 'حدث خطأ',
      'choose_image': 'اختر صورة',
      'gallery': 'المعرض',
      'camera': 'الكاميرا',
      'required_field': 'هذا الحقل مطلوب',
      'invalid_email': 'الرجاء إدخال بريد إلكتروني صحيح',
      'invalid_phone': 'الرجاء إدخال رقم هاتف صحيح',
    },
  };

  static String tr(BuildContext context, String key) {
    final locale = Localizations.localeOf(context).languageCode;
    return _translations[locale]?[key] ?? _translations['en']?[key] ?? key;
  }
}
