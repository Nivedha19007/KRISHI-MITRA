import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/delivery_model.dart';

class DeliveryRepository {
  final FirebaseFirestore _firestore;
  final List<DeliveryModel> _localDeliveries = [];

  DeliveryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _deliveriesCollection =>
      _firestore.collection('deliveries');

  CollectionReference<Map<String, dynamic>> get _ordersCollection =>
      _firestore.collection('orders');

  /// Creates a new delivery request in Firestore and local storage.
  Future<void> createDeliveryRequest(DeliveryModel delivery) async {
    final deliveryId = delivery.id.isNotEmpty
        ? delivery.id
        : 'del_${delivery.orderId.isNotEmpty ? delivery.orderId : DateTime.now().millisecondsSinceEpoch}';

    final finalDelivery = delivery.copyWith(id: deliveryId);

    _localDeliveries.removeWhere((d) => d.id == deliveryId || d.orderId == finalDelivery.orderId);
    _localDeliveries.insert(0, finalDelivery);

    debugPrint('[DELIVERY_REPO] Creating delivery request: $deliveryId for Order: ${finalDelivery.orderId}');

    try {
      await _deliveriesCollection.doc(deliveryId).set(finalDelivery.toMap(), SetOptions(merge: true));
      debugPrint('[DELIVERY_REPO] Delivery request stored successfully in Firestore!');
    } on FirebaseException catch (e) {
      debugPrint('[DELIVERY_REPO_ERROR] Firestore write failed: ${e.code} - ${e.message}');
    } catch (e) {
      debugPrint('[DELIVERY_REPO_ERROR] Unexpected error storing delivery: $e');
    }
  }

  /// Updates the delivery status and synchronizes it with the corresponding order status in Firestore.
  /// Status transition flow: Placed → Assigned → Pickup → In Transit → Delivered
  Future<void> updateDeliveryStatus(String deliveryId, String newStatus) async {
    final now = DateTime.now();
    final idx = _localDeliveries.indexWhere((d) => d.id == deliveryId);
    String targetOrderId = '';

    if (idx != -1) {
      _localDeliveries[idx] = _localDeliveries[idx].copyWith(
        deliveryStatus: newStatus,
        updatedAt: now,
      );
      targetOrderId = _localDeliveries[idx].orderId;
    }

    try {
      final docSnap = await _deliveriesCollection.doc(deliveryId).get();
      if (docSnap.exists && docSnap.data() != null) {
        targetOrderId = docSnap.data()!['orderId'] ?? targetOrderId;
      }

      await _deliveriesCollection.doc(deliveryId).update({
        'deliveryStatus': newStatus,
        'updatedAt': now.toIso8601String(),
      });

      if (targetOrderId.isNotEmpty) {
        await _ordersCollection.doc(targetOrderId).update({
          'orderStatus': newStatus,
          'status': newStatus,
          'updatedAt': now.toIso8601String(),
        });
      }

      debugPrint('[DELIVERY_REPO] Delivery $deliveryId & Order $targetOrderId updated to status: $newStatus');
    } on FirebaseException catch (e) {
      debugPrint('[DELIVERY_REPO_ERROR] updateDeliveryStatus failed: ${e.code} - ${e.message}');
      throw Exception('Failed to update delivery status: ${e.message ?? e.code}');
    }
  }

  /// Assigns a delivery partner to a delivery request and updates status to 'Assigned'.
  Future<void> assignDeliveryPartner({
    required String deliveryId,
    required String partnerId,
    required String partnerName,
    String partnerPhone = '',
  }) async {
    final now = DateTime.now();
    final idx = _localDeliveries.indexWhere((d) => d.id == deliveryId);
    String targetOrderId = '';

    if (idx != -1) {
      _localDeliveries[idx] = _localDeliveries[idx].copyWith(
        assignedPartnerId: partnerId,
        assignedPartnerName: partnerName,
        assignedPartnerPhone: partnerPhone,
        deliveryStatus: 'Assigned',
        updatedAt: now,
      );
      targetOrderId = _localDeliveries[idx].orderId;
    }

    try {
      final docSnap = await _deliveriesCollection.doc(deliveryId).get();
      if (docSnap.exists && docSnap.data() != null) {
        targetOrderId = docSnap.data()!['orderId'] ?? targetOrderId;
      }

      await _deliveriesCollection.doc(deliveryId).update({
        'assignedPartnerId': partnerId,
        'assignedPartnerName': partnerName,
        'assignedPartnerPhone': partnerPhone,
        'deliveryStatus': 'Assigned',
        'updatedAt': now.toIso8601String(),
      });

      if (targetOrderId.isNotEmpty) {
        await _ordersCollection.doc(targetOrderId).update({
          'orderStatus': 'Assigned',
          'status': 'Assigned',
          'updatedAt': now.toIso8601String(),
        });
      }

      debugPrint('[DELIVERY_REPO] Delivery $deliveryId assigned to $partnerName ($partnerId)');
    } on FirebaseException catch (e) {
      debugPrint('[DELIVERY_REPO_ERROR] assignDeliveryPartner failed: ${e.code} - ${e.message}');
      throw Exception('Failed to assign delivery partner: ${e.message ?? e.code}');
    }
  }

  /// Streams all platform delivery requests for Admin and Delivery Partner views.
  Stream<List<DeliveryModel>> watchAllDeliveries() {
    final authUser = fb.FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      return Stream.value(List.unmodifiable(_localDeliveries));
    }

    return _deliveriesCollection.snapshots().map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final list = snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          return DeliveryModel.fromMap(data, doc.id);
        }).toList();

        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      }
      return List<DeliveryModel>.unmodifiable(_localDeliveries);
    }).handleError((e) {
      debugPrint('[DELIVERY_REPO_WARN] watchAllDeliveries error: $e');
      return List<DeliveryModel>.unmodifiable(_localDeliveries);
    });
  }

  /// Streams delivery details for a specific order.
  Stream<DeliveryModel?> watchDeliveryForOrder(String orderId) {
    if (orderId.isEmpty) return Stream.value(null);

    return _deliveriesCollection
        .where('orderId', isEqualTo: orderId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return DeliveryModel.fromMap(
          Map<String, dynamic>.from(snapshot.docs.first.data()),
          snapshot.docs.first.id,
        );
      }
      final local = _localDeliveries.where((d) => d.orderId == orderId).firstOrNull;
      return local;
    }).handleError((e) {
      debugPrint('[DELIVERY_REPO_WARN] watchDeliveryForOrder error: $e');
      return null;
    });
  }
}

// Riverpod Providers
final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  return DeliveryRepository();
});

final allDeliveriesStreamProvider = StreamProvider<List<DeliveryModel>>((ref) {
  final repo = ref.watch(deliveryRepositoryProvider);
  return repo.watchAllDeliveries();
});

final deliveryForOrderStreamProvider =
    StreamProvider.family<DeliveryModel?, String>((ref, orderId) {
  final repo = ref.watch(deliveryRepositoryProvider);
  return repo.watchDeliveryForOrder(orderId);
});
