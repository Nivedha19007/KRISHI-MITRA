import 'package:flutter_test/flutter_test.dart';
import 'package:agriconnect/data/models/order_model.dart';
import 'package:agriconnect/data/models/product_model.dart';

void main() {
  group('Krishi Mitra Order & Product Model Tests', () {
    test('OrderModel serialization and deserialization', () {
      final now = DateTime.now();
      final order = OrderModel(
        id: 'ord_test_100',
        customerId: 'cust_123',
        customerName: 'Ramesh Customer',
        farmerId: 'farmer_456',
        farmerName: 'Suresh Farmer',
        productId: 'prod_789',
        productName: 'Organic Tomato',
        variety: 'Country',
        quantity: 10.0,
        unit: 'kg',
        pricePerUnit: 35.0,
        totalAmount: 350.0,
        paymentStatus: 'Cash on Delivery',
        orderStatus: 'Placed',
        deliveryAddress: 'Coimbatore, Tamil Nadu',
        batchId: 'TOM-COI-001',
        createdAt: now,
      );

      final map = order.toMap();
      expect(map['id'], 'ord_test_100');
      expect(map['customerId'], 'cust_123');
      expect(map['totalAmount'], 350.0);
      expect(map['paymentStatus'], 'Cash on Delivery');
      expect(map['orderStatus'], 'Placed');

      final restored = OrderModel.fromMap(map, 'ord_test_100');
      expect(restored.id, 'ord_test_100');
      expect(restored.customerName, 'Ramesh Customer');
      expect(restored.quantity, 10.0);
      expect(restored.pricePerUnit, 35.0);
    });

    test('ProductModel copyWith updates isPublished and stock', () {
      final product = ProductModel(
        id: 'prod_1',
        farmerId: 'farmer_1',
        farmerName: 'Farmer Arun',
        state: 'Tamil Nadu',
        district: 'Coimbatore',
        location: 'Farm 1',
        name: 'Rice',
        category: 'Grains',
        variety: 'Sona Masoori',
        quantity: 100.0,
        unit: 'kg',
        pricePerUnit: 50.0,
        harvestDate: DateTime.now(),
        expectedDeliveryDate: DateTime.now().add(const Duration(days: 2)),
        description: 'Premium rice',
        imageUrls: ['https://example.com/rice.jpg'],
        isPublished: true,
      );

      final updated = product.copyWith(
        isPublished: false,
        availableStock: 80.0,
      );

      expect(updated.isPublished, false);
      expect(updated.availableStock, 80.0);
      expect(updated.name, 'Rice');
    });
  });
}
