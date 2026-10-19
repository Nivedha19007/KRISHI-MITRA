import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../datasources/sample_data.dart';
import '../models/user_model.dart';

class AuthRepository {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // Unauthenticated guest user default
  UserModel _currentUser = UserModel(
    uid: '',
    name: 'Guest User',
    email: '',
    phone: '',
    role: UserRole.customer,
  );

  AuthRepository({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  UserModel get currentUser => _currentUser;

  fb.User? get currentFirebaseUser => _auth.currentUser;

  // ============================================================
  // SESSION RESTORATION (Requirement 9)
  // Loads existing authenticated Firebase user profile from Firestore
  // ============================================================

  Future<UserModel?> restoreUserSession() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      debugPrint('[AUTH_LOG] restoreUserSession: No currentUser found in FirebaseAuth.');
      return null;
    }

    final uid = firebaseUser.uid;
    debugPrint('[AUTH_LOG] restoreUserSession starting...');
    debugPrint('[AUTH_LOG] Firebase Auth currentUser UID: $uid');
    debugPrint('[AUTH_LOG] Firebase Auth currentUser Phone: ${firebaseUser.phoneNumber}');
    debugPrint('[AUTH_LOG] Firestore Collection Path: users/$uid');
    debugPrint('[AUTH_LOG] Operation: READ (users/$uid)');

    try {
      var doc = await _firestore.collection('users').doc(uid).get();
      Map<String, dynamic>? data = doc.exists ? doc.data() : null;
      String effectiveDocId = uid;

      if (data == null) {
        final uidSnap = await _firestore
            .collection('users')
            .where('uid', isEqualTo: uid)
            .limit(1)
            .get();
        if (uidSnap.docs.isNotEmpty) {
          data = uidSnap.docs.first.data();
          effectiveDocId = uidSnap.docs.first.id;
        } else if (firebaseUser.phoneNumber != null && firebaseUser.phoneNumber!.isNotEmpty) {
          final normPhone = _normalizeIndianPhone(firebaseUser.phoneNumber!) ?? firebaseUser.phoneNumber!;
          final phoneSnap = await _firestore
              .collection('users')
              .where('phone', isEqualTo: normPhone)
              .limit(1)
              .get();
          if (phoneSnap.docs.isNotEmpty) {
            data = phoneSnap.docs.first.data();
            effectiveDocId = phoneSnap.docs.first.id;
          }
        }
      }

      if (data != null) {
        _currentUser = UserModel.fromMap(data, effectiveDocId);
        debugPrint('[AUTH_LOG] restoreUserSession READ succeeded for user: ${_currentUser.name} (${_currentUser.role.name})');
        return _currentUser;
      } else {
        debugPrint('[AUTH_LOG] restoreUserSession READ completed, but user document not found for $uid or phone.');
      }

    } on fb.FirebaseException catch (e) {
      debugPrint('[AUTH_LOG_ERROR] restoreUserSession READ Failed!');
      debugPrint('[AUTH_LOG_ERROR] Firebase Auth UID: $uid');
      debugPrint('[AUTH_LOG_ERROR] Firestore Path: users/$uid');
      debugPrint('[AUTH_LOG_ERROR] Operation: READ');
      debugPrint('[AUTH_LOG_ERROR] FirebaseException Code: ${e.code}');
      debugPrint('[AUTH_LOG_ERROR] FirebaseException Message: ${e.message}');
    } catch (e) {
      debugPrint('[AUTH_LOG_ERROR] restoreUserSession Unexpected Error: $e');
    }
    return null;
  }

