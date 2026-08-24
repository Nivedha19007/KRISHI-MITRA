class OrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final String farmerId;
  final String farmerName;
  final String productId;
  final String productName;
  final String variety;
  final double quantity;
  final String unit;
  final double pricePerUnit;
  final double totalAmount;
  final String
  paymentStatus; // Payment Pending, Payment Successful, Cash on Delivery
  final String orderStatus; // Placed, Confirmed, Packed, Dispatched, Delivered
  final String deliveryAddress;
  final String batchId;
  final double? rating;
  final String? reviewText;
  final DateTime? reviewedAt;
  final String productImage;
  final DateTime? updatedAt;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.farmerId,
    required this.farmerName,
    required this.productId,
    required this.productName,
    required this.variety,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    required this.totalAmount,
    this.paymentStatus = 'Payment Pending',
    this.orderStatus = 'Pending',
    required this.deliveryAddress,
    required this.batchId,
    this.rating,
    this.reviewText,
    this.reviewedAt,
    this.productImage = '',
    this.updatedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    final now = updatedAt ?? DateTime.now();
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'variety': variety,
      'quantity': quantity,
      'unit': unit,
      'pricePerUnit': pricePerUnit,
      'totalAmount': totalAmount,
      'paymentStatus': paymentStatus,
      'orderStatus': orderStatus,
      'status': orderStatus,
      'deliveryAddress': deliveryAddress,
      'batchId': batchId,
      'rating': rating,
      'reviewText': reviewText,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'orderDate': createdAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return OrderModel(
      id: id,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      farmerId: map['farmerId'] ?? '',
      farmerName: map['farmerName'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImage: map['productImage'] ?? '',
      variety: map['variety'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'kg',
      pricePerUnit: (map['pricePerUnit'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: map['paymentStatus'] ?? 'Payment Pending',
      orderStatus: map['status'] ?? map['orderStatus'] ?? 'Pending',
      deliveryAddress: map['deliveryAddress'] ?? '',
      batchId: map['batchId'] ?? '',
      rating: (map['rating'] as num?)?.toDouble(),
      reviewText: map['reviewText'],
      reviewedAt: map['reviewedAt'] != null ? parseDate(map['reviewedAt']) : null,
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
      createdAt: map['createdAt'] != null
          ? parseDate(map['createdAt'])
          : map['orderDate'] != null
              ? parseDate(map['orderDate'])
              : DateTime.now(),
    );
  }

  OrderModel copyWith({
    String? id,
    String? customerId,
    String? orderStatus,
    String? paymentStatus,
    double? rating,
    String? reviewText,
    DateTime? reviewedAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName,
      farmerId: farmerId,
      farmerName: farmerName,
      productId: productId,
      productName: productName,
      productImage: productImage,
      variety: variety,
      quantity: quantity,
      unit: unit,
      pricePerUnit: pricePerUnit,
      totalAmount: totalAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderStatus: orderStatus ?? this.orderStatus,
      deliveryAddress: deliveryAddress,
      batchId: batchId,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      updatedAt: updatedAt ?? DateTime.now(),
      createdAt: createdAt,
    );
  }
}
