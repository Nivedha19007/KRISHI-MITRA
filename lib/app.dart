import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/localization/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/krishi_background.dart';
import 'features/auth/login_screen.dart';
import 'features/onboarding/welcome_screen.dart';
import 'features/traceability/public_product_timeline_screen.dart';
import 'l10n/app_localizations.dart';

/// Helper to sanitize and extract Batch ID from route paths or URLs safely
String extractBatchIdFromPath(String raw) {
  if (raw.isEmpty) return '';
  String s = Uri.decodeComponent(raw).trim();
  if (s.endsWith('/')) {
    s = s.substring(0, s.length - 1);
  }
  if (s.contains('/trace/')) {
    s = s.split('/trace/').last;
  } else if (s.contains('/timeline/')) {
    s = s.split('/timeline/').last;
  }
  s = s.split('?').first.split('#').first.split('/').first.trim();
  if (s == 'trace' || s == 'timeline') return '';
  return s;
}

/// Helper to detect if the active browser URL on Web is a QR Trace URL
String getWebTraceBatchId() {
  if (!kIsWeb) return '';
  try {
    final fullUrl = Uri.base.toString();
    final path = Uri.base.path;
    final fragment = Uri.base.fragment;

    for (final source in [fullUrl, path, fragment]) {
      if (source.contains('/trace/') || source.contains('/timeline/')) {
        final id = extractBatchIdFromPath(source);
        if (id.isNotEmpty) return id;
      }
    }

    if (Uri.base.queryParameters.containsKey('batchId')) {
      final q = Uri.base.queryParameters['batchId']?.trim() ?? '';
      if (q.isNotEmpty) return extractBatchIdFromPath(q);
    }
  } catch (e) {
    debugPrint('[TRACE_ROUTE_PARSE_ERROR] $e');
  }
  return '';
}

class KrishiMitraApp extends ConsumerWidget {
  const KrishiMitraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final webBatchId = getWebTraceBatchId();
    final isWebTrace = webBatchId.isNotEmpty;

    return MaterialApp(
      title: isWebTrace ? 'KRISHI MITRA | Crop Traceability' : 'KRISHI MITRA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) =>
          KrishiBackground(child: child ?? const SizedBox.shrink()),
      locale: currentLocale,
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('hi', ''), // Hindi
        Locale('ta', ''), // Tamil
        Locale('te', ''), // Telugu
        Locale('kn', ''), // Kannada
        Locale('ml', ''), // Malayalam
        Locale('mr', ''), // Marathi
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: isWebTrace ? '/trace/$webBatchId' : '/',
      onGenerateInitialRoutes: (initialRouteName) {
        final batchIdFromRoute = extractBatchIdFromPath(initialRouteName);
        final activeBatchId = isWebTrace ? webBatchId : batchIdFromRoute;

        if (activeBatchId.isNotEmpty) {
          return [
            MaterialPageRoute(
              builder: (_) => PublicProductTimelineScreen(batchId: activeBatchId),
              settings: RouteSettings(name: '/trace/$activeBatchId'),
            ),
          ];
        }

        return [
          MaterialPageRoute(
            builder: (_) => const WelcomeScreen(),
            settings: const RouteSettings(name: '/'),
          ),
        ];
      },
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
        final batchId = extractBatchIdFromPath(name);

        if (batchId.isNotEmpty &&
            (name.contains('/trace') || name.contains('/timeline'))) {
          return MaterialPageRoute(
            builder: (_) => PublicProductTimelineScreen(batchId: batchId),
            settings: settings,
          );
        }

        if (isWebTrace) {
          return MaterialPageRoute(
            builder: (_) => PublicProductTimelineScreen(batchId: webBatchId),
            settings: settings,
          );
        }

        if (name == '/login') {
          return MaterialPageRoute(
            builder: (_) => const LoginScreen(),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => const WelcomeScreen(),
          settings: settings,
        );
      },
    );
  }
}
