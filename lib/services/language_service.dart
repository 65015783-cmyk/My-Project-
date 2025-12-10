import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  Locale _locale = const Locale('th', 'TH');

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  LanguageService() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey);
      
      if (languageCode != null) {
        if (languageCode == 'th') {
          _locale = const Locale('th', 'TH');
        } else if (languageCode == 'en') {
          _locale = const Locale('en', '');
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading language: $e');
    }
  }

  Future<void> setLanguage(Locale locale) async {
    try {
      _locale = locale;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, locale.languageCode);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }

  Future<void> setThai() async {
    await setLanguage(const Locale('th', 'TH'));
  }

  Future<void> setEnglish() async {
    await setLanguage(const Locale('en', ''));
  }

  bool get isThai => _locale.languageCode == 'th';
  bool get isEnglish => _locale.languageCode == 'en';
}

