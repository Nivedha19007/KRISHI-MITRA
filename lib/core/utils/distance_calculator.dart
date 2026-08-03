import 'dart:math';

class DistanceCalculator {
  /// Calculates distance in kilometers between two lat/lng coordinates using Haversine formula
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 12742 = 2 * Earth Radius (6371 km)
  }

  /// Default coordinates lookup for major Indian districts / agricultural hubs
  static final Map<String, List<double>> districtCoordinates = {
    'Erode': [11.3410, 77.7172],
    'Coimbatore': [11.0168, 76.9558],
    'Salem': [11.6643, 78.1460],
    'Pollachi': [10.6609, 77.0048],
    'Tiruppur': [11.1085, 77.3411],
    'Madurai': [9.9252, 78.1198],
    'Dindigul': [10.3673, 77.9803],
    'Tiruchirappalli': [10.7905, 78.7047],
    'Thanjavur': [10.7870, 79.1378],
    'Chennai': [13.0827, 80.2707],
    'Bengaluru': [12.9716, 77.5946],
    'Mysuru': [12.2958, 76.6394],
    'Kolar': [13.1368, 78.1291],
    'Hyderabad': [17.3850, 78.4867],
    'Vijayawada': [16.5062, 80.6480],
    'Nashik': [19.9975, 73.7898],
    'Pune': [18.5204, 73.8567],
  };

  static List<double> getCoordinatesForDistrict(String district, String state) {
    if (districtCoordinates.containsKey(district)) {
      return districtCoordinates[district]!;
    }
    // Fallback to Coimbatore coordinates if unknown
    return [11.0168, 76.9558];
  }
}
