import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mandi_price_model.dart';
import '../datasources/sample_data.dart';

class MarketRepository {
  final List<MandiPriceModel> _prices = List.from(SampleData.sampleMandiPrices);

  List<MandiPriceModel> getMandiPrices({String? state, String? product, String? variety}) {
    return _prices.where((m) {
      if (state != null && state != 'All' && m.state != state) return false;
      if (product != null && product != 'All' && m.product.toLowerCase() != product.toLowerCase()) return false;
      if (variety != null && variety != 'All' && m.variety.toLowerCase() != variety.toLowerCase()) return false;
      return true;
    }).toList();
  }
}

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  return MarketRepository();
});

final mandiPricesProvider = Provider.family<List<MandiPriceModel>, Map<String, String>>((ref, filters) {
  final repo = ref.watch(marketRepositoryProvider);
  return repo.getMandiPrices(
    state: filters['state'],
    product: filters['product'],
    variety: filters['variety'],
  );
});
