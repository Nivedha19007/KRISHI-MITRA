class PredictionResult {
  final String product;
  final String variety;
  final String location;
  final double currentPrice;
  final double predictedPrice3Days;
  final double predictedPrice5Days;
  final double predictedPrice7Days;
  final double minPredictedPrice;
  final double maxPredictedPrice;
  final String trend; // Upward, Downward, Stable
  final double confidencePercentage;
  final String recommendation;

  PredictionResult({
    required this.product,
    required this.variety,
    required this.location,
    required this.currentPrice,
    required this.predictedPrice3Days,
    required this.predictedPrice5Days,
    required this.predictedPrice7Days,
    required this.minPredictedPrice,
    required this.maxPredictedPrice,
    required this.trend,
    required this.confidencePercentage,
    required this.recommendation,
  });
}

class PricePredictionService {
  /// Variety-specific price prediction abstraction.
  /// Accepts product, variety, location, and historical price list.
  /// Returns a structured PredictionResult.
  /// Can be connected to a Python/FastAPI ML server or TensorFlow Lite model in the future.
  Future<PredictionResult> predictPrice({
    required String product,
    required String variety,
    required String location,
    required double currentPrice,
    required List<double> historicalPrices,
  }) async {
    // Simulate brief network/ML calculation delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Variety-specific multiplier heuristics for prototype demonstration
    double multiplier = 1.15; // default upward multiplier
    if (variety.toLowerCase().contains('country') || variety.toLowerCase().contains('desi')) {
      multiplier = 1.22;
    } else if (variety.toLowerCase().contains('hybrid')) {
      multiplier = 1.10;
    } else if (variety.toLowerCase().contains('cherry')) {
      multiplier = 1.18;
    } else if (variety.toLowerCase().contains('roma')) {
      multiplier = 1.08;
    }

    final p3 = (currentPrice * (1 + (multiplier - 1) * 0.4)).roundToDouble();
    final p5 = (currentPrice * (1 + (multiplier - 1) * 0.7)).roundToDouble();
    final p7 = (currentPrice * multiplier).roundToDouble();

    final minPrice = (p7 * 0.95).roundToDouble();
    final maxPrice = (p7 * 1.05).roundToDouble();

    return PredictionResult(
      product: product,
      variety: variety,
      location: location,
      currentPrice: currentPrice,
      predictedPrice3Days: p3,
      predictedPrice5Days: p5,
      predictedPrice7Days: p7,
      minPredictedPrice: minPrice,
      maxPredictedPrice: maxPrice,
      trend: 'Upward',
      confidencePercentage: 82.5,
      recommendation:
          'Prices for $variety are showing an expected upward trend due to seasonal demand. Compare storage and delivery costs before deciding whether to sell now or hold stock.',
    );
  }
}
