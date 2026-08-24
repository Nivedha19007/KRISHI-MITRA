class WeatherData {
  final String state;
  final String district;
  final double temperatureCelsius;
  final String condition;
  final int rainfallProbabilityPercent;
  final int humidityPercent;
  final String advisoryNote;

  WeatherData({
    required this.state,
    required this.district,
    required this.temperatureCelsius,
    required this.condition,
    required this.rainfallProbabilityPercent,
    required this.humidityPercent,
    required this.advisoryNote,
  });
}

class WeatherService {
  Future<WeatherData> getWeatherForLocation(
    String state,
    String district,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));

    return WeatherData(
      state: state,
      district: district,
      temperatureCelsius: 28.5,
      condition: 'Partly Cloudy ⛅',
      rainfallProbabilityPercent: 35,
      humidityPercent: 68,
      advisoryNote:
          'Moderate humidity expected over $district. Ensure proper ventilation in crop storage units and plan pest inspection accordingly.',
    );
  }
}
