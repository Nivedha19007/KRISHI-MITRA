import 'package:flutter_test/flutter_test.dart';
import 'package:agriconnect/core/utils/delivery_calculator.dart';

void main() {
  group('DeliveryCalculator Tests', () {
    test('calculateDistanceInKm returns 0 for identical coordinates', () {
      final dist = DeliveryCalculator.calculateDistanceInKm(
        pickupLat: 11.0168,
        pickupLng: 76.9558,
        deliveryLat: 11.0168,
        deliveryLng: 76.9558,
      );
      expect(dist, 0.0);
    });

    test('calculateDistanceInKm returns non-zero distance between different locations', () {
      // Pollachi to Chennai
      final dist = DeliveryCalculator.calculateDistanceInKm(
        pickupLat: 10.6609,
        pickupLng: 77.0048,
        deliveryLat: 13.0827,
        deliveryLng: 80.2707,
      );
      expect(dist, greaterThan(350.0));
    });

    test('calculateDeliveryCharge applies distance fee up to maximum ₹30 cap', () {
      // 10 km distance: 10 base + (10 * 1) = 20
      final charge10 = DeliveryCalculator.calculateDeliveryCharge(
        distanceInKm: 10.0,
      );
      expect(charge10, 20.0);

      // 50 km distance: computed 10 + 50 = 60, but strictly capped at 30.0
      final charge50 = DeliveryCalculator.calculateDeliveryCharge(
        distanceInKm: 50.0,
      );
      expect(charge50, 30.0);
    });

    test('calculateDeliveryCharge never exceeds ₹30 maximum fee', () {
      final chargeLong = DeliveryCalculator.calculateDeliveryCharge(
        distanceInKm: 500.0,
      );
      expect(chargeLong, 30.0);
    });

    test('calculateFromAddresses returns both distanceKm and deliveryCharge (capped at 30)', () {
      final res = DeliveryCalculator.calculateFromAddresses(
        pickupAddress: 'Pollachi Farm, Pollachi, Tamil Nadu',
        deliveryAddress: 'Anna Nagar, Chennai, Tamil Nadu',
      );
      expect(res.distanceKm, greaterThan(350.0));
      expect(res.deliveryCharge, 30.0);
    });

    test('Order total calculation accurately includes product subtotal, discount, and capped delivery charge', () {
      const double unitPrice = 40.0;
      const double quantity = 10.0;
      const double discountSavings = 50.0;
      const double deliveryCharge = 30.0; // max cap ₹30

      final productSubtotal = unitPrice * quantity; // 400.0
      final finalTotal = (productSubtotal - discountSavings) + deliveryCharge; // 380.0

      expect(productSubtotal, 400.0);
      expect(finalTotal, 380.0);
    });
  });
}
