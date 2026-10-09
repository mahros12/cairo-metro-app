import 'package:cairo_metro_app/models/station.dart';

/// Represents a single station step along a computed metro route,
/// capturing the incoming line, outgoing line, and whether a line
/// transition/interchange occurs at this station.
class RouteStep {
  final Station station;
  final int stepIndex; // 1-based index in the path
  final int? incomingLine;
  final int? outgoingLine;
  final bool isOrigin;
  final bool isDestination;
  final bool isTransfer;
  final int? transferFromLine;
  final int? transferToLine;
  final String? direction; // e.g. "Helwan direction" or "Cairo University direction"

  const RouteStep({
    required this.station,
    required this.stepIndex,
    this.incomingLine,
    this.outgoingLine,
    this.isOrigin = false,
    this.isDestination = false,
    this.isTransfer = false,
    this.transferFromLine,
    this.transferToLine,
    this.direction,
  });

  /// The active line for the station's primary display (prefers outgoingLine, falls back to incomingLine)
  int get activeLine => outgoingLine ?? incomingLine ?? (station.lines.isNotEmpty ? station.lines.first : 1);
}
