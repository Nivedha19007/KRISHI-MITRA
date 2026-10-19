import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { farmer, customer, admin }

enum VerificationStatus { pending, verified, rejected }

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String state;
  final String district;
  final String village;
  final String deliveryAddress;
  final String farmerType; // e.g. Organic, Smallholder, Commercial
  final VerificationStatus verificationStatus;
  final String? profileImage;
  final String? certificateUrl;
  final String? certificateName;
  final DateTime? certificateUploadedAt;
  final VerificationStatus certificateStatus;
  final String? rejectionReason;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.state = 'Tamil Nadu',
    this.district = 'Coimbatore',
    this.village = '',
    this.deliveryAddress = '',
    this.farmerType = 'Organic Farmer',
    this.verificationStatus = VerificationStatus.pending,
    this.profileImage,
    this.certificateUrl,
    this.certificateName,
    this.certificateUploadedAt,
    this.certificateStatus = VerificationStatus.pending,
    this.rejectionReason,
    this.verifiedBy,
    this.verifiedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get fullAddress {
    if (deliveryAddress.trim().isNotEmpty) {
      return deliveryAddress.trim();
    }
    final parts = [
      if (village.trim().isNotEmpty) village.trim(),
      if (district.trim().isNotEmpty) district.trim(),
      if (state.trim().isNotEmpty) state.trim(),
    ];
    return parts.join(', ');
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'state': state,
      'district': district,
      'village': village,
      'deliveryAddress': deliveryAddress,
      'farmerType': farmerType,
      'verificationStatus': verificationStatus.name,
      'profileImage': profileImage,
      'certificateUrl': certificateUrl,
      'certificateName': certificateName,
      'certificateUploadedAt': certificateUploadedAt?.toIso8601String(),
      'certificateStatus': certificateStatus.name,
      'rejectionReason': rejectionReason,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    final rawRole = (map['role'] ?? '').toString().trim().toLowerCase();
    final rawStatus = (map['verificationStatus'] ?? '').toString().trim().toLowerCase();
    final rawCertStatus = (map['certificateStatus'] ?? '').toString().trim().toLowerCase();

    return UserModel(
      uid: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name.toLowerCase() == rawRole,
        orElse: () => UserRole.customer,
      ),
      state: map['state'] ?? 'Tamil Nadu',
      district: map['district'] ?? 'Coimbatore',
      village: map['village'] ?? '',
      deliveryAddress: map['deliveryAddress'] ?? map['address'] ?? '',
      farmerType: map['farmerType'] ?? 'Organic Farmer',
      verificationStatus: VerificationStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == rawStatus,
        orElse: () => VerificationStatus.pending,
      ),
      profileImage: map['profileImage'],
      certificateUrl: map['certificateUrl'],
      certificateName: map['certificateName'],
      certificateUploadedAt: parseNullableDate(map['certificateUploadedAt']),
      certificateStatus: VerificationStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == rawCertStatus,
        orElse: () => map['certificateUrl'] != null ? VerificationStatus.pending : VerificationStatus.pending,
      ),
      rejectionReason: map['rejectionReason'],
      verifiedBy: map['verifiedBy'],
      verifiedAt: parseNullableDate(map['verifiedAt']),
      createdAt: parseDate(map['createdAt']),
    );
  }

  UserModel copyWith({
    String? name,
    String? phone,
    UserRole? role,
    String? state,
    String? district,
    String? village,
    String? deliveryAddress,
    String? farmerType,
    VerificationStatus? verificationStatus,
    String? profileImage,
    String? certificateUrl,
    String? certificateName,
    DateTime? certificateUploadedAt,
    VerificationStatus? certificateStatus,
    String? rejectionReason,
    String? verifiedBy,
    DateTime? verifiedAt,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      state: state ?? this.state,
      district: district ?? this.district,
      village: village ?? this.village,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      farmerType: farmerType ?? this.farmerType,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      profileImage: profileImage ?? this.profileImage,
      certificateUrl: certificateUrl ?? this.certificateUrl,
      certificateName: certificateName ?? this.certificateName,
      certificateUploadedAt: certificateUploadedAt ?? this.certificateUploadedAt,
      certificateStatus: certificateStatus ?? this.certificateStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      createdAt: createdAt,
    );
  }
}
