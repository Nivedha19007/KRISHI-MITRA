import 'package:flutter/material.dart';
import '../../data/datasources/sample_data.dart';
import '../../core/constants/app_colors.dart';

import '../../core/localization/localized_helpers.dart';
import '../../core/widgets/responsive_center.dart';

class SchemesScreen extends StatelessWidget {
  const SchemesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final schemes = SampleData.sampleSchemes;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text('${l10n.schemesTitle} 🏛️')),
      body: ResponsiveCenter(
        maxWidth: 1000,
        child: ListView.builder(
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: AppColors.primaryDarkGreen,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text(
                            scheme.category,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: AppColors.primaryLightGreen
                              .withValues(alpha: 0.2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      scheme.description,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${l10n.eligibility}:',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      scheme.eligibility,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${l10n.keyBenefits}:',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      scheme.benefits,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          scheme.officialUrl,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Opening official portal: ${scheme.officialUrl}',
                                ),
                              ),
                            );
                          },
                          child: Text(
                            l10n.applyNow,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
