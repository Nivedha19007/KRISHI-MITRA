class ReviewModel {
  final String id;
  final String orderId;
  final String productId;
  final String farmerId;
  final String customerId;
  final String customerName;
  final String productName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.farmerId,
    required this.customerId,
    required this.customerName,
    required this.productName,
    required this.rating,
    required this.comment,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'productId': productId,
      'farmerId': farmerId,
      'customerId': customerId,
      'customerName': customerName,
      'productName': productName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return ReviewModel(
      id: id,
      orderId: map['orderId'] ?? '',
      productId: map['productId'] ?? '',
      farmerId: map['farmerId'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      productName: map['productName'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      comment: map['comment'] ?? map['reviewText'] ?? '',
      createdAt: parseDate(map['createdAt']),
    );
  }
}
