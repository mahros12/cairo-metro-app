import 'package:cairo_metro_app/controllers/user_controller.dart';
import 'package:cairo_metro_app/data/metro_network.dart';
import 'package:cairo_metro_app/models/route_step.dart';
import 'package:cairo_metro_app/models/station.dart';
import 'package:cairo_metro_app/services/maps_service.dart';
import 'package:cairo_metro_app/services/place_search_service.dart';
import 'package:cairo_metro_app/services/routing_service.dart';
import 'package:cairo_metro_app/utils/metro_theme.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class RouteController extends GetxController {
  late final MetroNetwork network;
  late final RoutingService routingService;

  final Rx<Station?> originStation = Rx<Station?>(null);
  final Rx<Station?> destinationStation = Rx<Station?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isLocating = false.obs;
  final RxMap<String, List<Station>> tripOptions = <String, List<Station>>{}.obs;
  
  // Destination by place information
  final RxString selectedPlaceName = ''.obs;
  final RxDouble placeDistanceKm = 0.0.obs;

  // Option selection: 'shortest' or 'leastTransitions'
  final RxString selectedOption = 'shortest'.obs;
  final RxString errorMessage = ''.obs;

  RouteController({MetroNetwork? customNetwork}) {
    network = customNetwork ?? MetroNetwork();
    network.buildNetwork();
    routingService = RoutingService(network);
  }

  @override
  void onInit() {
    super.onInit();
    // Provide default initial selection for immediate preview
    final helwan = network.findStationByName('Helwan');
    final opera = network.findStationByName('Opera');
    if (helwan != null && opera != null) {
      originStation.value = helwan;
      destinationStation.value = opera;
      calculateRoutes();
    }
  }

  List<Station> get allStations => network.allStations;

  void setOrigin(Station? station) {
    originStation.value = station;
    errorMessage.value = '';
    if (originStation.value != null && destinationStation.value != null) {
      calculateRoutes();
    } else {
      tripOptions.clear();
    }
  }

  bool get canCalculateRoute =>
      originStation.value != null &&
      destinationStation.value != null &&
      originStation.value!.id != destinationStation.value!.id;

  Future<void> useCurrentLocation() async {
    isLocating.value = true;
    try {
      // 1. Check if device location service is enabled
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (Get.context != null) {
          Get.snackbar(
            'Location Service Disabled',
            'Please turn on GPS/Location services on your device.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFE11D48),
            colorText: Colors.white,
            icon: const Icon(Icons.location_off_rounded, color: Colors.white),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          );
        }
        return;
      }

      // 2. Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (Get.context != null) {
            Get.snackbar(
              'Permission Denied',
              'Location permission is required to detect your nearest station.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: const Color(0xFFE11D48),
              colorText: Colors.white,
              icon: const Icon(Icons.location_disabled_rounded, color: Colors.white),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 3),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (Get.context != null) {
          Get.snackbar(
            'Permission Blocked',
            'Location permission is permanently denied. Please allow it in settings.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFE11D48),
            colorText: Colors.white,
            icon: const Icon(Icons.settings_rounded, color: Colors.white),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          );
        }
        return;
      }

      // 3. Query current GPS coordinates
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 6),
          ),
        );
      } catch (_) {
        // Fallback to last known position if current request timed out
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        if (Get.context != null) {
          Get.snackbar(
            'GPS Signal Lost',
            'Unable to acquire current GPS coordinates. Please try again.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFE11D48),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
          );
        }
        return;
      }

      // 4. Calculate nearest station to user's real GPS position
      final result = PlaceSearchService.findNearestStationToCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
        placeName: 'My Location',
        network: network,
      );

      if (result != null) {
        setOrigin(result.station);
        if (Get.context != null) {
          Get.snackbar(
            'Nearest Station Detected',
            'Closest: ${result.station.name} (${result.distanceKm} km away)',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF0F172A),
            colorText: Colors.white,
            icon: const Icon(Icons.my_location_rounded, color: Color(0xFF10B981)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          );
        }
      } else {
        if (Get.context != null) {
          Get.snackbar(
            'Out of Range',
            'No Cairo metro stations found near your current location.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFE11D48),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
          );
        }
      }
    } catch (e) {
      if (Get.context != null) {
        Get.snackbar(
          'Location Error',
          'Failed to determine location: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFE11D48),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      isLocating.value = false;
    }
  }

  void setDestination(Station? station) {
    destinationStation.value = station;
    selectedPlaceName.value = '';
    placeDistanceKm.value = 0.0;
    errorMessage.value = '';
    if (originStation.value != null && destinationStation.value != null) {
      calculateRoutes();
    } else {
      tripOptions.clear();
    }
  }

  /// Calculates the minimum distance to all metro stations from a given [place]
  /// and automatically sets the closest station as the destination.
  void setDestinationFromPlace(PlaceItem place) {
    final result = PlaceSearchService.findNearestStationToPlace(
      place: place,
      network: network,
    );

    if (result != null) {
      destinationStation.value = result.station;
      selectedPlaceName.value = place.name;
      placeDistanceKm.value = result.distanceKm;
      errorMessage.value = '';

      if (originStation.value != null && destinationStation.value != null) {
        calculateRoutes();
      }

      if (Get.context != null) {
        Get.snackbar(
          'Nearest Station Found',
          'Closest to ${place.name}: ${result.station.name} (${result.distanceKm} km)',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF0F172A),
          colorText: Colors.white,
          icon: const Icon(Icons.place_rounded, color: Color(0xFF10B981)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  /// Opens Google Maps with turn-by-turn directions from user's location to the origin station
  Future<void> openGoogleMapsForOrigin() async {
    if (originStation.value != null) {
      await MapsService.openDirectionsToStation(originStation.value!);
    }
  }

  void swapStations() {
    final temp = originStation.value;
    originStation.value = destinationStation.value;
    destinationStation.value = temp;
    errorMessage.value = '';
    if (originStation.value != null && destinationStation.value != null) {
      calculateRoutes();
    }
  }

  void selectOption(String optionKey) {
    if (optionKey == 'shortest' || optionKey == 'leastTransitions' || optionKey == 'leastTransfers') {
      selectedOption.value = optionKey;
    }
  }

  void selectShortest() {
    selectedOption.value = 'shortest';
  }

  void selectLeastTransitions() {
    selectedOption.value = 'leastTransitions';
  }

  bool get isShortestSelected => selectedOption.value == 'shortest';
  
  bool get isLeastTransitionsSelected =>
      selectedOption.value == 'leastTransitions' || selectedOption.value == 'leastTransfers';

  bool get routesAreIdentical {
    final s = tripOptions['shortest'];
    final lt = tripOptions['leastTransitions'] ?? tripOptions['leastTransfers'];
    if (s == null || lt == null || s.isEmpty || lt.isEmpty) return false;
    return const ListEquality().equals(s, lt);
  }

  void calculateRoutes() {
    if (originStation.value == null || destinationStation.value == null) {
      errorMessage.value = 'Please select both origin and destination stations.';
      tripOptions.clear();
      return;
    }

    if (originStation.value!.id == destinationStation.value!.id) {
      errorMessage.value = 'Origin and destination cannot be the same station.';
      tripOptions.clear();
      return;
    }

    errorMessage.value = '';
    isLoading.value = true;

    try {
      final routes = routingService.generateTripOptions(
        start: originStation.value!,
        destination: destinationStation.value!,
      );

      tripOptions.assignAll(routes);

      // Maintain selection if previously chose leastTransitions, otherwise default to shortest
      if (selectedOption.value != 'leastTransitions' && selectedOption.value != 'leastTransfers') {
        selectedOption.value = 'shortest';
      }
    } catch (e) {
      errorMessage.value = 'Failed to calculate route: $e';
      tripOptions.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Gets the active path according to the currently selected option
  List<Station> get currentPath {
    if (selectedOption.value == 'leastTransitions' || selectedOption.value == 'leastTransfers') {
      return tripOptions['leastTransitions'] ?? tripOptions['leastTransfers'] ?? [];
    }
    return tripOptions['shortest'] ?? tripOptions['primary'] ?? [];
  }

  /// Resolves the train direction (terminus) for a specific line leg
  String resolveDirection({
    required int line,
    required Station fromStation,
    required Station toStation,
    List<Station> remainingStationsOnLine = const [],
  }) {
    if (line == 1) {
      final iFrom = network.line1Names.indexOf(fromStation.name);
      final iTo = network.line1Names.indexOf(toStation.name);
      if (iFrom != -1 && iTo != -1) {
        return iTo < iFrom ? 'Helwan direction' : 'New El-Marg direction';
      }
      return 'Helwan direction';
    }

    if (line == 2) {
      final iFrom = network.line2Names.indexOf(fromStation.name);
      final iTo = network.line2Names.indexOf(toStation.name);
      if (iFrom != -1 && iTo != -1) {
        return iTo < iFrom ? 'El Mounib direction' : 'Shubra El-Kheima direction';
      }
      return 'El Mounib direction';
    }

    if (line == 3) {
      // Check if path heads into North branch (Rod El Farag Corridor)
      if (remainingStationsOnLine.any((s) => network.line3North.contains(s.name))) {
        return 'Rod El Farag Corridor direction';
      }
      // Check if path heads into South branch (Cairo University)
      if (remainingStationsOnLine.any((s) => network.line3South.contains(s.name))) {
        return 'Cairo University direction';
      }

      // Check within Trunk
      final iFrom = network.line3Trunk.indexOf(fromStation.name);
      final iTo = network.line3Trunk.indexOf(toStation.name);
      if (iFrom != -1 && iTo != -1) {
        if (iTo < iFrom) {
          return 'Adly Mansour direction';
        } else {
          return 'Cairo University direction';
        }
      }

      if (network.line3North.contains(fromStation.name) ||
          network.line3South.contains(fromStation.name)) {
        return 'Adly Mansour direction';
      }

      return 'Adly Mansour direction';
    }

    return '';
  }

  /// Transforms any Station path into detailed RouteSteps
  /// computing incoming lines, outgoing lines, line transitions, and train directions.
  List<RouteStep> computeStepsFor(List<Station> path) {
    if (path.isEmpty) return [];

    if (path.length == 1) {
      return [
        RouteStep(
          station: path.first,
          stepIndex: 1,
          isOrigin: true,
          isDestination: true,
          outgoingLine: path.first.lines.isNotEmpty ? path.first.lines.first : 1,
        )
      ];
    }

    // Determine the active line connecting each consecutive station pair
    final linesBetween = <int>[];
    for (int i = 0; i < path.length - 1; i++) {
      final current = path[i];
      final next = path[i + 1];
      final shared = current.lines.toSet().intersection(next.lines.toSet());

      if (i > 0 && shared.contains(linesBetween[i - 1])) {
        linesBetween.add(linesBetween[i - 1]);
      } else if (shared.isNotEmpty) {
        linesBetween.add(shared.first);
      } else {
        linesBetween.add(current.lines.isNotEmpty ? current.lines.first : 1);
      }
    }

    // Build the list of RouteStep objects
    final steps = <RouteStep>[];
    for (int i = 0; i < path.length; i++) {
      final isOrigin = (i == 0);
      final isDestination = (i == path.length - 1);
      final incomingLine = isOrigin ? null : linesBetween[i - 1];
      final outgoingLine = isDestination ? null : linesBetween[i];
      final isTransfer = (incomingLine != null &&
          outgoingLine != null &&
          incomingLine != outgoingLine);

      String? direction;
      if (isOrigin && outgoingLine != null && path.length > 1) {
        final remainingOnLine = <Station>[];
        for (int k = 1; k < path.length; k++) {
          if (linesBetween[k - 1] == outgoingLine) {
            remainingOnLine.add(path[k]);
          } else {
            break;
          }
        }
        direction = resolveDirection(
          line: outgoingLine,
          fromStation: path[0],
          toStation: path[1],
          remainingStationsOnLine: remainingOnLine,
        );
      } else if (isTransfer && i + 1 < path.length) {
        final remainingOnLine = <Station>[];
        for (int k = i + 1; k < path.length; k++) {
          if (linesBetween[k - 1] == outgoingLine) {
            remainingOnLine.add(path[k]);
          } else {
            break;
          }
        }
        direction = resolveDirection(
          line: outgoingLine,
          fromStation: path[i],
          toStation: path[i + 1],
          remainingStationsOnLine: remainingOnLine,
        );
      }

      steps.add(
        RouteStep(
          station: path[i],
          stepIndex: i + 1,
          incomingLine: incomingLine,
          outgoingLine: outgoingLine,
          isOrigin: isOrigin,
          isDestination: isDestination,
          isTransfer: isTransfer,
          transferFromLine: isTransfer ? incomingLine : null,
          transferToLine: isTransfer ? outgoingLine : null,
          direction: direction,
        ),
      );
    }

    return steps;
  }

  List<RouteStep> get currentRouteSteps => computeStepsFor(currentPath);

  String get initialDirection {
    final steps = currentRouteSteps;
    if (steps.isNotEmpty && steps.first.direction != null) {
      return steps.first.direction!;
    }
    return '';
  }

  int get stationCount => currentPath.length;

  int get transferCount => currentRouteSteps.where((step) => step.isTransfer).length;

  String get estimatedDuration =>
      MetroTheme.calculateEstimatedTime(stationCount, transferCount);

  int get ticketFare {
    if (Get.isRegistered<UserController>()) {
      return Get.find<UserController>().calculateUserFare(stationCount);
    }
    return MetroTheme.calculateFare(stationCount);
  }

  int getStationsCountFor(String optionKey) {
    return tripOptions[optionKey]?.length ?? 0;
  }

  int getTransfersCountFor(String optionKey) {
    final path = tripOptions[optionKey] ?? [];
    return computeStepsFor(path).where((s) => s.isTransfer).length;
  }
}