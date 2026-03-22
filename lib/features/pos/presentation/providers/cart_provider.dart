import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/sale.dart';
import '../../../inventory/domain/entities/product.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import 'pos_provider.dart';

class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, this.quantity = 1});

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  double get totalPrice => product.price * quantity;
}

class CartState {
  final List<CartItem> items;
  final double discount;
  final double taxRate;

  CartState({
    this.items = const [],
    this.discount = 0.0,
    this.taxRate = 0.0,
  });

  CartState copyWith({
    List<CartItem>? items,
    double? discount,
    double? taxRate,
  }) {
    return CartState(
      items: items ?? this.items,
      discount: discount ?? this.discount,
      taxRate: taxRate ?? this.taxRate,
    );
  }

  double get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);
  double get taxAmount => (subtotal - discount) * taxRate;
  double get total => subtotal - discount + taxAmount;
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() {
    return CartState();
  }

  void addProduct(Product product, {int quantity = 1}) {
    final existingIndex = state.items.indexWhere((i) => i.product.id == product.id);

    if (existingIndex >= 0) {
      final updatedItems = List<CartItem>.from(state.items);
      final currentItem = updatedItems[existingIndex];
      updatedItems[existingIndex] = currentItem.copyWith(quantity: currentItem.quantity + quantity);
      state = state.copyWith(items: updatedItems);
    } else {
      state = state.copyWith(items: [...state.items, CartItem(product: product, quantity: quantity)]);
    }
  }

  void updateQuantity(int productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeProduct(productId);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  void removeProduct(int productId) {
    state = state.copyWith(
      items: state.items.where((item) => item.product.id != productId).toList()
    );
  }

  void applyDiscount(double amount) {
    state = state.copyWith(discount: amount);
  }

  void setTaxRate(double rate) {
    state = state.copyWith(taxRate: rate);
  }

  void clear() {
    state = CartState();
  }

  Future<Sale?> checkout(String paymentMethod) async {
    if (state.items.isEmpty) return null;

    final posRepo = ref.read(posRepositoryProvider);

    final sale = Sale(
      totalAmount: state.total,
      discountAmount: state.discount,
      taxAmount: state.taxAmount,
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
    );

    final saleItems = state.items.map((item) => SaleItem(
      productId: item.product.id!,
      quantity: item.quantity,
      unitPrice: item.product.price,
    )).toList();

    try {
      final savedSale = await posRepo.createSale(sale, saleItems);
      // Refresh products to show updated stock
      ref.invalidate(productsProvider);
      clear();
      return savedSale;
    } catch (e) {
      // Handle error
      return null;
    }
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(() {
  return CartNotifier();
});
