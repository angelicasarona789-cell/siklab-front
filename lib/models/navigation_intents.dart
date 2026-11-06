import 'package:flutter/foundation.dart';

class NavigationIntents extends ChangeNotifier {
  static final NavigationIntents _instance = NavigationIntents._();
  NavigationIntents._();
  factory NavigationIntents() => _instance;

  String? _practiceLanguage;
  String? _moduleLanguage;
  int? _navigateToTab;
  String? get practiceLanguage => _practiceLanguage;
  String? get moduleLanguage => _moduleLanguage;
  int? get targetTab => _navigateToTab;

  void openPracticeLanguage(String language) {
    _practiceLanguage = language;
    notifyListeners();
  }

  void openModuleLanguage(String language) {
    _moduleLanguage = language;
    notifyListeners();
  }

  void navigateToTab(int index) {
    _navigateToTab = index;
    notifyListeners();
  }

  String? consumePracticeLanguage() {
    final value = _practiceLanguage;
    _practiceLanguage = null;
    return value;
  }

  String? consumeModuleLanguage() {
    final value = _moduleLanguage;
    _moduleLanguage = null;
    return value;
  }

  int? consumeNavigateToTab() {
    final value = _navigateToTab;
    _navigateToTab = null;
    return value;
  }
}
