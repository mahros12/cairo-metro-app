import 'package:cairo_metro_app/models/station.dart';
import 'package:cairo_metro_app/services/coordinate_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class MapsService {
  /// Launches Google Maps showing turn-by-turn directions from the user's
  /// current location to the target [station].
  static Future<bool> openDirectionsToStation(Station station) async {
    double? lat = station.latitude;
    double? lng = station.longitude;

    if (lat == null || lng == null) {
      if (Get.isRegistered<CoordinateService>()) {
        final coords = Get.find<CoordinateService>().coordinatesGrabber(station.id);
        if (coords != null) {
          lat = coords.lat;
          lng = coords.lng;
        }
      }
    }

    final Uri mapUri;
    if (lat != null && lng != null) {
      // Standard Google Maps Directions URL with GPS coordinates
      mapUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=walking');
    } else {
      // Fallback with named search query
      final encodedQuery = Uri.encodeComponent('${station.name} Metro Station, Cairo, Egypt');
      mapUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$encodedQuery&travelmode=walking');
    }

    try {
      final launched = await launchUrl(mapUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        // Try in-app/browser launch as fallback
        return await launchUrl(mapUri, mode: LaunchMode.platformDefault);
      }
      return true;
    } catch (e) {
      Get.snackbar(
        'Maps Error',
        'Could not open Google Maps: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1E293B),
        colorText: Colors.white,
      );
      return false;
    }
  }
}
