import 'user_model.dart';
import '../../core/utils/distance_calculator.dart';

class ProductModel {
  final String id;
  final String farmerId;
  final String farmerName;
  final String farmerMobile;
  final String state;
  final String district;
  final String village;
  final String location; // Farm Location
  final double latitude;
  final double longitude;
  final String name; // Crop Name
  final String
  category; // Crop Category: Vegetables, Fruits, Grains, Pulses, Spices
  final String variety; // Crop Variety: Country Tomato, Sona Masoori, etc.
  final double quantity; // Initial Quantity
  final double availableStock; // Available Stock
  final String unit; // Kg / Ton / Quintal
  final double pricePerUnit; // Price per Kg/Unit
  final DateTime harvestDate;
  final bool qualityChecked;
  final bool packed;
  final bool dispatched;
  final DateTime expectedDeliveryDate; // Expected Delivery Time
  final String description;
  final List<String> imageUrls;
  final String? certificateUrl;
  final String certificateName;
  final bool isOrganic; // Organic / Non Organic
  final bool isVerifiedFarmer; // Verified Farmer Badge
  final VerificationStatus certificationStatus;
  final String farmingType; // Organic, Conventional, GAP
  final String? batchId;
  final String? certificateId;
  final bool isPublished;
  final double rating;
  final int reviewCount;
  final double? bulkDiscountMinQty;
  final double? bulkDiscountPricePerUnit;
  final String? rejectionReason;
  final DateTime createdAt;

  bool get isOrganicVerified => isOrganic && certificationStatus == VerificationStatus.verified;

  ProductModel({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    this.farmerMobile = '',
    required this.state,
    required this.district,
    this.village = '',
    required this.location,
    double? latitude,
    double? longitude,
    required this.name,
    required this.category,
    required this.variety,
    required this.quantity,
    double? availableStock,
    required this.unit,
    required this.pricePerUnit,
    required this.harvestDate,
    this.qualityChecked = false,
    this.packed = false,
    this.dispatched = false,
    required this.expectedDeliveryDate,
    required this.description,
    required this.imageUrls,
    this.certificateUrl,
    this.certificateName = '',
    this.isOrganic = false,
    this.isVerifiedFarmer = false,
    this.certificationStatus = VerificationStatus.pending,
    this.farmingType = 'Conventional',
    this.batchId,
    this.certificateId,
    this.isPublished = true,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.bulkDiscountMinQty,
    this.bulkDiscountPricePerUnit,
    this.rejectionReason,
    DateTime? createdAt,
  }) : latitude =
           latitude ??
           DistanceCalculator.getCoordinatesForDistrict(district, state)[0],
       longitude =
           longitude ??
           DistanceCalculator.getCoordinatesForDistrict(district, state)[1],
       availableStock = availableStock ?? quantity,
       createdAt = createdAt ?? DateTime.now();

