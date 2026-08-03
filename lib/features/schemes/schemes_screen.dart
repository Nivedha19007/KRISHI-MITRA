import 'package:flutter/material.dart';
import '../../data/datasources/sample_data.dart';
import '../../core/constants/app_colors.dart';

class SchemesScreen extends StatelessWidget {
  const SchemesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final schemes = SampleData.sampleSchemes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Government Schemes 🏛️'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: schemes.length,
        itemBuilder: (context, index) {
          final scheme = schemes[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          scheme.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryDarkGreen),
                        ),
                      ),
                      Chip(
                        label: Text(scheme.category, style: const TextStyle(fontSize: 11)),
                        backgroundColor: AppColors.primaryLightGreen.withOpacity(0.2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(scheme.description, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 12),
                  const Text('Eligibility:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(scheme.eligibility, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  const SizedBox(height: 8),
                  const Text('Key Benefits:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(scheme.benefits, style: const TextStyle(fontSize: 13, color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(scheme.officialUrl, style: const TextStyle(fontSize: 12, color: Colors.blue, decoration: TextDecoration.underline)),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Opening official portal: ${scheme.officialUrl}')),
                          );
                        },
                        child: const Text('Apply Info'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
