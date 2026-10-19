import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/harvest_batch_model.dart';

class HarvestBatchRepository {
  final FirebaseFirestore _firestore;

  HarvestBatchRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('harvest_batches');

  Future<void> createHarvestBatch(HarvestBatchModel batch) async {
    await _collection.doc(batch.batchId).set(batch.toMap());
  }

  Future<HarvestBatchModel?> getHarvestBatch(String batchId) async {
    if (batchId.isEmpty) return null;
    final doc = await _collection.doc(batchId).get();
    if (!doc.exists || doc.data() == null) return null;
    return HarvestBatchModel.fromMap(doc.data()!, doc.id);
  }

  Stream<List<HarvestBatchModel>> watchBatchesForFarmer(String farmerId) {
    return _collection
        .where('farmerId', isEqualTo: farmerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HarvestBatchModel.fromMap(doc.data(), doc.id))
            .toList())
        .handleError((e) {
      return <HarvestBatchModel>[];
    });
  }

  Stream<List<HarvestBatchModel>> watchAllBatchesForAdmin() {
    return _collection.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => HarvestBatchModel.fromMap(doc.data(), doc.id))
        .toList()).handleError((e) {
      return <HarvestBatchModel>[];
    });
  }

  Future<void> updateBatchVerificationStatus({
    required String batchId,
    required String status,
    required String adminId,
    String? rejectionReason,
  }) async {
    await _collection.doc(batchId).update({
      'verificationStatus': status,
      'verifiedBy': adminId,
      'verifiedAt': DateTime.now().toIso8601String(),
      // ignore: use_null_aware_elements
      if (rejectionReason != null) 'rejectionReason': rejectionReason,




    });
  }
}

final harvestBatchRepositoryProvider = Provider<HarvestBatchRepository>((ref) {
  return HarvestBatchRepository();
});

final farmerBatchesStreamProvider =
    StreamProvider.family<List<HarvestBatchModel>, String>((ref, farmerId) {
  final repo = ref.watch(harvestBatchRepositoryProvider);
  return repo.watchBatchesForFarmer(farmerId);
});

final adminBatchesStreamProvider =
    StreamProvider<List<HarvestBatchModel>>((ref) {
  final repo = ref.watch(harvestBatchRepositoryProvider);
  return repo.watchAllBatchesForAdmin();
});
