import 'distance_calculator.dart';

class DeliveryResult {
  final double distanceKm;
  final double deliveryCharge;

  const DeliveryResult({
    required this.distanceKm,
    required this.deliveryCharge,
  });
}

class DeliveryCalculator {
  static const double defaultMaxFee = 30.0;
  static const double defaultBaseFee = 10.0;
  static const double defaultRatePerKm = 1.0;
  static const double defaultMinFee = 10.0;

  /// Attempts to infer latitude/longitude coordinates from an address string
  /// by matching known district/city names, or falls back to provided default coordinates.
  static List<double> getCoordinatesFromAddress(
    String address, {
    List<double>? fallbackCoords,
  }) {
    final cleanAddress = address.trim().toLowerCase();
    for (final entry in DistanceCalculator.districtCoordinates.entries) {
      if (cleanAddress.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return fallbackCoords ?? [11.0168, 76.9558]; // Default fallback (Coimbatore)
  }

  /// Calculates the straight-line distance in kilometers between pickup and delivery locations.
  static double calculateDistanceInKm({
    required double pickupLat,
    required double pickupLng,
    required double deliveryLat,
    required double deliveryLng,
  }) {
    // If coordinates are identical, distance is 0 km
    if (pickupLat == deliveryLat && pickupLng == deliveryLng) {
      return 0.0;
    }

    final distance = DistanceCalculator.calculateDistance(
      pickupLat,
      pickupLng,
      deliveryLat,
      deliveryLng,
    );

    return double.parse(distance.toStringAsFixed(2));
  }

  /// Calculates the delivery charge using a distance-based fee model.
  /// Formula: charge = baseFee + (distanceInKm * ratePerKm)
  /// Guaranteed NEVER to exceed maxFee (₹30.0).
  static double calculateDeliveryCharge({
    required double distanceInKm,
    double baseFee = defaultBaseFee,
    double ratePerKm = defaultRatePerKm,
    double minFee = defaultMinFee,
    double maxFee = defaultMaxFee,
  }) {
    if (distanceInKm <= 0.0) {
      return minFee;
    }

    final computed = baseFee + (distanceInKm * ratePerKm);
    final clamped = computed.clamp(minFee, maxFee);
    return double.parse(clamped.toStringAsFixed(2));
  }

  /// Convenience method to compute delivery charge directly from pickup and delivery addresses.
  static double calculateChargeFromAddresses({
    required String pickupAddress,
    required String deliveryAddress,
    List<double>? pickupCoords,
    List<double>? deliveryCoords,
    double baseFee = defaultBaseFee,
    double ratePerKm = defaultRatePerKm,
    double minFee = defaultMinFee,
    double maxFee = defaultMaxFee,
  }) {
    final res = calculateFromAddresses(
      pickupAddress: pickupAddress,
      deliveryAddress: deliveryAddress,
      pickupCoords: pickupCoords,
      deliveryCoords: deliveryCoords,
      baseFee: baseFee,
      ratePerKm: ratePerKm,
      minFee: minFee,
      maxFee: maxFee,
    );
    return res.deliveryCharge;
  }

  /// Returns both distanceInKm and deliveryCharge for complete transparency.
  /// Delivery charge is strictly capped at maxFee (₹30.0).
  static DeliveryResult calculateFromAddresses({
    required String pickupAddress,
    required String deliveryAddress,
    List<double>? pickupCoords,
    List<double>? deliveryCoords,
    double baseFee = defaultBaseFee,
    double ratePerKm = defaultRatePerKm,
    double minFee = defaultMinFee,
    double maxFee = defaultMaxFee,
  }) {
    final pCoords = pickupCoords ?? getCoordinatesFromAddress(pickupAddress);
    final dCoords = deliveryCoords ?? getCoordinatesFromAddress(deliveryAddress, fallbackCoords: pCoords);

    final dist = calculateDistanceInKm(
      pickupLat: pCoords[0],
      pickupLng: pCoords[1],
      deliveryLat: dCoords[0],
      deliveryLng: dCoords[1],
    );

    final charge = calculateDeliveryCharge(
      distanceInKm: dist,
      baseFee: baseFee,
      ratePerKm: ratePerKm,
      minFee: minFee,
      maxFee: maxFee,
    );

    return DeliveryResult(
      distanceKm: dist,
      deliveryCharge: charge,
    );
  }
}
