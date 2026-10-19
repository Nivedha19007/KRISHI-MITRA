class OrganicCertificateModel {
  final String certificateId;
  final String farmerId;
  final String farmerName;
  final String certificateType; // e.g. 'NPOP', 'PGS-India', 'USDA Organic', 'EU Organic'
  final String certificateNumber;
  final String certificationBody;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String certificateUrl; // Uploaded document/photo URL
  final String verificationStatus; // 'pending', 'approved', 'rejected', 'needsReview'
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final String? rejectionReason;

  OrganicCertificateModel({
    required this.certificateId,
    required this.farmerId,
    required this.farmerName,
    required this.certificateType,
    required this.certificateNumber,
    required this.certificationBody,
    required this.issueDate,
    required this.expiryDate,
    this.certificateUrl = '',
    this.verificationStatus = 'pending',
    this.verifiedAt,
    this.verifiedBy,
    this.rejectionReason,
  });

  bool get isApproved {
    if (verificationStatus != 'approved') return false;
    return DateTime.now().isBefore(expiryDate);
  }

  Map<String, dynamic> toMap() {
    return {
      'certificateId': certificateId,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'certificateType': certificateType,
      'certificateNumber': certificateNumber,
      'certificationBody': certificationBody,
      'issueDate': issueDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'certificateUrl': certificateUrl,
      'verificationStatus': verificationStatus,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'verifiedBy': verifiedBy,
      'rejectionReason': rejectionReason,
    };
  }

  factory OrganicCertificateModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedIssue = DateTime.now();
    if (map['issueDate'] != null) {
      parsedIssue = DateTime.tryParse(map['issueDate'].toString()) ?? DateTime.now();
    }

    DateTime parsedExpiry = DateTime.now().add(const Duration(days: 365));
    if (map['expiryDate'] != null) {
      parsedExpiry = DateTime.tryParse(map['expiryDate'].toString()) ?? parsedExpiry;
    }

    DateTime? parsedVerified;
    if (map['verifiedAt'] != null) {
      parsedVerified = DateTime.tryParse(map['verifiedAt'].toString());
    }

    return OrganicCertificateModel(
      certificateId: map['certificateId'] ?? id,
      farmerId: map['farmerId'] ?? '',
      farmerName: map['farmerName'] ?? '',
      certificateType: map['certificateType'] ?? 'NPOP Organic',
      certificateNumber: map['certificateNumber'] ?? '',
      certificationBody: map['certificationBody'] ?? '',
      issueDate: parsedIssue,
      expiryDate: parsedExpiry,
      certificateUrl: map['certificateUrl'] ?? '',
      verificationStatus: map['verificationStatus'] ?? 'pending',
      verifiedAt: parsedVerified,
      verifiedBy: map['verifiedBy'],
      rejectionReason: map['rejectionReason'],
    );
  }
}
