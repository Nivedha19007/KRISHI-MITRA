import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quality_complaint_model.dart';

class QualityComplaintRepository {
  final FirebaseFirestore _firestore;

  QualityComplaintRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('quality_complaints');

  Future<void> submitComplaint(QualityComplaintModel complaint) async {
    await _collection.doc(complaint.complaintId).set(complaint.toMap());
  }

  Stream<List<QualityComplaintModel>> watchComplaintsForCustomer(String customerId) {
    return _collection
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QualityComplaintModel.fromMap(doc.data(), doc.id))
            .toList())
        .handleError((e) {
      return <QualityComplaintModel>[];
    });
  }

  Stream<List<QualityComplaintModel>> watchAllComplaintsForAdmin() {
    return _collection.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => QualityComplaintModel.fromMap(doc.data(), doc.id))
        .toList()).handleError((e) {
      return <QualityComplaintModel>[];
    });
  }

  Future<void> updateComplaintStatus({
    required String complaintId,
    required String status,
    String? adminRemarks,
  }) async {
    await _collection.doc(complaintId).update({
      'status': status,
      // ignore: use_null_aware_elements
      if (adminRemarks != null) 'adminRemarks': adminRemarks,




    });
  }
}

final qualityComplaintRepositoryProvider =
    Provider<QualityComplaintRepository>((ref) {
  return QualityComplaintRepository();
});

final customerComplaintsStreamProvider =
    StreamProvider.family<List<QualityComplaintModel>, String>((ref, customerId) {
  final repo = ref.watch(qualityComplaintRepositoryProvider);
  return repo.watchComplaintsForCustomer(customerId);
});

final adminComplaintsStreamProvider =
    StreamProvider<List<QualityComplaintModel>>((ref) {
  final repo = ref.watch(qualityComplaintRepositoryProvider);
  return repo.watchAllComplaintsForAdmin();
});