  ProductModel copyWith({
    String? id,
    String? farmerId,
    String? farmerName,
    String? farmerMobile,
    String? state,
    String? district,
    String? village,
    String? location,
    double? latitude,
    double? longitude,
    String? name,
    String? category,
    String? variety,
    double? quantity,
    double? availableStock,
    String? unit,
    double? pricePerUnit,
    DateTime? harvestDate,
    bool? qualityChecked,
    bool? packed,
    bool? dispatched,
    DateTime? expectedDeliveryDate,
    String? description,
    List<String>? imageUrls,
    String? certificateUrl,
    String? certificateName,
    bool? isOrganic,
    bool? isVerifiedFarmer,
    VerificationStatus? certificationStatus,
    String? farmingType,
    String? batchId,
    String? certificateId,
    bool? isPublished,
    double? rating,
    int? reviewCount,
    double? bulkDiscountMinQty,
    double? bulkDiscountPricePerUnit,
    String? rejectionReason,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      farmerMobile: farmerMobile ?? this.farmerMobile,
      state: state ?? this.state,
      district: district ?? this.district,
      village: village ?? this.village,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      name: name ?? this.name,
      category: category ?? this.category,
      variety: variety ?? this.variety,
      quantity: quantity ?? this.quantity,
      availableStock: availableStock ?? this.availableStock,
      unit: unit ?? this.unit,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      harvestDate: harvestDate ?? this.harvestDate,
      qualityChecked: qualityChecked ?? this.qualityChecked,
      packed: packed ?? this.packed,
      dispatched: dispatched ?? this.dispatched,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      certificateUrl: certificateUrl ?? this.certificateUrl,
      certificateName: certificateName ?? this.certificateName,
      isOrganic: isOrganic ?? this.isOrganic,
      isVerifiedFarmer: isVerifiedFarmer ?? this.isVerifiedFarmer,
      certificationStatus: certificationStatus ?? this.certificationStatus,
      farmingType: farmingType ?? this.farmingType,
      batchId: batchId ?? this.batchId,
      certificateId: certificateId ?? this.certificateId,
      isPublished: isPublished ?? this.isPublished,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      bulkDiscountMinQty: bulkDiscountMinQty ?? this.bulkDiscountMinQty,
      bulkDiscountPricePerUnit: bulkDiscountPricePerUnit ?? this.bulkDiscountPricePerUnit,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'farmerMobile': farmerMobile,
      'state': state,
      'district': district,
      'village': village,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'name': name,
      'category': category,
      'variety': variety,
      'quantity': quantity,
      'availableStock': availableStock,
      'unit': unit,
      'pricePerUnit': pricePerUnit,
      'harvestDate': harvestDate.toIso8601String(),
      'qualityChecked': qualityChecked,
      'packed': packed,
      'dispatched': dispatched,
      'expectedDeliveryDate': expectedDeliveryDate.toIso8601String(),
      'description': description,
      'imageUrls': imageUrls,
      'certificateUrl': certificateUrl,
      'certificateName': certificateName,
      'isOrganic': isOrganic,
      'isVerifiedFarmer': isVerifiedFarmer,
      'certificationStatus': certificationStatus.name,
      'farmingType': farmingType,
      'batchId': batchId,
      'certificateId': certificateId,
      'isPublished': isPublished,
      'rating': rating,
      'reviewCount': reviewCount,
      'bulkDiscountMinQty': bulkDiscountMinQty,
      'bulkDiscountPricePerUnit': bulkDiscountPricePerUnit,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    final qty = (map['quantity'] as num?)?.toDouble() ?? 0.0;
    final dist = map['district'] ?? 'Coimbatore';
    final st = map['state'] ?? 'Tamil Nadu';
    final defaultCoords = DistanceCalculator.getCoordinatesForDistrict(
      dist,
      st,
    );

    return ProductModel(
      id: id,
      farmerId: map['farmerId'] ?? '',
      farmerName: map['farmerName'] ?? '',
      farmerMobile: map['farmerMobile'] ?? '+91 98765 43210',
      state: st,
      district: dist,
      village: map['village'] ?? '',
      location: map['location'] ?? 'Coimbatore Farm',
      latitude: (map['latitude'] as num?)?.toDouble() ?? defaultCoords[0],
      longitude: (map['longitude'] as num?)?.toDouble() ?? defaultCoords[1],
      name: map['name'] ?? '',
      category: map['category'] ?? 'Vegetables',
      variety: map['variety'] ?? 'General',
      quantity: qty,
      availableStock: (map['availableStock'] as num?)?.toDouble() ?? qty,
      unit: map['unit'] ?? 'kg',
      pricePerUnit: (map['pricePerUnit'] as num?)?.toDouble() ?? 0.0,
      harvestDate: map['harvestDate'] != null
          ? DateTime.parse(map['harvestDate'])
          : DateTime.now(),
      qualityChecked: map['qualityChecked'] ?? true,
      packed: map['packed'] ?? true,
      dispatched: map['dispatched'] ?? false,
      expectedDeliveryDate: map['expectedDeliveryDate'] != null
          ? DateTime.parse(map['expectedDeliveryDate'])
          : DateTime.now().add(const Duration(days: 2)),
      description: map['description'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      certificateUrl: map['certificateUrl'],
      certificateName: map['certificateName'] ?? 'Organic Certified',
      isOrganic: map['isOrganic'] ?? true,
      isVerifiedFarmer: map['isVerifiedFarmer'] ?? true,
      certificationStatus: VerificationStatus.values.firstWhere(
        (e) => e.name == map['certificationStatus'],
        orElse: () => VerificationStatus.verified,
      ),
      farmingType: map['farmingType'] ?? 'Organic',
      batchId: map['batchId'],
      certificateId: map['certificateId'],
      isPublished: map['isPublished'] ?? true,
      rating: (map['rating'] as num?)?.toDouble() ?? 4.8,
      reviewCount: map['reviewCount'] ?? 12,
      bulkDiscountMinQty: (map['bulkDiscountMinQty'] as num?)?.toDouble(),
      bulkDiscountPricePerUnit: (map['bulkDiscountPricePerUnit'] as num?)?.toDouble(),
      rejectionReason: map['rejectionReason'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
