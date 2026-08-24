enum TimelineStage {
  cultivated,
  seeded,
  cropGrowing,
  harvested,
  qualityVerified,
  packed,
  dispatched,
  shipped,
  delivered,
}

extension TimelineStageX on TimelineStage {
  String get displayName {
    switch (this) {
      case TimelineStage.cultivated:
      case TimelineStage.seeded:
        return 'Seeded';
      case TimelineStage.cropGrowing:
        return 'Crop Growing';
      case TimelineStage.harvested:
        return 'Harvested';
      case TimelineStage.qualityVerified:
        return 'Quality Verified';
      case TimelineStage.packed:
        return 'Packed';
      case TimelineStage.dispatched:
      case TimelineStage.shipped:
        return 'Shipped';
      case TimelineStage.delivered:
        return 'Delivered';
    }
  }
}

class TimelineMilestone {
  final String id;
  final TimelineStage stage;
  final String title;
  final String description;
  final DateTime? timestamp; // NULL if farmer has not entered a timestamp
  final String status; // 'completed', 'current', 'pending'
  final String location;
  final String actorName;

  TimelineMilestone({
    String? id,
    required this.stage,
    required this.title,
    this.description = '',
    this.timestamp,
    String? status,
    bool? isCompleted,
    this.location = '',
    this.actorName = '',
  })  : id = id ?? stage.name,
        status = status ?? (isCompleted == false ? 'pending' : (isCompleted == true ? 'completed' : (timestamp != null ? 'completed' : 'pending')));

  bool get isCompleted => status == 'completed' || status == 'current';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stage': stage.name,
      'title': title,
      'description': description,
      'timestamp': timestamp?.toIso8601String(),
      'status': status,
      'isCompleted': isCompleted,
      'location': location,
      'actorName': actorName,
    };
  }

  factory TimelineMilestone.fromMap(Map<String, dynamic> map) {
    final stageStr = map['stage'] ?? map['id'] ?? 'seeded';
    final stageVal = TimelineStage.values.firstWhere(
      (e) =>
          e.name.toLowerCase() == stageStr.toString().toLowerCase() ||
          e.displayName.toLowerCase() == stageStr.toString().toLowerCase(),
      orElse: () => TimelineStage.seeded,
    );

    DateTime? parsedTime;
    if (map['timestamp'] != null) {
      if (map['timestamp'] is String && (map['timestamp'] as String).isNotEmpty) {
        parsedTime = DateTime.tryParse(map['timestamp']);
      }
    }

    final isComp = map['isCompleted'] == true;
    final statusStr = map['status'] ?? (isComp ? 'completed' : 'pending');

    return TimelineMilestone(
      id: map['id'] ?? stageVal.name,
      stage: stageVal,
      title: map['title'] ?? stageVal.displayName,
      description: map['description'] ?? '',
      timestamp: parsedTime,
      status: statusStr,
      location: map['location'] ?? '',
      actorName: map['actorName'] ?? map['farmerName'] ?? '',
    );
  }

  TimelineMilestone copyWith({
    String? id,
    TimelineStage? stage,
    String? title,
    String? description,
    DateTime? timestamp,
    bool clearTimestamp = false,
    String? status,
    String? location,
    String? actorName,
  }) {
    return TimelineMilestone(
      id: id ?? this.id,
      stage: stage ?? this.stage,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: clearTimestamp ? null : (timestamp ?? this.timestamp),
      status: status ?? this.status,
      location: location ?? this.location,
      actorName: actorName ?? this.actorName,
    );
  }
}

class BatchModel {
  final String batchId; // e.g. CAR-COI-670979
  final String productId;
  final String farmerId;
  final String farmerName;
  final String farmLocation;
  final String productName;
  final String variety;
  final double quantity;
  final String qualityStatus;
  final String certificateInfo;
  final String currentStatus;
  final String qrDataUrl;
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
    String? qrDataUrl,
    required this.timeline,
  }) : qrDataUrl =
           qrDataUrl ?? 'https://krishi-mitra-38a5f.web.app/trace/$batchId';

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
      'qrDataUrl': qrDataUrl,
      'timeline': timeline.map((e) => e.toMap()).toList(),
    };
  }

  factory BatchModel.fromMap(Map<String, dynamic> map, String id) {
    final bId = map['batchId'] ?? id;
    return BatchModel(
      batchId: bId,
      productId: map['productId'] ?? '',
      farmerId: map['farmerId'] ?? '',
      farmerName: map['farmerName'] ?? '',
      farmLocation: map['farmLocation'] ?? '',
      productName: map['productName'] ?? '',
      variety: map['variety'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      qualityStatus: map['qualityStatus'] ?? 'Grade A+',
      certificateInfo: map['certificateInfo'] ?? '',
      currentStatus: map['currentStatus'] ?? 'Seeded',
      qrDataUrl:
          map['qrDataUrl'] ?? 'https://krishi-mitra-38a5f.web.app/trace/$bId',
      timeline:
          (map['timeline'] as List<dynamic>?)
              ?.map(
                (e) => TimelineMilestone.fromMap(Map<String, dynamic>.from(e)),
              )
              .toList() ??
          [],
    );
  }
}
