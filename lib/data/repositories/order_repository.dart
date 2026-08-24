import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datasources/sample_data.dart';
import '../models/order_model.dart';
import '../models/review_model.dart';

class FarmerStats {
  final double totalRevenue;
  final int totalOrders;
  final int pendingOrders;
  final int completedOrders;
  final double totalProductsSold;
  final double averageRating;
  final int totalReviews;

  FarmerStats({
    required this.totalRevenue,
    required this.totalOrders,
    required this.pendingOrders,
    required this.completedOrders,
    required this.totalProductsSold,
    required this.averageRating,
    required this.totalReviews,
  });
}

class OrderRepository {
  final FirebaseFirestore _firestore;
  final List<OrderModel> _localOrders = List<OrderModel>.from(
    SampleData.sampleOrders,
  );

  OrderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersCollection =>
      _firestore.collection('orders');

  // ============================================================
  // PLACE ORDER (Requirement 8: Atomic Stock Transaction)
  // ============================================================

  Future<void> placeOrder(OrderModel order) async {
    final currentAuthUid = fb.FirebaseAuth.instance.currentUser?.uid;
    final effectiveCustomerId = (currentAuthUid != null && currentAuthUid.isNotEmpty)
        ? currentAuthUid
        : order.customerId;

    final orderId = order.id.isNotEmpty
        ? order.id
        : 'ord_${DateTime.now().millisecondsSinceEpoch}';

    final finalOrder = order.copyWith(
      id: orderId,
      customerId: effectiveCustomerId,
    );

    debugPrint('[ORDER_REPO] Starting atomic transaction for Order ID: $orderId');
    debugPrint('[ORDER_REPO] Target Product ID: ${finalOrder.productId}');
    debugPrint('[ORDER_REPO] Customer UID: $effectiveCustomerId | Farmer UID: ${finalOrder.farmerId}');

    final productRef = _firestore.collection('products').doc(finalOrder.productId);
    final orderRef = _ordersCollection.doc(orderId);

    try {
      await _firestore.runTransaction((transaction) async {
        final productDoc = await transaction.get(productRef);

        if (!productDoc.exists || productDoc.data() == null) {
          throw Exception('Product document not found in Firestore.');
        }

        final productData = productDoc.data()!;
        final currentStock = (productData['availableStock'] as num?)?.toDouble() ?? 0.0;

        if (currentStock < finalOrder.quantity) {
          throw Exception(
            'Insufficient stock available. Requested: ${finalOrder.quantity}, Available: $currentStock',
          );
        }

        final newStock = currentStock - finalOrder.quantity;
        transaction.update(productRef, {
          'availableStock': newStock,
        });

        transaction.set(orderRef, finalOrder.toMap(), SetOptions(merge: true));
      });

      _localOrders.insert(0, finalOrder);
      debugPrint('[ORDER_REPO] Transaction succeeded! Stock deducted & order placed.');
    } on FirebaseException catch (e) {
      debugPrint('[ORDER_REPO_ERROR] Transaction failed: ${e.code} - ${e.message}');
      throw Exception('Failed to place order [${e.code}]: ${e.message ?? "Permission denied."}');
    } catch (e) {
      debugPrint('[ORDER_REPO_ERROR] Transaction failed: $e');
      rethrow;
    }
  }

