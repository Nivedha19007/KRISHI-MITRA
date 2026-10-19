class HarvestBatchModel {
  final String batchId;
  final String farmerId;
  final String farmerName;
  final String productId;
  final String productName;
  final DateTime harvestDate;
  final double quantity;
  final String qualityGrade; // e.g. 'Grade A+', 'Standard', 'Premium'
  final List<String> harvestPhotos;
  final String verificationStatus; // 'pending', 'approved', 'rejected', 'needsReview'
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final String? rejectionReason;
  final String metadata;

  HarvestBatchModel({
    required this.batchId,
    required this.farmerId,
    required this.farmerName,
    required this.productId,
    required this.productName,
    required this.harvestDate,
    required this.quantity,
    this.qualityGrade = 'Grade A+',
    this.harvestPhotos = const [],
    this.verificationStatus = 'pending',
    this.verifiedAt,
    this.verifiedBy,
    this.rejectionReason,
    this.metadata = '',
  });

  bool get isApproved => verificationStatus == 'approved';

  Map<String, dynamic> toMap() {
    return {
      'batchId': batchId,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'productId': productId,
      'productName': productName,
      'harvestDate': harvestDate.toIso8601String(),
      'quantity': quantity,
      'qualityGrade': qualityGrade,
      'harvestPhotos': harvestPhotos,
      'verificationStatus': verificationStatus,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'verifiedBy': verifiedBy,
      'rejectionReason': rejectionReason,
      'metadata': metadata,
    };
  }

  factory HarvestBatchModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedHarvest = DateTime.now();
    if (map['harvestDate'] != null) {
      parsedHarvest = DateTime.tryParse(map['harvestDate'].toString()) ?? DateTime.now();
    }

    DateTime? parsedVerified;
    if (map['verifiedAt'] != null) {
      parsedVerified = DateTime.tryParse(map['verifiedAt'].toString());
    }

    return HarvestBatchModel(
      batchId: map['batchId'] ?? id,
      farmerId: map['farmerId'] ?? '',
      farmerName: map['farmerName'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      harvestDate: parsedHarvest,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      qualityGrade: map['qualityGrade'] ?? 'Grade A+',
      harvestPhotos: List<String>.from(map['harvestPhotos'] ?? []),
      verificationStatus: map['verificationStatus'] ?? 'pending',
      verifiedAt: parsedVerified,
      verifiedBy: map['verifiedBy'],
      rejectionReason: map['rejectionReason'],
      metadata: map['metadata'] ?? '',
    );
  }
}
