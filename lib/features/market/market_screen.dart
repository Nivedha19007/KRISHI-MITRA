import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/repositories/market_repository.dart';
import '../../data/datasources/sample_data.dart';
import '../../core/constants/app_colors.dart';
import 'price_prediction_screen.dart';

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  String _selectedState = 'Tamil Nadu';
  String _selectedProduct = 'Tomato';
  String _selectedVariety = 'Country Tomato';

  final List<String> _products = ['Tomato', 'Onion', 'Potato', 'Grape', 'Rice', 'Wheat'];
  final List<String> _varieties = ['Country Tomato', 'Hybrid Tomato', 'Cherry Tomato', 'Roma Tomato', 'Nashik Red'];

  @override
  Widget build(BuildContext context) {
    final mandiPrices = ref.watch(mandiPricesProvider({
      'state': _selectedState,
      'product': _selectedProduct,
      'variety': _selectedVariety,
    }));

    // If no filtered price match, fallback to sample prices for visual chart
    final displayPrices = mandiPrices.isNotEmpty ? mandiPrices : SampleData.sampleMandiPrices;
    final primaryMandi = displayPrices.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Mandi Prices 📊'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Bar Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedState,
                            decoration: const InputDecoration(labelText: 'State'),
                            items: SampleData.states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (val) => setState(() => _selectedState = val!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedProduct,
                            decoration: const InputDecoration(labelText: 'Crop'),
                            items: _products.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                            onChanged: (val) => setState(() => _selectedProduct = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedVariety,
                      decoration: const InputDecoration(
                        labelText: 'Variety Specific (Crucial for Prediction)',
                        prefixIcon: Icon(Icons.park),
                      ),
                      items: _varieties.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                      onChanged: (val) => setState(() => _selectedVariety = val!),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Smart Prediction Banner Tile
            Card(
              color: AppColors.accentGold.withOpacity(0.15),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.auto_graph, size: 40, color: AppColors.primaryDarkGreen),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_selectedVariety Forecast',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Text('View 3-7 day ML variety price predictions & trends.', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDarkGreen),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PricePredictionScreen(
                              product: _selectedProduct,
                              variety: _selectedVariety,
                              location: 'Coimbatore, $_selectedState',
                              currentPrice: primaryMandi.currentPricePerKg,
                              historicalPrices: primaryMandi.historical7Days,
                            ),
                          ),
                        );
                      },
                      child: const Text('Predict'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Mandi Price Comparison List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mandi Price Comparison', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Today: ₹${primaryMandi.currentPricePerKg}/kg', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
              ],
            ),
            const SizedBox(height: 12),

            ...displayPrices.map(
              (mandi) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: mandi.isUpward ? AppColors.primaryLightGreen.withOpacity(0.3) : Colors.red.shade100,
                    child: Icon(
                      mandi.isUpward ? Icons.trending_up : Icons.trending_down,
                      color: mandi.isUpward ? AppColors.primaryGreen : Colors.red,
                    ),
                  ),
                  title: Text(mandi.mandiName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('District: ${mandi.district} | Range: ₹${mandi.minPrice} - ₹${mandi.maxPrice}'),
                  trailing: Text(
                    '₹${mandi.currentPricePerKg.toStringAsFixed(0)}/kg',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // fl_chart 7-Day Historical Trend Chart
            const Text('7-Day Historical Price Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true),
                      titlesData: const FlTitlesData(
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
                      lineBarsData: [
                        LineChartBarData(
                          spots: primaryMandi.historical7Days
                              .asMap()
                              .entries
                              .map((e) => FlSpot(e.key.toDouble(), e.value))
                              .toList(),
                          isCurved: true,
                          color: AppColors.primaryGreen,
                          barWidth: 4,
                          belowBarData: BarAreaData(show: true, color: AppColors.primaryGreen.withOpacity(0.2)),
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