  // ============================================================
  // UPDATE ORDER STATUS
  // ============================================================

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final idx = _localOrders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _localOrders[idx] = _localOrders[idx].copyWith(
        orderStatus: newStatus,
      );
    }

    try {
      await _ordersCollection.doc(orderId).update({
        'orderStatus': newStatus,
        'status': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('[ORDER_REPO] Order $orderId status updated to: $newStatus');
    } on FirebaseException catch (e) {
      debugPrint('[ORDER_REPO_ERROR] updateOrderStatus failed: ${e.code} - ${e.message}');
      throw Exception('Failed to update order status: ${e.message ?? e.code}');
    }
  }

  // ============================================================
  // WATCH / GET ORDERS FOR USER
  // ============================================================

  List<OrderModel> getOrdersForUser(String uid, bool isFarmer) {
    if (isFarmer) {
      return _localOrders.where((o) => o.farmerId == uid).toList();
    }
    return _localOrders.where((o) => o.customerId == uid).toList();
  }

  Stream<List<OrderModel>> watchOrdersForUser(String uid, bool isFarmer) {
    final authUid = fb.FirebaseAuth.instance.currentUser?.uid;
    if (authUid == null || authUid.isEmpty || uid.isEmpty) {
      return Stream.value(getOrdersForUser(uid, isFarmer));
    }

    final queryField = isFarmer ? 'farmerId' : 'customerId';
    final query = _ordersCollection.where(queryField, isEqualTo: uid);

    return query.snapshots().map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final remoteOrders = snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          for (final k in ['reviewedAt', 'createdAt', 'updatedAt', 'orderDate']) {
            if (data[k] is Timestamp) {
              data[k] = (data[k] as Timestamp).toDate().toIso8601String();
            }
          }
          return OrderModel.fromMap(data, doc.id);
        }).toList();

        for (final o in remoteOrders) {
          final idx = _localOrders.indexWhere((lo) => lo.id == o.id);
          if (idx != -1) {
            _localOrders[idx] = o;
          } else {
            _localOrders.insert(0, o);
          }
        }
      }
      return getOrdersForUser(uid, isFarmer);
    }).handleError((e) {
      debugPrint('[ORDER_REPO_WARN] watchOrdersForUser error: $e');
      return getOrdersForUser(uid, isFarmer);
    });
  }

  Stream<List<OrderModel>> watchAllPlatformOrders() {
    final authUser = fb.FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      return Stream.value([]);
    }

    return _ordersCollection.snapshots().map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          for (final k in ['reviewedAt', 'createdAt', 'updatedAt', 'orderDate']) {
            if (data[k] is Timestamp) {
              data[k] = (data[k] as Timestamp).toDate().toIso8601String();
            }
          }
          return OrderModel.fromMap(data, doc.id);
        }).toList();
      }
      return List<OrderModel>.unmodifiable(_localOrders);
    }).handleError((e) {
      debugPrint('[ORDER_REPO_WARN] watchAllPlatformOrders error: $e');
      return List<OrderModel>.unmodifiable(_localOrders);
    });
  }

  // ============================================================
  // REVIEWS & FEEDBACK
  // ============================================================

  Stream<List<ReviewModel>> watchReviewsForFarmer(String farmerId) {
    final authUid = fb.FirebaseAuth.instance.currentUser?.uid;
    if (authUid == null || authUid.isEmpty || farmerId.isEmpty) {
      return Stream.value(<ReviewModel>[]);
    }

    return _firestore
        .collection('reviews')
        .where('farmerId', isEqualTo: farmerId)
        .snapshots()
        .map<List<ReviewModel>>((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
            .toList();
      }
      return <ReviewModel>[];
    }).handleError((e) {
      debugPrint('[ORDER_REPO_WARN] watchReviewsForFarmer error: $e');
      return <ReviewModel>[];
    });
  }

  Future<void> addOrderFeedback(
    String orderId,
    double rating,
    String reviewText,
  ) async {
    final now = DateTime.now();
    final idx = _localOrders.indexWhere((o) => o.id == orderId);
    OrderModel? targetOrder;

    if (idx != -1) {
      _localOrders[idx] = _localOrders[idx].copyWith(
        rating: rating,
        reviewText: reviewText,
        reviewedAt: now,
      );
      targetOrder = _localOrders[idx];
    }

    try {
      await _ordersCollection.doc(orderId).update({
        'rating': rating,
        'reviewText': reviewText,
        'reviewedAt': now.toIso8601String(),
      });

      if (targetOrder != null) {
        final reviewId = 'rev_${DateTime.now().millisecondsSinceEpoch}';
        final review = ReviewModel(
          id: reviewId,
          orderId: orderId,
          farmerId: targetOrder.farmerId,
          customerId: targetOrder.customerId,
          customerName: targetOrder.customerName,
          productId: targetOrder.productId,
          productName: targetOrder.productName,
          rating: rating,
          comment: reviewText,
          createdAt: now,
        );

        await _firestore.collection('reviews').doc(reviewId).set(review.toMap());

        final productId = targetOrder.productId;
        final reviewsSnap = await _firestore
            .collection('reviews')
            .where('productId', isEqualTo: productId)
            .get();

        if (reviewsSnap.docs.isNotEmpty) {
          final count = reviewsSnap.docs.length;
          final sum = reviewsSnap.docs.fold<double>(
            0.0,
            (t, d) => t + ((d.data()['rating'] as num?)?.toDouble() ?? 0.0),
          );
          final avgRating = double.parse((sum / count).toStringAsFixed(1));

          await _firestore.collection('products').doc(productId).update({
            'rating': avgRating,
            'reviewCount': count,
          });
        }
      }
    } on FirebaseException catch (e) {
      debugPrint('[ORDER_REPO_ERROR] addOrderFeedback failed: ${e.code} - ${e.message}');
      throw Exception('Failed to submit review: ${e.message ?? e.code}');
    }
  }
}

