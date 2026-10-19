class DeliveryModel {
  final String id;
  final String orderId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String farmerId;
  final String farmerName;
  final String farmerPhone;
  final String pickupLocation;
  final double pickupLatitude;
  final double pickupLongitude;
  final String deliveryAddress;
  final double deliveryLatitude;
  final double deliveryLongitude;
  final double distanceKm;
  final double deliveryCharge;
  final double productSubtotal;
  final double finalTotal;
  final String deliveryStatus; // Placed, Assigned, Pickup, In Transit, Delivered
  final String? assignedPartnerId;
  final String? assignedPartnerName;
  final String? assignedPartnerPhone;
  final DateTime createdAt;
  final DateTime? updatedAt;

  DeliveryModel({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.customerName,
    this.customerPhone = '',
    required this.farmerId,
    required this.farmerName,
    this.farmerPhone = '',
    required this.pickupLocation,
    this.pickupLatitude = 0.0,
    this.pickupLongitude = 0.0,
    required this.deliveryAddress,
    this.deliveryLatitude = 0.0,
    this.deliveryLongitude = 0.0,
    this.distanceKm = 0.0,
    required this.deliveryCharge,
    this.productSubtotal = 0.0,
    this.finalTotal = 0.0,
    this.deliveryStatus = 'Placed',
    this.assignedPartnerId,
    this.assignedPartnerName,
    this.assignedPartnerPhone,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    final now = updatedAt ?? DateTime.now();
    return {
      'id': id,
      'orderId': orderId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'farmerPhone': farmerPhone,
      'pickupLocation': pickupLocation,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'deliveryAddress': deliveryAddress,
      'deliveryLatitude': deliveryLatitude,
      'deliveryLongitude': deliveryLongitude,
      'distanceKm': distanceKm,
      'deliveryCharge': deliveryCharge,
      'productSubtotal': productSubtotal,
      'finalTotal': finalTotal,
      'deliveryStatus': deliveryStatus,
      'assignedPartnerId': assignedPartnerId,
      'assignedPartnerName': assignedPartnerName,
      'assignedPartnerPhone': assignedPartnerPhone,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };
  }

  factory DeliveryModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return DeliveryModel(
      id: id,
      orderId: map['orderId'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      farmerId: map['farmerId'] ?? '',
      farmerName: map['farmerName'] ?? '',
      farmerPhone: map['farmerPhone'] ?? '',
      pickupLocation: map['pickupLocation'] ?? '',
      pickupLatitude: (map['pickupLatitude'] as num?)?.toDouble() ?? 0.0,
      pickupLongitude: (map['pickupLongitude'] as num?)?.toDouble() ?? 0.0,
      deliveryAddress: map['deliveryAddress'] ?? '',
      deliveryLatitude: (map['deliveryLatitude'] as num?)?.toDouble() ?? 0.0,
      deliveryLongitude: (map['deliveryLongitude'] as num?)?.toDouble() ?? 0.0,
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0.0,
      deliveryCharge: (map['deliveryCharge'] as num?)?.toDouble() ?? 0.0,
      productSubtotal: (map['productSubtotal'] as num?)?.toDouble() ?? 0.0,
      finalTotal: (map['finalTotal'] as num?)?.toDouble() ?? 0.0,
      deliveryStatus: map['deliveryStatus'] ?? 'Placed',
      assignedPartnerId: map['assignedPartnerId'],
      assignedPartnerName: map['assignedPartnerName'],
      assignedPartnerPhone: map['assignedPartnerPhone'],
      createdAt: parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
    );
  }

  DeliveryModel copyWith({
    String? id,
    String? orderId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? farmerId,
    String? farmerName,
    String? farmerPhone,
    String? pickupLocation,
    double? pickupLatitude,
    double? pickupLongitude,
    String? deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
    double? distanceKm,
    double? deliveryCharge,
    double? productSubtotal,
    double? finalTotal,
    String? deliveryStatus,
    String? assignedPartnerId,
    String? assignedPartnerName,
    String? assignedPartnerPhone,
    DateTime? updatedAt,
  }) {
    return DeliveryModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      farmerPhone: farmerPhone ?? this.farmerPhone,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      distanceKm: distanceKm ?? this.distanceKm,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      productSubtotal: productSubtotal ?? this.productSubtotal,
      finalTotal: finalTotal ?? this.finalTotal,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      assignedPartnerId: assignedPartnerId ?? this.assignedPartnerId,
      assignedPartnerName: assignedPartnerName ?? this.assignedPartnerName,
      assignedPartnerPhone: assignedPartnerPhone ?? this.assignedPartnerPhone,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