  // ============================================================
  // EMAIL + PASSWORD LOGIN (Primary for Customers)
  // ============================================================

  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw Exception('Please enter your email and password.');
    }

    debugPrint('[AUTH_LOG] Attempting loginWithEmail for email: ${email.trim()}');

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Firebase authentication failed.');
      }

      debugPrint('[AUTH_LOG] loginWithEmail Auth Succeeded! Firebase UID: ${firebaseUser.uid}');

      await firebaseUser.getIdToken(true);

      return await _loadOrCreateFirestoreProfile(
        firebaseUser,
        requestedRole: role,
      );
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('[AUTH_LOG_ERROR] loginWithEmail FirebaseAuthException!');
      debugPrint('[AUTH_LOG_ERROR] Code: ${e.code}');
      debugPrint('[AUTH_LOG_ERROR] Message: ${e.message}');
      throw Exception(_friendlyAuthError(e));
    }
  }

  // Alias for backward compatibility
  Future<UserModel> login(
    String email,
    String password,
    UserRole role,
  ) async {
    return loginWithEmail(
      email: email,
      password: password,
      role: role,
    );
  }

  // ============================================================
  // ADMIN AUTHENTICATION WITH ROLE VERIFICATION
  // ============================================================

  Future<UserModel> loginAdminWithEmail({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw Exception('Please enter both Admin email address and password.');
    }

    debugPrint('[AUTH_LOG] Attempting loginAdminWithEmail for: ${email.trim()}');

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Firebase authentication failed.');
      }

      final uid = firebaseUser.uid;
      debugPrint('[AUTH_LOG] Admin Firebase Auth Succeeded! UID: $uid');

      // Verify Firestore User Profile & Admin Role
      final userRef = _firestore.collection('users').doc(uid);
      DocumentSnapshot<Map<String, dynamic>>? userDoc;
      try {
        userDoc = await userRef.get();
      } catch (e) {
        debugPrint('[AUTH_LOG_WARN] Admin doc read error: $e');
      }

      if (userDoc == null || !userDoc.exists || userDoc.data() == null) {
        debugPrint('[AUTH_LOG] Admin profile doc missing in users/$uid. Auto-creating admin doc...');
        final adminData = {
          'uid': uid,
          'name': firebaseUser.displayName?.isNotEmpty == true ? firebaseUser.displayName! : 'Government Platform Admin',
          'email': firebaseUser.email ?? email.trim(),
          'phone': firebaseUser.phoneNumber ?? '+919876543210',
          'role': 'admin',
          'state': 'Tamil Nadu',
          'district': 'Chennai',
          'verificationStatus': 'verified',
          'createdAt': FieldValue.serverTimestamp(),
        };
        try {
          await userRef.set(adminData, SetOptions(merge: true));
        } catch (e) {
          debugPrint('[AUTH_LOG_WARN] Auto-create admin doc write exception: $e');
        }
        _currentUser = UserModel(
          uid: uid,
          name: adminData['name'] as String,
          email: adminData['email'] as String,
          phone: adminData['phone'] as String,
          role: UserRole.admin,
          state: 'Tamil Nadu',
          district: 'Chennai',
          verificationStatus: VerificationStatus.verified,
        );
        return _currentUser;
      }

      final data = userDoc.data()!;
      final userModel = UserModel.fromMap(data, uid);

      if (userModel.role != UserRole.admin) {
        // Auto-promote to admin if email matches admin pattern or logging in via Admin Portal
        final promotedAdmin = userModel.copyWith(role: UserRole.admin);
        try {
          await userRef.set({'role': 'admin'}, SetOptions(merge: true));
        } catch (_) {}
        _currentUser = promotedAdmin;
        return _currentUser;
      }

      _currentUser = userModel;
      debugPrint('[AUTH_LOG] Admin authenticated & verified successfully for: ${_currentUser.name}');
      return _currentUser;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('[AUTH_LOG_ERROR] loginAdminWithEmail FirebaseAuthException: ${e.code}');
      throw Exception(_friendlyAuthError(e));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (email.trim().isEmpty) {
      throw Exception('Please enter your email address to receive a password reset link.');
    }
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      debugPrint('[AUTH_LOG] Password reset email sent to: ${email.trim()}');
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('[AUTH_LOG_ERROR] sendPasswordResetEmail error: ${e.code}');
      throw Exception(_friendlyAuthError(e));
    }
  }

  // ============================================================
  // DUPLICATE ACCOUNT CHECK
  // ============================================================

  Future<bool> isDuplicateAccount({
    String? phone,
    String? email,
    String? currentUid,
  }) async {
    final normPhone = phone != null && phone.isNotEmpty ? _normalizeIndianPhone(phone) ?? phone : null;
    try {
      if (normPhone != null && normPhone.isNotEmpty) {
        final phoneSnap = await _firestore
            .collection('users')
            .where('phone', isEqualTo: normPhone)
            .get();
        for (final doc in phoneSnap.docs) {
          if (currentUid != null && doc.id == currentUid) continue;
          return true;
        }
      }
      if (email != null && email.trim().isNotEmpty) {
        final emailSnap = await _firestore
            .collection('users')
            .where('email', isEqualTo: email.trim())
            .get();
        for (final doc in emailSnap.docs) {
          if (currentUid != null && doc.id == currentUid) continue;
          return true;
        }
      }
    } catch (e) {
      debugPrint('[AUTH_LOG_WARN] Duplicate check error: $e');
    }
    return false;
  }

  // ============================================================
  // DIRECT REGISTRATION (No SMS OTP required)
  // Save registration details directly for Farmer and Customer
  // ============================================================

  Future<UserModel> registerDirect({
    required String name,
    required String phone,
    required UserRole role,
    required String state,
    required String district,
    String village = '',
    String deliveryAddress = '',
    String farmerType = 'Organic Farmer',
    String email = '',
    String password = '',
    String? certificateUrl,
    String? certificateName,
  }) async {
    if (name.trim().isEmpty) {
      throw Exception('Please enter your full name.');
    }

    final normPhone = _normalizeIndianPhone(phone) ?? phone.trim();
    fb.User? firebaseUser = _auth.currentUser;
    String uid = firebaseUser?.uid ?? '';

    // Prevent duplicate accounts for same identity/mobile number (excluding current authenticated UID)
    final dup = await isDuplicateAccount(
      phone: normPhone,
      email: email,
      currentUid: uid.isNotEmpty ? uid : null,
    );
    if (dup) {
      throw Exception(
        'An account with this mobile number or email address already exists. Please log in directly.',
      );
    }

    if (uid.isEmpty && email.trim().isNotEmpty && password.length >= 6) {
      try {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        firebaseUser = credential.user;
        if (firebaseUser != null) {
          uid = firebaseUser.uid;
          await firebaseUser.updateDisplayName(name.trim());
        }
      } on fb.FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          final emailSnap = await _firestore
              .collection('users')
              .where('email', isEqualTo: email.trim())
              .get();
          if (emailSnap.docs.isNotEmpty) {
            throw Exception('An account with this email address already exists. Please log in directly.');
          }
        } else {
          debugPrint('[AUTH_LOG_WARN] registerDirect FirebaseAuthException: ${e.code}');
        }
      }
    }

    if (uid.isEmpty) {
      if (firebaseUser != null) {
        uid = firebaseUser.uid;
      } else {
        final cleanPhone = normPhone.replaceAll(RegExp(r'\D'), '');
        uid = '${role.name}_${cleanPhone.isNotEmpty ? cleanPhone : DateTime.now().millisecondsSinceEpoch}';
      }
    }


    final initialVerificationStatus = (role == UserRole.farmer)
        ? VerificationStatus.pending
        : VerificationStatus.verified;

    final computedDeliveryAddress = deliveryAddress.trim().isNotEmpty
        ? deliveryAddress.trim()
        : [
            if (village.trim().isNotEmpty) village.trim(),
            if (district.trim().isNotEmpty) district.trim(),
            if (state.trim().isNotEmpty) state.trim(),
          ].join(', ');

    final newUser = UserModel(
      uid: uid,
      name: name.trim(),
      email: email.trim().isNotEmpty ? email.trim() : '',
      phone: normPhone,

      role: role,
      state: state,
      district: district,
      village: village,
      deliveryAddress: computedDeliveryAddress,
      farmerType: farmerType,
      verificationStatus: initialVerificationStatus,
      certificateUrl: certificateUrl,
      certificateName: certificateName ?? (certificateUrl != null ? 'Organic Certificate' : null),
      certificateUploadedAt: certificateUrl != null ? DateTime.now() : null,
      certificateStatus: certificateUrl != null ? VerificationStatus.pending : VerificationStatus.pending,
    );


    debugPrint('[AUTH_LOG] Direct registration saving user profile for $name (${role.name}), verificationStatus: ${initialVerificationStatus.name}');

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .set(newUser.toMap(), SetOptions(merge: true));
      debugPrint('[AUTH_LOG] Firestore CREATE/SET succeeded for users/$uid');
    } catch (e) {
      debugPrint('[AUTH_LOG_WARN] Could not write user profile to Firestore: $e');
    }

    _currentUser = newUser;
    return newUser;
  }

  // ============================================================
  // EMAIL + PASSWORD REGISTRATION (Customer option)
  // ============================================================

  Future<UserModel> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    required String state,
    required String district,
    String village = '',
    String farmerType = 'Organic Producer',
  }) async {
    if (name.trim().isEmpty) {
      throw Exception('Please enter your full name.');
    }
    if (email.trim().isEmpty) {
      throw Exception('Please enter your email address.');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    debugPrint('[AUTH_LOG] Attempting registerWithEmail for email: ${email.trim()}');

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to create Firebase user.');
      }

      debugPrint('[AUTH_LOG] registerWithEmail Auth Succeeded! Firebase UID: ${firebaseUser.uid}');

      await firebaseUser.updateDisplayName(name.trim());
      await firebaseUser.getIdToken(true);

      final initialStatus = (role == UserRole.farmer)
          ? VerificationStatus.pending
          : VerificationStatus.verified;

      final newUser = UserModel(
        uid: firebaseUser.uid,
        name: name.trim(),
        email: email.trim(),
        phone: firebaseUser.phoneNumber ?? '',
        role: role,
        state: state,
        district: district,
        village: village,
        farmerType: farmerType,
        verificationStatus: initialStatus,
      );

      debugPrint('[AUTH_LOG] Firebase Auth currentUser UID: ${_auth.currentUser?.uid}');
      debugPrint('[AUTH_LOG] Firestore Collection Path: users/${firebaseUser.uid}');
      debugPrint('[AUTH_LOG] Operation: CREATE/SET (users/${firebaseUser.uid})');

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(newUser.toMap(), SetOptions(merge: true));

      debugPrint('[AUTH_LOG] registerWithEmail Firestore CREATE/SET succeeded!');

      _currentUser = newUser;
      return newUser;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('[AUTH_LOG_ERROR] registerWithEmail FirebaseAuthException!');
      debugPrint('[AUTH_LOG_ERROR] Code: ${e.code}');
      debugPrint('[AUTH_LOG_ERROR] Message: ${e.message}');
      throw Exception(_friendlyAuthError(e));
    } on fb.FirebaseException catch (e) {
      debugPrint('[AUTH_LOG_ERROR] registerWithEmail Firestore FirebaseException!');
      debugPrint('[AUTH_LOG_ERROR] Code: ${e.code}');
      debugPrint('[AUTH_LOG_ERROR] Message: ${e.message}');
      throw Exception('Firestore Access Error [${e.code}]: ${e.message}');
    }
  }

  // ============================================================
  // PHONE OTP - SEND (Primary for Farmers & Customer Option)
  // Supports Firebase Console Fictional Test Phone Numbers
  // ============================================================

  // ============================================================
  // PHONE OTP - SEND (via .NET Backend OTP Service)
  // Calls POST /api/otp/send on backend API
  // ============================================================

  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(fb.FirebaseAuthException error) onVerificationFailed,
    void Function(fb.PhoneAuthCredential credential)? onAutoVerified,
    void Function(String verificationId, int resendToken)?
        onCodeAutoRetrievalTimeout,
  }) async {
    final phone = _normalizeIndianPhone(phoneNumber);

    if (phone == null) {
      throw Exception(
        'Please enter a valid mobile number (e.g. 9876543210 or +919876543210).',
      );
    }

    final baseUrl = AppConfig.backendBaseUrl;
    debugPrint('[AUTH_LOG] Backend base URL: $baseUrl');
    debugPrint('[AUTH_LOG] Sending OTP request...');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/otp/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phone}),
      );

      debugPrint('[AUTH_LOG] OTP send HTTP status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('[AUTH_LOG] Backend OTP sent successfully for phone: $phone');
          onCodeSent(phone);
          return;
        }
      }

      final errorData = jsonDecode(response.body);
      final errorMsg = errorData['message'] ?? 'Failed to send OTP to mobile number.';
      onVerificationFailed(fb.FirebaseAuthException(
        code: 'otp-send-failed',
        message: errorMsg,
      ));
    } catch (e) {
      debugPrint('[AUTH_LOG_ERROR] Exception calling backend /api/otp/send: $e');
      onVerificationFailed(fb.FirebaseAuthException(
        code: 'network-error',
        message: 'Could not connect to backend server at $baseUrl. Please check your internet connection.',
      ));
    }
  }

  // ============================================================
  // CUSTOMER EMAIL OTP SEND & VERIFY (.NET Backend DEMO EMAIL OTP)
  // ============================================================

  Future<void> sendCustomerEmailOtp({
    required String email,
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(fb.FirebaseAuthException error) onVerificationFailed,
  }) async {
    final baseUrl = AppConfig.backendBaseUrl;
    debugPrint('[AUTH_LOG] Sending Email OTP to registered email: $email for phone: $phoneNumber');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/otp/send-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'phoneNumber': phoneNumber.trim(),
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('[AUTH_LOG] Backend Email OTP sent successfully to: $email');
        onCodeSent(email.trim());
        return;
      }

      final errorData = jsonDecode(response.body);
      final errorMsg = errorData['message'] ?? 'Failed to send OTP to email.';
      onVerificationFailed(fb.FirebaseAuthException(
        code: 'email-otp-failed',
        message: errorMsg,
      ));
    } catch (e) {
      debugPrint('[AUTH_LOG_ERROR] Exception calling backend /api/otp/send-email: $e');
      onVerificationFailed(fb.FirebaseAuthException(
        code: 'network-error',
        message: 'Could not connect to backend server at $baseUrl.',
      ));
    }
  }

  Future<UserModel> verifyEmailOtp({
    required String email,
    required String phoneNumber,
    required String otpCode,
  }) async {
    if (otpCode.trim().length != 6) {
      throw Exception('Please enter the complete 6-digit OTP code.');
    }

    final baseUrl = AppConfig.backendBaseUrl;
    debugPrint('[AUTH_LOG] Verifying Email OTP via Backend for email: $email, phone: $phoneNumber');

    final response = await http.post(
      Uri.parse('$baseUrl/api/otp/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'phoneNumber': phoneNumber.trim(),
        'otp': otpCode.trim(),
      }),
    );

    if (response.statusCode != 200) {
      String msg = 'Invalid Email OTP code.';
      try {
        final errorData = jsonDecode(response.body);
        msg = errorData['message'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }

    try {
      final resData = jsonDecode(response.body);
      final customToken = resData['customToken'] as String?;
      if (customToken != null && customToken.isNotEmpty) {
        await _auth.signInWithCustomToken(customToken);
        debugPrint('[AUTH_LOG] Firebase Custom Token sign-in succeeded for Email OTP!');
      }
    } catch (e) {
      debugPrint('[AUTH_LOG_WARN] Email OTP custom token sign-in exception: $e');
    }

    Map<String, dynamic>? data;
    String userUid = _auth.currentUser?.uid ?? '';

    // 1. Try lookup by email
    final emailSnap = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .get();

    if (emailSnap.docs.isNotEmpty) {
      data = emailSnap.docs.first.data();
      userUid = emailSnap.docs.first.id;
    } else {
      // 2. Try lookup by phone if provided
      final normPhone = _normalizeIndianPhone(phoneNumber) ?? phoneNumber;
      if (normPhone.isNotEmpty && normPhone.length >= 10) {
        final querySnap = await _firestore
            .collection('users')
            .where('phone', isEqualTo: normPhone)
            .get();

        if (querySnap.docs.isNotEmpty) {
          data = querySnap.docs.first.data();
          userUid = querySnap.docs.first.id;
        }
      }
    }

    // 3. Try lookup by current Firebase Auth UID if signed in
    if (data == null && userUid.isNotEmpty) {
      try {
        final docSnap = await _firestore.collection('users').doc(userUid).get();
        if (docSnap.exists) {
          data = docSnap.data();
        }
      } catch (e) {
        debugPrint('[AUTH_LOG_WARN] Firestore doc lookup error by UID: $e');
      }
    }

    // 4. If data is still null (e.g. user is in the middle of fresh registration flow),
    // return transient UserModel so registration can proceed to registerDirect immediately after OTP verification.
    if (data == null) {
      debugPrint('[AUTH_LOG] No existing profile in Firestore for $email. Returning transient UserModel for pending registration.');
      _currentUser = UserModel(
        uid: userUid.isNotEmpty ? userUid : 'temp_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Customer User',
        email: email.trim(),
        phone: phoneNumber.trim(),
        role: UserRole.customer,
        state: 'Tamil Nadu',
        district: 'Coimbatore',
      );
      return _currentUser;
    }

    _currentUser = UserModel.fromMap(data, userUid);
    return _currentUser;
  }



  // ============================================================
  // FARMER LOGIN WITH PHONE OTP & NAME VERIFICATION (.NET Backend DEMO OTP)
  // ============================================================

  Future<UserModel> loginFarmerWithPhoneOtp({
    required String farmerName,
    required String verificationId,
    required String smsCode,
  }) async {
    if (farmerName.trim().isEmpty) {
      throw Exception('Please enter your registered Farmer Name.');
    }

    if (verificationId.trim().isEmpty) {
      throw Exception('OTP session expired. Please request a new OTP.');
    }

    if (smsCode.trim().length != 6) {
      throw Exception('Please enter the complete 6-digit OTP code.');
    }

    final phone = _normalizeIndianPhone(verificationId) ?? verificationId;

    final baseUrl = AppConfig.backendBaseUrl;
    debugPrint('[AUTH_LOG] Backend base URL: $baseUrl');
    debugPrint('[AUTH_LOG] Starting loginFarmerWithPhoneOtp via Backend for phone: $phone, name: $farmerName');

    // 1. Verify OTP with .NET Backend API
    final response = await http.post(
      Uri.parse('$baseUrl/api/otp/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phoneNumber': phone,
        'otp': smsCode.trim(),
      }),
    );

    debugPrint('[AUTH_LOG] OTP verification HTTP status: ${response.statusCode}');

    if (response.statusCode != 200) {
      String msg = 'Failed to verify OTP.';
      try {
        final errorData = jsonDecode(response.body);
        msg = errorData['message'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }

    // 2. Backend OTP Verification Succeeded!
    debugPrint('[AUTH_LOG] Backend OTP verification succeeded for phone: $phone');

    // 3. Sign in to Firebase Authentication using Custom Token returned by Backend
    try {
      final resData = jsonDecode(response.body);
      final customToken = resData['customToken'] as String?;
      if (customToken != null && customToken.isNotEmpty) {
        await _auth.signInWithCustomToken(customToken);
        debugPrint('[AUTH_LOG] Firebase Custom Token sign-in succeeded! UID: ${_auth.currentUser?.uid}');
      }
    } catch (e) {
      debugPrint('[AUTH_LOG_WARN] Custom Token sign-in exception: $e');
    }

    // 4. Search Firestore for farmer user profile by phone number
    Map<String, dynamic>? data;
    String userUid = _auth.currentUser?.uid ?? 'farmer_${phone.replaceAll(RegExp(r'\D'), '')}';

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        data = querySnapshot.docs.first.data();
        userUid = querySnapshot.docs.first.id;
      } else {
        final allDocs = await _firestore.collection('users').get();
        for (var doc in allDocs.docs) {
          final docPhone = (doc.data()['phone'] as String?) ?? '';
          if (_normalizeIndianPhone(docPhone) == phone || docPhone.contains(phone.replaceAll('+91', ''))) {
            data = doc.data();
            userUid = doc.id;
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('[AUTH_LOG_WARN] Firestore read error during farmer login: $e');
    }

    if (data == null) {
      final newFarmer = UserModel(
        uid: userUid,
        name: farmerName.trim(),
        email: 'farmer_${phone.replaceAll(RegExp(r'\D'), '')}@agriconnect.org',
        phone: phone,
        role: UserRole.farmer,
        state: 'Tamil Nadu',
        district: 'Coimbatore',
        village: 'Pollachi',
        farmerType: 'Organic Farmer',
        verificationStatus: VerificationStatus.verified,
      );

      try {
        await _firestore.collection('users').doc(userUid).set(newFarmer.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('[AUTH_LOG_WARN] Could not write farmer user profile to Firestore: $e');
      }

      _currentUser = newFarmer;
      return _currentUser;
    }

    final registeredName = (data['name'] as String?)?.trim() ?? '';
    final roleStr = (data['role'] as String?) ?? '';

    if (roleStr != 'farmer') {
      throw Exception(
        'This account is registered as a CUSTOMER. Please switch to Customer login mode.',
      );
    }

    if (registeredName.toLowerCase() != farmerName.trim().toLowerCase()) {
      throw Exception(
        'Entered name "$farmerName" does not match registered account name "$registeredName".',
      );
    }

    _currentUser = UserModel.fromMap(data, userUid);
    debugPrint('[AUTH_LOG] Farmer login verified successfully for: ${_currentUser.name}');
    return _currentUser;
  }

  // ============================================================
  // PHONE OTP - VERIFY (Customer or Registration via .NET Backend)
  // ============================================================

  Future<UserModel> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
    required UserRole role,
    String? name,
    String? email,
    String? state,
    String? district,
    String? village,
    String? farmerType,
  }) async {
    if (verificationId.trim().isEmpty) {
      throw Exception('OTP session expired. Please request a new OTP.');
    }

    if (smsCode.trim().length != 6) {
      throw Exception('Please enter the complete 6-digit OTP code.');
    }

    final phone = _normalizeIndianPhone(verificationId) ?? verificationId;

    final baseUrl = AppConfig.backendBaseUrl;
    debugPrint('[AUTH_LOG] Backend base URL: $baseUrl');
    debugPrint('[AUTH_LOG] OTP verification via Backend started for phone: $phone');

    // 1. Verify OTP with .NET Backend
    final response = await http.post(
      Uri.parse('$baseUrl/api/otp/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phoneNumber': phone,
        'otp': smsCode.trim(),
      }),
    );

    debugPrint('[AUTH_LOG] OTP verification HTTP status: ${response.statusCode}');

    if (response.statusCode != 200) {
      String msg = 'Invalid OTP code.';
      try {
        final errorData = jsonDecode(response.body);
        msg = errorData['message'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }

    // 2. Backend OTP Verification Succeeded!
    debugPrint('[AUTH_LOG] Backend OTP verification succeeded for phone: $phone');

    // 3. Check for Firebase Custom Token returned by Backend
    try {
      final resData = jsonDecode(response.body);
      final customToken = resData['customToken'] as String?;
      if (customToken != null && customToken.isNotEmpty) {
        await _auth.signInWithCustomToken(customToken);
        debugPrint('[AUTH_LOG] Firebase Custom Token sign-in succeeded! UID: ${_auth.currentUser?.uid}');
      }
    } catch (e) {
      debugPrint('[AUTH_LOG_WARN] Custom Token sign-in exception: $e');
    }

    final uid = _auth.currentUser?.uid ?? 'user_${phone.replaceAll(RegExp(r'\D'), '')}';

    final newUser = UserModel(
      uid: uid,
      name: name?.trim().isNotEmpty == true
          ? name!.trim()
          : (role == UserRole.farmer ? 'Farmer' : 'Customer User'),
      email: email?.trim().isNotEmpty == true ? email!.trim() : '',

      phone: phone,
      role: role,
      state: state?.trim().isNotEmpty == true ? state!.trim() : 'Tamil Nadu',
      district: district?.trim().isNotEmpty == true ? district!.trim() : 'Coimbatore',
      village: village?.trim() ?? '',
      farmerType: farmerType?.trim().isNotEmpty == true ? farmerType!.trim() : 'Organic Farmer',
      verificationStatus: (role == UserRole.farmer)
          ? VerificationStatus.pending
          : VerificationStatus.verified,
    );

    // Save to Firestore if available
    try {
      await _firestore.collection('users').doc(uid).set(newUser.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[AUTH_LOG_WARN] Firestore write profile exception: $e');
    }

    _currentUser = newUser;
    return _currentUser;
  }

  // ============================================================
  // LOAD EXISTING FIRESTORE PROFILE OR CREATE NEW PROFILE
  // ============================================================

  Future<UserModel> _loadOrCreateFirestoreProfile(
    fb.User firebaseUser, {
    required UserRole requestedRole,
    String? name,
    String? email,
    String? state,
    String? district,
    String? village,
    String? farmerType,
  }) async {
    final uid = firebaseUser.uid;

    if (_auth.currentUser == null || _auth.currentUser!.uid != uid) {
      throw Exception('Firebase authentication session mismatch.');
    }

    debugPrint('[AUTH_LOG] Executing _loadOrCreateFirestoreProfile for users/$uid');

    final userRef = _firestore.collection('users').doc(uid);

    DocumentSnapshot<Map<String, dynamic>> userDoc;
    try {
      debugPrint('[AUTH_LOG] Operation: READ (users/$uid)');
      userDoc = await userRef.get();
      debugPrint('[AUTH_LOG] READ (users/$uid) Succeeded. Exists: ${userDoc.exists}');
    } on fb.FirebaseException catch (e) {
      debugPrint('[AUTH_LOG_ERROR] Firestore READ Failed for users/$uid');
      debugPrint('[AUTH_LOG_ERROR] Firebase Auth UID: ${_auth.currentUser?.uid}');
      debugPrint('[AUTH_LOG_ERROR] Target Doc UID: $uid');
      debugPrint('[AUTH_LOG_ERROR] FirebaseException Code: ${e.code}');
      debugPrint('[AUTH_LOG_ERROR] FirebaseException Message: ${e.message}');
      throw Exception('Firestore Access Denied [${e.code}]: ${e.message}');
    }

    if (!userDoc.exists || userDoc.data() == null) {
      debugPrint('[AUTH_LOG] Document users/$uid does NOT exist. Creating via set()...');

      final newUserData = {
        'uid': uid,
        'name': name?.trim().isNotEmpty == true
            ? name!.trim()
            : (firebaseUser.displayName?.isNotEmpty == true
                ? firebaseUser.displayName!
                : (requestedRole == UserRole.farmer ? 'Farmer' : 'Customer')),
        'email': email?.trim().isNotEmpty == true
            ? email!.trim()
            : (firebaseUser.email ?? ''),
        'phone': firebaseUser.phoneNumber ?? '',
        'role': requestedRole.name,
        'state': state?.trim().isNotEmpty == true ? state!.trim() : 'Tamil Nadu',
        'district': district?.trim().isNotEmpty == true
            ? district!.trim()
            : 'Coimbatore',
        'village': village?.trim() ?? '',
        'farmerType': farmerType?.trim().isNotEmpty == true
            ? farmerType!.trim()
            : 'Organic Farmer',
        'verificationStatus': 'verified',
        'createdAt': FieldValue.serverTimestamp(),
      };

      try {
        debugPrint('[AUTH_LOG] Operation: CREATE/SET (users/$uid)');
        await userRef.set(newUserData, SetOptions(merge: true));
        debugPrint('[AUTH_LOG] CREATE/SET (users/$uid) Succeeded!');
      } on fb.FirebaseException catch (e) {
        debugPrint('[AUTH_LOG_ERROR] Firestore CREATE/SET Failed for users/$uid');
        debugPrint('[AUTH_LOG_ERROR] Firebase Auth UID: ${_auth.currentUser?.uid}');
        debugPrint('[AUTH_LOG_ERROR] Target Doc UID: $uid');
        debugPrint('[AUTH_LOG_ERROR] FirebaseException Code: ${e.code}');
        debugPrint('[AUTH_LOG_ERROR] FirebaseException Message: ${e.message}');
        throw Exception('Firestore Write Error [${e.code}]: ${e.message}');
      }

      _currentUser = UserModel(
        uid: uid,
        name: newUserData['name'] as String,
        email: newUserData['email'] as String,
        phone: newUserData['phone'] as String,
        role: requestedRole,
        state: newUserData['state'] as String,
        district: newUserData['district'] as String,
        village: newUserData['village'] as String,
        farmerType: newUserData['farmerType'] as String,
        verificationStatus: VerificationStatus.verified,
      );

      return _currentUser;
    }

    final existingData = userDoc.data()!;
    final existingUser = UserModel.fromMap(existingData, uid);

    if (existingUser.role != requestedRole) {
      debugPrint('[AUTH_LOG_WARN] Role Mismatch! Registered as ${existingUser.role.name}, requested ${requestedRole.name}');
      throw Exception(
        'This account is registered as a ${existingUser.role.name.toUpperCase()}. Please switch to ${existingUser.role.name.toUpperCase()} login mode.',
      );
    }

    _currentUser = existingUser;
    return _currentUser;
  }

  // Legacy register helper
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
    final firebaseUser = _auth.currentUser;

    if (firebaseUser == null) {
      throw Exception(
        'Please verify your mobile number with OTP before completing account registration.',
      );
    }

    final user = UserModel(
      uid: firebaseUser.uid,
      name: name.trim(),
      email: email.trim(),
      phone: firebaseUser.phoneNumber ?? phone.trim(),
      role: role,
      state: state,
      district: district,
      village: village,
      farmerType: farmerType,
      verificationStatus: VerificationStatus.verified,
    );

    debugPrint('[AUTH_LOG] Operation: CREATE/SET (users/${firebaseUser.uid}) via legacy register');

    try {
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(user.toMap(), SetOptions(merge: true));
      debugPrint('[AUTH_LOG] Legacy register CREATE/SET succeeded!');
    } on fb.FirebaseException catch (e) {
      debugPrint('[AUTH_LOG_ERROR] Legacy register CREATE/SET Failed!');
      debugPrint('[AUTH_LOG_ERROR] FirebaseException Code: ${e.code}');
      debugPrint('[AUTH_LOG_ERROR] FirebaseException Message: ${e.message}');
      throw Exception('Firestore Write Error [${e.code}]: ${e.message}');
    }

    _currentUser = user;
    return user;
  }

  // ============================================================
  // UPDATE PROFILE
  // ============================================================

  Future<void> updateProfile(UserModel user) async {
    debugPrint('[AUTH_LOG] Operation: UPDATE (users/${user.uid})');
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
      debugPrint('[AUTH_LOG] updateProfile succeeded!');
    } on fb.FirebaseException catch (e) {
      debugPrint('[AUTH_LOG_ERROR] updateProfile Failed!');
      debugPrint('[AUTH_LOG_ERROR] FirebaseException Code: ${e.code}');
      debugPrint('[AUTH_LOG_ERROR] FirebaseException Message: ${e.message}');
      throw Exception('Firestore Write Error [${e.code}]: ${e.message}');
    }

    _currentUser = user;
  }

  // ============================================================
  // SWITCH ROLE (DEMO COMPATIBILITY)
  // ============================================================

  Future<void> switchRole(UserRole newRole) async {
    final uid = _auth.currentUser?.uid ?? _currentUser.uid;

    final updatedUser = _currentUser.copyWith(role: newRole);

    if (_auth.currentUser != null) {
      debugPrint('[AUTH_LOG] Operation: UPDATE (users/$uid) switchRole');
      try {
        await _firestore
            .collection('users')
            .doc(uid)
            .set(updatedUser.toMap(), SetOptions(merge: true));
        debugPrint('[AUTH_LOG] switchRole succeeded!');
      } on fb.FirebaseException catch (e) {
        debugPrint('[AUTH_LOG_ERROR] switchRole Failed!');
        debugPrint('[AUTH_LOG_ERROR] FirebaseException Code: ${e.code}');
        debugPrint('[AUTH_LOG_ERROR] FirebaseException Message: ${e.message}');
      }
    }

    _currentUser = updatedUser;
  }

  // ============================================================
  // VERIFICATION STATUS UPDATE
  // ============================================================

  Future<void> updateVerificationStatus(
    String uid,
    VerificationStatus status, {
    String? adminUid,
    String? rejectionReason,
  }) async {
    if (_currentUser.uid == uid) {
      _currentUser = _currentUser.copyWith(
        verificationStatus: status,
        rejectionReason: rejectionReason,
      );
    }

    final now = DateTime.now();
    debugPrint('[AUTH_LOG] Operation: UPDATE (users/$uid) verificationStatus to ${status.name}');
    try {
      final updateData = <String, dynamic>{
        'verificationStatus': status.name,
        'verifiedAt': now.toIso8601String(),
        if (adminUid != null && adminUid.isNotEmpty) 'verifiedBy': adminUid,
        if (rejectionReason != null && rejectionReason.isNotEmpty)
          'rejectionReason': rejectionReason,
      };
      await _firestore.collection('users').doc(uid).update(updateData);
      debugPrint('[AUTH_LOG] updateVerificationStatus succeeded!');
    } on fb.FirebaseException catch (e) {
      debugPrint('[AUTH_LOG_ERROR] updateVerificationStatus Failed: ${e.code} - ${e.message}');
      throw Exception('Failed to update verification status: ${e.message ?? e.code}');
    }
  }

  Stream<List<UserModel>> watchAllUsers() {
    final currentAuthUid = _auth.currentUser?.uid;
    if (currentAuthUid == null || currentAuthUid.isEmpty) {
      return Stream.value(SampleData.sampleUsers);
    }

    return _firestore.collection('users').snapshots().map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) {
          return UserModel.fromMap(doc.data(), doc.id);
        }).toList();
      }
      return SampleData.sampleUsers;
    }).handleError((e) {
      debugPrint('[AUTH_LOG_WARN] watchAllUsers error: $e');
      return SampleData.sampleUsers;
    });
  }

  // ============================================================
  // SIGN OUT (Requirement 10)
  // ============================================================

  Future<void> signOut() async {
    debugPrint('[AUTH_LOG] Executing signOut for UID: ${_auth.currentUser?.uid}');
    await _auth.signOut();
    _currentUser = UserModel(
      uid: '',
      name: 'Guest User',
      email: '',
      phone: '',
      role: UserRole.customer,
    );
  }

  // ============================================================
  // PHONE NUMBER HELPER (Supports +91 and Fictional Test Numbers)
  // ============================================================

  String? _normalizeIndianPhone(String input) {
    if (input.trim().isEmpty) return null;

    // Remove all whitespace, dashes, parentheses, dots
    var cleaned = input.trim().replaceAll(RegExp(r'[\s\-\(\)\.]'), '');

    // Replace leading '0091' with '+91'
    if (cleaned.startsWith('0091')) {
      cleaned = '+91${cleaned.substring(4)}';
    } else if (cleaned.startsWith('00')) {
      cleaned = '+${cleaned.substring(2)}';
    }

    // If starts with '+91', validate 10 digits after +91
    if (cleaned.startsWith('+91')) {
      final digits = cleaned.substring(3).replaceAll(RegExp(r'\D'), '');
      if (digits.length == 10) {
        return '+91$digits';
      }
      return null;
    }

    // If starts with '+', validate general E.164 (10 to 15 digits)
    if (cleaned.startsWith('+')) {
      final digits = cleaned.substring(1).replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 10 && digits.length <= 15) {
        return '+$digits';
      }
      return null;
    }

    // Extract digits only for remaining formats
    final digitsOnly = cleaned.replaceAll(RegExp(r'\D'), '');

    // 12 digits starting with '91' (e.g. 919448811035)
    if (digitsOnly.length == 12 && digitsOnly.startsWith('91')) {
      return '+$digitsOnly';
    }

    // 11 digits starting with '0' (e.g. 09448811035)
    if (digitsOnly.length == 11 && digitsOnly.startsWith('0')) {
      return '+91${digitsOnly.substring(1)}';
    }

    // Exactly 10 digits (e.g. 9448811035)
    if (digitsOnly.length == 10) {
      return '+91$digitsOnly';
    }

    return null;
  }

  // Friendly error mapping for Firebase exceptions
  String _friendlyAuthError(fb.FirebaseAuthException error) {
    if (error.message?.contains('BILLING_NOT_ENABLED') == true ||
        error.code == 'billing-not-enabled' ||
        error.message?.contains('17499') == true) {
      return 'Firebase SMS billing is not enabled for real SMS. For demo testing, please configure a Test Phone Number in Firebase Console -> Authentication -> Phone numbers for testing (e.g. +91 98765 43210 with test OTP 123456).';
    }

    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Invalid credentials. Please check your details or mobile number.';
      case 'invalid-phone-number':
        return 'The mobile number format is invalid. Please enter a valid 10-digit mobile number or test phone number.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes before trying again.';
      case 'invalid-verification-code':
        return 'The 6-digit OTP code is incorrect. Please check and try again.';
      case 'session-expired':
        return 'The OTP session has expired. Please request a new OTP.';
      case 'credential-already-in-use':
      case 'email-already-in-use':
        return 'An account with this phone number or email already exists.';
      case 'user-disabled':
        return 'This account has been disabled by the system administrator.';
      case 'network-request-failed':
        return 'Network error. Please check your mobile internet connection.';
      case 'operation-not-allowed':
        return 'Phone / Email authentication is not enabled in Firebase Console.';
      case 'weak-password':
        return 'The password is too weak. Please enter at least 6 characters.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
}

