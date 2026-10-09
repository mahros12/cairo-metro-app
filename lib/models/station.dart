class Station {
  Station({required this.id, required this.name, required this.lines, this.longitude, this.latitude});
  final String id;
  final String name;
  final List<int> lines;
  final double? latitude;
  final double? longitude;

  bool get isTransfer => lines.length > 1;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Station && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
