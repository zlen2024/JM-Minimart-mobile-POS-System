abstract class Syncable {
  Map<String, dynamic> toMap();
  bool get isSynced;
  DateTime? get lastUpdated;
}
