import 'package:cairo_metro_app/controllers/route_controller.dart';
import 'package:cairo_metro_app/models/station.dart';
import 'package:cairo_metro_app/controllers/theme_controller.dart';
import 'package:cairo_metro_app/utils/metro_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StationSelectorHeader extends StatelessWidget {
  final RouteController controller = Get.find<RouteController>();

  StationSelectorHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = ThemeController.to.isDarkMode.value;
      return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MetroTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: MetroTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  children: [
                    // Origin Picker with Google Maps directions button on the right
                    Obx(
                      () => Row(
                        children: [
                          Expanded(
                            child: _buildStationPicker(
                              context: context,
                              label: 'Origin Station',
                              hint: 'Choose start station',
                              selectedStation: controller.originStation.value,
                              icon: Icons.trip_origin,
                              iconColor: const Color(0xFF10B981),
                              onSelected: (station) => controller.setOrigin(station),
                            ),
                          ),
                          if (controller.originStation.value != null) ...[
                            const SizedBox(width: 8),
                            Tooltip(
                              message: 'Directions to station in Google Maps',
                              child: InkWell(
                                onTap: () => controller.openGoogleMapsForOrigin(),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: MetroTheme.isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.directions_rounded,
                                    color: Color(0xFF2563EB),
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Destination Picker
                    Obx(
                      () => _buildStationPicker(
                        context: context,
                        label: 'Destination Station',
                        hint: 'Choose end station',
                        selectedStation: controller.destinationStation.value,
                        icon: Icons.location_on,
                        iconColor: const Color(0xFFEF4444),
                        onSelected: (station) => controller.setDestination(station),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Swap Button
              InkWell(
                onTap: () => controller.swapStations(),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MetroTheme.cardSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: MetroTheme.dividerColor),
                  ),
                  child: Icon(
                    Icons.swap_vert_rounded,
                    size: 26,
                    color: MetroTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          // Error feedback if any
          Obx(() {
            if (controller.errorMessage.value.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Color(0xFFE11D48)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      controller.errorMessage.value,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFE11D48),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
    });
  }

  Widget _buildStationPicker({
    required BuildContext context,
    required String label,
    required String hint,
    required Station? selectedStation,
    required IconData icon,
    required Color iconColor,
    required ValueChanged<Station?> onSelected,
  }) {
    return InkWell(
      onTap: () => _openStationSearchModal(context, label, onSelected),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: MetroTheme.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MetroTheme.dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: MetroTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedStation?.name ?? hint,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selectedStation != null ? FontWeight.w600 : FontWeight.w400,
                      color: selectedStation != null ? MetroTheme.textPrimary : MetroTheme.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (selectedStation != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: selectedStation.lines.map((lineNum) {
                  return Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: MetroTheme.getLineColor(lineNum),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'L$lineNum',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  );
                }).toList(),
              )
            else
              Icon(Icons.arrow_drop_down, color: MetroTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  void _openStationSearchModal(
    BuildContext context,
    String title,
    ValueChanged<Station?> onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _StationSearchSheet(
          title: title,
          stations: controller.allStations,
          onSelected: (station) {
            Navigator.of(ctx).pop();
            onSelected(station);
          },
        );
      },
    );
  }
}

class _StationSearchSheet extends StatefulWidget {
  final String title;
  final List<Station> stations;
  final ValueChanged<Station> onSelected;

  const _StationSearchSheet({
    required this.title,
    required this.stations,
    required this.onSelected,
  });

  @override
  State<_StationSearchSheet> createState() => _StationSearchSheetState();
}

class _StationSearchSheetState extends State<_StationSearchSheet> {
  late List<Station> _filteredStations;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredStations = widget.stations;
  }

  void _filter(String query) {
    final cleanQuery = query.toLowerCase().replaceAll(' ', '').replaceAll('-', '');
    setState(() {
      if (cleanQuery.isEmpty) {
        _filteredStations = widget.stations;
      } else {
        _filteredStations = widget.stations.where((station) {
          final cleanName = station.name.toLowerCase().replaceAll(' ', '').replaceAll('-', '');
          return cleanName.contains(cleanQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = ThemeController.to.isDarkMode.value;
      return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: MetroTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
            widget.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: MetroTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filter,
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: MetroTheme.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _filter('');
                        },
                      )
                    : null,
                hintText: 'Search station by name...',
                hintStyle: TextStyle(color: MetroTheme.textMuted, fontSize: 14),
                filled: true,
                fillColor: MetroTheme.inputFill,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: MetroTheme.textPrimary, fontSize: 14),
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: MetroTheme.dividerColor),
          // Stations List
          Expanded(
            child: _filteredStations.isEmpty
                ? Center(
                    child: Text(
                      'No stations found',
                      style: TextStyle(color: MetroTheme.textSecondary),
                    ),
                  )
                : ListView.separated(
                    itemCount: _filteredStations.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, indent: 16, endIndent: 16, color: MetroTheme.dividerColor),
                    itemBuilder: (context, index) {
                      final station = _filteredStations[index];
                      return ListTile(
                        onTap: () => widget.onSelected(station),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: MetroTheme.cardSecondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.train_rounded,
                            size: 20,
                            color: MetroTheme.textPrimary,
                          ),
                        ),
                        title: Text(
                          station.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: MetroTheme.textPrimary,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: station.lines.map((lineNum) {
                            return Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: MetroTheme.getLineColor(lineNum),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Line $lineNum',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
    });
  }
}
