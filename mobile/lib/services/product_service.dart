import 'package:artisan_mobile/core/constants/api_constants.dart';
import 'package:artisan_mobile/core/network/api_client.dart';
import 'package:artisan_mobile/models/product.dart';

class ProductService {
  final ApiClient _apiClient;

  ApiClient get apiClient => _apiClient;

  ProductService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Fetches paginated and optionally filtered products list from FastAPI backend
  Future<List<Product>> getProducts({
    int page = 1,
    int pageSize = 20,
    String? category,
    String? status,
    int? artisanId,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };

    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (artisanId != null) {
      queryParams['artisan_id'] = artisanId;
    }

    final response = await _apiClient.get(
      ApiConstants.products,
      queryParams: queryParams,
    );

    if (response is List) {
      return response
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Fetches a single product by primary key ID
  Future<Product> getProduct(int id) async {
    final response = await _apiClient.get(ApiConstants.productById(id));
    return Product.fromJson(response as Map<String, dynamic>);
  }

  /// Creates a new product on the backend
  Future<Product> createProduct(Product product) async {
    final response = await _apiClient.post(
      ApiConstants.products,
      body: product.toCreateJson(),
    );
    return Product.fromJson(response as Map<String, dynamic>);
  }

  /// Updates existing product fields (ownership is immutable)
  Future<Product> updateProduct(int id, Product product) async {
    final response = await _apiClient.put(
      ApiConstants.productById(id),
      body: product.toUpdateJson(),
    );
    return Product.fromJson(response as Map<String, dynamic>);
  }

  /// Deletes a product by ID
  Future<void> deleteProduct(int id) async {
    await _apiClient.delete(ApiConstants.productById(id));
  }

  /// Uploads and studio-enhances a product image
  Future<Map<String, dynamic>> uploadProductImage(
    int productId,
    List<int> fileBytes,
    String filename, {
    String backgroundMode = 'white',
  }) async {
    final response = await _apiClient.postMultipart(
      ApiConstants.productImages(productId),
      fileBytes: fileBytes,
      filename: filename,
      queryParams: {'background_mode': backgroundMode},
    );
    return response as Map<String, dynamic>;
  }

  /// Fetches all images attached to a product
  Future<List<Map<String, dynamic>>> getProductImages(int productId) async {
    final response = await _apiClient.get(ApiConstants.productImages(productId));
    if (response is List) {
      return response.map((item) => item as Map<String, dynamic>).toList();
    }
    return [];
  }

  /// Deletes an image from a product
  Future<void> deleteProductImage(int productId, int imageId) async {
    await _apiClient.delete(ApiConstants.productImageById(productId, imageId));
  }

  /// Performs instant AI studio enhancement preview without attaching to a product
  Future<Map<String, dynamic>> enhanceImagePreview(
    List<int> fileBytes,
    String filename, {
    String backgroundMode = 'white',
  }) async {
    final response = await _apiClient.postMultipart(
      ApiConstants.aiEnhanceImage,
      fileBytes: fileBytes,
      filename: filename,
      queryParams: {'background_mode': backgroundMode},
    );
    return response as Map<String, dynamic>;
  }

  /// Transcribes spoken artisan voice audio
  Future<Map<String, dynamic>> transcribeAudio(
    List<int> fileBytes,
    String filename,
  ) async {
    final response = await _apiClient.postMultipart(
      ApiConstants.aiTranscribe,
      fileBytes: fileBytes,
      filename: filename,
    );
    return response as Map<String, dynamic>;
  }

  /// Generates structured multilingual catalog and extracts verified facts from transcript
  Future<Map<String, dynamic>> generateCatalogContent(
    String transcript, {
    String sourceLanguage = 'auto',
    List<String> targetLanguages = const ['en', 'hi'],
    String? artisanNotes,
  }) async {
    final body = <String, dynamic>{
      'text': transcript,
      'source_language': sourceLanguage,
      'target_languages': targetLanguages,
    };
    if (artisanNotes != null && artisanNotes.isNotEmpty) {
      body['artisan_notes'] = artisanNotes;
    }

    final response = await _apiClient.post(
      ApiConstants.aiCatalogGenerate,
      body: body,
    );
    return response as Map<String, dynamic>;
  }

  /// High-level AI assistant for PS-90: extracts product details, stories, and recommended pricing in one call
  Future<Map<String, dynamic>> autoExtractAndPrice(
    String transcript, {
    String sourceLanguage = 'auto',
    List<String> targetLanguages = const ['en', 'hi', 'or'],
    String? artisanNotes,
  }) async {
    return await generateCatalogContent(
      transcript,
      sourceLanguage: sourceLanguage,
      targetLanguages: targetLanguages,
      artisanNotes: artisanNotes,
    );
  }

  /// Translates text across Indian languages preserving craft terminology
  Future<Map<String, dynamic>> translateText(
    String text, {
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.aiCatalogTranslate,
      body: {
        'text': text,
        'source_language': sourceLanguage,
        'target_language': targetLanguage,
      },
    );
    return response as Map<String, dynamic>;
  }

  /// Calculates dynamic 3-tier pricing recommendations and profit breakdown
  Future<Map<String, dynamic>> calculatePricing(Map<String, dynamic> request) async {
    final response = await _apiClient.post(
      ApiConstants.aiPricingCalculate,
      body: request,
    );
    return response as Map<String, dynamic>;
  }

  /// Fetches craft category benchmarks and living wage guidelines
  Future<Map<String, dynamic>> getPricingBenchmarks() async {
    final response = await _apiClient.get(ApiConstants.aiPricingBenchmarks);
    return response as Map<String, dynamic>;
  }

  /// Fetches B2B and retail inquiries received for artisan's products
  Future<List<Map<String, dynamic>>> getArtisanInquiries(int artisanId, {String? status}) async {
    final queryParams = <String, dynamic>{};
    if (status != null && status.isNotEmpty && status != 'all') {
      queryParams['status_filter'] = status;
    }

    final response = await _apiClient.get(
      ApiConstants.artisanInquiries(artisanId),
      queryParams: queryParams,
    );

    if (response is List) {
      return response.map((item) => item as Map<String, dynamic>).toList();
    }
    return [];
  }

  /// Updates inquiry status (e.g., 'contacted', 'accepted', 'declined')
  Future<Map<String, dynamic>> updateInquiryStatus(int inquiryId, String newStatus) async {
    final response = await _apiClient.put(
      ApiConstants.inquiryStatus(inquiryId),
      body: {'status': newStatus},
    );
    return response as Map<String, dynamic>;
  }

  /// Exports product into standard ONDC Protocol JSON item format
  Future<Map<String, dynamic>> getOndcExport(int productId) async {
    final response = await _apiClient.get(ApiConstants.marketplaceOndcExport(productId));
    return response as Map<String, dynamic>;
  }

  /// Exports product into Government e-Marketplace (GeM) bulk catalog format
  Future<Map<String, dynamic>> getGemExport(int productId) async {
    final response = await _apiClient.get(ApiConstants.marketplaceGemExport(productId));
    return response as Map<String, dynamic>;
  }

  /// Fetches public published products from the marketplace discovery feed with optional filters
  Future<List<Map<String, dynamic>>> getMarketplaceProducts({
    String? query,
    String? category,
    double? minPrice,
    double? maxPrice,
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (query != null && query.trim().isNotEmpty) {
      queryParams['query'] = query.trim();
    }
    if (category != null && category.trim().isNotEmpty && category != 'All') {
      queryParams['category'] = category.trim();
    }
    if (minPrice != null) {
      queryParams['min_price'] = minPrice;
    }
    if (maxPrice != null) {
      queryParams['max_price'] = maxPrice;
    }

    final response = await _apiClient.get(
      ApiConstants.marketplaceProducts,
      queryParams: queryParams,
    );

    if (response is List) {
      return response.map((item) => item as Map<String, dynamic>).toList();
    }
    return [];
  }

  /// Fetches single published product details with safe public artisan data
  Future<Map<String, dynamic>> getMarketplaceProduct(int productId) async {
    final response = await _apiClient.get(ApiConstants.marketplaceProductById(productId));
    return response as Map<String, dynamic>;
  }

  /// Submits a buyer B2B or retail inquiry for a published product
  Future<Map<String, dynamic>> submitProductInquiry(
    int productId,
    Map<String, dynamic> inquiryData,
  ) async {
    final response = await _apiClient.post(
      ApiConstants.productInquiries(productId),
      body: inquiryData,
    );
    return response as Map<String, dynamic>;
  }


  /// Flushes queued offline actions to the backend sync batch endpoint
  Future<Map<String, dynamic>> syncBatch(int artisanId, List<Map<String, dynamic>> actions) async {
    final response = await _apiClient.post(
      ApiConstants.syncBatch,
      body: {
        'artisan_id': artisanId,
        'actions': actions,
      },
    );
    return response as Map<String, dynamic>;
  }

  /// Fetches delta updates from server since given timestamp
  Future<Map<String, dynamic>> getSyncDelta(int artisanId, {DateTime? since}) async {
    final queryParams = <String, dynamic>{'artisan_id': artisanId};
    if (since != null) {
      queryParams['since'] = since.toIso8601String();
    }
    final response = await _apiClient.get(
      ApiConstants.syncDelta,
      queryParams: queryParams,
    );
    return response as Map<String, dynamic>;
  }

  /// Verifies connection to FastAPI backend and PostgreSQL, with auto-fallback to alternate reachable hosts
  Future<bool> checkDatabaseHealth() async {
    const checkTimeout = Duration(milliseconds: 1500);

    // 1. Try current configured URL first
    try {
      final response = await _apiClient.get(ApiConstants.healthDb, timeout: checkTimeout);
      if (response is Map && response['database'] == 'connected') {
        return true;
      }
    } catch (_) {}

    // 2. Try candidate fallback host addresses
    final candidateHosts = [
      'http://127.0.0.1:8000',
      'http://localhost:8000',
      'http://10.221.235.31:8000',
      'http://10.133.121.165:8000',
      'http://10.0.2.2:8000',
    ];

    for (final host in candidateHosts) {
      if (host == ApiConstants.customBaseUrl) continue;
      try {
        final testUrl = '$host/health/db';
        final response = await _apiClient.get(testUrl, timeout: checkTimeout);
        if (response is Map && response['database'] == 'connected') {
          ApiConstants.customBaseUrl = host;
          return true;
        }
      } catch (_) {}
    }

    return false;
  }
}
