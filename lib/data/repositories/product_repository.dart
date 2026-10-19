import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/app_config.dart';
import '../datasources/sample_data.dart';
import '../models/batch_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';

class ProductRepository {
  final FirebaseFirestore _firestore;
  final List<ProductModel> _localProducts = List<ProductModel>.from(
    SampleData.sampleProducts,
  );

  ProductRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _productsCollection =>
      _firestore.collection('products');

  List<ProductModel> getInitialProducts() {
    return List<ProductModel>.unmodifiable(_localProducts);
  }

  // ============================================================
  // GET / QUERY PRODUCTS
  // ============================================================

  Future<List<ProductModel>> getProducts({
    String? category,
    String? state,
    String? district,
    String? farmerId,
    String? searchQuery,
    bool isFarmerView = false,
  }) async {
    List<ProductModel> products = List<ProductModel>.from(_localProducts);

    try {
      Query<Map<String, dynamic>> query = _productsCollection;

      if (!isFarmerView) {
        query = query.where('isPublished', isEqualTo: true);
      }

      if (farmerId != null && farmerId.isNotEmpty) {
        query = query.where('farmerId', isEqualTo: farmerId);
      }

      if (category != null && category != 'All') {
        query = query.where('category', isEqualTo: category);
      }

      if (state != null && state != 'All') {
        query = query.where('state', isEqualTo: state);
      }

      if (district != null && district != 'All') {
        query = query.where('district', isEqualTo: district);
      }

      final snapshot = await query.get().timeout(const Duration(seconds: 4));

      if (snapshot.docs.isNotEmpty) {
        final remoteProducts = snapshot.docs
            .map(
              (doc) => ProductModel.fromMap(
                _convertFirestoreData(doc.data()),
                doc.id,
              ),
            )
            .toList();

        for (final p in remoteProducts) {
          final idx = _localProducts.indexWhere((lp) => lp.id == p.id);
          if (idx != -1) {
            _localProducts[idx] = p;
          } else {
            _localProducts.insert(0, p);
          }
        }
        products = List<ProductModel>.from(_localProducts);
      }
    } catch (e) {
      debugPrint('[PRODUCT_REPO_WARN] getProducts warning: $e');
    }

    var filtered = products;

    if (!isFarmerView) {
      filtered = filtered.where((p) => p.isPublished).toList();
    }

    if (farmerId != null && farmerId.isNotEmpty) {
      filtered = filtered.where((p) => p.farmerId == farmerId).toList();
    }

    if (category != null && category != 'All') {
      filtered = filtered.where((p) => p.category == category).toList();
    }

    if (state != null && state != 'All') {
      filtered = filtered.where((p) => p.state == state).toList();
    }

    if (district != null && district != 'All') {
      filtered = filtered.where((p) => p.district == district).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.variety.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            p.farmerName.toLowerCase().contains(q);
      }).toList();
    }

    return filtered;
  }

  // ============================================================
  // UPLOAD PRODUCT IMAGES TO FIREBASE STORAGE
  // ============================================================

  Future<List<String>> _uploadProductImages(
    String productId,
    List<XFile> images,
  ) async {
    if (images.isEmpty) return [];

    final uploadedUrls = <String>[];

    for (int i = 0; i < images.length; i++) {
      try {
        final file = File(images[i].path);
        if (!await file.exists()) continue;

        final ref = FirebaseStorage.instance
            .ref()
            .child('products')
            .child(productId)
            .child('image_$i.jpg');

        final uploadTask = await ref.putFile(
          file,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        final url = await uploadTask.ref.getDownloadURL();
        uploadedUrls.add(url);
        debugPrint('[PRODUCT_REPO] Image uploaded to Storage: $url');
      } catch (e) {
        debugPrint('[PRODUCT_REPO_WARN] Storage image upload failed: $e');
      }
    }

    return uploadedUrls;
  }

  // ============================================================
  // ADD PRODUCT
  // ============================================================

  Future<void> addProduct(
    ProductModel product, {
    List<XFile>? imageFiles,
  }) async {
    final authUid = fb.FirebaseAuth.instance.currentUser?.uid;
    final effectiveFarmerId = (authUid != null && authUid.isNotEmpty)
        ? authUid
        : product.farmerId;

    final productId = product.id.isNotEmpty
        ? product.id
        : 'prod_${DateTime.now().millisecondsSinceEpoch}';

    List<String> imageUrls = List<String>.from(product.imageUrls);
    if (imageFiles != null && imageFiles.isNotEmpty) {
      final storageUrls = await _uploadProductImages(productId, imageFiles);
      if (storageUrls.isNotEmpty) {
        imageUrls = storageUrls;
      }
    }

    final finalProduct = product.copyWith(
      id: productId,
      farmerId: effectiveFarmerId,
      imageUrls: imageUrls,
      availableStock: product.availableStock,
    );

    final idx = _localProducts.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      _localProducts[idx] = finalProduct;
    } else {
      _localProducts.insert(0, finalProduct);
    }

    final batchId = 'BATCH-${finalProduct.id}';
    final initialTimeline = [
      TimelineMilestone(
        id: 'seeded',
        stage: TimelineStage.seeded,
        title: 'Seeded',
        description: 'Sown high-grade crop seeds in prepared soil',
        timestamp: null,
        status: 'pending',
        location: '${finalProduct.district}, ${finalProduct.state}',
        actorName: finalProduct.farmerName,
      ),
      TimelineMilestone(
        id: 'crop_growing',
        stage: TimelineStage.cropGrowing,
        title: 'Crop Growing',
        description: 'Organic cultivation & regular farm monitoring',
        timestamp: null,
        status: 'pending',
        location: '${finalProduct.district}, ${finalProduct.state}',
        actorName: finalProduct.farmerName,
      ),
      TimelineMilestone(
        id: 'harvested',
        stage: TimelineStage.harvested,
        title: 'Harvested',
        description: 'Harvested fresh from farm fields',
        timestamp: finalProduct.harvestDate,
        status: 'completed',
        location: '${finalProduct.district}, ${finalProduct.state}',
        actorName: finalProduct.farmerName,
      ),
      TimelineMilestone(
        id: 'quality_verified',
        stage: TimelineStage.qualityVerified,
        title: 'Quality Verified',
        description: 'Quality inspection & grade assignment',
        timestamp: null,
        status: 'pending',
        location: '${finalProduct.district}, ${finalProduct.state}',
        actorName: finalProduct.farmerName,
      ),
      TimelineMilestone(
        id: 'packed',
        stage: TimelineStage.packed,
        title: 'Packed',
        description: 'Cleaned and packed into eco-friendly containers',
        timestamp: null,
        status: 'pending',
        location: '${finalProduct.district}, ${finalProduct.state}',
        actorName: finalProduct.farmerName,
      ),
      TimelineMilestone(
        id: 'shipped',
        stage: TimelineStage.shipped,
        title: 'Shipped',
        description: 'Dispatched for customer delivery',
        timestamp: null,
        status: 'pending',
        location: '${finalProduct.district}, ${finalProduct.state}',
        actorName: finalProduct.farmerName,
      ),
      TimelineMilestone(
        id: 'delivered',
        stage: TimelineStage.delivered,
        title: 'Delivered',
        description: 'Delivered to customer doorstep',
        timestamp: null,
        status: 'pending',
        location: '${finalProduct.district}, ${finalProduct.state}',
        actorName: finalProduct.farmerName,
      ),
    ];

    final batch = BatchModel(
      batchId: batchId,
      productId: finalProduct.id,
      farmerId: finalProduct.farmerId,
      farmerName: finalProduct.farmerName,
      farmLocation: '${finalProduct.district}, ${finalProduct.state}',
      productName: finalProduct.name,
      variety: finalProduct.variety,
      quantity: finalProduct.quantity,
      qualityStatus: 'Grade A+ (Quality Verified)',
      certificateInfo: finalProduct.certificateName.isNotEmpty
          ? finalProduct.certificateName
          : 'Organic India Certificate #IND-ORG-8821',
      currentStatus: 'Harvested',
      qrDataUrl: 'https://krishi-mitra-38a5f.web.app/trace/$batchId',
      timeline: initialTimeline,
    );

    try {
      final productMap = finalProduct.toMap();
      productMap['batchId'] = batchId;

      await _productsCollection
          .doc(finalProduct.id)
          .set(productMap, SetOptions(merge: true));

      await _firestore
          .collection('batches')
          .doc(batchId)
          .set(batch.toMap(), SetOptions(merge: true));

      debugPrint('[PRODUCT_REPO] Firestore product & batch added successfully: ${finalProduct.id}');
    } on fb.FirebaseException catch (e) {
      debugPrint('[PRODUCT_REPO_ERROR] Firestore addProduct failed: ${e.code} - ${e.message}');
      throw Exception('Failed to add product to marketplace [${e.code}]: ${e.message ?? "Permission denied."}');
    } catch (e) {
      debugPrint('[PRODUCT_REPO_ERROR] addProduct error: $e');
      rethrow;
    }
  }

  // ============================================================
  // SAVE FARMER TIMELINE (Requirement #5, #7, #8, #12)
  // Updates Firestore batches/{batchId} timeline without regenerating QR URL
  // ============================================================

  Future<void> saveBatchTimeline(
    String batchId,
    List<TimelineMilestone> timeline, {
    String? qualityStatus,
    String? certificateInfo,
  }) async {
    final completedMilestones = timeline.where((m) => m.isCompleted).toList();
    completedMilestones.sort((a, b) {
      if (a.timestamp == null && b.timestamp == null) return 0;
      if (a.timestamp == null) return 1;
      if (b.timestamp == null) return -1;
      return a.timestamp!.compareTo(b.timestamp!);
    });

    final latestStage = completedMilestones.isNotEmpty
        ? completedMilestones.last.title
        : 'Awaiting Update';

    final timelineMaps = timeline.map((m) => m.toMap()).toList();

    try {
      final batchRef = _firestore.collection('batches').doc(batchId);
      final updateData = <String, dynamic>{
        'timeline': timelineMaps,
        'currentStatus': latestStage,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (qualityStatus != null) updateData['qualityStatus'] = qualityStatus;
      if (certificateInfo != null) updateData['certificateInfo'] = certificateInfo;

      await batchRef.set(updateData, SetOptions(merge: true));
      debugPrint('[PRODUCT_REPO] Saved farmer-controlled timeline for batch $batchId to Firestore');
    } catch (e) {
      debugPrint('[PRODUCT_REPO_ERROR] saveBatchTimeline failed: $e');
      throw Exception('Failed to save timeline to Firestore: $e');
    }
  }

  // ============================================================
  // UPDATE PRODUCT
  // ============================================================

  // ============================================================
  // DEDUCT PRODUCT STOCK
  // ============================================================

  void deductProductStock(String productId, double quantity) {
    final idx = _localProducts.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      final currentStock = _localProducts[idx].availableStock;
      final newStock = (currentStock - quantity) < 0 ? 0.0 : (currentStock - quantity);
      _localProducts[idx] = _localProducts[idx].copyWith(availableStock: newStock);
      debugPrint('[PRODUCT_REPO] Stock deducted for $productId: $currentStock -> $newStock kg');
    }
  }

  Future<void> updateProduct(
    ProductModel product, {
    List<XFile>? newImageFiles,
  }) async {
    List<String> imageUrls = List<String>.from(product.imageUrls);
    if (newImageFiles != null && newImageFiles.isNotEmpty) {
      final storageUrls = await _uploadProductImages(product.id, newImageFiles);
      if (storageUrls.isNotEmpty) {
        imageUrls = storageUrls;
      }
    }

    final finalProduct = product.copyWith(imageUrls: imageUrls);

    final idx = _localProducts.indexWhere((p) => p.id == product.id);
    if (idx != -1) {
      _localProducts[idx] = finalProduct;
    }

    try {
      await _productsCollection
          .doc(product.id)
          .set(finalProduct.toMap(), SetOptions(merge: true));

      debugPrint('[PRODUCT_REPO] Firestore updateProduct succeeded: ${product.id}');
    } on fb.FirebaseException catch (e) {
      debugPrint('[PRODUCT_REPO_ERROR] updateProduct failed: ${e.code} - ${e.message}');
      throw Exception('Failed to update product: ${e.message ?? e.code}');
    }
  }

  // ============================================================
  // DELETE PRODUCT
  // ============================================================

  Future<void> deleteProduct(String productId) async {
    _localProducts.removeWhere((p) => p.id == productId);

    try {
      await _productsCollection.doc(productId).delete();
      debugPrint('[PRODUCT_REPO] Firestore product $productId deleted');
    } on fb.FirebaseException catch (e) {
      debugPrint('[PRODUCT_REPO_ERROR] deleteProduct failed: ${e.code} - ${e.message}');
      throw Exception('Failed to delete product: ${e.message ?? e.code}');
    }
  }

  // ============================================================
  // ADMIN PRODUCT VERIFICATION & APPROVAL (Requirement #7, #8)
  // ============================================================

  Future<void> updateProductVerification(
    String productId, {
    required VerificationStatus status,
    required bool isVerifiedFarmer,
    String? rejectionReason,
  }) async {
    final idx = _localProducts.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      _localProducts[idx] = _localProducts[idx].copyWith(
        certificationStatus: status,
        isVerifiedFarmer: isVerifiedFarmer,
        rejectionReason: rejectionReason,
      );
    }

    try {
      await _productsCollection.doc(productId).update({
        'certificationStatus': status.name,
        'isVerifiedFarmer': isVerifiedFarmer,
        'rejectionReason': rejectionReason,
        'verifiedAt': DateTime.now().toIso8601String(),
        'verifiedBy': fb.FirebaseAuth.instance.currentUser?.uid ?? 'admin',
      });
      debugPrint('[PRODUCT_REPO] Product $productId verification status updated to ${status.name}');
    } on fb.FirebaseException catch (e) {
      debugPrint('[PRODUCT_REPO_ERROR] updateProductVerification error: ${e.code} - ${e.message}');
      throw Exception('Failed to update product verification: ${e.message ?? e.code}');
    }
  }

  Future<BatchModel?> getBatchById(String batchId) async {
    final cleanId = AppConfig.sanitizeBatchId(batchId);
    try {
      final doc = await _firestore.collection('batches').doc(cleanId).get().timeout(const Duration(seconds: 3));
      if (doc.exists && doc.data() != null) {
        return BatchModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      debugPrint('[PRODUCT_REPO_WARN] getBatchById error: $e');
    }

    // Fallback 1: check local products
    ProductModel? matchedProduct;
    try {
      matchedProduct = _localProducts.firstWhere(
        (p) =>
            (p.batchId != null &&
                AppConfig.sanitizeBatchId(p.batchId!) == cleanId) ||
            p.id == cleanId ||
            cleanId.contains(p.id) ||
            'BATCH-${p.id}' == cleanId,
      );
    } catch (_) {}

    // Fallback 2: check sample products
    if (matchedProduct == null) {
      try {
        matchedProduct = SampleData.sampleProducts.firstWhere(
          (p) =>
              (p.batchId != null &&
                  AppConfig.sanitizeBatchId(p.batchId!) == cleanId) ||
              p.id == cleanId ||
              cleanId.contains(p.id) ||
              'BATCH-${p.id}' == cleanId,
        );
      } catch (_) {}
    }

    if (matchedProduct != null) {
      return BatchModel(
        batchId: cleanId,
        productId: matchedProduct.id,
        farmerId: matchedProduct.farmerId,
        farmerName: matchedProduct.farmerName,
        farmLocation: '${matchedProduct.district}, ${matchedProduct.state}',
        productName: matchedProduct.name,
        variety: matchedProduct.variety,
        quantity: matchedProduct.quantity,
        qualityStatus: matchedProduct.isOrganic
            ? 'Grade A+ (Organic Certified)'
            : 'Grade A (Quality Checked)',
        certificateInfo: matchedProduct.certificateName.isNotEmpty
            ? matchedProduct.certificateName
            : 'Organic India Certificate #IND-ORG-8821',
        currentStatus: matchedProduct.dispatched
            ? 'Dispatched 🚚'
            : (matchedProduct.packed
                ? 'Packed 📦'
                : (matchedProduct.qualityChecked
                    ? 'Quality Checked 🧪'
                    : 'Harvested 🌾')),
        qrDataUrl: 'https://krishi-mitra-38a5f.web.app/trace/$cleanId',
        timeline: [
          TimelineMilestone(
            stage: TimelineStage.cultivated,
            title: 'Sown & Cultivated 🌱',
            description: 'Cultivation and nursery management at ${matchedProduct.district}',
            timestamp: matchedProduct.harvestDate.subtract(const Duration(days: 90)),
            location: '${matchedProduct.district}, ${matchedProduct.state}',
            isCompleted: true,
          ),
          TimelineMilestone(
            stage: TimelineStage.harvested,
            title: 'Harvested 🌾',
            description: 'Crop harvested fresh at peak maturity',
            timestamp: matchedProduct.harvestDate,
            location: '${matchedProduct.district}, ${matchedProduct.state}',
            isCompleted: true,
          ),
          TimelineMilestone(
            stage: TimelineStage.qualityVerified,
            title: 'Quality Checked 🧪',
            description: 'Tested for moisture and organic quality standard compliance',
            timestamp: matchedProduct.harvestDate.add(const Duration(hours: 6)),
            location: '${matchedProduct.district} Agri Testing Lab',
            isCompleted: matchedProduct.qualityChecked || matchedProduct.packed || matchedProduct.dispatched,
          ),
          TimelineMilestone(
            stage: TimelineStage.packed,
            title: 'Packed & QR Tagged 📦',
            description: 'Batch sorted, sealed with batch tag #$cleanId',
            timestamp: matchedProduct.harvestDate.add(const Duration(days: 1)),
            location: '${matchedProduct.district} Packaging Hub',
            isCompleted: matchedProduct.packed || matchedProduct.dispatched,
          ),
          TimelineMilestone(
            stage: TimelineStage.dispatched,
            title: 'Dispatched for Delivery 🚚',
            description: 'Handed over to verified logistics network for customer delivery',
            timestamp: matchedProduct.expectedDeliveryDate.subtract(const Duration(hours: 12)),
            location: 'Transit Network',
            isCompleted: matchedProduct.dispatched,
          ),
        ],
      );
    }

    return null;
  }

  // Real-time stream listening to products collection
  Stream<List<ProductModel>> watchProducts({
    String? category,
    String? state,
    String? district,
    String? farmerId,
    bool isFarmerView = false,
  }) {
    Query<Map<String, dynamic>> query = _productsCollection;

    if (!isFarmerView) {
      query = query.where('isPublished', isEqualTo: true);
    }

    if (farmerId != null && farmerId.isNotEmpty) {
      query = query.where('farmerId', isEqualTo: farmerId);
    }

    return query.snapshots().map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final remoteProducts = snapshot.docs
            .map(
              (doc) => ProductModel.fromMap(
                _convertFirestoreData(doc.data()),
                doc.id,
              ),
            )
            .toList();

        for (final p in remoteProducts) {
          final idx = _localProducts.indexWhere((lp) => lp.id == p.id);
          if (idx != -1) {
            _localProducts[idx] = p;
          } else {
            _localProducts.insert(0, p);
          }
        }
      }
      return List<ProductModel>.unmodifiable(_localProducts);
    }).handleError((_) {
      return List<ProductModel>.unmodifiable(_localProducts);
    });
  }

  Stream<List<ProductModel>> watchAllPlatformProducts() {
    return _productsCollection.snapshots().map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) {
          return ProductModel.fromMap(
            _convertFirestoreData(doc.data()),
            doc.id,
          );
        }).toList();
      }
      return List<ProductModel>.unmodifiable(_localProducts);
    }).handleError((e) {
      debugPrint('[PRODUCT_REPO_WARN] watchAllPlatformProducts error: $e');
      return List<ProductModel>.unmodifiable(_localProducts);
    });
  }

  Map<String, dynamic> _convertFirestoreData(Map<String, dynamic> data) {
    final converted = Map<String, dynamic>.from(data);

    for (final key in ['harvestDate', 'expectedDeliveryDate', 'createdAt']) {
      final value = converted[key];

      if (value is Timestamp) {
        converted[key] = value.toDate().toIso8601String();
      }
    }

    return converted;
  }
}

