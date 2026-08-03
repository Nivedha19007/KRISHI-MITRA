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
  final String farmerType; // e.g. Organic, Smallholder, Commercial
  final VerificationStatus verificationStatus;
  final String? profileImage;
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
    this.farmerType = 'Organic Farmer',
    this.verificationStatus = VerificationStatus.pending,
    this.profileImage,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

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
      'farmerType': farmerType,
      'verificationStatus': verificationStatus.name,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.customer,
      ),
      state: map['state'] ?? 'Tamil Nadu',
      district: map['district'] ?? 'Coimbatore',
      village: map['village'] ?? '',
      farmerType: map['farmerType'] ?? 'Organic Farmer',
      verificationStatus: VerificationStatus.values.firstWhere(
        (e) => e.name == map['verificationStatus'],
        orElse: () => VerificationStatus.pending,
      ),
      profileImage: map['profileImage'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  UserModel copyWith({
    String? name,
    String? phone,
    UserRole? role,
    String? state,
    String? district,
    String? village,
    String? farmerType,
    VerificationStatus? verificationStatus,
    String? profileImage,
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
      farmerType: farmerType ?? this.farmerType,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt,
    );
  }
}
