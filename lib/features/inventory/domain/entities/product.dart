import 'syncable.dart';

class Product implements Syncable {
  final int? id;
  final int? categoryId;
  final String name;
  final String? sku;
  final String? barcode;
  final double price;
  final double? costPrice;
  final int stockQuantity;
  final int lowStockThreshold;
  final String? imagePath;
  @override
  final bool isSynced;
  @override
  final DateTime? lastUpdated;

  Product({
    this.id,
    this.categoryId,
    required this.name,
    this.sku,
    this.barcode,
    required this.price,
    this.costPrice,
    this.stockQuantity = 0,
    this.lowStockThreshold = 5,
    this.imagePath,
    this.isSynced = false,
    this.lastUpdated,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'price': price,
      'cost_price': costPrice,
      'stock_quantity': stockQuantity,
      'low_stock_threshold': lowStockThreshold,
      'image_path': imagePath,
      'is_synced': isSynced ? 1 : 0,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      categoryId: map['category_id'],
      name: map['name'],
      sku: map['sku'],
      barcode: map['barcode'],
      price: map['price'],
      costPrice: map['cost_price'],
      stockQuantity: map['stock_quantity'] ?? 0,
      lowStockThreshold: map['low_stock_threshold'] ?? 5,
      imagePath: map['image_path'],
      isSynced: map['is_synced'] == 1,
      lastUpdated: map['last_updated'] != null
          ? DateTime.parse(map['last_updated'])
          : null,
    );
  }

  Product copyWith({
    int? id,
    int? categoryId,
    String? name,
    String? sku,
    String? barcode,
    double? price,
    double? costPrice,
    int? stockQuantity,
    int? lowStockThreshold,
    String? imagePath,
    bool? isSynced,
    DateTime? lastUpdated,
  }) {
    return Product(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      imagePath: imagePath ?? this.imagePath,
      isSynced: isSynced ?? this.isSynced,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
