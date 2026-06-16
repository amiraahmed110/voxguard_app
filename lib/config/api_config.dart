/// Centralized API endpoints for the VoxGuard backend.
///
/// Network calls should reference these constants instead of hard-coding the
/// host, so the address only ever has to change in one place. Other screens
/// still inline the URL today and can be migrated here over time.
class ApiConfig {
  const ApiConfig._();

  /// Base address of the main REST API.
  static const String baseUrl = 'http://192.168.1.191:8000/api';

  /// SOS / emergency endpoints, e.g. `$sosBaseUrl/start`.
  static const String sosBaseUrl = '$baseUrl/sos';
}
