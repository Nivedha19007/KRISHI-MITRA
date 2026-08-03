class CommentModel {
  final String id;
  final String farmerId;
  final String farmerName;
  final String farmerAvatar;
  final String content;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.farmerAvatar,
    required this.content,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'farmerAvatar': farmerAvatar,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map, String id) {
    return CommentModel(
      id: id,
      farmerId: map['farmerId'] ?? '',
      farmerName: map['farmerName'] ?? '',
      farmerAvatar: map['farmerAvatar'] ?? '',
      content: map['content'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }
}

class PostModel {
  final String id;
  final String farmerId;
  final String farmerName;
  final String farmerState;
  final String farmerDistrict;
  final String category; // Crop Problem, Pest/Disease, Seeds, Machinery, Excess Stock, Buying Request, Selling Request, General Advice
  final String content;
  final String? imageUrl;
  final int likesCount;
  final List<String> likedByUids;
  final List<CommentModel> comments;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.farmerState,
    required this.farmerDistrict,
    required this.category,
    required this.content,
    this.imageUrl,
    this.likesCount = 0,
    this.likedByUids = const [],
    this.comments = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'farmerState': farmerState,
      'farmerDistrict': farmerDistrict,
      'category': category,
      'content': content,
      'imageUrl': imageUrl,
      'likesCount': likesCount,
      'likedByUids': likedByUids,
      'comments': comments.map((c) => c.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map, String id) {
    return PostModel(
      id: id,
      farmerId: map['farmerId'] ?? '',
      farmerName: map['farmerName'] ?? '',
      farmerState: map['farmerState'] ?? 'Tamil Nadu',
      farmerDistrict: map['farmerDistrict'] ?? 'Coimbatore',
      category: map['category'] ?? 'General Advice',
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'],
      likesCount: map['likesCount'] ?? 0,
      likedByUids: List<String>.from(map['likedByUids'] ?? []),
      comments: (map['comments'] as List<dynamic>?)
              ?.map((e) => CommentModel.fromMap(Map<String, dynamic>.from(e), e['id'] ?? ''))
              .toList() ??
          [],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }
}
