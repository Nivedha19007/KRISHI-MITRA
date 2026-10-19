import 'package:flutter_test/flutter_test.dart';
import 'package:agriconnect/data/models/delivery_model.dart';

void main() {
  group('DeliveryModel Tests', () {
    test('toMap and fromMap serialize and deserialize correctly', () {
      final now = DateTime.now();
      final delivery = DeliveryModel(
        id: 'del_12345',
        orderId: 'ord_12345',
        customerId: 'cust_001',
        customerName: 'Ramesh Kumar',
        customerPhone: '+919876543210',
        farmerId: 'farm_001',
        farmerName: 'Senthil Farmer',
        farmerPhone: '+919876543211',
        pickupLocation: 'Pollachi, Tamil Nadu',
        pickupLatitude: 10.6609,
        pickupLongitude: 77.0048,
        deliveryAddress: 'Anna Nagar, Chennai, Tamil Nadu',
        deliveryLatitude: 13.0827,
        deliveryLongitude: 80.2707,
        deliveryCharge: 85.0,
        productSubtotal: 500.0,
        finalTotal: 585.0,
        deliveryStatus: 'Placed',
        createdAt: now,
      );

      final map = delivery.toMap();
      final restored = DeliveryModel.fromMap(map, 'del_12345');

      expect(restored.id, 'del_12345');
      expect(restored.orderId, 'ord_12345');
      expect(restored.customerId, 'cust_001');
      expect(restored.farmerName, 'Senthil Farmer');
      expect(restored.deliveryCharge, 85.0);
      expect(restored.finalTotal, 585.0);
      expect(restored.deliveryStatus, 'Placed');
    });

    test('delivery status transitions progress correctly Placed -> Assigned -> Pickup -> In Transit -> Delivered', () {
      var delivery = DeliveryModel(
        id: 'del_100',
        orderId: 'ord_100',
        customerId: 'cust_1',
        customerName: 'Customer',
        farmerId: 'farm_1',
        farmerName: 'Farmer',
        pickupLocation: 'Coimbatore',
        deliveryAddress: 'Salem',
        deliveryCharge: 50.0,
      );

      expect(delivery.deliveryStatus, 'Placed');

      delivery = delivery.copyWith(
        deliveryStatus: 'Assigned',
        assignedPartnerId: 'partner_1',
        assignedPartnerName: 'Fast Express Logistics',
      );
      expect(delivery.deliveryStatus, 'Assigned');
      expect(delivery.assignedPartnerName, 'Fast Express Logistics');

      delivery = delivery.copyWith(deliveryStatus: 'Pickup');
      expect(delivery.deliveryStatus, 'Pickup');

      delivery = delivery.copyWith(deliveryStatus: 'In Transit');
      expect(delivery.deliveryStatus, 'In Transit');

      delivery = delivery.copyWith(deliveryStatus: 'Delivered');
      expect(delivery.deliveryStatus, 'Delivered');
    });
  });
}
