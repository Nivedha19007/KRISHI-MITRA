import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/organic_certificate_model.dart';

class OrganicCertificateRepository {
  final FirebaseFirestore _firestore;

  OrganicCertificateRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('organic_certificates');

  Future<void> submitCertificate(OrganicCertificateModel cert) async {
    await _collection.doc(cert.certificateId).set(cert.toMap());
  }

  Future<OrganicCertificateModel?> getCertificate(String certId) async {
    if (certId.isEmpty) return null;
    final doc = await _collection.doc(certId).get();
    if (!doc.exists || doc.data() == null) return null;
    return OrganicCertificateModel.fromMap(doc.data()!, doc.id);
  }

  Stream<List<OrganicCertificateModel>> watchCertificatesForFarmer(String farmerId) {
    return _collection
        .where('farmerId', isEqualTo: farmerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrganicCertificateModel.fromMap(doc.data(), doc.id))
            .toList())
        .handleError((e) {
      return <OrganicCertificateModel>[];
    });
  }

  Stream<List<OrganicCertificateModel>> watchAllCertificatesForAdmin() {
    return _collection.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => OrganicCertificateModel.fromMap(doc.data(), doc.id))
        .toList()).handleError((e) {
      return <OrganicCertificateModel>[];
    });
  }

  Future<void> updateCertificateVerificationStatus({
    required String certificateId,
    required String status,
    required String adminId,
    String? rejectionReason,
  }) async {
    await _collection.doc(certificateId).update({
      'verificationStatus': status,
      'verifiedBy': adminId,
      'verifiedAt': DateTime.now().toIso8601String(),
      // ignore: use_null_aware_elements
      if (rejectionReason != null) 'rejectionReason': rejectionReason,




    });
  }
}

final organicCertificateRepositoryProvider =
    Provider<OrganicCertificateRepository>((ref) {
  return OrganicCertificateRepository();
});

final farmerCertificatesStreamProvider =
    StreamProvider.family<List<OrganicCertificateModel>, String>((ref, farmerId) {
  final repo = ref.watch(organicCertificateRepositoryProvider);
  return repo.watchCertificatesForFarmer(farmerId);
});

final adminCertificatesStreamProvider =
    StreamProvider<List<OrganicCertificateModel>>((ref) {
  final repo = ref.watch(organicCertificateRepositoryProvider);
  return repo.watchAllCertificatesForAdmin();
});
