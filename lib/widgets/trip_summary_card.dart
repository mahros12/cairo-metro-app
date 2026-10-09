import 'package:cairo_metro_app/controllers/route_controller.dart';
import 'package:cairo_metro_app/controllers/user_controller.dart';
import 'package:cairo_metro_app/controllers/theme_controller.dart';
import 'package:cairo_metro_app/utils/metro_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TripSummaryCard extends StatelessWidget {
  final RouteController controller = Get.find<RouteController>();

  TripSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = ThemeController.to.isDarkMode.value;
      if (controller.currentPath.isEmpty) return const SizedBox.shrink();

      final isShortest = controller.isShortestSelected;
      final isLeastTransitions = controller.isLeastTransitionsSelected;
      final areIdentical = controller.routesAreIdentical;

      final shortestStations = controller.getStationsCountFor('shortest');
      final shortestTransfers = controller.getTransfersCountFor('shortest');

      final leastTransitionsStations = controller.getStationsCountFor('leastTransitions');
      final leastTransitionsTransfers = controller.getTransfersCountFor('leastTransitions');

      final currentStationCount = controller.stationCount;
      final currentTransferCount = controller.transferCount;
      final currentTime = controller.estimatedDuration;
      final currentFare = controller.ticketFare;

      String fareLabel = 'Fare';
      if (Get.isRegistered<UserController>()) {
        final user = Get.find<UserController>();
        if (user.category == UserCategory.specialNeeds) {
          fareLabel = 'Fare (Special)';
        } else if (user.category == UserCategory.over60) {
          fareLabel = 'Fare (Over 60)';
        }
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MetroTheme.surface,
          borderRadius: BorderRadius.circular(16),
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
          children: [
            // Two Route Options: Shortest Path vs Least Transitions
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: MetroTheme.inputFill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  // Option 1: Shortest Path
                  Expanded(
                    child: _buildOptionTab(
                      isSelected: isShortest,
                      title: 'Shortest Path',
                      icon: Icons.bolt_rounded,
                      activeColor: const Color(0xFF2563EB),
                      stations: shortestStations,
                      transfers: shortestTransfers,
                      onTap: () => controller.selectShortest(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Option 2: Least Transitions
                  Expanded(
                    child: _buildOptionTab(
                      isSelected: isLeastTransitions,
                      title: 'Least Transitions',
                      icon: Icons.swap_horizontal_circle_outlined,
                      activeColor: const Color(0xFF7C3AED),
                      stations: leastTransitionsStations,
                      transfers: leastTransitionsTransfers,
                      onTap: () => controller.selectLeastTransitions(),
                    ),
                  ),
                ],
              ),
            ),

            if (areIdentical)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 14, color: Colors.green.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Both options share the same optimal route',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // 4 Metrics for Selected Option
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem(
                  icon: Icons.alt_route_rounded,
                  label: 'Stations',
                  value: '$currentStationCount',
                  iconColor: const Color(0xFF3B82F6),
                ),
                _buildDivider(),
                _buildMetricItem(
                  icon: Icons.timer_outlined,
                  label: 'Est. Time',
                  value: currentTime,
                  iconColor: const Color(0xFFF59E0B),
                ),
                _buildDivider(),
                _buildMetricItem(
                  icon: Icons.swap_calls_rounded,
                  label: 'Transfers',
                  value: currentTransferCount == 0 ? 'Direct' : '$currentTransferCount',
                  iconColor: currentTransferCount == 0
                      ? const Color(0xFF10B981)
                      : const Color(0xFF8B5CF6),
                ),
                _buildDivider(),
                _buildMetricItem(
                  icon: Icons.confirmation_number_outlined,
                  label: fareLabel,
                  value: '$currentFare EGP',
                  iconColor: const Color(0xFF059669),
                ),
              ],
            ),

            if (controller.initialDirection.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: MetroTheme.inputFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: MetroTheme.dividerColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.explore_rounded, size: 16, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Boarding Train: ${controller.initialDirection}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: MetroTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildOptionTab({
    required bool isSelected,
    required String title,
    required IconData icon,
    required Color activeColor,
    required int stations,
    required int transfers,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? MetroTheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: activeColor.withValues(alpha: 0.35), width: 1.5)
              : Border.all(color: Colors.transparent, width: 1.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? activeColor : MetroTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? MetroTheme.textPrimary : MetroTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              '$stations stn • ${transfers == 0 ? 'Direct' : '$transfers trans'}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? activeColor : MetroTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 28,
      width: 1,
      color: MetroTheme.dividerColor,
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: MetroTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: MetroTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
