import 'package:flutter_test/flutter_test.dart';
import 'package:agriconnect/data/models/order_model.dart';
import 'package:agriconnect/data/models/product_model.dart';
import 'package:agriconnect/data/models/user_model.dart';

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

    test('Bulk discount calculation and stock availability check', () {
      final product = ProductModel(
        id: 'prod_bulk',
        farmerId: 'farmer_1',
        farmerName: 'Farmer Arun',
        state: 'Tamil Nadu',
        district: 'Erode',
        location: 'Farm 1',
        name: 'Turmeric',
        category: 'Spices',
        variety: 'Erode Organic',
        quantity: 500.0,
        availableStock: 50.0,
        unit: 'kg',
        pricePerUnit: 150.0,
        bulkDiscountMinQty: 20.0,
        bulkDiscountPricePerUnit: 120.0,
        harvestDate: DateTime.now(),
        expectedDeliveryDate: DateTime.now().add(const Duration(days: 2)),
        description: 'Pure Erode organic turmeric',
        imageUrls: ['https://example.com/turmeric.jpg'],
        isPublished: true,
      );

      // Normal order (< min bulk qty)
      double qtyNormal = 10.0;
      double normalUnitPrice = (product.bulkDiscountMinQty != null &&
              product.bulkDiscountPricePerUnit != null &&
              qtyNormal >= product.bulkDiscountMinQty!)
          ? product.bulkDiscountPricePerUnit!
          : product.pricePerUnit;
      expect(normalUnitPrice, 150.0);
      expect(qtyNormal * normalUnitPrice, 1500.0);

      // Bulk order (>= min bulk qty)
      double qtyBulk = 25.0;
      double bulkUnitPrice = (product.bulkDiscountMinQty != null &&
              product.bulkDiscountPricePerUnit != null &&
              qtyBulk >= product.bulkDiscountMinQty!)
          ? product.bulkDiscountPricePerUnit!
          : product.pricePerUnit;
      expect(bulkUnitPrice, 120.0);
      expect(qtyBulk * bulkUnitPrice, 3000.0);

      // Stock deduction simulation
      double newStock = product.availableStock - qtyBulk;
      expect(newStock, 25.0);
      expect(newStock >= 0, true);
    });

    test('UserModel verification status transitions and role checks', () {
      final user = UserModel(
        uid: 'farmer_test_1',
        name: 'Kumar',
        email: 'kumar@agriconnect.org',
        phone: '+919876543210',
        role: UserRole.farmer,
        verificationStatus: VerificationStatus.pending,
      );

      expect(user.verificationStatus, VerificationStatus.pending);

      final verifiedUser = user.copyWith(
        verificationStatus: VerificationStatus.verified,
        verifiedBy: 'admin_1',
        verifiedAt: DateTime.now(),
      );

      expect(verifiedUser.verificationStatus, VerificationStatus.verified);
      expect(verifiedUser.verifiedBy, 'admin_1');

      final rejectedUser = user.copyWith(
        verificationStatus: VerificationStatus.rejected,
        rejectionReason: 'Invalid certificate documents provided.',
      );

      expect(rejectedUser.verificationStatus, VerificationStatus.rejected);
      expect(rejectedUser.rejectionReason, 'Invalid certificate documents provided.');
    });
  });
}
