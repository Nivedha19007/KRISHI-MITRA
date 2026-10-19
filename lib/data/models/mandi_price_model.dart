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
      previousPricePerKg:
          (map['previousPricePerKg'] as num?)?.toDouble() ?? 0.0,
      minPrice: (map['minPrice'] as num?)?.toDouble() ?? 0.0,
      maxPrice: (map['maxPrice'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? '₹/kg',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      historical7Days: List<double>.from(
        (map['historical7Days'] as List<dynamic>?)?.map(
              (e) => (e as num).toDouble(),
            ) ??
            [],
      ),
    );
  }

  static double _parsePrice(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    final str = val.toString().replaceAll(',', '').trim();
    return double.tryParse(str) ?? 0.0;
  }

  factory MandiPriceModel.fromAgmarknetApi(Map<String, dynamic> map) {
    final rawMin = _parsePrice(map['Min_Price'] ?? map['min_price'] ?? map['minPrice'] ?? map['min']);
    final rawMax = _parsePrice(map['Max_Price'] ?? map['max_price'] ?? map['maxPrice'] ?? map['max']);
    final rawModal = _parsePrice(map['Modal_Price'] ?? map['modal_price'] ?? map['modalPrice'] ?? map['modal']);

    // AGMARKNET mandi prices are per Quintal (100 kg). Convert to ₹/kg.
    final modalPerKg = rawModal > 0 ? (rawModal / 100.0) : 0.0;
    var minPerKg = rawMin > 0 ? (rawMin / 100.0) : 0.0;
    var maxPerKg = rawMax > 0 ? (rawMax / 100.0) : 0.0;

    // Fallbacks if min or max is omitted by upstream government dataset
    if (minPerKg == 0.0 && modalPerKg > 0.0) {
      minPerKg = modalPerKg;
    }
    if (maxPerKg == 0.0 && modalPerKg > 0.0) {
      maxPerKg = modalPerKg;
    }

    DateTime parsedDate = DateTime.now();
    final rawDate = map['Arrival_Date'] ?? map['arrival_date'] ?? map['arrivalDate'] ?? map['date'];
    final arrivalStr = rawDate?.toString().trim();
    if (arrivalStr != null && arrivalStr.isNotEmpty) {
      if (arrivalStr.contains('/')) {
        final parts = arrivalStr.split('/');
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]) ?? 1;
          final month = int.tryParse(parts[1]) ?? 1;
          final year = int.tryParse(parts[2]) ?? DateTime.now().year;
          parsedDate = DateTime(year, month, day);
        }
      } else if (arrivalStr.contains('-')) {
        final parts = arrivalStr.split('-');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            parsedDate = DateTime.tryParse(arrivalStr) ?? DateTime.now();
          } else {
            final day = int.tryParse(parts[0]) ?? 1;
            final month = int.tryParse(parts[1]) ?? 1;
            final year = int.tryParse(parts[2]) ?? DateTime.now().year;
            parsedDate = DateTime(year, month, day);
          }
        }
      } else {
        parsedDate = DateTime.tryParse(arrivalStr) ?? DateTime.now();
      }
    }

    final marketName = (map['Market'] ?? map['market'] ?? map['market_name'] ?? map['mandi'] ?? map['mandiName'] ?? 'APMC Mandi')
        .toString()
        .trim();
    final stateName = (map['State'] ?? map['state'] ?? map['state_name'] ?? map['stateName'] ?? '')
        .toString()
        .trim();
    final districtName = (map['District'] ?? map['district'] ?? map['district_name'] ?? map['districtName'] ?? '')
        .toString()
        .trim();
    final commodityName = (map['Commodity'] ?? map['commodity'] ?? map['commodity_name'] ?? map['crop'] ?? map['product'] ?? '')
        .toString()
        .trim();
    final varietyName = (map['Variety'] ?? map['variety'] ?? map['variety_name'] ?? map['grade'] ?? 'Standard')
        .toString()
        .trim();

    return MandiPriceModel(
      id: '${stateName}_${districtName}_${marketName}_$commodityName',
      state: stateName,
      district: districtName,
      mandiName: marketName,
      product: commodityName,
      variety: varietyName,
      currentPricePerKg: modalPerKg,
      previousPricePerKg: modalPerKg,
      minPrice: minPerKg,
      maxPrice: maxPerKg,
      unit: '₹/kg',
      date: parsedDate,
      historical7Days: const [],
    );
  }
}
