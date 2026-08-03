import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../datasources/sample_data.dart';

class AuthRepository {
  UserModel _currentUser = SampleData.sampleUsers.first; // Default Farmer Arun

  UserModel get currentUser => _currentUser;

  Future<UserModel> login(String email, String password, UserRole role) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final match = SampleData.sampleUsers.firstWhere(
      (u) => u.role == role,
      orElse: () => UserModel(
        uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: email.split('@').first,
        email: email,
        phone: '+91 98765 00000',
        role: role,
      ),
    );
    _currentUser = match;
    return _currentUser;
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required UserRole role,
    required String state,
    required String district,
    String village = '',
    String farmerType = 'Organic Producer',
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = UserModel(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      role: role,
      state: state,
      district: district,
      village: village,
      farmerType: farmerType,
      verificationStatus: role == UserRole.farmer ? VerificationStatus.pending : VerificationStatus.verified,
    );
    return _currentUser;
  }

  void switchRole(UserRole newRole) {
    _currentUser = SampleData.sampleUsers.firstWhere(
      (u) => u.role == newRole,
      orElse: () => _currentUser.copyWith(role: newRole),
    );
  }

  void updateVerificationStatus(String uid, VerificationStatus status) {
    if (_currentUser.uid == uid) {
      _currentUser = _currentUser.copyWith(verificationStatus: status);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class CurrentUserNotifier extends StateNotifier<UserModel> {
  final AuthRepository _repo;

  CurrentUserNotifier(this._repo) : super(_repo.currentUser);

  Future<void> login(String email, String password, UserRole role) async {
    final user = await _repo.login(email, password, role);
    state = user;
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required UserRole role,
    required String geoState,
    required String district,
    String village = '',
    String farmerType = 'Organic Producer',
  }) async {
    final user = await _repo.register(
      name: name,
      email: email,
      phone: phone,
      role: role,
      state: geoState,
      district: district,
      village: village,
      farmerType: farmerType,
    );
    state = user;
  }

  void switchRole(UserRole newRole) {
    _repo.switchRole(newRole);
    state = _repo.currentUser;
  }

  void setUser(UserModel user) {
    state = user;
  }

  void setVerification(VerificationStatus status) {
    _repo.updateVerificationStatus(state.uid, status);
    state = state.copyWith(verificationStatus: status);
  }
}

final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, UserModel>((ref) {
  return CurrentUserNotifier(ref.watch(authRepositoryProvider));
});
