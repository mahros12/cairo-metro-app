import 'package:cairo_metro_app/controllers/route_controller.dart';
import 'package:cairo_metro_app/utils/metro_theme.dart';
import 'package:cairo_metro_app/widgets/route_timeline_tile.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RouteTimelineView extends StatelessWidget {
  final RouteController controller = Get.find<RouteController>();

  RouteTimelineView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Calculating best metro route...',
                  style: TextStyle(
                    fontSize: 14,
                    color: MetroTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final steps = controller.currentRouteSteps;

      if (steps.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: MetroTheme.cardSecondary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.map_rounded,
                    size: 48,
                    color: MetroTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Plan Your Metro Trip',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: MetroTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select an origin and destination station above to preview the route, transfers, and line transitions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: MetroTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        itemCount: steps.length,
        itemBuilder: (context, index) {
          return RouteTimelineTile(step: steps[index]);
        },
      );
    });
  }
}
