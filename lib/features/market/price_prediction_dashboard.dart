import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/india_locations.dart';

import '../../core/widgets/responsive_center.dart';

class PricePredictionDashboard extends StatefulWidget {
  const PricePredictionDashboard({super.key});

  @override
  State<PricePredictionDashboard> createState() =>
      _PricePredictionDashboardState();
}

class _PricePredictionDashboardState extends State<PricePredictionDashboard> {
  String _selectedCrop = 'Tomato';
  String _selectedVariety = 'Country Tomato';
  String _selectedState = 'Tamil Nadu';

  final List<String> _crops = [
    'Tomato',
    'Onion',
    'Rice',
    'Mango',
    'Grape',
    'Wheat',
  ];
  final List<String> _varieties = [
    'Country Tomato',
    'Hybrid Tomato',
    'Nashik Red',
    'Sona Masoori',
    'Alphonso',
  ];

  @override
  Widget build(BuildContext context) {
    // Prediction calculations
    double todayPrice = 24.0;
    if (_selectedCrop == 'Rice') todayPrice = 52.0;
    if (_selectedCrop == 'Mango') todayPrice = 140.0;
    if (_selectedCrop == 'Onion') todayPrice = 22.0;

    final p7 = (todayPrice * 1.12).roundToDouble(); // +12%
    final p15 = (todayPrice * 1.25).roundToDouble(); // +25%
    final p30 = (todayPrice * 1.40).roundToDouble(); // +40%
    final expectedIncreasePercent = 40.0;
    const confidenceScore = 84.5;
    const trend = 'Increasing 📈';

    return Scaffold(
      appBar: AppBar(title: const Text('Future Price Prediction 🔮')),
      body: ResponsiveCenter(
        maxWidth: 1000,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Crop & Variety Selector Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedState,
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
                              onChanged: (v) =>
                                  setState(() => _selectedState = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedCrop,
                              decoration: const InputDecoration(
                                labelText: 'Crop',
                              ),
                              items: _crops
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedCrop = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _varieties.contains(_selectedVariety)
                            ? _selectedVariety
                            : _varieties.first,
                        decoration: const InputDecoration(
                          labelText: 'Select Crop Variety',
                          prefixIcon: Icon(Icons.park),
                        ),
                        items: _varieties
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedVariety = v!),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Prediction Overview Card
              Card(
                color: AppColors.primaryGreen,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$_selectedCrop ($_selectedVariety)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Chip(
                            label: Text('$confidenceScore% Confidence'),
                            backgroundColor: AppColors.accentGold,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Today\'s Price',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '₹${todayPrice.toStringAsFixed(0)}/kg',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                '30-Day Forecast',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '₹${p30.toStringAsFixed(0)}/kg',
                                style: const TextStyle(
                                  color: AppColors.accentGold,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.trending_up,
                            color: Colors.greenAccent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Market Trend: $trend (+$expectedIncreasePercent% Expected Increase)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 7, 15, 30 Day Prediction Cards
              const Text(
                'Multi-Day Price Prediction Timeline',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  _buildForecastCard(
                    'Today',
                    '₹${todayPrice.toStringAsFixed(0)}',
                  ),
                  const SizedBox(width: 8),
                  _buildForecastCard('7 Days', '₹${p7.toStringAsFixed(0)}'),
                  const SizedBox(width: 8),
                  _buildForecastCard('15 Days', '₹${p15.toStringAsFixed(0)}'),
                  const SizedBox(width: 8),
                  _buildForecastCard(
                    '30 Days',
                    '₹${p30.toStringAsFixed(0)}',
                    isHighlighted: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Interactive Prediction Graph using fl_chart
              const Text(
                'Price Forecast Curve (Next 30 Days)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    height: 220,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: const FlTitlesData(
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              FlSpot(0, todayPrice),
                              FlSpot(7, p7),
                              FlSpot(15, p15),
                              FlSpot(30, p30),
                            ],
                            isCurved: true,
                            color: AppColors.accentGold,
                            barWidth: 4,
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.accentGold.withValues(
                                alpha: 0.2,
                              ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildForecastCard(
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return Expanded(
      child: Card(
        color: isHighlighted ? AppColors.mintBg : Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isHighlighted
                      ? AppColors.primaryGreen
                      : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
