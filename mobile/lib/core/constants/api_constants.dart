class ApiConstants {
  static const String devBaseUrl = 'http://127.0.0.1:8000';
  static const String prodBaseUrl = String.fromEnvironment(
    'API_PROD_URL',
    defaultValue: 'https://api.artisanai.in',
  );

  static const String _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: bool.fromEnvironment('dart.vm.product') ? prodBaseUrl : devBaseUrl,
  );

  static String customBaseUrl = _defaultBaseUrl;

  static String get baseUrl => customBaseUrl;

  // Endpoints
  static String get products => '$baseUrl/products';
  static String productById(int id) => '$baseUrl/products/$id';
  static String productImages(int productId) => '$baseUrl/products/$productId/images';
  static String productImageById(int productId, int imageId) => '$baseUrl/products/$productId/images/$imageId';
  static String get aiEnhanceImage => '$baseUrl/ai/images/enhance';
  static String get aiTranscribe => '$baseUrl/ai/transcribe';
  static String get aiCatalogTranscribe => '$baseUrl/ai/catalog/transcribe';
  static String get aiCatalogGenerate => '$baseUrl/ai/catalog/generate';
  static String get aiCatalogTranslate => '$baseUrl/ai/catalog/translate';
  static String get aiPricingCalculate => '$baseUrl/ai/pricing/calculate';
  static String get aiPricingBenchmarks => '$baseUrl/ai/pricing/benchmarks';
  static String get authLogin => '$baseUrl/auth/login';
  static String get authRegister => '$baseUrl/auth/register';
  static String get authOtpSend => '$baseUrl/auth/otp/send';
  static String get authOtpVerify => '$baseUrl/auth/otp/verify';
  static String get authMe => '$baseUrl/auth/me';
  static String get authProfileUpdate => '$baseUrl/auth/me/profile';
  static String artisanInquiries(int artisanId) => '$baseUrl/artisans/$artisanId/inquiries';
  static String inquiryStatus(int inquiryId) => '$baseUrl/inquiries/$inquiryId/status';
  static String productInquiries(int productId) => '$baseUrl/products/$productId/inquiries';
  static String get marketplaceProducts => '$baseUrl/marketplace/products';
  static String marketplaceProductById(int productId) => '$baseUrl/marketplace/products/$productId';
  static String marketplaceOndcExport(int productId) => '$baseUrl/marketplace/export/ondc/$productId';
  static String marketplaceGemExport(int productId) => '$baseUrl/marketplace/export/gem/$productId';
  static String get syncBatch => '$baseUrl/sync/batch';
  static String get syncDelta => '$baseUrl/sync/delta';
  static String get healthDb => '$baseUrl/health/db';
  static String get healthRoot => '$baseUrl/';

  /// Resolves relative '/uploads/...' URLs against the configured API base URL
  static String resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$normalizedBase$normalizedPath';
  }

  // Default Demo Artisan ID for prototype stage
  static const int defaultArtisanId = 1;
}
