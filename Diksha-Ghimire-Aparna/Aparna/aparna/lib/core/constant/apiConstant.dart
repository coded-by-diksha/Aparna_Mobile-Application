import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstant {
  static String _requiredEnv(String key) {
    final raw = dotenv.env[key]?.trim();
    if (raw == null || raw.isEmpty) {
      throw StateError('Missing required .env value: $key');
    }
    return raw;
  }

  static String _requiredUrl(String key) {
    final raw = _requiredEnv(key);
    return raw.endsWith('/') ? raw : '$raw/';
  }

  // API base URLs
  static final String remoteBaseUrl = _requiredUrl('REMOTE_BASE_URL');
  static final String localBaseUrl = _requiredUrl('LOCAL_BASE_URL');

  // Third-party service URLs
  static final String osrmRoutingBaseUrl = _requiredUrl('OSRM_ROUTING_BASE_URL');
  static final String openStreetMapTileUrlTemplate = _requiredEnv('OSM_TILE_URL_TEMPLATE');
  static final String nominatimReverseBaseUrl = _requiredUrl('NOMINATIM_REVERSE_BASE_URL');
  static final String googleLogoUrl = _requiredEnv('GOOGLE_LOGO_URL');

  // Default request timeout before fallback (10 seconds)
  static const Duration requestTimeout = Duration(seconds: 10);

  // Keep false when you want all requests to stay on Render.
  static const bool enableLocalFallback = false;

  // Use remote URL for all requests (with optional local fallback support)
  static String get baseUrl => remoteBaseUrl;
}
