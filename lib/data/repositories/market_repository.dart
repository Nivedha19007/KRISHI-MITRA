import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../models/mandi_price_model.dart';
import '../datasources/sample_data.dart';

@immutable
class MandiFilterQuery {
  final String? state;
  final String? district;
  final String? commodity;

  const MandiFilterQuery({
    this.state,
    this.district,
    this.commodity,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MandiFilterQuery &&
        other.state == state &&
        other.district == district &&
        other.commodity == commodity;
  }

  @override
  int get hashCode => Object.hash(state, district, commodity);

  @override
  String toString() =>
      'MandiFilterQuery(state: $state, district: $district, commodity: $commodity)';
}

class MarketRepository {
  final http.Client _httpClient;
  final List<MandiPriceModel> _prices = List.from(SampleData.sampleMandiPrices);

  MarketRepository({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Dynamically queries the .NET Backend GET /api/mandi/prices endpoint
  Future<List<MandiPriceModel>> fetchLiveMandiPrices({
    String? state,
    String? district,
    String? commodity,
  }) async {
    final queryParams = <String, String>{};
    if (state != null && state.trim().isNotEmpty && state != 'All') {
      queryParams['state'] = state.trim();
    }
    if (district != null && district.trim().isNotEmpty && district != 'All') {
      queryParams['district'] = district.trim();
    }
    if (commodity != null && commodity.trim().isNotEmpty && commodity != 'All') {
      queryParams['commodity'] = commodity.trim();
    }

    final uri = Uri.parse('${AppConfig.backendBaseUrl}/api/mandi/prices')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    debugPrint('[MARKET_REPO] Fetching live Mandi prices: $uri');

    try {
      final response = await _httpClient
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      debugPrint('[MARKET_REPO] HTTP ${response.statusCode} from $uri');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic>? rawRecords;
        if (decoded is Map<String, dynamic>) {
          rawRecords = decoded['records'] as List<dynamic>?;
        } else if (decoded is List<dynamic>) {
          rawRecords = decoded;
        }

        if (rawRecords != null && rawRecords.isNotEmpty) {
          final list = rawRecords
              .whereType<Map<String, dynamic>>()
              .map((r) => MandiPriceModel.fromAgmarknetApi(r))
              .toList();
          debugPrint('[MARKET_REPO] Successfully parsed ${list.length} Mandi records from backend.');
          return list;
        }
        debugPrint('[MARKET_REPO] Backend returned 200 OK with 0 records for query.');
        return [];
      } else {
        final errorMsg = 'Backend returned HTTP ${response.statusCode}: ${response.body}';
        debugPrint('[MARKET_REPO_ERROR] $errorMsg');
        throw Exception('Failed to load Mandi prices (HTTP ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('[MARKET_REPO_ERROR] Exception fetching live mandi prices: $e');
      rethrow;
    }
  }

  List<MandiPriceModel> getMandiPrices({
    String? state,
    String? product,
    String? variety,
  }) {
    return _prices.where((m) {
      if (state != null && state != 'All' && m.state != state) return false;
      if (product != null &&
          product != 'All' &&
          m.product.toLowerCase() != product.toLowerCase()) {
        return false;
      }
      if (variety != null &&
          variety != 'All' &&
          m.variety.toLowerCase() != variety.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
  }
}

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  return MarketRepository();
});

final liveMandiPricesProvider =
    FutureProvider.family<List<MandiPriceModel>, MandiFilterQuery>((ref, filter) async {
  final repo = ref.watch(marketRepositoryProvider);
  return repo.fetchLiveMandiPrices(
    state: filter.state,
    district: filter.district,
    commodity: filter.commodity,
  );
});

final mandiPricesProvider =
    Provider.family<List<MandiPriceModel>, Map<String, String>>((ref, filters) {
  final repo = ref.watch(marketRepositoryProvider);
  return repo.getMandiPrices(
    state: filters['state'],
    product: filters['product'],
    variety: filters['variety'],
  );
});
