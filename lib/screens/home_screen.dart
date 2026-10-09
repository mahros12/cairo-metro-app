import 'dart:async';
import 'package:cairo_metro_app/controllers/route_controller.dart';
import 'package:cairo_metro_app/controllers/theme_controller.dart';
import 'package:cairo_metro_app/controllers/user_controller.dart';
import 'package:cairo_metro_app/screens/login_screen.dart';
import 'package:cairo_metro_app/screens/route_details_screen.dart';
import 'package:cairo_metro_app/services/nlp_search_service.dart';
import 'package:cairo_metro_app/services/place_search_service.dart';
import 'package:cairo_metro_app/utils/metro_theme.dart';
import 'package:cairo_metro_app/widgets/ticket_pricing_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widgets/station_selector_header.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final RouteController controller = Get.find<RouteController>();

  void _onFindRoutePressed() {
    if (controller.originStation.value == null || controller.destinationStation.value == null) {
      Get.snackbar(
        'Missing Station',
        'Please choose both start and destination stations.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE11D48),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (controller.originStation.value!.id == controller.destinationStation.value!.id) {
      Get.snackbar(
        'Invalid Selection',
        'Start and destination stations cannot be the same.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE11D48),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    controller.calculateRoutes();
    Get.to(() => RouteDetailsScreen());
  }

  void _openPlaceSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PlaceSearchSheet(
        onPlaceSelected: (place) {
          Navigator.of(ctx).pop();
          controller.setDestinationFromPlace(place);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = ThemeController.to.isDarkMode.value;
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
                Icons.directions_subway_rounded,
                color: MetroTheme.line1Color,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cairo Metro',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: MetroTheme.textPrimary,
                  ),
                ),
                Text(
                  'Plan Your Trip',
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
          Obx(() {
            final themeController = ThemeController.to;
            final isDark = themeController.isDarkMode.value;
            return IconButton(
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: isDark ? const Color(0xFFFBBF24) : MetroTheme.textSecondary,
              ),
              tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              onPressed: () => themeController.toggleTheme(),
            );
          }),
          IconButton(
            icon: Icon(Icons.logout_rounded, color: MetroTheme.textSecondary),
            tooltip: 'Sign Out',
            onPressed: () async {
              if (Get.isRegistered<UserController>()) {
                await Get.find<UserController>().clearUser();
              }
              Get.offAll(() => const LoginScreen());
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: MetroTheme.dividerColor),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // Active Passenger Greeting & Category Badge
              Obx(() {
                if (!Get.isRegistered<UserController>()) return const SizedBox.shrink();
                final user = Get.find<UserController>();
                if (user.userName.value.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: MetroTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: MetroTheme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: MetroTheme.line1Color.withValues(alpha: 0.12),
                          child: Text(
                            user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'P',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: MetroTheme.line1Color,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${user.firstName} 👋',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: MetroTheme.textPrimary,
                                ),
                              ),
                              Text(
                                '${user.categoryLabel} • ${user.categoryFareDescription}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: MetroTheme.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 4),

              // Station Selection Header (Origin, Destination, Swap & Maps icon)
              StationSelectorHeader(),

              // Selected Place Info Banner (if destination was set from place)
              Obx(() {
                if (controller.selectedPlaceName.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MetroTheme.isDark ? const Color(0xFF065F46).withValues(alpha: 0.25) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.place_rounded,
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
                              'Destination: ${controller.selectedPlaceName.value}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF065F46),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Closest station: ${controller.destinationStation.value?.name ?? ''} (${controller.placeDistanceKm.value} km away)',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Color(0xFF065F46)),
                        onPressed: () {
                          controller.selectedPlaceName.value = '';
                          controller.placeDistanceKm.value = 0.0;
                        },
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 6),

              // Option 1: Use Current Location (Detect nearest metro station using device GPS)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InkWell(
                  onTap: () => controller.useCurrentLocation(),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: MetroTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Obx(() {
                            if (controller.isLocating.value) {
                              return const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF2563EB),
                                ),
                              );
                            }
                            return const Icon(
                              Icons.my_location_rounded,
                              size: 20,
                              color: Color(0xFF2563EB),
                            );
                          }),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Use Current Location',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: MetroTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'Find & set nearest metro station as origin',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: MetroTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: MetroTheme.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Option 2: Destination by Place / Landmark (Search any place in Greater Cairo)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InkWell(
                  onTap: () => _openPlaceSearchModal(context),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: MetroTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.travel_explore_rounded,
                            size: 20,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Destination by Place / Landmark',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: MetroTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'Type place name to calculate closest metro station',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: MetroTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: MetroTheme.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Find Route CTA Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(() {
                  final canGo = controller.canCalculateRoute;
                  return ElevatedButton(
                    onPressed: _onFindRoutePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canGo ? MetroTheme.line1Color : (MetroTheme.isDark ? const Color(0xFF334155) : const Color(0xFF94A3B8)),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: canGo ? 3 : 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_rounded, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Find Best Route',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

              // Quick Popular Destinations Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Popular Destinations',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: MetroTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildQuickStationChip('Sadat (Tahrir)', 'Sadat'),
                        _buildQuickStationChip('Cairo University', 'Cairo University'),
                        _buildQuickStationChip('Attaba', 'Attaba'),
                        _buildQuickStationChip('Adly Mansour', 'Adly Mansour'),
                        _buildQuickStationChip('Opera', 'Opera'),
                        _buildQuickStationChip('Maadi', 'Maadi'),
                        _buildQuickStationChip('Rod El Farag', 'Rod El Farag Corridor'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Official Ticket Pricing Section (3 categories: Normal, Over 60, Special Needs)
              const TicketPricingCard(),

              const SizedBox(height: 24),

              // Metro Lines Quick Overview Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MetroTheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: MetroTheme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cairo Metro Lines',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: MetroTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLineInfoRow(
                      lineNum: 1,
                      name: 'Line 1 (Blue)',
                      terminals: 'Helwan ↔ New El Marg',
                      color: MetroTheme.line1Color,
                    ),
                    Divider(height: 16, color: MetroTheme.dividerColor),
                    _buildLineInfoRow(
                      lineNum: 2,
                      name: 'Line 2 (Red)',
                      terminals: 'El Mounib ↔ Shubra El Kheima',
                      color: MetroTheme.line2Color,
                    ),
                    Divider(height: 16, color: MetroTheme.dividerColor),
                    _buildLineInfoRow(
                      lineNum: 3,
                      name: 'Line 3 (Green)',
                      terminals: 'Adly Mansour ↔ Rod El Farag / Cairo Univ',
                      color: MetroTheme.line3Color,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    });
  }

  Widget _buildQuickStationChip(String label, String stationLookupName) {
    return ActionChip(
      onPressed: () {
        final station = controller.network.findStationByName(stationLookupName);
        if (station != null) {
          controller.setDestination(station);
        }
      },
      avatar: Icon(Icons.place_rounded, size: 16, color: MetroTheme.textSecondary),
      label: Text(label),
      labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: MetroTheme.textPrimary),
      backgroundColor: MetroTheme.surface,
      side: BorderSide(color: MetroTheme.dividerColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildLineInfoRow({
    required int lineNum,
    required String name,
    required String terminals,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const Spacer(),
        Text(
          terminals,
          style: TextStyle(
            fontSize: 11,
            color: MetroTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _PlaceSearchSheet extends StatefulWidget {
  final ValueChanged<PlaceItem> onPlaceSelected;

  const _PlaceSearchSheet({required this.onPlaceSelected});

  @override
  State<_PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends State<_PlaceSearchSheet> {
  final TextEditingController _textController = TextEditingController();
  List<PlaceItem> _filteredPlaces = PlaceSearchService.cairoPlaces;
  bool _isLoading = false;
  Timer? _debounceTimer;
  int _searchSession = 0;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    final clean = query.trim();

    if (clean.isEmpty) {
      _searchSession++;
      setState(() {
        _isLoading = false;
        _filteredPlaces = PlaceSearchService.cairoPlaces;
      });
      return;
    }

    // Immediately display any matching offline places for instantaneous feedback
    final localMatches = PlaceSearchService.searchPlaces(clean);
    setState(() {
      _filteredPlaces = localMatches;
      _isLoading = true;
    });

    // Debounce live geocoding to prevent excessive network requests
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performLiveSearch(clean);
    });
  }

  Future<void> _performLiveSearch(String query) async {
    final currentSession = ++_searchSession;
    final results = await PlaceSearchService.geocodePlaces(query);
    if (!mounted || currentSession != _searchSession) return;
    setState(() {
      _filteredPlaces = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MetroTheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.only(top: 16),
        child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: MetroTheme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Search Destination by Place',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: MetroTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Search any street, hospital, university, or place in Greater Cairo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: MetroTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _textController,
              onChanged: _onSearchChanged,
              onSubmitted: (query) {
                _debounceTimer?.cancel();
                if (query.trim().isNotEmpty) {
                  setState(() => _isLoading = true);
                  _performLiveSearch(query.trim());
                }
              },
              textInputAction: TextInputAction.search,
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: MetroTheme.textSecondary),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                    if (_textController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _textController.clear();
                          _onSearchChanged('');
                        },
                      ),
                  ],
                ),
                hintText: 'Type any place, street, or area in Cairo...',
                hintStyle: TextStyle(color: MetroTheme.textMuted, fontSize: 13),
                filled: true,
                fillColor: MetroTheme.isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: MetroTheme.textPrimary, fontSize: 14),
            ),
          ),
          const SizedBox(height: 10),

          // Search scope indicator tag with NLP feedback
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFF7C3AED)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _textController.text.isEmpty
                        ? 'Popular Cairo Locations (NLP Smart Search)'
                        : (NlpSearchService.extractDestinationEntity(_textController.text) != _textController.text.trim()
                            ? 'Smart NLP: "${NlpSearchService.extractDestinationEntity(_textController.text)}"'
                            : 'Live NLP Geocoding Results'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6D28D9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_filteredPlaces.isNotEmpty)
                  Text(
                    '${_filteredPlaces.length} places',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: MetroTheme.dividerColor),
          // Results list
          Expanded(
            child: _filteredPlaces.isEmpty && !_isLoading
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off_rounded, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'No places found',
                            style: TextStyle(fontWeight: FontWeight.bold, color: MetroTheme.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try typing the name in Arabic or English, or search by neighborhood/street name.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: MetroTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _filteredPlaces.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: MetroTheme.dividerColor,
                    ),
                    itemBuilder: (context, index) {
                      final place = _filteredPlaces[index];
                      return ListTile(
                        onTap: () => widget.onPlaceSelected(place),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: MetroTheme.isDark ? 0.25 : 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.place_rounded,
                            color: Color(0xFF7C3AED),
                            size: 22,
                          ),
                        ),
                        title: Text(
                          place.arabicName != null && place.arabicName!.isNotEmpty && place.name != place.arabicName
                              ? '${place.name} • ${place.arabicName}'
                              : place.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: MetroTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          place.category,
                          style: TextStyle(
                            fontSize: 11,
                            color: MetroTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: MetroTheme.textMuted,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}
}
