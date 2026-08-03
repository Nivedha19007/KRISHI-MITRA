class MandiPriceModel {
  final String id;
  final String state;
  final String district;
  final String mandiName;
  final String product;
  final String variety;
  final double currentPricePerKg;
  final double previousPricePerKg;
  final double minPrice;
  final double maxPrice;
  final String unit;
  final DateTime date;
  final List<double> historical7Days;

  MandiPriceModel({
    required this.id,
    required this.state,
    required this.district,
    required this.mandiName,
    required this.product,
    required this.variety,
    required this.currentPricePerKg,
    required this.previousPricePerKg,
    required this.minPrice,
    required this.maxPrice,
    this.unit = '₹/kg',
    DateTime? date,
    required this.historical7Days,
  }) : date = date ?? DateTime.now();

  double get priceChange => currentPricePerKg - previousPricePerKg;
  bool get isUpward => priceChange >= 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'state': state,
      'district': district,
      'mandiName': mandiName,
      'product': product,
      'variety': variety,
      'currentPricePerKg': currentPricePerKg,
      'previousPricePerKg': previousPricePerKg,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'unit': unit,
      'date': date.toIso8601String(),
      'historical7Days': historical7Days,
    };
  }

  factory MandiPriceModel.fromMap(Map<String, dynamic> map, String id) {
    return MandiPriceModel(
      id: id,
      state: map['state'] ?? '',
      district: map['district'] ?? '',
      mandiName: map['mandiName'] ?? '',
      product: map['product'] ?? '',
      variety: map['variety'] ?? 'General',
      currentPricePerKg: (map['currentPricePerKg'] as num?)?.toDouble() ?? 0.0,
      previousPricePerKg: (map['previousPricePerKg'] as num?)?.toDouble() ?? 0.0,
      minPrice: (map['minPrice'] as num?)?.toDouble() ?? 0.0,
      maxPrice: (map['maxPrice'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? '₹/kg',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      historical7Days: List<double>.from((map['historical7Days'] as List<dynamic>?)?.map((e) => (e as num).toDouble()) ?? []),
    );
  }
}
