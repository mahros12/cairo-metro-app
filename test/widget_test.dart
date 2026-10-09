import 'package:cairo_metro_app/controllers/route_controller.dart';
import 'package:cairo_metro_app/controllers/user_controller.dart';
import 'package:cairo_metro_app/screens/home_screen.dart';
import 'package:cairo_metro_app/screens/login_screen.dart';
import 'package:cairo_metro_app/screens/route_details_screen.dart';
import 'package:cairo_metro_app/screens/welcome_temp_screen.dart';
import 'package:cairo_metro_app/services/coordinate_service.dart';
import 'package:cairo_metro_app/widgets/route_timeline_tile.dart';
import 'package:cairo_metro_app/widgets/ticket_pricing_card.dart';
import 'package:cairo_metro_app/widgets/trip_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:get/get.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockGeolocatorPlatform extends GeolocatorPlatform with MockPlatformInterfaceMixin {
  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async => LocationPermission.always;

  @override
  Future<LocationPermission> requestPermission() async => LocationPermission.always;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async {
    return Position(
      latitude: 30.0444, // Sadat station coordinates
      longitude: 31.2357,
      timestamp: DateTime(2026, 1, 1),
      accuracy: 5.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }

  @override
  Future<Position?> getLastKnownPosition({bool forceLocationManager = false}) async {
    return Position(
      latitude: 30.0444,
      longitude: 31.2357,
      timestamp: DateTime(2026, 1, 1),
      accuracy: 5.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }
}

void main() {
  setUp(() {
    GeolocatorPlatform.instance = MockGeolocatorPlatform();
  });

  testWidgets('Full passenger login, welcome temp screen, ticket pricing, and route flow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({});
    Get.reset();
    Get.put(CoordinateService(), permanent: true);
    Get.put(UserController(), permanent: true);
    Get.put(RouteController(), permanent: true);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: LoginScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify LoginScreen renders with passenger inputs
    expect(find.text('Cairo Metro'), findsOneWidget);
    expect(find.text('Passenger Details'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Age (Years)'), findsOneWidget);
    expect(find.text('Special Needs (ذوي الهمم)'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);

    // Enter Senior + Special Needs passenger details to test priority
    await tester.enterText(find.widgetWithText(TextFormField, 'Full Name'), 'Hassan Ali');
    await tester.enterText(find.widgetWithText(TextFormField, 'Age (Years)'), '68');
    await tester.tap(find.text('Special Needs (ذوي الهمم)'));
    await tester.pumpAndSettle();

    // Tap "Get Started"
    await tester.tap(find.text('Get Started'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // 2. Verify WelcomeTempScreen renders greeting with 1st name
    expect(find.byType(WelcomeTempScreen), findsOneWidget);
    expect(find.text('Hello, Hassan! 👋'), findsOneWidget);
    expect(find.text('Special Needs (ذوي الهمم)'), findsWidgets);
    expect(find.text('Fixed 5 EGP for all zones'), findsOneWidget);

    // Tap "Continue to Home" on WelcomeTempScreen
    await tester.tap(find.text('Continue to Home'));
    await tester.pumpAndSettle();

    // 3. Verify HomeScreen renders with greeting & TicketPricingCard
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Hello, Hassan 👋'), findsOneWidget);
    expect(find.byType(TicketPricingCard), findsOneWidget);
    expect(find.text('Official Ticket Pricing'), findsOneWidget);
    expect(find.text('Active: Special Needs (5 EGP)'), findsOneWidget);
    expect(find.text('Plan Your Trip'), findsOneWidget);
    expect(find.text('Use Current Location'), findsOneWidget);
    expect(find.text('Destination by Place / Landmark'), findsOneWidget);

    // Verify Google Maps directions icon is NOT present initially (no origin selected)
    final controller = Get.find<RouteController>();
    controller.originStation.value = null;
    await tester.pumpAndSettle();
    expect(find.byTooltip('Directions to station in Google Maps'), findsNothing);

    // Tap "Use Current Location" -> sets origin to Sadat
    await tester.tap(find.text('Use Current Location'));
    await tester.pumpAndSettle();

    // Verify Google Maps directions icon APPEARS next to Origin Station
    expect(find.byTooltip('Directions to station in Google Maps'), findsOneWidget);

    // Tap "Destination by Place / Landmark" to open Place Search Modal
    await tester.tap(find.text('Destination by Place / Landmark'));
    await tester.pumpAndSettle();

    // Verify Place Search Sheet renders
    expect(find.text('Search Destination by Place'), findsOneWidget);
    expect(find.textContaining('Cairo Tower'), findsWidgets);

    // Select "Cairo Tower" -> should calculate min distance and set destination to Opera
    await tester.tap(find.textContaining('Cairo Tower').first);
    await tester.pumpAndSettle();

    // Verify destination is set to Opera
    expect(controller.destinationStation.value?.name, equals('Opera'));
    expect(controller.selectedPlaceName.value, equals('Cairo Tower'));
    expect(find.textContaining('Cairo Tower'), findsOneWidget);

    // Tap "Find Best Route" to navigate to RouteDetailsScreen
    await tester.tap(find.text('Find Best Route'));
    await tester.pumpAndSettle();

    // 3. Verify RouteDetailsScreen renders
    expect(find.byType(RouteDetailsScreen), findsOneWidget);
    expect(find.byType(TripSummaryCard), findsOneWidget);

    // Verify Shortest Path and Least Transitions option buttons
    expect(find.text('Shortest Path'), findsOneWidget);
    expect(find.text('Least Transitions'), findsOneWidget);

    // Verify Timeline rendered
    expect(find.byType(RouteTimelineTile), findsWidgets);

    // Verify Back button returns to HomeScreen
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Auto-routes directly to HomeScreen when user is already logged in locally', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({
      'cairo_metro_user_name': 'Sara Ahmed',
      'cairo_metro_user_age': 28,
      'cairo_metro_user_special_needs': false,
      'cairo_metro_user_logged_in': true,
    });

    Get.reset();
    Get.put(CoordinateService(), permanent: true);
    final userController = Get.put(UserController(), permanent: true);
    Get.put(RouteController(), permanent: true);

    final isLoggedIn = await userController.loadUserFromStorage();
    expect(isLoggedIn, isTrue);

    await tester.pumpWidget(
      GetMaterialApp(
        home: isLoggedIn ? HomeScreen() : const LoginScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify HomeScreen renders directly without showing LoginScreen
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.text('Hello, Sara 👋'), findsOneWidget);
  });
}