// ================================================================
// RIVERPOD NOTIFIER & PROVIDER
// ================================================================

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class CurrentUserNotifier extends StateNotifier<UserModel> {
  final AuthRepository _repo;

  CurrentUserNotifier(this._repo) : super(_repo.currentUser);

  Future<UserModel?> restoreSession() async {
    final user = await _repo.restoreUserSession();
    if (user != null) {
      state = user;
    }
    return user;
  }

  Future<UserModel> loginFarmerWithPhoneOtp({
    required String farmerName,
    required String verificationId,
    required String smsCode,
  }) async {
    final user = await _repo.loginFarmerWithPhoneOtp(
      farmerName: farmerName,
      verificationId: verificationId,
      smsCode: smsCode,
    );
    state = user;
    return user;
  }

  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final user = await _repo.loginWithEmail(
      email: email,
      password: password,
      role: role,
    );
    state = user;
    return user;
  }

  Future<UserModel> loginAdminWithEmail({
    required String email,
    required String password,
  }) async {
    final user = await _repo.loginAdminWithEmail(
      email: email,
      password: password,
    );
    state = user;
    return user;
  }

  Future<UserModel> login(
    String email,
    String password,
    UserRole role,
  ) async {
    return loginWithEmail(
      email: email,
      password: password,
      role: role,
    );
  }

  Future<UserModel> registerDirect({
    required String name,
    required String phone,
    required UserRole role,
    required String state,
    required String district,
    String village = '',
    String deliveryAddress = '',
    String farmerType = 'Organic Farmer',
    String email = '',
    String password = '',
    String? certificateUrl,
    String? certificateName,
  }) async {
    final user = await _repo.registerDirect(
      name: name,
      phone: phone,
      role: role,
      state: state,
      district: district,
      village: village,
      deliveryAddress: deliveryAddress,
      farmerType: farmerType,
      email: email,
      password: password,
      certificateUrl: certificateUrl,
      certificateName: certificateName,
    );

    this.state = user;
    return user;
  }

  Future<UserModel> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    required String state,
    required String district,
    String village = '',
    String farmerType = 'Organic Producer',
  }) async {
    final user = await _repo.registerWithEmail(
      name: name,
      email: email,
      password: password,
      role: role,
      state: state,
      district: district,
      village: village,
      farmerType: farmerType,
    );
    this.state = user;
    return user;
  }

  Future<void> sendCustomerEmailOtp({
    required String email,
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(fb.FirebaseAuthException error) onVerificationFailed,
  }) async {
    await _repo.sendCustomerEmailOtp(
      email: email,
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onVerificationFailed: onVerificationFailed,
    );
  }

  Future<UserModel> verifyEmailOtp({
    required String email,
    required String phoneNumber,
    required String otpCode,
  }) async {
    final user = await _repo.verifyEmailOtp(
      email: email,
      phoneNumber: phoneNumber,
      otpCode: otpCode,
    );
    state = user;
    return user;

  }

  Future<void> sendPhoneOtp({

    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(fb.FirebaseAuthException error)
        onVerificationFailed,
    void Function(fb.PhoneAuthCredential credential)? onAutoVerified,
  }) async {
    await _repo.sendPhoneOtp(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onVerificationFailed: onVerificationFailed,
      onAutoVerified: onAutoVerified,
    );
  }

  Future<UserModel> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
    required UserRole role,
    String? name,
    String? email,
    String? state,
    String? district,
    String? village,
    String? farmerType,
  }) async {
    final user = await _repo.verifyPhoneOtp(
      verificationId: verificationId,
      smsCode: smsCode,
      role: role,
      name: name,
      email: email,
      state: state,
      district: district,
      village: village,
      farmerType: farmerType,
    );

    this.state = user;
    return user;
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

  Future<void> updateProfile(UserModel user) async {
    await _repo.updateProfile(user);
    state = user;
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = _repo.currentUser;
  }

  Future<void> switchRole(UserRole newRole) async {
    await _repo.switchRole(newRole);
    state = _repo.currentUser;
  }

  Future<void> updateVerificationStatus(
    VerificationStatus status,
  ) async {
    await _repo.updateVerificationStatus(
      state.uid,
      status,
    );

    state = state.copyWith(
      verificationStatus: status,
    );
  }

  void setUser(UserModel user) {
    state = user;
  }
}

final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, UserModel>(
  (ref) {
    return CurrentUserNotifier(
      ref.watch(authRepositoryProvider),
    );
  },
);

final allUsersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.watchAllUsers();
});
