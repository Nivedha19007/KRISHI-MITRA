import 'package:flutter/material.dart';
import '../../core/services/weather_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';

import '../../core/widgets/responsive_center.dart';

class AdvisoryScreen extends StatefulWidget {
  const AdvisoryScreen({super.key});

  @override
  State<AdvisoryScreen> createState() => _AdvisoryScreenState();
}

class _AdvisoryScreenState extends State<AdvisoryScreen> {
  final _weatherService = WeatherService();
  WeatherData? _weather;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  void _loadWeather() async {
    final w = await _weatherService.getWeatherForLocation(
      'Tamil Nadu',
      'Coimbatore',
    );
    if (mounted) {
      setState(() {
        _weather = w;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.advisoryTitle)),
      body: ResponsiveCenter(
        maxWidth: 1000,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weather Card
              if (_weather != null)
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_weather!.district}, ${_weather!.state}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  _weather!.condition,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            Text(
                              '${_weather!.temperatureCelsius}°C',
                              style: const TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.water_drop,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Rainfall Chance: ${_weather!.rainfallProbabilityPercent}%',
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.air, color: Colors.blue, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              'Humidity: ${_weather!.humidityPercent}%',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '💡 ${_weather!.advisoryNote}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              Text(
                l10n.advisoryTitle,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _buildTipCard(
                '🌱 Soil Health & Organic Composting',
                'Apply neem cake and trichoderma viride before transplanting country tomato saplings to protect roots against fungal wilt.',
              ),
              _buildTipCard(
                '💧 Efficient Irrigation Guidelines',
                'Adopt drip irrigation in morning hours to conserve water and prevent leaf surface moisture accumulation during high-humidity periods.',
              ),
              _buildTipCard(
                '🐛 Biological Pest Management',
                'Set yellow sticky traps around vegetable plots to monitor and control whitefly and thrips populations organically.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipCard(String title, String desc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.primaryDarkGreen,
              ),
            ),
            const SizedBox(height: 6),
            Text(desc, style: const TextStyle(fontSize: 15, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
