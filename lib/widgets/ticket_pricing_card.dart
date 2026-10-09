import 'package:cairo_metro_app/controllers/user_controller.dart';
import 'package:cairo_metro_app/controllers/theme_controller.dart';
import 'package:cairo_metro_app/utils/metro_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TicketPricingCard extends StatefulWidget {
  const TicketPricingCard({super.key});

  @override
  State<TicketPricingCard> createState() => _TicketPricingCardState();
}

class _TicketPricingCardState extends State<TicketPricingCard> {
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<UserController>()) {
      final user = Get.find<UserController>();
      switch (user.category) {
        case UserCategory.normal:
          _selectedCategoryIndex = 0;
          break;
        case UserCategory.over60:
          _selectedCategoryIndex = 1;
          break;
        case UserCategory.specialNeeds:
          _selectedCategoryIndex = 2;
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final _ = ThemeController.to.isDarkMode.value;
    final hasUser = Get.isRegistered<UserController>();
    final user = hasUser ? Get.find<UserController>() : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MetroTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MetroTheme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: MetroTheme.isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with Icon & Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.confirmation_number_rounded,
                  color: Color(0xFF059669),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Official Ticket Pricing',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: MetroTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '3 Passenger Fare Categories',
                      style: TextStyle(
                        fontSize: 11,
                        color: MetroTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (user != null)
                Obx(() {
                  final activeCategory = user.category;
                  String label = 'Normal';
                  Color chipColor = const Color(0xFF059669);
                  if (activeCategory == UserCategory.specialNeeds) {
                    label = 'Special Needs (5 EGP)';
                    chipColor = const Color(0xFF0284C7);
                  } else if (activeCategory == UserCategory.over60) {
                    label = 'Over 60 (Half)';
                    chipColor = const Color(0xFFD97706);
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: chipColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: chipColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'Active: $label',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: chipColor,
                      ),
                    ),
                  );
                }),
            ],
          ),
          const SizedBox(height: 14),

          // 3 Category Tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: MetroTheme.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildCategoryTab(
                  index: 0,
                  title: 'Normal',
                  icon: Icons.person_outline_rounded,
                  activeColor: const Color(0xFF059669),
                ),
                const SizedBox(width: 4),
                _buildCategoryTab(
                  index: 1,
                  title: 'Over 60',
                  icon: Icons.elderly_rounded,
                  activeColor: const Color(0xFFD97706),
                ),
                const SizedBox(width: 4),
                _buildCategoryTab(
                  index: 2,
                  title: 'Special Needs',
                  icon: Icons.accessible_rounded,
                  activeColor: const Color(0xFF0284C7),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Active Category Pricing Details
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _buildCategoryDetails(_selectedCategoryIndex, user),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab({
    required int index,
    required String title,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _selectedCategoryIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategoryIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? MetroTheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
            border: isSelected
                ? Border.all(color: activeColor.withValues(alpha: 0.35))
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? activeColor : MetroTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? activeColor : MetroTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDetails(int index, UserController? user) {
    if (index == 0) {
      // Normal Ticket
      return Column(
        key: const ValueKey(0),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Standard Passenger Fare',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: MetroTheme.textPrimary),
              ),
              const Spacer(),
              _buildTierBadge('Zone-Based', const Color(0xFF059669)),
            ],
          ),
          const SizedBox(height: 10),
          _buildFareTierGrid(
            tiers: const [
              {'stations': '1 - 9', 'price': '10 EGP', 'sub': 'Zone 1'},
              {'stations': '10 - 16', 'price': '12 EGP', 'sub': 'Zone 2'},
              {'stations': '17 - 23', 'price': '15 EGP', 'sub': 'Zone 3'},
              {'stations': '23+', 'price': '20 EGP', 'sub': 'Zone 4'},
            ],
            color: const Color(0xFF059669),
          ),
        ],
      );
    } else if (index == 1) {
      // Over 60 (Half Price)
      return Column(
        key: const ValueKey(1),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Senior Citizen (Over 60)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: MetroTheme.textPrimary),
              ),
              const Spacer(),
              _buildTierBadge('50% Off Half Price', const Color(0xFFD97706)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Eligible for passengers aged 60 and above with valid National ID.',
            style: TextStyle(fontSize: 11, color: MetroTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          _buildFareTierGrid(
            tiers: const [
              {'stations': '1 - 9', 'price': '5 EGP', 'sub': 'Zone 1'},
              {'stations': '10 - 16', 'price': '6 EGP', 'sub': 'Zone 2'},
              {'stations': '17 - 23', 'price': '8 EGP', 'sub': 'Zone 3'},
              {'stations': '23+', 'price': '10 EGP', 'sub': 'Zone 4'},
            ],
            color: const Color(0xFFD97706),
          ),
        ],
      );
    } else {
      // Special Needs (Fixed 5 EGP)
      return Column(
        key: const ValueKey(2),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Special Needs (ذوي الهمم)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: MetroTheme.textPrimary),
              ),
              const Spacer(),
              _buildTierBadge('Fixed 5 EGP', const Color(0xFF0284C7)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: MetroTheme.isDark
                  ? const Color(0xFF0284C7).withValues(alpha: 0.15)
                  : const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.accessible_forward_rounded,
                    color: Color(0xFF0284C7),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '5 EGP Flat Fare',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: MetroTheme.isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Valid for any trip distance, any number of stations, and all metro lines.',
                        style: TextStyle(
                          fontSize: 11,
                          color: MetroTheme.isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: MetroTheme.isDark
                  ? const Color(0xFFD97706).withValues(alpha: 0.15)
                  : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: Color(0xFFD97706)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Priority: If passenger is over 60 & special needs, the 5 EGP fare takes precedence.',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: MetroTheme.isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildTierBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildFareTierGrid({
    required List<Map<String, String>> tiers,
    required Color color,
  }) {
    return Row(
      children: tiers.map((tier) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: MetroTheme.cardSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: MetroTheme.dividerColor),
            ),
            child: Column(
              children: [
                Text(
                  tier['stations']!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: MetroTheme.textSecondary,
                  ),
                ),
                Text(
                  'stations',
                  style: TextStyle(fontSize: 9, color: MetroTheme.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  tier['price']!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  tier['sub']!,
                  style: TextStyle(fontSize: 9, color: MetroTheme.textMuted),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
