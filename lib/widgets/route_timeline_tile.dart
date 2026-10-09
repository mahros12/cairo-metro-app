import 'package:cairo_metro_app/models/route_step.dart';
import 'package:cairo_metro_app/utils/metro_theme.dart';
import 'package:flutter/material.dart';

class RouteTimelineTile extends StatelessWidget {
  final RouteStep step;

  const RouteTimelineTile({
    super.key,
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: Timeline vertical rail
          SizedBox(
            width: 54,
            child: Column(
              children: [
                // Top line connector
                Expanded(
                  child: Container(
                    width: 5,
                    decoration: BoxDecoration(
                      color: step.incomingLine != null
                          ? MetroTheme.getLineColor(step.incomingLine!)
                          : Colors.transparent,
                      borderRadius: step.isOrigin
                          ? const BorderRadius.vertical(top: Radius.circular(3))
                          : BorderRadius.zero,
                    ),
                  ),
                ),
                // Station node indicator
                _buildStationNode(),
                // Bottom line connector
                Expanded(
                  child: Container(
                    width: 5,
                    decoration: BoxDecoration(
                      color: step.outgoingLine != null
                          ? MetroTheme.getLineColor(step.outgoingLine!)
                          : Colors.transparent,
                      borderRadius: step.isDestination
                          ? const BorderRadius.vertical(bottom: Radius.circular(3))
                          : BorderRadius.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right: Station info & Interchange Callout
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: step.isOrigin ? 4 : 8,
                bottom: step.isDestination ? 4 : 8,
                right: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStationHeader(),
                  if (step.isTransfer) _buildTransferCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the station node icon/shape depending on station role
  Widget _buildStationNode() {
    if (step.isOrigin) {
      final color = MetroTheme.getLineColor(step.activeLine);
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: MetroTheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 4),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    if (step.isDestination) {
      final color = MetroTheme.getLineColor(step.activeLine);
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.flag_rounded,
          size: 16,
          color: Colors.white,
        ),
      );
    }

    if (step.isTransfer) {
      final fromColor = MetroTheme.getLineColor(step.transferFromLine!);
      final toColor = MetroTheme.getLineColor(step.transferToLine!);

      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [fromColor, toColor],
          ),
          boxShadow: [
            BoxShadow(
              color: toColor.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: MetroTheme.background, width: 3),
        ),
        child: const Center(
          child: Icon(
            Icons.swap_vert_rounded,
            size: 18,
            color: Colors.white,
          ),
        ),
      );
    }

    // Regular intermediate station
    final lineColor = MetroTheme.getLineColor(step.activeLine);
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: MetroTheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: lineColor, width: 3.5),
      ),
    );
  }

  /// Builds the station name, step badge, and line pills
  Widget _buildStationHeader() {
    final isKeyStation = step.isOrigin || step.isDestination || step.isTransfer;

    return Row(
      children: [
        // Station Name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      step.station.name,
                      style: TextStyle(
                        fontSize: isKeyStation ? 16 : 14,
                        fontWeight: isKeyStation ? FontWeight.bold : FontWeight.w500,
                        color: isKeyStation
                            ? MetroTheme.textPrimary
                            : const Color(0xFF334155),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (step.isOrigin)
                    _buildRoleTag('Start', const Color(0xFF10B981))
                  else if (step.isDestination)
                    _buildRoleTag('Destination', const Color(0xFFEF4444))
                  else if (step.isTransfer)
                    _buildRoleTag('Transfer', const Color(0xFF8B5CF6)),
                ],
              ),
              if (!step.isTransfer)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Stop ${step.stepIndex} • ${MetroTheme.getLineName(step.activeLine)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: MetroTheme.textSecondary,
                    ),
                  ),
                ),
              if (step.isOrigin && step.direction != null && step.direction!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: MetroTheme.getLineColor(step.activeLine).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: MetroTheme.getLineColor(step.activeLine).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.navigation_rounded,
                        size: 13,
                        color: MetroTheme.getLineColor(step.activeLine),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Board ${MetroTheme.getLineName(step.activeLine)} • ${step.direction}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: MetroTheme.getLineColor(step.activeLine),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Available lines passing through this station
        Row(
          mainAxisSize: MainAxisSize.min,
          children: step.station.lines.map((l) {
            final isActive = l == step.activeLine;
            return Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? MetroTheme.getLineColor(l)
                    : MetroTheme.getLineColor(l).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'L$l',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : MetroTheme.getLineColor(l),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRoleTag(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  /// Builds the rich interchange transition banner displaying the color switch!
  Widget _buildTransferCard() {
    final fromLine = step.transferFromLine!;
    final toLine = step.transferToLine!;
    final fromColor = MetroTheme.getLineColor(fromLine);
    final toColor = MetroTheme.getLineColor(toLine);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MetroTheme.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: MetroTheme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_subway_rounded,
                size: 16,
                color: MetroTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Line Interchange',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: MetroTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'Stop ${step.stepIndex}',
                style: TextStyle(
                  fontSize: 11,
                  color: MetroTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Color Switch Bar showing transition from Line A to Line B
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  fromColor.withValues(alpha: 0.12),
                  toColor.withValues(alpha: 0.12),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: MetroTheme.dividerColor,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Arriving Line Badge
                _buildLineBadge(fromLine, fromColor),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_forward_rounded, size: 16, color: toColor),
                    ],
                  ),
                ),
                // Departing Line Badge
                _buildLineBadge(toLine, toColor),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            step.direction != null && step.direction!.isNotEmpty
                ? 'Transfer from ${MetroTheme.getLineName(fromLine)} to ${MetroTheme.getLineName(toLine)} ("${step.direction}")'
                : 'Transfer from ${MetroTheme.getLineName(fromLine)} to ${MetroTheme.getLineName(toLine)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: MetroTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineBadge(int line, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        MetroTheme.getLineName(line),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
