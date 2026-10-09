import 'package:cairo_metro_app/controllers/route_controller.dart';
import 'package:cairo_metro_app/controllers/theme_controller.dart';
import 'package:cairo_metro_app/controllers/user_controller.dart';
import 'package:cairo_metro_app/data/metro_network.dart';
import 'package:cairo_metro_app/services/coordinate_service.dart';
import 'package:cairo_metro_app/services/nlp_search_service.dart';
import 'package:cairo_metro_app/services/place_search_service.dart';
import 'package:cairo_metro_app/services/routing_service.dart';
import 'package:cairo_metro_app/utils/metro_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    Get.put(CoordinateService());
  });

  test('MetroNetwork builds cleanly and allStations contains all lines', () {
    final network = MetroNetwork();
    expect(() => network.buildNetwork(), returnsNormally);

    final stations = network.allStations;
    expect(stations.isNotEmpty, isTrue);

    // Verify key interchange stations exist
    final sadat = network.findStationByName('Sadat');
    expect(sadat, isNotNull);
    expect(sadat!.lines.contains(1), isTrue);
    expect(sadat.lines.contains(2), isTrue);

    final attaba = network.findStationByName('Attaba');
    expect(attaba, isNotNull);
    expect(attaba!.lines.contains(2), isTrue);
    expect(attaba.lines.contains(3), isTrue);

    // Verify Tawfikiya station key works
    final tawfikiya = network.findStationByName('El-Tawfikiya');
    expect(tawfikiya, isNotNull);
  });

  test('RoutingService calculates route on single line without transfers', () {
    final network = MetroNetwork();
    network.buildNetwork();
    final routingService = RoutingService(network);

    final start = network.findStationByName('Helwan')!;
    final end = network.findStationByName('Maadi')!;

    final path = routingService.findShortestPath(start, end);
    expect(path.isNotEmpty, isTrue);
    expect(path.first.name, equals('Helwan'));
    expect(path.last.name, equals('Maadi'));
  });

  test('RoutingService and RouteController provide selectable Shortest Path and Least Transitions', () {
    final controller = RouteController();
    final helwan = controller.network.findStationByName('Helwan')!;
    final opera = controller.network.findStationByName('Opera')!;

    controller.setOrigin(helwan);
    controller.setDestination(opera);

    // Both options must be present
    expect(controller.tripOptions.containsKey('shortest'), isTrue);
    expect(controller.tripOptions.containsKey('leastTransitions'), isTrue);

    // Default selection is shortest
    expect(controller.isShortestSelected, isTrue);

    // Switch to Least Transitions
    controller.selectLeastTransitions();
    expect(controller.isLeastTransitionsSelected, isTrue);
    expect(controller.currentPath.isNotEmpty, isTrue);

    // Switch back to Shortest
    controller.selectShortest();
    expect(controller.isShortestSelected, isTrue);
    expect(controller.currentPath.isNotEmpty, isTrue);
  });

  test('RouteController computes RouteSteps and detects transfer at Sadat (Line 1 to Line 2)', () {
    final controller = RouteController();
    final helwan = controller.network.findStationByName('Helwan')!;
    final opera = controller.network.findStationByName('Opera')!;

    controller.setOrigin(helwan);
    controller.setDestination(opera);

    final steps = controller.currentRouteSteps;
    expect(steps.isNotEmpty, isTrue);
    expect(steps.first.station.name, equals('Helwan'));
    expect(steps.first.isOrigin, isTrue);
    expect(steps.last.station.name, equals('Opera'));
    expect(steps.last.isDestination, isTrue);

    // Verify Sadat is marked as an interchange station
    final sadatStep = steps.firstWhere((s) => s.station.name == 'Sadat');
    expect(sadatStep.isTransfer, isTrue);
    expect(sadatStep.transferFromLine, equals(1));
    expect(sadatStep.transferToLine, equals(2));

    // Verify line continuity: before Sadat is Line 1, after Sadat is Line 2
    final sadatIndex = steps.indexOf(sadatStep);
    expect(steps[sadatIndex - 1].outgoingLine, equals(1));
    expect(steps[sadatIndex + 1].incomingLine, equals(2));
  });

  test('RouteController computes multi-line transfer (Line 1 to Line 3)', () {
    final controller = RouteController();
    final maadi = controller.network.findStationByName('Maadi')!;
    final kitkat = controller.network.findStationByName('Kit Kat')!;

    controller.setOrigin(maadi);
    controller.setDestination(kitkat);

    final steps = controller.currentRouteSteps;
    expect(steps.isNotEmpty, isTrue);
    expect(controller.transferCount, greaterThanOrEqualTo(1));
  });

  test('Trip direction resolution: Ain Shams to Al-Ahram shows Helwan direction and Adly Mansour direction', () {
    final controller = RouteController();
    final ainShams = controller.network.findStationByName('Ain Shams')!;
    final alAhram = controller.network.findStationByName('Al-Ahram')!;

    controller.setOrigin(ainShams);
    controller.setDestination(alAhram);

    // Initial boarding direction from Ain Shams is heading towards Helwan
    expect(controller.initialDirection, contains('Helwan direction'));

    // Test Least Transitions mode (Line 1 to Line 3 transfer at Gamal AbdElNasser)
    controller.selectLeastTransitions();
    final ltSteps = controller.currentRouteSteps;
    expect(ltSteps.first.direction, contains('Helwan direction'));
    final directTransfer = ltSteps.firstWhere((s) => s.isTransfer);
    expect(directTransfer.station.name, equals('Gamal AbdElNasser'));
    expect(directTransfer.transferFromLine, equals(1));
    expect(directTransfer.transferToLine, equals(3));
    expect(directTransfer.direction, contains('Adly Mansour direction'));

    // Test Shortest path mode (Line 1 -> Line 2 at Al-Shohadaa -> Line 3 at Attaba)
    controller.selectShortest();
    final sSteps = controller.currentRouteSteps;
    expect(sSteps.first.direction, contains('Helwan direction'));
    final firstTransfer = sSteps.firstWhere((s) => s.isTransfer);
    expect(firstTransfer.direction, contains('El Mounib direction'));
    final line3Transfer = sSteps.where((s) => s.isTransfer).last;
    expect(line3Transfer.transferToLine, equals(3));
    expect(line3Transfer.direction, contains('Adly Mansour direction'));
  });

  test('MetroTheme fare and line color rules are accurate', () {
    expect(MetroTheme.calculateFare(5), equals(10));
    expect(MetroTheme.calculateFare(9), equals(10));
    expect(MetroTheme.calculateFare(10), equals(12));
    expect(MetroTheme.calculateFare(16), equals(12));
    expect(MetroTheme.calculateFare(17), equals(15));
    expect(MetroTheme.calculateFare(23), equals(15));
    expect(MetroTheme.calculateFare(24), equals(20));

    expect(MetroTheme.getLineName(1), equals('Line 1'));
    expect(MetroTheme.getLineName(2), equals('Line 2'));
    expect(MetroTheme.getLineName(3), equals('Line 3'));

    expect(MetroTheme.getLineColor(1), equals(MetroTheme.line1Color));
    expect(MetroTheme.getLineColor(2), equals(MetroTheme.line2Color));
    expect(MetroTheme.getLineColor(3), equals(MetroTheme.line3Color));
  });

  test('MetroTheme line colors: Line 1 is Blue and Line 2 is Red', () {
    // User requirement: Line 1 (blue), Line 2 (red)
    expect(MetroTheme.line1Color, equals(const Color(0xFF1E88E5)));
    expect(MetroTheme.line2Color, equals(const Color(0xFFD32F2F)));
    expect(MetroTheme.getLineColor(1), equals(MetroTheme.line1Color));
    expect(MetroTheme.getLineColor(2), equals(MetroTheme.line2Color));
    expect(MetroTheme.getLineFullName(1), contains('Line 1'));
    expect(MetroTheme.getLineFullName(2), contains('Line 2'));
  });

  test('ThemeController toggles dark mode and dynamically switches MetroTheme colors', () async {
    SharedPreferences.setMockInitialValues({});
    final themeController = ThemeController();
    Get.put(themeController);
    expect(themeController.isDarkMode.value, isFalse);
    expect(themeController.themeMode, equals(ThemeMode.light));
    expect(MetroTheme.background, equals(MetroTheme.backgroundLight));
    expect(MetroTheme.surface, equals(MetroTheme.surfaceLight));

    await themeController.toggleTheme();
    expect(themeController.isDarkMode.value, isTrue);
    expect(themeController.themeMode, equals(ThemeMode.dark));
    expect(MetroTheme.background, equals(MetroTheme.backgroundDark));
    expect(MetroTheme.surface, equals(MetroTheme.surfaceDark));

    // Toggle back to light
    await themeController.toggleTheme();
    expect(themeController.isDarkMode.value, isFalse);
    expect(themeController.themeMode, equals(ThemeMode.light));
    expect(MetroTheme.background, equals(MetroTheme.backgroundLight));
  });

  test('PlaceSearchService calculates minimum distance and finds nearest station', () {
    final network = MetroNetwork();
    network.buildNetwork();

    // Test Cairo Tower (expected nearest is Opera)
    const cairoTower = PlaceItem(
      name: 'Cairo Tower',
      category: 'Landmark',
      latitude: 30.0459,
      longitude: 31.2243,
    );
    final towerResult = PlaceSearchService.findNearestStationToPlace(
      place: cairoTower,
      network: network,
    );
    expect(towerResult, isNotNull);
    expect(towerResult!.station.name, equals('Opera'));
    expect(towerResult.distanceKm, lessThan(1.0));

    // Test Egyptian Museum Tahrir (expected nearest is Sadat)
    const museum = PlaceItem(
      name: 'The Egyptian Museum',
      category: 'Museum',
      latitude: 30.0478,
      longitude: 31.2336,
    );
    final museumResult = PlaceSearchService.findNearestStationToPlace(
      place: museum,
      network: network,
    );
    expect(museumResult, isNotNull);
    expect(museumResult!.station.name, equals('Sadat'));
    expect(museumResult.distanceKm, lessThan(0.8));

    // Test RouteController.setDestinationFromPlace
    final controller = RouteController();
    controller.setDestinationFromPlace(cairoTower);
    expect(controller.destinationStation.value?.name, equals('Opera'));
    expect(controller.selectedPlaceName.value, equals('Cairo Tower'));
    expect(controller.placeDistanceKm.value, greaterThan(0.0));
  });

  test('MetroTheme calculateOver60Fare calculates half price correctly', () {
    expect(MetroTheme.calculateOver60Fare(5), equals(5));
    expect(MetroTheme.calculateOver60Fare(9), equals(5));
    expect(MetroTheme.calculateOver60Fare(10), equals(6));
    expect(MetroTheme.calculateOver60Fare(16), equals(6));
    expect(MetroTheme.calculateOver60Fare(17), equals(8));
    expect(MetroTheme.calculateOver60Fare(23), equals(8));
    expect(MetroTheme.calculateOver60Fare(24), equals(10));
    expect(MetroTheme.calculateOver60Fare(30), equals(10));
  });

  test('UserController accurately parses first name and handles edge cases', () {
    final user = UserController();
    user.setUser(name: 'Ahmed Mohamed Ali', age: 25, specialNeeds: false);
    expect(user.firstName, equals('Ahmed'));

    user.setUser(name: '  Sara  ', age: 30, specialNeeds: false);
    expect(user.firstName, equals('Sara'));

    user.setUser(name: '', age: 20, specialNeeds: false);
    expect(user.firstName, equals('Traveler'));
  });

  test('UserController categories and priority rule: Special Needs takes priority over Over 60', () {
    final user = UserController();

    // Standard passenger (age <= 60, not special needs)
    user.setUser(name: 'Ali', age: 35, specialNeeds: false);
    expect(user.category, equals(UserCategory.normal));
    expect(user.calculateUserFare(5), equals(10));  // Zone 1
    expect(user.calculateUserFare(15), equals(12)); // Zone 2
    expect(user.calculateUserFare(20), equals(15)); // Zone 3
    expect(user.calculateUserFare(25), equals(20)); // Zone 4

    // Senior passenger (age > 60, not special needs) -> Half price
    user.setUser(name: 'Hassan', age: 65, specialNeeds: false);
    expect(user.category, equals(UserCategory.over60));
    expect(user.calculateUserFare(5), equals(5));   // Zone 1
    expect(user.calculateUserFare(15), equals(6));  // Zone 2
    expect(user.calculateUserFare(20), equals(8));  // Zone 3
    expect(user.calculateUserFare(25), equals(10)); // Zone 4

    // Special needs passenger (age <= 60) -> Fixed 5 EGP
    user.setUser(name: 'Nour', age: 28, specialNeeds: true);
    expect(user.category, equals(UserCategory.specialNeeds));
    expect(user.calculateUserFare(5), equals(5));
    expect(user.calculateUserFare(15), equals(5));
    expect(user.calculateUserFare(25), equals(5));

    // CRITICAL REQUIREMENT: Over 60 AND Special Needs -> Priority is 5 EGP fixed!
    user.setUser(name: 'Mahmoud', age: 72, specialNeeds: true);
    expect(user.category, equals(UserCategory.specialNeeds));
    expect(user.calculateUserFare(5), equals(5));
    expect(user.calculateUserFare(15), equals(5));
    expect(user.calculateUserFare(20), equals(5));
    expect(user.calculateUserFare(30), equals(5));
  });

  test('RouteController ticketFare dynamically uses UserController fare', () {
    final userController = Get.put(UserController());
    final routeController = RouteController();

    final helwan = routeController.network.findStationByName('Helwan')!;
    final maadi = routeController.network.findStationByName('Maadi')!;
    routeController.setOrigin(helwan);
    routeController.setDestination(maadi);

    final count = routeController.stationCount; // ~10 stations

    // Normal user
    userController.setUser(name: 'Tamer', age: 30, specialNeeds: false);
    expect(routeController.ticketFare, equals(MetroTheme.calculateFare(count)));

    // Senior over 60
    userController.setUser(name: 'Tamer', age: 65, specialNeeds: false);
    expect(routeController.ticketFare, equals(MetroTheme.calculateOver60Fare(count)));

    // Over 60 with Special Needs -> 5 EGP
    userController.setUser(name: 'Tamer', age: 65, specialNeeds: true);
    expect(routeController.ticketFare, equals(5));
  });

  test('PlaceSearchService finds nearest station for arbitrary Cairo locations and districts', () {
    final network = MetroNetwork();
    network.buildNetwork();

    // Test Kasr Al Ainy Hospital
    const kasrAlAiny = PlaceItem(
      name: 'Kasr Al Ainy Hospital',
      category: 'Hospital',
      latitude: 30.0305,
      longitude: 31.2291,
    );
    final result = PlaceSearchService.findNearestStationToPlace(
      place: kasrAlAiny,
      network: network,
    );
    expect(result, isNotNull);
    expect(result!.distanceKm, lessThan(1.5));

    // Test offline search matches districts and hospitals
    final dokkiMatch = PlaceSearchService.searchPlaces('Dokki');
    expect(dokkiMatch.isNotEmpty, isTrue);

    final hospitalMatch = PlaceSearchService.searchPlaces('57357');
    expect(hospitalMatch.isNotEmpty, isTrue);
  });

  test('UserController persists user details to local storage and restores on next load', () async {
    final user = UserController();

    // Initially no user saved
    final initialLoaded = await user.loadUserFromStorage();
    expect(initialLoaded, isFalse);
    expect(user.isLoggedIn.value, isFalse);

    // Save user details
    await user.setUser(name: 'Kareem Ahmed', age: 63, specialNeeds: false);
    expect(user.isLoggedIn.value, isTrue);
    expect(user.userName.value, equals('Kareem Ahmed'));
    expect(user.firstName, equals('Kareem'));
    expect(user.category, equals(UserCategory.over60));

    // Create a new controller instance simulating next app launch
    final nextLaunchUser = UserController();
    final restored = await nextLaunchUser.loadUserFromStorage();
    expect(restored, isTrue);
    expect(nextLaunchUser.isLoggedIn.value, isTrue);
    expect(nextLaunchUser.userName.value, equals('Kareem Ahmed'));
    expect(nextLaunchUser.userAge.value, equals(63));
    expect(nextLaunchUser.category, equals(UserCategory.over60));

    // Clear user upon sign out
    await nextLaunchUser.clearUser();
    expect(nextLaunchUser.isLoggedIn.value, isFalse);
    expect(nextLaunchUser.userName.value, isEmpty);

    // Verify after logout, loadUserFromStorage returns false
    final afterLogoutUser = UserController();
    final reloadedAfterLogout = await afterLogoutUser.loadUserFromStorage();
    expect(reloadedAfterLogout, isFalse);
  });

  test('NlpSearchService accurately normalizes Arabic, extracts intent, and performs fuzzy matching', () {
    // 1. Normalization
    expect(NlpSearchService.normalize('الْقَاهِرَةُ'), equals('القاهره'));
    expect(NlpSearchService.normalize('الأهلي'), equals('الاهلي'));
    expect(NlpSearchService.normalize('إمبابة'), equals('امبابه'));

    // 2. Intent extraction (Arabic & English)
    expect(NlpSearchService.extractDestinationEntity('عايز اروح جامعه القاهره'), equals('جامعه القاهره'));
    expect(NlpSearchService.extractDestinationEntity('عاوز اروح مستشفى 57357'), equals('مستشفى 57357'));
    expect(NlpSearchService.extractDestinationEntity('عايز اروح الميرلاند'), equals('الميرلاند'));
    expect(NlpSearchService.extractDestinationEntity('i want to go to cairo tower'), equals('cairo tower'));
    expect(NlpSearchService.extractDestinationEntity('i want to go to merryland park'), equals('merryland park'));
    expect(NlpSearchService.extractDestinationEntity('how to get to el maadi'), equals('maadi'));
    expect(NlpSearchService.extractDestinationEntity('take me to the egyptian museum'), equals('egyptian museum'));
    expect(NlpSearchService.extractDestinationEntity('take me to Zamalek'), equals('Zamalek'));

    // 3. Candidate generation (Arabic prefixes and spelling variations)
    final candidates = NlpSearchService.generateQueryCandidates('المعادي');
    expect(candidates, contains('المعادي'));
    expect(candidates, contains('معادي'));

    final merrylandCandidates = NlpSearchService.generateQueryCandidates('الميرلاند');
    expect(merrylandCandidates, contains('الميرلاند'));
    expect(merrylandCandidates, contains('الميريلاند'));

    // 4. Similarity scoring
    final simUni = NlpSearchService.calculateSimilarity('جامعه القاهره', 'جامعة القاهرة');
    expect(simUni, greaterThanOrEqualTo(0.9));

    final simMaadi = NlpSearchService.calculateSimilarity('معادي', 'المعادي');
    expect(simMaadi, greaterThanOrEqualTo(0.8));

    // 5. TEST CASE: "الميرلاند" matches Merryland Park and finds nearest station Al-Ahram
    final merrylandResults = PlaceSearchService.searchPlaces('الميرلاند');
    expect(merrylandResults, isNotEmpty);
    expect(merrylandResults.first.name, equals('Merryland Park (Heliopolis)'));

    final merrylandWithIntent = PlaceSearchService.searchPlaces('عايز اروح الميرلاند');
    expect(merrylandWithIntent, isNotEmpty);
    expect(merrylandWithIntent.first.name, equals('Merryland Park (Heliopolis)'));

    final merrylandEnglish = PlaceSearchService.searchPlaces('i want to go to merryland park');
    expect(merrylandEnglish, isNotEmpty);
    expect(merrylandEnglish.first.name, equals('Merryland Park (Heliopolis)'));

    // Typo in English: "Meryland"
    final merrylandTypo = PlaceSearchService.searchPlaces('Meryland');
    expect(merrylandTypo, isNotEmpty);
    expect(merrylandTypo.first.name, equals('Merryland Park (Heliopolis)'));

    // Verify nearest station to Merryland Park is Al-Ahram (Line 3 Heliopolis)
    final network = MetroNetwork()..buildNetwork();
    final nearestToMerryland = PlaceSearchService.findNearestStationToPlace(
      place: merrylandResults.first,
      network: network,
    );
    expect(nearestToMerryland, isNotNull);
    expect(nearestToMerryland!.station.name, equals('Al-Ahram'));

    // 6. ZERO-GARBAGE GUARANTEE: Non-matching queries must return empty list []
    final gibberishResults = PlaceSearchService.searchPlaces('asdfghjkl123');
    expect(gibberishResults, isEmpty);

    final foreignCityResults = PlaceSearchService.searchPlaces('باريس');
    expect(foreignCityResults, isEmpty);

    // 7. Offline search ranking with other landmarks
    final searchResults = PlaceSearchService.searchPlaces('عايز اروح مستشفى 57357');
    expect(searchResults.first.name, equals("Children's Cancer Hospital 57357"));

    final uniResults = PlaceSearchService.searchPlaces('جامعه القاهره');
    expect(uniResults.first.name, equals('Cairo University Campus'));
  });
}

