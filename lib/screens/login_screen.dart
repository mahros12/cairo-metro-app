import 'package:cairo_metro_app/controllers/theme_controller.dart';
import 'package:cairo_metro_app/controllers/user_controller.dart';
import 'package:cairo_metro_app/screens/welcome_temp_screen.dart';
import 'package:cairo_metro_app/utils/metro_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  bool _isSpecialNeeds = false;

  final UserController _userController = Get.find<UserController>();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();
      final age = int.tryParse(_ageController.text.trim()) ?? 25;

      await _userController.setUser(
        name: name,
        age: age,
        specialNeeds: _isSpecialNeeds,
      );

      Get.off(
        () => const WelcomeTempScreen(),
        transition: Transition.fadeIn,
      );
    }
  }

  Future<void> _continueAsGuest() async {
    await _userController.setUser(
      name: 'Guest Passenger',
      age: 30,
      specialNeeds: false,
    );

    Get.off(
      () => const WelcomeTempScreen(),
      transition: Transition.fadeIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = ThemeController.to.isDarkMode.value;
      final isDark = ThemeController.to.isDarkMode.value;
      return Scaffold(
        backgroundColor: MetroTheme.background,
        body: SafeArea(
          child: Stack(
            children: [
              // Theme Toggle button top right
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    color: isDark ? const Color(0xFFFBBF24) : MetroTheme.textSecondary,
                  ),
                  tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                  onPressed: () => ThemeController.to.toggleTheme(),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Cairo Metro Logo Badge
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [MetroTheme.line1Color, MetroTheme.line2Color],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: MetroTheme.line1Color.withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.directions_subway_rounded,
                              size: 46,
                              color: Colors.white,
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),

                  // App Title & Tagline
                  Text(
                    'Cairo Metro',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: MetroTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Navigate Line 1, Line 2, and Line 3 with ease',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: MetroTheme.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Passenger Details Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: MetroTheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: MetroTheme.dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: MetroTheme.isDark ? 0.3 : 0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Passenger Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: MetroTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enter your info for accurate fare calculation',
                          style: TextStyle(
                            fontSize: 13,
                            color: MetroTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Name Field
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            hintText: 'e.g. Ahmed Mohamed',
                            prefixIcon: Icon(Icons.person_outline_rounded, color: MetroTheme.textSecondary),
                            filled: true,
                            fillColor: MetroTheme.inputFill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: MetroTheme.dividerColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: MetroTheme.dividerColor),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Age Field
                        TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            labelText: 'Age (Years)',
                            hintText: 'e.g. 62',
                            prefixIcon: Icon(Icons.cake_outlined, color: MetroTheme.textSecondary),
                            helperText: 'Ages over 60 receive 50% discount',
                            helperStyle: TextStyle(fontSize: 12, color: MetroTheme.textSecondary),
                            filled: true,
                            fillColor: MetroTheme.inputFill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: MetroTheme.dividerColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: MetroTheme.dividerColor),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your age';
                            }
                            final parsed = int.tryParse(value.trim());
                            if (parsed == null || parsed <= 0 || parsed > 120) {
                              return 'Please enter a valid age (1-120)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Special Needs Checkbox
                        Container(
                          decoration: BoxDecoration(
                            color: _isSpecialNeeds
                                ? (MetroTheme.isDark ? const Color(0xFF0369A1).withValues(alpha: 0.25) : const Color(0xFFE0F2FE))
                                : MetroTheme.inputFill,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _isSpecialNeeds
                                  ? const Color(0xFF0284C7)
                                  : MetroTheme.dividerColor,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: CheckboxListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              value: _isSpecialNeeds,
                              activeColor: const Color(0xFF0284C7),
                              checkColor: Colors.white,
                              secondary: Icon(
                                Icons.accessible_rounded,
                                color: _isSpecialNeeds ? const Color(0xFF0284C7) : MetroTheme.textSecondary,
                              ),
                              title: Text(
                                'Special Needs (ذوي الهمم)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: MetroTheme.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                'Priority fixed 5 EGP fare across all zones',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: MetroTheme.textSecondary,
                                ),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _isSpecialNeeds = val ?? false;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Continue Button
                        ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MetroTheme.line1Color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Continue as Guest Button
                        OutlinedButton(
                          onPressed: _continueAsGuest,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MetroTheme.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: MetroTheme.dividerColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Continue as Guest',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Metro lines color dots badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLineDot(MetroTheme.line1Color, 'Line 1'),
                      const SizedBox(width: 16),
                      _buildLineDot(MetroTheme.line2Color, 'Line 2'),
                      const SizedBox(width: 16),
                      _buildLineDot(MetroTheme.line3Color, 'Line 3'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);
    });
  }

  Widget _buildLineDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: MetroTheme.textSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
