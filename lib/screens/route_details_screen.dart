import 'package:cairo_metro_app/controllers/route_controller.dart';
import 'package:cairo_metro_app/controllers/theme_controller.dart';
import 'package:cairo_metro_app/utils/metro_theme.dart';
import 'package:cairo_metro_app/widgets/route_timeline_view.dart';
import 'package:cairo_metro_app/widgets/trip_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RouteDetailsScreen extends StatelessWidget {
  RouteDetailsScreen({super.key});

  final RouteController controller = Get.find<RouteController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = ThemeController.to.isDarkMode.value;
      final isDark = ThemeController.to.isDarkMode.value;
      return Scaffold(
        backgroundColor: MetroTheme.background,
        appBar: AppBar(
          backgroundColor: MetroTheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: MetroTheme.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Obx(() {
            final origin = controller.originStation.value?.name ?? 'Start';
            final destination = controller.destinationStation.value?.name ?? 'End';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$origin → $destination',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: MetroTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Route & Trip Details',
                  style: TextStyle(
                    fontSize: 11,
                    color: MetroTheme.textSecondary,
                  ),
                ),
              ],
            );
          }),
          actions: [
            IconButton(
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: isDark ? const Color(0xFFFBBF24) : MetroTheme.textSecondary,
              ),
              tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              onPressed: () => ThemeController.to.toggleTheme(),
            ),
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: MetroTheme.textPrimary),
              tooltip: 'Recalculate Route',
              onPressed: () => controller.calculateRoutes(),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: MetroTheme.dividerColor),
          ),
        ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Trip Information & Option Switcher (Shortest Path vs Least Transitions)
            TripSummaryCard(),

            const SizedBox(height: 4),

            // Route Timeline
            Expanded(
              child: RouteTimelineView(),
            ),
          ],
        ),
      ),
    );
    });
  }
}
