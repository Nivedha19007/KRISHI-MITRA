import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';

import '../../core/widgets/responsive_center.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    final languages = [
      {'name': 'English', 'code': 'en'},
      {'name': 'हिन्दी (Hindi)', 'code': 'hi'},
      {'name': 'தமிழ் (Tamil)', 'code': 'ta'},
      {'name': 'తెలుగు (Telugu)', 'code': 'te'},
      {'name': 'ಕನ್ನಡ (Kannada)', 'code': 'kn'},
      {'name': 'മലയാളം (Malayalam)', 'code': 'ml'},
      {'name': 'मराठी (Marathi)', 'code': 'mr'},
      {'name': 'ગુજરાતી (Gujarati)', 'code': 'gu'},
      {'name': 'ਪੰਜਾਬੀ (Punjabi)', 'code': 'pa'},
      {'name': 'বাংলা (Bengali)', 'code': 'bn'},
      {'name': 'ଓଡ଼ିଆ (Odia)', 'code': 'or'},
      {'name': 'অসমীয়া (Assamese)', 'code': 'as'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Application Settings ⚙️')),
      body: ResponsiveCenter(
        maxWidth: 800,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'App Preferences',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 8),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.language,
                      color: AppColors.primaryGreen,
                    ),
                    title: const Text(
                      'Application Language',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      languages.firstWhere(
                        (l) => l['code'] == currentLocale.languageCode,
                      )['name']!,
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select Language',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: ListView(
                                  children: languages.map((lang) {
                                    final isSel =
                                        lang['code'] ==
                                        currentLocale.languageCode;
                                    return ListTile(
                                      title: Text(
                                        lang['name']!,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      trailing: isSel
                                          ? const Icon(
                                              Icons.check_circle,
                                              color: AppColors.primaryGreen,
                                            )
                                          : null,
                                      onTap: () {
                                        ref
                                            .read(localeProvider.notifier)
                                            .setLocale(lang['code']!);
                                        Navigator.pop(context);
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(
                      Icons.dark_mode_outlined,
                      color: AppColors.primaryGreen,
                    ),
                    title: const Text(
                      'Material 3 Dark Mode',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      'Switch between Light and Dark themes',
                      style: TextStyle(fontSize: 14),
                    ),
                    value: false,
                    onChanged: (val) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Theme settings updated.'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Notifications & Privacy',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 8),

            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(
                      Icons.notifications_active_outlined,
                      color: AppColors.primaryGreen,
                    ),
                    title: const Text(
                      'Push Notifications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      'Order updates & Mandi price alerts',
                      style: TextStyle(fontSize: 14),
                    ),
                    value: true,
                    onChanged: (val) {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.security,
                      color: AppColors.primaryGreen,
                    ),
                    title: const Text(
                      'Privacy & Data Protection',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Support & About',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 8),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.help_outline,
                      color: AppColors.primaryGreen,
                    ),
                    title: const Text(
                      'Help & Farmer Support',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      'Toll-Free Helpline: 1800-180-1551',
                      style: TextStyle(fontSize: 14),
                    ),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.info_outline,
                      color: AppColors.primaryGreen,
                    ),
                    title: const Text(
                      'About KRISHI MITRA',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      'Version 2.0.0 (Production Build)',
                      style: TextStyle(fontSize: 14),
                    ),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
