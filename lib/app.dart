import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/locale_provider.dart';
import 'features/auth/login_screen.dart';
import 'l10n/app_localizations.dart';

class KrishiMitraApp extends ConsumerWidget {
  const KrishiMitraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'KRISHI MITRA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: currentLocale,
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('hi', ''), // Hindi
        Locale('ta', ''), // Tamil
        Locale('te', ''), // Telugu
        Locale('kn', ''), // Kannada
        Locale('ml', ''), // Malayalam
        Locale('mr', ''), // Marathi
        Locale('gu', ''), // Gujarati
        Locale('pa', ''), // Punjabi
        Locale('bn', ''), // Bengali
        Locale('or', ''), // Odia
        Locale('as', ''), // Assamese
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const LoginScreen(),
    );
  }
}
