class ApiConstant {
  // Primary remote server URL
  static const String remoteBaseUrl = "https://diksha-ghimire-aparna.onrender.com/";
  // static const String remoteBaseUrl = "http://192.168.43.54:3000/";
  
  // Local fallback URL for IPv4
  static const String localBaseUrl = "http://192.168.43.54:3000/";
  
  // Default request timeout before fallback (10 seconds)
  static const Duration requestTimeout = Duration(seconds: 10);

  // Keep false when you want all requests to stay on Render.
  static const bool enableLocalFallback = false;
  
  // Use remote URL for web, local for mobile (with fallback support)
  static const String baseUrl = remoteBaseUrl;
}
