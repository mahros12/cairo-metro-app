import 'package:cairo_metro_app/controllers/route_controller.dart';
import 'package:cairo_metro_app/controllers/theme_controller.dart';
import 'package:cairo_metro_app/utils/metro_theme.dart';
import 'package:cairo_metro_app/widgets/route_timeline_view.dart';

import 'package:cairo_metro_app/widgets/trip_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widgets/station_selector_header.dart';

class RouteScreen extends StatelessWidget {
  RouteScreen({super.key});

  final RouteController controller = Get.put(RouteController());

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
          centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: MetroTheme.line1Color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.subway_rounded,
                color: MetroTheme.line1Color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cairo Metro Navigator',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: MetroTheme.textPrimary,
                  ),
                ),
                Text(
                  'Line 1 • Line 2 • Line 3',
                  style: TextStyle(
                    fontSize: 11,
                    color: MetroTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Quick Sample Route Presets Menu
          PopupMenuButton<String>(
            icon: Icon(Icons.tune_rounded, color: MetroTheme.textPrimary),
            tooltip: 'Sample Routes',
            onSelected: (preset) => _applyPreset(preset),
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  'Sample Test Routes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: MetroTheme.textSecondary,
                  ),
                ),
              ),
              const PopupMenuItem(
                value: 'helwan_opera',
                child: Text('Helwan → Opera (L1 → L2 via Sadat)'),
              ),
              const PopupMenuItem(
                value: 'maadi_mansour',
                child: Text('Maadi → Adly Mansour (L1 → L3 via Nasser)'),
              ),
              const PopupMenuItem(
                value: 'two_transfers',
                child: Text('Dar El-Salam → Sudan (2 Transfers)'),
              ),
              const PopupMenuItem(
                value: 'line3_branch',
                child: Text('Adly Mansour → Rod El Farag Corridor (L3)'),
              ),
            ],
          ),
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
            // Top station selection panel
            StationSelectorHeader(),

            // Trip metrics & option picker
            TripSummaryCard(),

            // Timeline displaying the route with color transitions
            Expanded(
              child: RouteTimelineView(),
            ),
          ],
        ),
      ),
    );
    });
  }

  void _applyPreset(String preset) {
    switch (preset) {
      case 'helwan_opera':
        controller.setOrigin(controller.network.findStationByName('Helwan'));
        controller.setDestination(controller.network.findStationByName('Opera'));
        break;
      case 'maadi_mansour':
        controller.setOrigin(controller.network.findStationByName('Maadi'));
        controller.setDestination(controller.network.findStationByName('Adly Mansour'));
        break;
      case 'two_transfers':
        controller.setOrigin(controller.network.findStationByName('Dar El-Salam'));
        controller.setDestination(controller.network.findStationByName('Sudan'));
        break;
      case 'line3_branch':
        controller.setOrigin(controller.network.findStationByName('Adly Mansour'));
        controller.setDestination(controller.network.findStationByName('Rod El Farag Corridor'));
        break;
    }
  }
}
