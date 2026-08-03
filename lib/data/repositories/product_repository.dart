import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../models/batch_model.dart';
import '../datasources/sample_data.dart';

class ProductRepository {
  final List<ProductModel> _products = List.from(SampleData.sampleProducts);
  final List<BatchModel> _batches = [];

  List<ProductModel> getProducts({
    String? category,
    String? state,
    String? district,
    String? farmerId,
    String? searchQuery,
  }) {
    return _products.where((p) {
      if (category != null && category != 'All' && p.category != category) return false;
      if (state != null && state != 'All' && p.state != state) return false;
      if (district != null && district != 'All' && p.district != district) return false;
      if (farmerId != null && p.farmerId != farmerId) return false;
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        final matchName = p.name.toLowerCase().contains(query);
        final matchVariety = p.variety.toLowerCase().contains(query);
        final matchFarmer = p.farmerName.toLowerCase().contains(query);
        final matchDistrict = p.district.toLowerCase().contains(query);
        final matchState = p.state.toLowerCase().contains(query);
        final matchCategory = p.category.toLowerCase().contains(query);
        if (!matchName && !matchVariety && !matchFarmer && !matchDistrict && !matchState && !matchCategory) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  ProductModel? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  BatchModel? getBatchById(String batchId) {
    try {
      return _batches.firstWhere((b) => b.batchId == batchId);
    } catch (_) {
      // Find product matching batchId or create sample batch model from product information
      final product = _products.firstWhere(
        (p) => p.batchId == batchId,
        orElse: () => _products.first,
      );
      return BatchModel(
        batchId: batchId,
        productId: product.id,
        farmerId: product.farmerId,
        farmerName: product.farmerName,
        farmLocation: product.location,
        productName: product.name,
        variety: product.variety,
        quantity: product.quantity,
        currentStatus: product.dispatched ? 'Dispatched 🚚' : 'Quality Checked 🧪',
        timeline: SampleData.getTimelineForCrop(
          cropName: product.name,
          batchId: batchId,
          farmerName: product.farmerName,
          location: product.location,
          harvestDate: product.harvestDate,
        ),
      );
    }
  }

  void addProduct(ProductModel product) {
    _products.insert(0, product);
    final batchId = product.batchId ?? 'BATCH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    _batches.insert(
      0,
      BatchModel(
        batchId: batchId,
        productId: product.id,
        farmerId: product.farmerId,
        farmerName: product.farmerName,
        farmLocation: product.location,
        productName: product.name,
        variety: product.variety,
        quantity: product.quantity,
        currentStatus: 'Quality Checked 🧪',
        timeline: SampleData.getTimelineForCrop(
          cropName: product.name,
          batchId: batchId,
          farmerName: product.farmerName,
          location: product.location,
          harvestDate: product.harvestDate,
        ),
      ),
    );
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

class ProductsNotifier extends StateNotifier<List<ProductModel>> {
  final ProductRepository _repo;

  ProductsNotifier(this._repo) : super(_repo.getProducts());

  void filter({String? category, String? selectedState, String? selectedDistrict, String? searchQuery}) {
    state = _repo.getProducts(
      category: category,
      state: selectedState,
      district: selectedDistrict,
      searchQuery: searchQuery,
    );
  }

  void addProduct(ProductModel product) {
    _repo.addProduct(product);
    state = _repo.getProducts();
  }
}

final productsProvider = StateNotifierProvider<ProductsNotifier, List<ProductModel>>((ref) {
  return ProductsNotifier(ref.watch(productRepositoryProvider));
});

final farmerProductsProvider = Provider.family<List<ProductModel>, String>((ref, farmerId) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getProducts(farmerId: farmerId);
});
