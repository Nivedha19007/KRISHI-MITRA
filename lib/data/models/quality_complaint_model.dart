class QualityComplaintModel {
  final String complaintId;
  final String customerId;
  final String customerName;
  final String orderId;
  final String productId;
  final String productName;
  final String batchId;
  final String issueType; // 'spoiledProduce', 'poorQuality', 'incorrectQuality', 'other'
  final String description;
  final String photoUrl;
  final String status; // 'pending', 'reviewed', 'resolved', 'rejected'
  final DateTime createdAt;
  final String? adminRemarks;

  QualityComplaintModel({
    required this.complaintId,
    required this.customerId,
    required this.customerName,
    required this.orderId,
    required this.productId,
    required this.productName,
    this.batchId = '',
    required this.issueType,
    required this.description,
    this.photoUrl = '',
    this.status = 'pending',
    DateTime? createdAt,
    this.adminRemarks,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'complaintId': complaintId,
      'customerId': customerId,
      'customerName': customerName,
      'orderId': orderId,
      'productId': productId,
      'productName': productName,
      'batchId': batchId,
      'issueType': issueType,
      'description': description,
      'photoUrl': photoUrl,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'adminRemarks': adminRemarks,
    };
  }

  factory QualityComplaintModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedCreated = DateTime.now();
    if (map['createdAt'] != null) {
      parsedCreated = DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now();
    }

    return QualityComplaintModel(
      complaintId: map['complaintId'] ?? id,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      orderId: map['orderId'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      batchId: map['batchId'] ?? '',
      issueType: map['issueType'] ?? 'poorQuality',
      description: map['description'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: parsedCreated,
      adminRemarks: map['adminRemarks'],
    );
  }
}