// ================================================================
// RIVERPOD NOTIFIERS & PROVIDERS
// ================================================================

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

class ProductsNotifier extends StateNotifier<List<ProductModel>> {
  final ProductRepository _repo;
  StreamSubscription<List<ProductModel>>? _subscription;

  ProductsNotifier(this._repo) : super(_repo.getInitialProducts()) {
    _init();
  }

  void _init() {
    _subscription = _repo.watchProducts().listen((products) {
      state = products;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> loadProducts({
    String? category,
    String? selectedState,
    String? selectedDistrict,
    String? searchQuery,
    String? farmerId,
    bool isFarmerView = false,
  }) async {
    state = await _repo.getProducts(
      category: category,
      state: selectedState,
      district: selectedDistrict,
      searchQuery: searchQuery,
      farmerId: farmerId,
      isFarmerView: isFarmerView,
    );
  }

  Future<void> filter({
    String? category,
    String? selectedState,
    String? selectedDistrict,
    String? searchQuery,
  }) async {
    await loadProducts(
      category: category,
      selectedState: selectedState,
      selectedDistrict: selectedDistrict,
      searchQuery: searchQuery,
    );
  }

  Future<void> addProduct(ProductModel product) async {
    await _repo.addProduct(product);
    state = [product, ...state.where((p) => p.id != product.id)];
  }

  Future<void> updateProduct(ProductModel product) async {
    await _repo.updateProduct(product);
    state = state.map((p) => p.id == product.id ? product : p).toList();
  }

  Future<void> deleteProduct(String productId) async {
    await _repo.deleteProduct(productId);
    state = state.where((p) => p.id != productId).toList();
  }

  Future<void> togglePublishStatus(ProductModel product) async {
    final updated = product.copyWith(isPublished: !product.isPublished);
    await updateProduct(updated);
  }

  void deductStock(String productId, double quantity) {
    _repo.deductProductStock(productId, quantity);
    state = state.map((p) {
      if (p.id == productId) {
        final currentStock = p.availableStock;
        final newStock = (currentStock - quantity) < 0 ? 0.0 : (currentStock - quantity);
        return p.copyWith(availableStock: newStock);
      }
      return p;
    }).toList();
  }
}


final productsProvider =
    StateNotifierProvider<ProductsNotifier, List<ProductModel>>((ref) {
      return ProductsNotifier(ref.watch(productRepositoryProvider));
    });

final farmerProductsProvider =
    FutureProvider.family<List<ProductModel>, String>((ref, farmerId) async {
      final allProducts = ref.watch(productsProvider);
      final filtered = allProducts.where((p) => p.farmerId == farmerId).toList();
      if (filtered.isNotEmpty) return filtered;
      return ref
          .watch(productRepositoryProvider)
          .getProducts(farmerId: farmerId, isFarmerView: true);
    });

final allPlatformProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.watchAllPlatformProducts();
});
