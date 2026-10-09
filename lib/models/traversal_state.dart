import 'package:cairo_metro_app/models/station.dart';

class TraversalState implements Comparable<TraversalState> {
  final Station station;
  final int? currentLine;
  final int stationsCount;
  final int transfersCount;
  final List<Station> path;
  final bool prioritizeLeastTransitions;

  TraversalState({
    required this.station,
    required this.currentLine,
    required this.stationsCount,
    required this.transfersCount,
    required this.path,
    this.prioritizeLeastTransitions = false,
  });

  /// Single scalar cost for backward compatibility
  int get cost => prioritizeLeastTransitions
      ? (transfersCount * 1000 + stationsCount)
      : (stationsCount * 100 + transfersCount);

  @override
  int compareTo(TraversalState other) {
    if (prioritizeLeastTransitions) {
      // 1. Absolute priority: fewest transfers
      final transferDiff = transfersCount.compareTo(other.transfersCount);
      if (transferDiff != 0) return transferDiff;
      // 2. Tie-breaker: fewest stations
      return stationsCount.compareTo(other.stationsCount);
    } else {
      // 1. Absolute priority: fewest stations
      final stationDiff = stationsCount.compareTo(other.stationsCount);
      if (stationDiff != 0) return stationDiff;
      // 2. Tie-breaker: fewest transfers
      return transfersCount.compareTo(other.transfersCount);
    }
  }
}