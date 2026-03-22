import 'syncable.dart';

class Category implements Syncable {
  final int? id;
  final String name;
  final String? color;
  @override
  final bool isSynced;
  @override
  final DateTime? lastUpdated;

  Category({
    this.id,
    required this.name,
    this.color,
    this.isSynced = false,
    this.lastUpdated,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'is_synced': isSynced ? 1 : 0,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      color: map['color'],
      isSynced: map['is_synced'] == 1,
      lastUpdated: map['last_updated'] != null
          ? DateTime.parse(map['last_updated'])
          : null,
    );
  }

  Category copyWith({
    int? id,
    String? name,
    String? color,
    bool? isSynced,
    DateTime? lastUpdated,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      isSynced: isSynced ?? this.isSynced,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
