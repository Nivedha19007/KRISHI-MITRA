import 'package:flutter/material.dart';
import '../../core/services/weather_service.dart';
import '../../core/constants/app_colors.dart';

class AdvisoryScreen extends StatefulWidget {
  const AdvisoryScreen({super.key});

  @override
  State<AdvisoryScreen> createState() => _AdvisoryScreenState();
}

class _AdvisoryScreenState extends State<AdvisoryScreen> {
  final _weatherService = WeatherService();
  WeatherData? _weather;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  void _loadWeather() async {
    final w = await _weatherService.getWeatherForLocation('Tamil Nadu', 'Coimbatore');
    if (mounted) {
      setState(() {
        _weather = w;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agricultural Advisory & Weather'),
      ),
      body: SingleChildScrollView(
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
                              Text('${_weather!.district}, ${_weather!.state}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(_weather!.condition, style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                          Text(
                            '${_weather!.temperatureCelsius}°C',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.water_drop, color: Colors.blue, size: 18),
                          const SizedBox(width: 4),
                          Text('Rainfall Chance: ${_weather!.rainfallProbabilityPercent}%'),
                          const SizedBox(width: 16),
                          const Icon(Icons.air, color: Colors.blue, size: 18),
                          const SizedBox(width: 4),
                          Text('Humidity: ${_weather!.humidityPercent}%'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '💡 ${_weather!.advisoryNote}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),

            const Text('Seasonal Advisory Reminders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryDarkGreen)),
            const SizedBox(height: 6),
            Text(desc, style: const TextStyle(fontSize: 13, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
