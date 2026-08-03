enum TimelineStage {
  cultivated,
  harvested,
  qualityVerified,
  packed,
  dispatched,
  delivered,
}

class TimelineMilestone {
  final TimelineStage stage;
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isCompleted;
  final String location;

  TimelineMilestone({
    required this.stage,
    required this.title,
    required this.description,
    required this.timestamp,
    this.isCompleted = true,
    required this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'stage': stage.name,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'isCompleted': isCompleted,
      'location': location,
    };
  }

  factory TimelineMilestone.fromMap(Map<String, dynamic> map) {
    return TimelineMilestone(
      stage: TimelineStage.values.firstWhere(
        (e) => e.name == map['stage'],
        orElse: () => TimelineStage.cultivated,
      ),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp']) : DateTime.now(),
      isCompleted: map['isCompleted'] ?? true,
      location: map['location'] ?? '',
    );
  }
}

class BatchModel {
  final String batchId; // e.g. TOM-CBE-001
  final String productId;
  final String farmerId;
  final String farmerName;
  final String farmLocation;
  final String productName;
  final String variety;
  final double quantity;
  final String qualityStatus; // Grade A+, Organic Certified
  final String certificateInfo;
  final String currentStatus;
  final List<TimelineMilestone> timeline;

  BatchModel({
    required this.batchId,
    required this.productId,
    required this.farmerId,
    required this.farmerName,
    required this.farmLocation,
    required this.productName,
    required this.variety,
    required this.quantity,
    this.qualityStatus = 'Grade A+ (Quality Verified)',
    this.certificateInfo = 'Organic India Certificate #IND-ORG-8821',
    required this.currentStatus,
    required this.timeline,
  });

  Map<String, dynamic> toMap() {
    return {
      'batchId': batchId,
      'productId': productId,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'farmLocation': farmLocation,
      'productName': productName,
      'variety': variety,
      'quantity': quantity,
      'qualityStatus': qualityStatus,
      'certificateInfo': certificateInfo,
      'currentStatus': currentStatus,
      'timeline': timeline.map((e) => e.toMap()).toList(),
    };
  }

  factory BatchModel.fromMap(Map<String, dynamic> map, String id) {
    return BatchModel(
      batchId: id,
      productId: map['productId'] ?? '',
      farmerId: map['farmerId'] ?? '',
      farmerName: map['farmerName'] ?? '',
      farmLocation: map['farmLocation'] ?? '',
      productName: map['productName'] ?? '',
      variety: map['variety'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      qualityStatus: map['qualityStatus'] ?? 'Grade A+',
      certificateInfo: map['certificateInfo'] ?? '',
      currentStatus: map['currentStatus'] ?? 'In Transit',
      timeline: (map['timeline'] as List<dynamic>?)
              ?.map((e) => TimelineMilestone.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }
}
