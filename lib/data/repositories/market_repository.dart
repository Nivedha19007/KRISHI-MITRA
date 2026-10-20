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

  static const String _primaryResourceId = '35985678-0d79-46b4-9ed6-6f13308a1d24';
  static const String _secondaryResourceId = '9ef84268-d588-465a-a308-a864a43d0070';
  static const String _dataGovApiKey = '579b464db66ec23bdd000001b3e85b5bfab041e166329d1a10969bea';

  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'User-Agent': 'curl/8.13.0',
  };

  MarketRepository({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Fetches live Mandi prices with a resilient multi-tier strategy:
  /// Tier 1: Direct official Government of India Agmarknet API (data.gov.in)
  /// Tier 2: Backend proxy (http/https API proxy)
  /// Tier 3: Curated realistic reference prices (offline fallback)
  Future<List<MandiPriceModel>> fetchLiveMandiPrices({
    String? state,
    String? district,
    String? commodity,
  }) async {
    final cleanState = (state != null && state.trim().isNotEmpty && state != 'All')
        ? state.trim()
        : null;
    final cleanDistrict = (district != null && district.trim().isNotEmpty && district != 'All')
        ? district.trim()
        : null;
    final cleanCommodity = (commodity != null && commodity.trim().isNotEmpty && commodity != 'All')
        ? commodity.trim()
        : null;

    debugPrint('[MARKET_REPO] fetchLiveMandiPrices State=$cleanState, District=$cleanDistrict, Commodity=$cleanCommodity');

    // 1. Direct Government Agmarknet API (fastest, authentic live data)
    try {
      final govRecords = await _fetchFromDataGov(
        state: cleanState,
        district: cleanDistrict,
        commodity: cleanCommodity,
      );
      if (govRecords.isNotEmpty) {
        debugPrint('[MARKET_REPO] Returning ${govRecords.length} records from data.gov.in.');
        return govRecords;
      }
    } catch (e) {
      debugPrint('[MARKET_REPO] Direct data.gov.in query failed: $e');
    }

    // 2. Backend proxy query
    try {
      final backendRecords = await _fetchFromBackendProxy(
        state: cleanState,
        district: cleanDistrict,
        commodity: cleanCommodity,
      );
      if (backendRecords.isNotEmpty) {
        debugPrint('[MARKET_REPO] Returning ${backendRecords.length} records from Backend proxy.');
        return backendRecords;
      }
    } catch (e) {
      debugPrint('[MARKET_REPO] Backend proxy query failed: $e');
    }

    // 3. Fallback to curated realistic Mandi prices for offline resilience
    debugPrint('[MARKET_REPO] Remote sources returned 0 records or offline. Checking curated reference prices.');
    final localFallback = getMandiPrices(
      state: cleanState,
      product: cleanCommodity,
    );
    if (localFallback.isNotEmpty) {
      debugPrint('[MARKET_REPO] Returning ${localFallback.length} curated reference records.');
      return localFallback;
    }

    debugPrint('[MARKET_REPO] No mandi prices found matching query.');
    return [];
  }

  Future<List<MandiPriceModel>> _fetchFromDataGov({
    String? state,
    String? district,
    String? commodity,
  }) async {
    final resourceIds = [_primaryResourceId, _secondaryResourceId];

    for (final resId in resourceIds) {
      final queryAttempts = <Map<String, String>>[];

      // Attempt 1: State + District + Commodity
      if (state != null && district != null && commodity != null) {
        queryAttempts.add({
          'api-key': _dataGovApiKey,
          'format': 'json',
          'limit': '100',
          'filters[state]': state,
          'filters[district]': district,
          'filters[commodity]': commodity,
        });
      }

      // Attempt 2: State + Commodity (nearby markets in state if district has 0 daily records)
      if (state != null && commodity != null) {
        queryAttempts.add({
          'api-key': _dataGovApiKey,
          'format': 'json',
          'limit': '100',
          'filters[state]': state,
          'filters[commodity]': commodity,
        });
      }

      // Attempt 3: State only
      if (state != null && commodity == null) {
        queryAttempts.add({
          'api-key': _dataGovApiKey,
          'format': 'json',
          'limit': '100',
          'filters[state]': state,
        });
      }

      // Attempt 4: Commodity only
      if (state == null && commodity != null) {
        queryAttempts.add({
          'api-key': _dataGovApiKey,
          'format': 'json',
          'limit': '100',
          'filters[commodity]': commodity,
        });
      }

      // Fallback: Broad top records
      if (queryAttempts.isEmpty) {
        queryAttempts.add({
          'api-key': _dataGovApiKey,
          'format': 'json',
          'limit': '100',
        });
      }

      for (final params in queryAttempts) {
        try {
          final uri = Uri.https('api.data.gov.in', '/resource/$resId', params);
          debugPrint('[MARKET_REPO] Querying data.gov.in: $uri');

          final response = await _httpClient
              .get(uri, headers: _headers)
              .timeout(const Duration(seconds: 8));

          if (response.statusCode == 200) {
            final decoded = jsonDecode(response.body);
            if (decoded is Map<String, dynamic> && decoded['status'] == 'ok') {
              final rawRecords = decoded['records'] as List<dynamic>?;
              if (rawRecords != null && rawRecords.isNotEmpty) {
                final list = _parseAndFilterRecords(
                  rawRecords,
                  state: state,
                  district: district,
                  commodity: commodity,
                );
                if (list.isNotEmpty) {
                  return list;
                }
              }
            }
          }
        } catch (e) {
          debugPrint('[MARKET_REPO] data.gov.in attempt error: $e');
        }
      }
    }
    return [];
  }

  Future<List<MandiPriceModel>> _fetchFromBackendProxy({
    String? state,
    String? district,
    String? commodity,
  }) async {
    final queryParams = <String, String>{};
    if (state != null && state.isNotEmpty) {
      queryParams['state'] = state;
    }
    if (district != null && district.isNotEmpty) {
      queryParams['district'] = district;
    }
    if (commodity != null && commodity.isNotEmpty) {
      queryParams['commodity'] = commodity;
    }

    final uri = Uri.parse('${AppConfig.backendBaseUrl}/api/mandi/prices')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    debugPrint('[MARKET_REPO] Querying backend proxy: $uri');

    final response = await _httpClient
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['status'] == 'error') {
        return [];
      }

      List<dynamic>? rawRecords;
      if (decoded is Map<String, dynamic>) {
        rawRecords = decoded['records'] as List<dynamic>?;
      } else if (decoded is List<dynamic>) {
        rawRecords = decoded;
      }

      if (rawRecords != null && rawRecords.isNotEmpty) {
        return _parseAndFilterRecords(
          rawRecords,
          state: state,
          district: district,
          commodity: commodity,
        );
      }
    }
    return [];
  }

  List<MandiPriceModel> _parseAndFilterRecords(
    List<dynamic> rawRecords, {
    String? state,
    String? district,
    String? commodity,
  }) {
    return rawRecords
        .whereType<Map<String, dynamic>>()
        .map((r) => MandiPriceModel.fromAgmarknetApi(r))
        .where((model) {
          if (state != null && state != 'All' && !_matchNormalized(model.state, state)) {
            return false;
          }
          if (district != null && district != 'All' && !_matchNormalized(model.district, district)) {
            // If strict district matching filtered it out, allow state matching as secondary
            return false;
          }
          if (commodity != null && commodity != 'All' && !_matchCommodity(model.product, commodity)) {
            return false;
          }
          return true;
        })
        .toList();
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
      if (state != null && state != 'All' && !_matchNormalized(m.state, state)) return false;
      if (product != null &&
          product != 'All' &&
          !_matchCommodity(m.product, product)) {
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
