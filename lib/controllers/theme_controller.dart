import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static const String _keyDarkMode = 'cairo_metro_dark_mode';

  final RxBool isDarkMode = false.obs;

  static ThemeController get to {
    if (Get.isRegistered<ThemeController>()) {
      return Get.find<ThemeController>();
    }
    return Get.put(ThemeController(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    loadThemeFromStorage();
  }

  Future<void> loadThemeFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDark = prefs.getBool(_keyDarkMode);
      if (savedDark != null) {
        isDarkMode.value = savedDark;
        Get.changeThemeMode(savedDark ? ThemeMode.dark : ThemeMode.light);
      }
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    isDarkMode.value = !isDarkMode.value;
    final mode = isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
    Get.changeThemeMode(mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDarkMode, isDarkMode.value);
    } catch (_) {}
  }

  ThemeMode get themeMode => isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
}
