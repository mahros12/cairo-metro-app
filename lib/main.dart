import 'package:cairo_metro_app/controllers/route_controller.dart';
import 'package:cairo_metro_app/controllers/theme_controller.dart';
import 'package:cairo_metro_app/controllers/user_controller.dart';
import 'package:cairo_metro_app/screens/home_screen.dart';
import 'package:cairo_metro_app/screens/login_screen.dart';
import 'package:cairo_metro_app/services/coordinate_service.dart';
import 'package:cairo_metro_app/utils/metro_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Injects services and controllers globally
  Get.put(CoordinateService(), permanent: true);
  final themeController = Get.put(ThemeController(), permanent: true);
  final userController = Get.put(UserController(), permanent: true);
  Get.put(RouteController(), permanent: true);

  // Check if a saved user profile already exists in local storage
  final bool isLoggedIn = await userController.loadUserFromStorage();
  await themeController.loadThemeFromStorage();

  runApp(
    GetMaterialApp(
      title: 'Cairo Metro',
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.cupertino,
      theme: MetroTheme.lightTheme,
      darkTheme: MetroTheme.darkTheme,
      themeMode: themeController.themeMode,
      home: isLoggedIn ? HomeScreen() : const LoginScreen(),
    ),
  );
}