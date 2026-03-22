import '../../../inventory/domain/entities/syncable.dart';

class SaleItem {
  final int? id;
  final int? saleId;
  final int productId;
  final int quantity;
  final double unitPrice;

  SaleItem({
    this.id,
    this.saleId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'],
      saleId: map['sale_id'],
      productId: map['product_id'],
      quantity: map['quantity'],
      unitPrice: map['unit_price'],
    );
  }

  SaleItem copyWith({
    int? id,
    int? saleId,
    int? productId,
    int? quantity,
    double? unitPrice,
  }) {
    return SaleItem(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
}

class Sale implements Syncable {
  final int? id;
  final double totalAmount;
  final double? discountAmount;
  final double? taxAmount;
  final String? paymentMethod;
  final DateTime? createdAt;
  @override
  final bool isSynced;
  @override
  final DateTime? lastUpdated;

  Sale({
    this.id,
    required this.totalAmount,
    this.discountAmount,
    this.taxAmount,
    this.paymentMethod,
    this.createdAt,
    this.isSynced = false,
    this.lastUpdated,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'total_amount': totalAmount,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'payment_method': paymentMethod,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      totalAmount: map['total_amount'],
      discountAmount: map['discount_amount'],
      taxAmount: map['tax_amount'],
      paymentMethod: map['payment_method'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      isSynced: map['is_synced'] == 1,
    );
  }

  Sale copyWith({
    int? id,
    double? totalAmount,
    double? discountAmount,
    double? taxAmount,
    String? paymentMethod,
    DateTime? createdAt,
    bool? isSynced,
    DateTime? lastUpdated,
  }) {
    return Sale(
      id: id ?? this.id,
      totalAmount: totalAmount ?? this.totalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
