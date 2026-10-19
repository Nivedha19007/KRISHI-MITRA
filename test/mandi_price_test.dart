import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:agriconnect/data/models/mandi_price_model.dart';
import 'package:agriconnect/data/repositories/market_repository.dart';

void main() {
  group('MandiPriceModel Tests', () {
    test('fromAgmarknetApi parses numeric and string fields correctly', () {
      final sampleRecord = {
        'state': 'Tamil Nadu',
        'district': 'Erode',
        'market': 'Gobichettipalayam',
        'commodity': 'Tomato',
        'variety': 'Local',
        'arrival_date': '24/08/2026',
        'min_price': '2000',
        'max_price': '3000',
        'modal_price': '2500',
      };

      final model = MandiPriceModel.fromAgmarknetApi(sampleRecord);

      expect(model.state, 'Tamil Nadu');
      expect(model.district, 'Erode');
      expect(model.mandiName, 'Gobichettipalayam');
      expect(model.product, 'Tomato');
      expect(model.variety, 'Local');
      expect(model.currentPricePerKg, 25.0); // 2500 / 100
      expect(model.minPrice, 20.0); // 2000 / 100
      expect(model.maxPrice, 30.0); // 3000 / 100
      expect(model.date.year, 2026);
      expect(model.date.month, 8);
      expect(model.date.day, 24);
    });

    test('fromAgmarknetApi handles prices with commas and hyphenated dates', () {
      final sampleRecord = {
        'stateName': 'Maharashtra',
        'districtName': 'Nashik',
        'mandiName': 'Lasalgaon',
        'crop': 'Onion',
        'grade': 'Red',
        'date': '2026-08-24',
        'minPrice': '1,800',
        'maxPrice': '2,400',
        'modalPrice': '2,100',
      };

      final model = MandiPriceModel.fromAgmarknetApi(sampleRecord);

      expect(model.state, 'Maharashtra');
      expect(model.district, 'Nashik');
      expect(model.mandiName, 'Lasalgaon');
      expect(model.product, 'Onion');
      expect(model.variety, 'Red');
      expect(model.currentPricePerKg, 21.0); // 2100 / 100
      expect(model.minPrice, 18.0); // 1800 / 100
      expect(model.maxPrice, 24.0); // 2400 / 100
      expect(model.date.year, 2026);
      expect(model.date.month, 8);
      expect(model.date.day, 24);
    });

    test('fromAgmarknetApi applies fallback when min or max price is missing or 0', () {
      final sampleRecord = {
        'state': 'Punjab',
        'district': 'Ludhiana',
        'market': 'Khanna',
        'commodity': 'Wheat',
        'modal_price': 2200,
        'min_price': 0,
        'max_price': null,
      };

      final model = MandiPriceModel.fromAgmarknetApi(sampleRecord);

      expect(model.currentPricePerKg, 22.0);
      expect(model.minPrice, 22.0); // falls back to modal price per kg
      expect(model.maxPrice, 22.0); // falls back to modal price per kg
    });
  });

  group('MarketRepository Filtering Tests', () {
    final rawApiJson = jsonEncode({
      'status': 'ok',
      'records': [
        {
          'state': 'Tamil Nadu',
          'district': 'Erode',
          'market': 'Gobi',
          'commodity': 'Tomato',
          'variety': 'Local',
          'modal_price': '2500'
        },
        {
          'state': 'Tamil Nadu',
          'district': 'Coimbatore',
          'market': 'Cbe Market',
          'commodity': 'Tomato',
          'variety': 'Hybrid',
          'modal_price': '2600'
        },
        {
          'state': 'Maharashtra',
          'district': 'Nashik',
          'market': 'Lasalgaon',
          'commodity': 'Onion',
          'variety': 'Red',
          'modal_price': '2100'
        },
      ]
    });

    test('fetchLiveMandiPrices filters strictly by state, district, and commodity', () async {
      final mockClient = MockClient((request) async {
        return http.Response(rawApiJson, 200);
      });

      final repo = MarketRepository(httpClient: mockClient);

      // Search state: Tamil Nadu, district: Erode, commodity: Tomato
      final results = await repo.fetchLiveMandiPrices(
        state: 'Tamil Nadu',
        district: 'Erode',
        commodity: 'Tomato',
      );

      expect(results.length, 1);
      expect(results.first.state, 'Tamil Nadu');
      expect(results.first.district, 'Erode');
      expect(results.first.product, 'Tomato');
    });

    test('fetchLiveMandiPrices handles state aliases and crop synonyms', () async {
      final aliasApiJson = jsonEncode({
        'status': 'ok',
        'records': [
          {
            'state': 'Keralam',
            'district': 'Malappuram',
            'market': 'Chungathara VFPCK',
            'commodity': 'Banana',
            'variety': 'Local',
            'modal_price': '3500'
          },
          {
            'state': 'Uttar Pradesh',
            'district': 'Mau(Maunathbhanjan)',
            'market': 'Kopaganj APMC',
            'commodity': 'Paddy(Common)',
            'variety': 'Common',
            'modal_price': '2400'
          },
        ]
      });

      final mockClient = MockClient((request) async {
        return http.Response(aliasApiJson, 200);
      });

      final repo = MarketRepository(httpClient: mockClient);

      // Search 'Kerala' matching 'Keralam'
      final keralaResults = await repo.fetchLiveMandiPrices(
        state: 'Kerala',
        district: 'Malappuram',
        commodity: 'Banana',
      );
      expect(keralaResults.length, 1);
      expect(keralaResults.first.state, 'Keralam');

      // Search 'Mau' matching 'Mau(Maunathbhanjan)' and 'Rice' matching 'Paddy(Common)'
      final upResults = await repo.fetchLiveMandiPrices(
        state: 'Uttar Pradesh',
        district: 'Mau',
        commodity: 'Rice',
      );
      expect(upResults.length, 1);
      expect(upResults.first.district, 'Mau(Maunathbhanjan)');
    });

    test('fetchLiveMandiPrices returns empty list when no record matches all criteria', () async {
      final mockClient = MockClient((request) async {
        return http.Response(rawApiJson, 200);
      });

      final repo = MarketRepository(httpClient: mockClient);

      // Search state: Tamil Nadu, district: Erode, commodity: Wheat (not present in raw records)
      final results = await repo.fetchLiveMandiPrices(
        state: 'Tamil Nadu',
        district: 'Erode',
        commodity: 'Wheat',
      );

      expect(results.isEmpty, isTrue);
    });
  });
}
