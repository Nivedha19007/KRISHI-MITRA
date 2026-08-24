import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/repositories/market_repository.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/india_locations.dart';
import '../../core/widgets/responsive_center.dart';
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

  final List<String> _products = [
    'Tomato',
    'Onion',
    'Potato',
    'Grape',
    'Rice',
    'Wheat',
    'Cotton',
    'Banana',
    'Carrot',
    'All',
  ];

  final List<String> _varieties = [
    'Country Tomato',
    'Hybrid Tomato',
    'Cherry Tomato',
    'Roma Tomato',
    'Nashik Red',
    'Standard',
  ];

  @override
  Widget build(BuildContext context) {
    final liveMandiAsync = ref.watch(
      liveMandiPricesProvider(
        MandiFilterQuery(
          state: _selectedState,
          commodity: _selectedProduct,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Mandi Prices 📊'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 1000,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter Bar Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedState,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'State',
                                ),
                                items: IndiaLocations.statesAndUTs
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(
                                          s,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedState = val);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedProduct,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Crop',
                                ),
                                items: _products
                                    .map(
                                      (p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(p),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedProduct = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedVariety,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText:
                                'Variety Specific (Crucial for Prediction)',
                            prefixIcon: Icon(Icons.park),
                          ),
                          items: _varieties
                              .map(
                                (v) =>
                                    DropdownMenuItem(value: v, child: Text(v)),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedVariety = val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Async Handling
                liveMandiAsync.when(
                  loading: () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ),
                  error: (err, stack) => Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Failed to fetch live mandi prices from backend: $err',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (prices) {
                    if (prices.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.search_off,
                                  size: 44,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No live Mandi prices found for $_selectedState → $_selectedProduct',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final primaryMandi = prices.first;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Smart Prediction Banner Tile
                        Card(
                          color: AppColors.accentGold.withValues(alpha: 0.15),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.auto_graph,
                                  size: 44,
                                  color: AppColors.primaryDarkGreen,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$_selectedProduct Forecast',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const Text(
                                        'View ML variety price predictions & trends.',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        AppColors.primaryDarkGreen,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PricePredictionScreen(
                                          product: _selectedProduct,
                                          variety: _selectedVariety,
                                          location:
                                              '${primaryMandi.district}, ${primaryMandi.state}',
                                          currentPrice:
                                              primaryMandi.currentPricePerKg,
                                          historicalPrices:
                                              primaryMandi.historical7Days,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Predict',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Mandi Price Comparison List Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Live Mandi Price Comparison',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Top: ₹${primaryMandi.currentPricePerKg.toStringAsFixed(1)}/kg',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        ...prices.map(
                          (mandi) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.primaryLightGreen.withValues(
                                  alpha: 0.3,
                                ),
                                child: const Icon(
                                  Icons.storefront,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                              title: Text(
                                mandi.mandiName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              subtitle: Text(
                                'District: ${mandi.district} | Range: ₹${mandi.minPrice.toStringAsFixed(1)} - ₹${mandi.maxPrice.toStringAsFixed(1)}/kg',
                                style: const TextStyle(fontSize: 14),
                              ),
                              trailing: Text(
                                '₹${mandi.currentPricePerKg.toStringAsFixed(1)}/kg',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (primaryMandi.historical7Days.isNotEmpty) ...[
                          const Text(
                            '7-Day Historical Price Trend',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: primaryMandi.historical7Days
                                            .asMap()
                                            .entries
                                            .map(
                                              (e) => FlSpot(
                                                e.key.toDouble(),
                                                e.value,
                                              ),
                                            )
                                            .toList(),
                                        isCurved: true,
                                        color: AppColors.primaryGreen,
                                        barWidth: 4,
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: AppColors.primaryGreen
                                              .withValues(alpha: 0.2),
                                        ),
                                        dotData: const FlDotData(show: true),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
