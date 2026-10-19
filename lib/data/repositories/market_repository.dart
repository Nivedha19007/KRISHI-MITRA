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
        if (decoded is Map<String, dynamic> && decoded['status'] == 'error') {
          final msg = decoded['message'] ?? decoded['error'] ?? 'API error';
          debugPrint('[MARKET_REPO_ERROR] Backend status error: $msg');
          throw Exception(msg);
        }

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
              .where((model) {
                if (state != null && state != 'All' && !_matchNormalized(model.state, state)) {
                  return false;
                }
                if (district != null && district != 'All' && !_matchNormalized(model.district, district)) {
                  return false;
                }
                if (commodity != null && commodity != 'All' && !_matchCommodity(model.product, commodity)) {
                  return false;
                }
                return true;
              })
              .toList();
          debugPrint('[MARKET_REPO] Successfully parsed ${list.length} Mandi records matching query.');
          return list;
        }
        debugPrint('[MARKET_REPO] Backend returned 200 OK with 0 records for query.');
        return [];
      } else {
        String errorMsg = 'Failed to load Mandi prices (HTTP ${response.statusCode})';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic> && (decoded['message'] != null || decoded['error'] != null)) {
            errorMsg = decoded['message']?.toString() ?? decoded['error']?.toString() ?? errorMsg;
          }
        } catch (_) {}
        debugPrint('[MARKET_REPO_ERROR] $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[MARKET_REPO_ERROR] Exception fetching live mandi prices: $e');
      rethrow;
    }
  }

  static String _normalize(String input) {
    if (input.isEmpty) return '';
    return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').trim();
  }

  static bool _matchNormalized(String? value, String? target) {
    if (target == null || target.trim().isEmpty || target.trim() == 'All') return true;
    if (value == null || value.trim().isEmpty) return false;
    final valNorm = _normalize(value);
    final targetNorm = _normalize(target);
    if (valNorm == targetNorm) return true;
    if (valNorm.contains(targetNorm) || targetNorm.contains(valNorm)) return true;

    final stateAliases = {
      'Kerala': ['kerala', 'keralam'],
      'Keralam': ['kerala', 'keralam'],
      'Odisha': ['odisha', 'orissa'],
      'Orissa': ['odisha', 'orissa'],
      'Puducherry': ['puducherry', 'pondicherry'],
      'Pondicherry': ['puducherry', 'pondicherry'],
    };

    for (final entry in stateAliases.entries) {
      final keyNorm = _normalize(entry.key);
      if (targetNorm == keyNorm || targetNorm.contains(keyNorm) || keyNorm.contains(targetNorm)) {
        for (final alias in entry.value) {
          final aliasNorm = _normalize(alias);
          if (valNorm == aliasNorm || valNorm.contains(aliasNorm) || aliasNorm.contains(valNorm)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  static bool _matchCommodity(String? value, String? target) {
    if (target == null || target.trim().isEmpty || target.trim() == 'All') return true;
    if (value == null || value.trim().isEmpty) return false;
    final valNorm = _normalize(value);
    final targetNorm = _normalize(target);
    if (valNorm == targetNorm || valNorm.contains(targetNorm) || targetNorm.contains(valNorm)) {
      return true;
    }
    final synonyms = {
      'tomato': ['tomato', 'tamato'],
      'potato': ['potato', 'aloo'],
      'onion': ['onion', 'pyaz'],
      'rice': ['rice', 'paddy', 'paddycommon', 'bpt', 'dhan'],
      'paddy': ['rice', 'paddy', 'paddycommon', 'bpt', 'dhan'],
      'wheat': ['wheat', 'gehun'],
      'banana': ['banana', 'bananaripe', 'bananagreen'],
      'chilli': ['chilli', 'chillies', 'greenchilli', 'chili', 'chilired', 'drychillies', 'capsicum'],
      'groundnut': ['groundnut', 'groundnutseed', 'peanut'],
      'ginger': ['ginger', 'gingergreen', 'gingerdry'],
      'brinjal': ['brinjal', 'eggplant'],
      'maize': ['maize', 'corn'],
      'cucumber': ['cucumbar', 'cucumbarkheera', 'cucumber', 'kheera'],
      'okra': ['bhindiladiesfinger', 'bhindi', 'ladiesfinger'],
      'ladies finger': ['bhindiladiesfinger', 'bhindi', 'ladiesfinger'],
      'cauliflower': ['cauliflower'],
      'cabbage': ['cabbage'],
      'carrot': ['carrot'],
      'apple': ['apple'],
      'tur': ['redgramarharturwhole', 'tur', 'arhar'],
      'arhar': ['redgramarharturwhole', 'tur', 'arhar'],
      'urad': ['blackgramurdbeanswhole', 'urad', 'urd'],
      'moong': ['greengrammoongwhole', 'moong'],
      'chana': ['bengalgramgramwhole', 'chana', 'gram'],
    };
    for (final entry in synonyms.entries) {
      final keyNorm = _normalize(entry.key);
      if (targetNorm == keyNorm || targetNorm.contains(keyNorm) || keyNorm.contains(targetNorm)) {
        for (final syn in entry.value) {
          if (valNorm.contains(syn)) return true;
        }
      }
    }
    return false;
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
