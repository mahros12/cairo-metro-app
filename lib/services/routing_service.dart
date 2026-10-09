import 'package:collection/collection.dart';
import 'package:cairo_metro_app/models/station.dart';
import 'package:cairo_metro_app/data/metro_network.dart';
import 'package:cairo_metro_app/models/traversal_state.dart';

class RoutingService {
  final MetroNetwork network;

  RoutingService(this.network);

  /// Computes the optimal path between [start] and [destination].
  ///
  /// When [prioritizeLeastTransitions] is true:
  ///   1. Minimizes total line transfers (transitions) strictly first.
  ///   2. Uses fewest stations as the tie-breaker.
  ///
  /// When [prioritizeLeastTransitions] is false (Shortest Path):
  ///   1. Minimizes total stations strictly first.
  ///   2. Uses fewest transfers as the tie-breaker.
  List<Station> findShortestPath(
    Station start,
    Station destination, {
    bool prioritizeLeastTransitions = false,
  }) {
    if (start.id == destination.id) return [start];

    final queue = PriorityQueue<TraversalState>();

    // Keyed by (stationId, line) to avoid discarding valid paths arriving on different lines
    final bestCosts = <({String stationId, int? line}), ({int stations, int transfers})>{};

    final startState = TraversalState(
      station: start,
      currentLine: null,
      stationsCount: 0,
      transfersCount: 0,
      path: [start],
      prioritizeLeastTransitions: prioritizeLeastTransitions,
    );

    queue.add(startState);
    bestCosts[(stationId: start.id, line: null)] = (stations: 0, transfers: 0);

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();

      if (current.station.id == destination.id) {
        return current.path;
      }

      final neighbors = network.graph[current.station] ?? [];
      for (final neighbor in neighbors) {
        // Prevent simple back-tracking loops
        if (current.path.length >= 2 && current.path[current.path.length - 2].id == neighbor.id) {
          continue;
        }

        final sharedLines = current.station.lines.toSet().intersection(
          neighbor.lines.toSet(),
        );
        if (sharedLines.isEmpty) continue;

        // If currently on a line shared with neighbor, prioritize staying on that line
        final List<int> candidateLines;
        if (current.currentLine != null && sharedLines.contains(current.currentLine)) {
          candidateLines = [current.currentLine!];
        } else {
          candidateLines = sharedLines.toList();
        }

        for (final newLine in candidateLines) {
          final isTransfer = current.currentLine != null && current.currentLine != newLine;
          final nextTransfers = current.transfersCount + (isTransfer ? 1 : 0);
          final nextStations = current.stationsCount + 1;

          final key = (stationId: neighbor.id, line: (newLine as int?));
          final existing = bestCosts[key];

          bool isBetter = false;
          if (existing == null) {
            isBetter = true;
          } else if (prioritizeLeastTransitions) {
            if (nextTransfers < existing.transfers) {
              isBetter = true;
            } else if (nextTransfers == existing.transfers && nextStations < existing.stations) {
              isBetter = true;
            }
          } else {
            if (nextStations < existing.stations) {
              isBetter = true;
            } else if (nextStations == existing.stations && nextTransfers < existing.transfers) {
              isBetter = true;
            }
          }

          if (isBetter) {
            bestCosts[key] = (stations: nextStations, transfers: nextTransfers);
            queue.add(
              TraversalState(
                station: neighbor,
                currentLine: newLine,
                stationsCount: nextStations,
                transfersCount: nextTransfers,
                path: [...current.path, neighbor],
                prioritizeLeastTransitions: prioritizeLeastTransitions,
              ),
            );
          }
        }
      }
    }

    return [];
  }

  Map<String, List<Station>> generateTripOptions({
    required Station start,
    required Station destination,
  }) {
    final shortestRoute = findShortestPath(
      start,
      destination,
      prioritizeLeastTransitions: false,
    );
    final leastTransfersRoute = findShortestPath(
      start,
      destination,
      prioritizeLeastTransitions: true,
    );
    final routesAreEqual = ListEquality().equals(
      shortestRoute,
      leastTransfersRoute,
    );

    return {
      'shortest': shortestRoute,
      'leastTransitions': leastTransfersRoute,
      'leastTransfers': leastTransfersRoute,
      if (routesAreEqual) 'primary': shortestRoute,
    };
  }
}
