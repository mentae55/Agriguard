import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  bool _isArabic = false;
  bool get isArabic => _isArabic;

  Locale get currentLocale => _isArabic ? const Locale('ar') : const Locale('en');

  void toggleLanguage() {
    _isArabic = !_isArabic;
    notifyListeners();
  }
}
