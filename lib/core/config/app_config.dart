import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class AppConfig {
  /// Custom base domain for public timeline QR links.
  static String _customBaseUrl = '';

  static int devPort = 53604;
  static int devBackendPort = 8080;

  /// Default production public HTTPS backend URL.
  static const String productionBackendUrl = 'https://krishi-mitra-d6pl.onrender.com';

  /// Custom override for backend base URL if set at runtime.
  static String _customBackendBaseUrl = '';

  /// Returns the base URL for the .NET backend API.
  /// Hierarchy:
  /// 1. Custom runtime override (_customBackendBaseUrl)
  /// 2. Build configuration parameter (--dart-define=BACKEND_BASE_URL=...)
  /// 3. Release / Production Mode (kReleaseMode): Public HTTPS backend URL
  /// 4. Local Development Mode (kDebugMode / Profile Mode): http://localhost:8080
  static String get backendBaseUrl {
    // 1. Custom runtime override
    if (_customBackendBaseUrl.trim().isNotEmpty) {
      return _customBackendBaseUrl.trim();
    }

    // 2. Build configuration parameter (--dart-define=BACKEND_BASE_URL=...)
    const envBackendUrl = String.fromEnvironment('BACKEND_BASE_URL');
    if (envBackendUrl.trim().isNotEmpty) {
      return envBackendUrl.trim();
    }

    // 3. Release / Production mode: Always use public HTTPS backend
    if (kReleaseMode) {
      return productionBackendUrl;
    }

    // 4. Default for debug mode on mobile/desktop/web: local server on port 8080
    return 'http://localhost:$devBackendPort';
  }

  static set customBackendBaseUrl(String url) {
    _customBackendBaseUrl = url;
  }

  /// Production Firebase Web App domain
  static const String defaultProductionUrl = 'https://krishi-mitra-38a5f.web.app';

  /// Returns the active domain URL.
  static String get baseUrl {
    if (_customBaseUrl.trim().isNotEmpty) {
      return _customBaseUrl.trim();
    }
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty &&
          origin != 'null' &&
          !origin.contains('localhost') &&
          !origin.contains('127.0.0.1')) {
        return origin;
      }
    }
    return defaultProductionUrl;
  }

  static set baseUrl(String url) {
    _customBaseUrl = url;
  }

  /// Generates a dynamic public product timeline URL for ANY given Batch ID.
  /// Example: https://krishi-mitra-38a5f.web.app/trace/CAR-COI-670979
  static String getTimelineUrl(String batchId) {
    final cleanId = sanitizeBatchId(batchId);
    return '$baseUrl/trace/$cleanId';
  }

  /// Sanitizes batch IDs by stripping URL paths, query parameters, or legacy prefix strings.
  static String sanitizeBatchId(String rawId) {
    String clean = rawId.trim();
    if (clean.contains('/trace/')) {
      clean = clean.split('/trace/').last.split('?').first.split('#').first;
    } else if (clean.contains('/timeline/')) {
      clean = clean.split('/timeline/').last.split('?').first.split('#').first;
    }
    clean = clean
        .replaceAll('KRISHI_MITRA_BATCH_', '')
        .replaceAll('KRISHIMITRA_BATCH:', '')
        .trim();
    return clean;
  }

  /// Launches the timeline URL directly in the user's web browser.
  static Future<void> launchTimelineUrl(String batchId) async {
    final urlString = getTimelineUrl(batchId);
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
