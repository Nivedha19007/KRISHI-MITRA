import 'package:flutter_test/flutter_test.dart';
import 'package:agriconnect/data/models/mandi_price_model.dart';

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
}
