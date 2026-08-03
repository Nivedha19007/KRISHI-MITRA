import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';

class OrderRepository {
  final List<OrderModel> _orders = [
    OrderModel(
      id: 'ord_1001',
      customerId: 'customer_priya',
      customerName: 'Priya Sharma',
      farmerId: 'farmer_arun',
      farmerName: 'Arun Kumar',
      productId: 'prod_1',
      productName: 'Country Tomato',
      variety: 'Country Red',
      quantity: 5.0,
      unit: 'kg',
      pricePerUnit: 24.0,
      totalAmount: 120.0,
      paymentStatus: 'Payment Successful (Online Pay)',
      orderStatus: 'Delivered',
      deliveryAddress: 'Flat 402, Green Avenue, Anna Nagar, Chennai, Tamil Nadu',
      batchId: 'TOM-ERD-101',
      rating: 5.0,
      reviewText: 'Super fresh country tomatoes delivered straight from Arun farm! Highly recommended.',
      reviewedAt: DateTime.now().subtract(const Duration(hours: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    OrderModel(
      id: 'ord_1002',
      customerId: 'customer_priya',
      customerName: 'Priya Sharma',
      farmerId: 'farmer_arun',
      farmerName: 'Arun Kumar',
      productId: 'prod_2',
      productName: 'Sona Masoori Rice',
      variety: 'Sona Masoori Premium',
      quantity: 10.0,
      unit: 'kg',
      pricePerUnit: 52.0,
      totalAmount: 520.0,
      paymentStatus: 'Cash on Delivery',
      orderStatus: 'Dispatched 🚚',
      deliveryAddress: 'Flat 402, Green Avenue, Anna Nagar, Chennai, Tamil Nadu',
      batchId: 'RIC-CBE-004',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
  ];

  List<OrderModel> getOrdersForUser(String uid, bool isFarmer) {
    if (isFarmer) {
      return _orders.where((o) => o.farmerId == uid || uid.isEmpty).toList();
    } else {
      return _orders.where((o) => o.customerId == uid || uid.isEmpty).toList();
    }
  }

  void placeOrder(OrderModel order) {
    _orders.insert(0, order);
  }

  void updateOrderStatus(String orderId, String newStatus) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(orderStatus: newStatus);
    }
  }

  void addOrderFeedback(String orderId, double rating, String reviewText) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(
        rating: rating,
        reviewText: reviewText,
        reviewedAt: DateTime.now(),
      );
    }
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

class OrdersNotifier extends StateNotifier<List<OrderModel>> {
  final OrderRepository _repo;
  final String _uid;
  final bool _isFarmer;

  OrdersNotifier(this._repo, this._uid, this._isFarmer)
      : super(_repo.getOrdersForUser(_uid, _isFarmer));

  void placeOrder(OrderModel order) {
    _repo.placeOrder(order);
    state = _repo.getOrdersForUser(_uid, _isFarmer);
  }

  void updateStatus(String orderId, String status) {
    _repo.updateOrderStatus(orderId, status);
    state = _repo.getOrdersForUser(_uid, _isFarmer);
  }

  void submitFeedback(String orderId, double rating, String reviewText) {
    _repo.addOrderFeedback(orderId, rating, reviewText);
    state = _repo.getOrdersForUser(_uid, _isFarmer);
  }
}

final ordersProvider = StateNotifierProvider.family<OrdersNotifier, List<OrderModel>, Map<String, dynamic>>((ref, params) {
  return OrdersNotifier(
    ref.watch(orderRepositoryProvider),
    params['uid'] as String,
    params['isFarmer'] as bool,
  );
});
