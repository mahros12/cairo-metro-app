import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cairo_metro_app/controllers/user_controller.dart';
import 'package:cairo_metro_app/screens/home_screen.dart';
import 'package:cairo_metro_app/utils/metro_theme.dart';

class WelcomeTempScreen extends StatefulWidget {
  const WelcomeTempScreen({super.key});

  @override
  State<WelcomeTempScreen> createState() => _WelcomeTempScreenState();
}

class _WelcomeTempScreenState extends State<WelcomeTempScreen> {
  Timer? _timer;
  final UserController _userController = Get.find<UserController>();

  @override
  void initState() {
    super.initState();
    // Auto transition to HomeScreen after 2.5 seconds
    _timer = Timer(const Duration(milliseconds: 2500), () {
      _goToHome();
    });
  }

  void _goToHome() {
    _timer?.cancel();
    Get.off(() => HomeScreen(), transition: Transition.fadeIn);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _userController.firstName;
    final category = _userController.category;
    final categoryLabel = _userController.categoryLabel;
    final fareDesc = _userController.categoryFareDescription;

    Color badgeColor;
    Color badgeBg;
    IconData badgeIcon;

    switch (category) {
      case UserCategory.specialNeeds:
        badgeColor = const Color(0xFF0284C7);
        badgeBg = const Color(0xFFE0F2FE);
        badgeIcon = Icons.accessible;
        break;
      case UserCategory.over60:
        badgeColor = const Color(0xFFD97706);
        badgeBg = const Color(0xFFFEF3C7);
        badgeIcon = Icons.elderly;
        break;
      case UserCategory.normal:
        badgeColor = const Color(0xFF059669);
        badgeBg = const Color(0xFFD1FAE5);
        badgeIcon = Icons.person;
        break;
    }

    return Scaffold(
      backgroundColor: MetroTheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Metro Icon Avatar
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [MetroTheme.line1Color, MetroTheme.line2Color],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: MetroTheme.line1Color.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.subway_rounded,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Greeting text
                Text(
                  "Hello, $firstName! 👋",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: MetroTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Welcome to Cairo Metro Navigator",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: MetroTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),

                // Passenger Category Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, color: badgeColor, size: 24),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            categoryLabel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                            ),
                          ),
                          Text(
                            fareDesc,
                            style: TextStyle(
                              fontSize: 12,
                              color: badgeColor.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Progress Indicator
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: MetroTheme.line1Color,
                  ),
                ),
                const SizedBox(height: 24),

                // Manual Continue Button
                TextButton.icon(
                  onPressed: _goToHome,
                  icon: const Text(
                    "Continue to Home",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: MetroTheme.line1Color,
                    ),
                  ),
                  label: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: MetroTheme.line1Color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
