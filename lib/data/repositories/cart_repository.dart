import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';

class CartItem {
  final ProductModel product;
  final double quantity;

  CartItem({required this.product, required this.quantity});

  double get effectiveUnitPrice {
    if (product.bulkDiscountMinQty != null &&
        product.bulkDiscountPricePerUnit != null &&
        product.bulkDiscountMinQty! > 0 &&
        quantity >= product.bulkDiscountMinQty!) {
      return product.bulkDiscountPricePerUnit!;
    }
    return product.pricePerUnit;
  }

  bool get isBulkDiscountApplied {
    return effectiveUnitPrice < product.pricePerUnit;
  }

  double get totalPrice => effectiveUnitPrice * quantity;

  double get normalTotalPrice => product.pricePerUnit * quantity;

  double get discountAmount => normalTotalPrice - totalPrice;

  CartItem copyWith({ProductModel? product, double? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addToCart(ProductModel product, double qty) {
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      final existing = state[index];
      final updatedList = List<CartItem>.from(state);
      updatedList[index] = existing.copyWith(quantity: existing.quantity + qty);
      state = updatedList;
    } else {
      state = [...state, CartItem(product: product, quantity: qty)];
    }
  }

  void updateQuantity(String productId, double qty) {
    if (qty <= 0) {
      removeFromCart(productId);
      return;
    }
    state = state.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: qty);
      }
      return item;
    }).toList();
  }

  void removeFromCart(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void clearCart() {
    state = [];
  }

  double get totalCartAmount {
    return state.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  int get itemCount {
    return state.length;
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});
