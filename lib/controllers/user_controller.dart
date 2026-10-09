import 'package:cairo_metro_app/utils/metro_theme.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserCategory {
  normal,
  over60,
  specialNeeds,
}

class UserController extends GetxController {
  static const String _keyName = 'cairo_metro_user_name';
  static const String _keyAge = 'cairo_metro_user_age';
  static const String _keySpecial = 'cairo_metro_user_special_needs';
  static const String _keyLoggedIn = 'cairo_metro_user_logged_in';

  final RxString userName = ''.obs;
  final RxInt userAge = 0.obs;
  final RxBool isSpecialNeeds = false.obs;
  final RxBool isLoggedIn = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserFromStorage();
  }

  /// Extracts the user's first name (e.g. "Ahmed Mohamed" -> "Ahmed")
  String get firstName {
    final trimmed = userName.value.trim();
    if (trimmed.isEmpty) return 'Traveler';
    return trimmed.split(' ').first;
  }

  /// Determines the user's fare category.
  /// RULE: If the user is over 60 and special needs is true,
  /// priority is given to the 5 EGP special needs price!
  UserCategory get category {
    if (isSpecialNeeds.value) {
      return UserCategory.specialNeeds;
    }
    if (userAge.value > 60) {
      return UserCategory.over60;
    }
    return UserCategory.normal;
  }

  String get categoryLabel {
    switch (category) {
      case UserCategory.specialNeeds:
        return 'Special Needs (ذوي الهمم)';
      case UserCategory.over60:
        return 'Senior Citizen (Over 60)';
      case UserCategory.normal:
        return 'Standard Passenger';
    }
  }

  String get categoryFareDescription {
    switch (category) {
      case UserCategory.specialNeeds:
        return 'Fixed 5 EGP for all zones';
      case UserCategory.over60:
        return 'Half price (50% discount)';
      case UserCategory.normal:
        return 'Standard zone fare';
    }
  }

  /// Calculates the ticket fare for this specific user.
  /// - Special needs: 5 EGP fixed (takes priority over age > 60).
  /// - Over 60: Half price.
  /// - Normal: Standard zone tariff.
  int calculateUserFare(int stationCount) {
    if (stationCount <= 0) return 0;
    
    // Priority 1: Special Needs (5 EGP fixed)
    if (isSpecialNeeds.value) {
      return 5;
    }

    final normalFare = MetroTheme.calculateFare(stationCount);

    // Priority 2: Over 60 (Half price)
    if (userAge.value > 60) {
      return MetroTheme.calculateOver60Fare(stationCount);
    }

    // Default: Normal price
    return normalFare;
  }

  /// Loads saved user details from SharedPreferences local storage.
  /// Returns `true` if an active logged-in user exists, `false` otherwise.
  Future<bool> loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLoggedIn = prefs.getBool(_keyLoggedIn) ?? false;
      final savedName = prefs.getString(_keyName) ?? '';

      if (savedLoggedIn && savedName.trim().isNotEmpty) {
        userName.value = savedName.trim();
        userAge.value = prefs.getInt(_keyAge) ?? 25;
        isSpecialNeeds.value = prefs.getBool(_keySpecial) ?? false;
        isLoggedIn.value = true;
        return true;
      }
    } catch (_) {
      // In case of platform exception during storage access
    }
    isLoggedIn.value = false;
    return false;
  }

  /// Sets user info in memory AND persists it into local storage.
  Future<void> setUser({
    required String name,
    required int age,
    required bool specialNeeds,
  }) async {
    userName.value = name.trim();
    userAge.value = age;
    isSpecialNeeds.value = specialNeeds;
    isLoggedIn.value = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyName, userName.value);
      await prefs.setInt(_keyAge, userAge.value);
      await prefs.setBool(_keySpecial, isSpecialNeeds.value);
      await prefs.setBool(_keyLoggedIn, true);
    } catch (_) {}
  }

  /// Clears user info from memory AND deletes it from local storage.
  Future<void> clearUser() async {
    reset();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyName);
      await prefs.remove(_keyAge);
      await prefs.remove(_keySpecial);
      await prefs.setBool(_keyLoggedIn, false);
    } catch (_) {}
  }

  void reset() {
    userName.value = '';
    userAge.value = 0;
    isSpecialNeeds.value = false;
    isLoggedIn.value = false;
  }
}