// ================================================================
// RIVERPOD PROVIDERS
// ================================================================

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

final customerOrdersStreamProvider =
    StreamProvider.family<List<OrderModel>, String>((ref, customerId) {
      final repo = ref.watch(orderRepositoryProvider);
      return repo.watchOrdersForUser(customerId, false);
    });

final farmerOrdersStreamProvider =
    StreamProvider.family<List<OrderModel>, String>((ref, farmerId) {
      final repo = ref.watch(orderRepositoryProvider);
      return repo.watchOrdersForUser(farmerId, true);
    });

final farmerReviewsStreamProvider =
    StreamProvider.family<List<ReviewModel>, String>((ref, farmerId) {
      final repo = ref.watch(orderRepositoryProvider);
      return repo.watchReviewsForFarmer(farmerId);
    });

final allPlatformOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.watchAllPlatformOrders();
});

final farmerStatisticsProvider =
    Provider.family<FarmerStats, String>((ref, farmerId) {
      final ordersAsync = ref.watch(farmerOrdersStreamProvider(farmerId));
      final reviewsAsync = ref.watch(farmerReviewsStreamProvider(farmerId));

      final orders = ordersAsync.value ?? [];
      final reviews = reviewsAsync.value ?? [];

      final totalRevenue = orders.fold<double>(
        0.0,
        (total, o) => total + o.totalAmount,
      );
      final totalOrders = orders.length;
      final pendingOrders =
          orders.where((o) => o.orderStatus != 'Delivered').length;
      final completedOrders =
          orders.where((o) => o.orderStatus == 'Delivered').length;
      final totalProductsSold = orders.fold<double>(
        0.0,
        (total, o) => total + o.quantity,
      );

      final totalReviews = reviews.length;
      final avgRating = totalReviews > 0
          ? reviews.fold<double>(0.0, (total, r) => total + r.rating) /
              totalReviews
          : (orders.where((o) => o.rating != null).isNotEmpty
              ? orders
                      .where((o) => o.rating != null)
                      .fold<double>(0.0, (total, o) => total + (o.rating ?? 0)) /
                  orders.where((o) => o.rating != null).length
              : 0.0);

      return FarmerStats(
        totalRevenue: totalRevenue,
        totalOrders: totalOrders,
        pendingOrders: pendingOrders,
        completedOrders: completedOrders,
        totalProductsSold: totalProductsSold,
        averageRating: double.parse(avgRating.toStringAsFixed(1)),
        totalReviews: totalReviews,
      );
    });
