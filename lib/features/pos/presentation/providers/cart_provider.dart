import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/sale.dart';
import '../../../inventory/domain/entities/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice => product.price * quantity;
}

class CartState {
  final List<CartItem> items;

  CartState({this.items = const []});

  double get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);
  double get estimatedTax => subtotal * 0.08; // 8% tax
  double get total => subtotal + estimatedTax;

  CartState copyWith({List<CartItem>? items}) {
    return CartState(items: items ?? this.items);
  }
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() {
    return CartState();
  }

  void addProduct(Product product) {
    final existingIndex = state.items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      final newItems = List<CartItem>.from(state.items);
      newItems[existingIndex] = CartItem(
        product: product,
        quantity: newItems[existingIndex].quantity + 1,
      );
      state = state.copyWith(items: newItems);
    } else {
      state = state.copyWith(items: [...state.items, CartItem(product: product)]);
    }
  }

  void updateQuantity(Product product, int newQuantity) {
    if (newQuantity <= 0) {
      removeProduct(product);
      return;
    }
    final existingIndex = state.items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      final newItems = List<CartItem>.from(state.items);
      newItems[existingIndex] = CartItem(product: product, quantity: newQuantity);
      state = state.copyWith(items: newItems);
    }
  }

  void removeProduct(Product product) {
    final newItems = state.items.where((item) => item.product.id != product.id).toList();
    state = state.copyWith(items: newItems);
  }

  void clearCart() {
    state = CartState();
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(() {
  return CartNotifier();
});
