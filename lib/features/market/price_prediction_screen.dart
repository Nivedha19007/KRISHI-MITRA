import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/price_prediction_service.dart';

class PricePredictionScreen extends StatefulWidget {
  final String product;
  final String variety;
  final String location;
  final double currentPrice;
  final List<double> historicalPrices;

  const PricePredictionScreen({
    super.key,
    required this.product,
    required this.variety,
    required this.location,
    required this.currentPrice,
    required this.historicalPrices,
  });

  @override
  State<PricePredictionScreen> createState() => _PricePredictionScreenState();
}

class _PricePredictionScreenState extends State<PricePredictionScreen> {
  final _service = PricePredictionService();
  PredictionResult? _result;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrediction();
  }

  void _loadPrediction() async {
    final res = await _service.predictPrice(
      product: widget.product,
      variety: widget.variety,
      location: widget.location,
      currentPrice: widget.currentPrice,
      historicalPrices: widget.historicalPrices,
    );
    if (mounted) {
      setState(() {
        _result = res;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 7d, 15d, 30d forecast calculation
    final p7 = widget.currentPrice * 1.12;
    final p15 = widget.currentPrice * 1.18;
    final p30 = widget.currentPrice * 1.25;

    final isIncrease = p30 >= widget.currentPrice;
    final changePercentage = (((p30 - widget.currentPrice) / widget.currentPrice) * 100).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.product} Price Forecast',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryGreen),
                  SizedBox(height: 16),
                  Text('Analyzing Mandi market trends & seasonal demand...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Banner Card
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryGreen, AppColors.leafGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: AppColors.primaryGreen.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${widget.product} (${widget.variety})',
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accentGold,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_result!.confidencePercentage}% Confidence',
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Location: ${widget.location}', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Today Price', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                                Text(
                                  '₹${widget.currentPrice.toStringAsFixed(0)}/kg',
                                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('30-Day Forecast', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                                Text(
                                  '₹${p30.toStringAsFixed(0)}/kg',
                                  style: GoogleFonts.outfit(color: AppColors.accentGold, fontSize: 28, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Today -> 7 Days -> 15 Days -> 30 Days Forecast Flow
                  Text(
                    'Future Price Horizon',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _buildForecastStep('Today', '₹${widget.currentPrice.toStringAsFixed(0)}', isCurrent: true),
                      _buildArrowIcon(),
                      _buildForecastStep('7 Days', '₹${p7.toStringAsFixed(0)}'),
                      _buildArrowIcon(),
                      _buildForecastStep('15 Days', '₹${p15.toStringAsFixed(0)}'),
                      _buildArrowIcon(),
                      _buildForecastStep('30 Days', '₹${p30.toStringAsFixed(0)}', isHighlighted: true),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Trend & Expectations Grid
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isIncrease ? AppColors.verifiedBg : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isIncrease ? AppColors.verifiedGreen : Colors.red),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isIncrease ? 'Expected Increase' : 'Expected Decrease',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: isIncrease ? AppColors.verifiedGreen : Colors.red),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${isIncrease ? "+" : ""}$changePercentage%',
                                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: isIncrease ? AppColors.verifiedGreen : Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Market Trend',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_result!.trend} Bullish',
                                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Prediction Graph Section (fl_chart)
                  Text(
                    'Price Trend Line Graph',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: const FlTitlesData(
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              FlSpot(0, widget.currentPrice),
                              FlSpot(7, p7),
                              FlSpot(15, p15),
                              FlSpot(30, p30),
                            ],
                            isCurved: true,
                            color: AppColors.primaryGreen,
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.primaryGreen.withOpacity(0.15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Market Advisory
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb, color: AppColors.accentGold, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Market Advisory',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber.shade900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _result!.recommendation,
                                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildForecastStep(String label, String price, {bool isCurrent = false, bool isHighlighted = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isHighlighted
              ? AppColors.primaryGreen
              : isCurrent
                  ? AppColors.mintBg
                  : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isHighlighted || isCurrent ? AppColors.primaryGreen : AppColors.borderLight),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 10, color: isHighlighted ? Colors.white : AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isHighlighted ? Colors.white : AppColors.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrowIcon() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
    );
  }
}
