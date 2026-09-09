class ProductImage {
  final int id;
  final int productId;
  final String originalUrl;
  final String? processedUrl;
  final DateTime? createdAt;

  const ProductImage({
    required this.id,
    required this.productId,
    required this.originalUrl,
    this.processedUrl,
    this.createdAt,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] as int? ?? 0,
      productId: json['product_id'] as int? ?? 0,
      originalUrl: json['original_url'] as String? ?? '',
      processedUrl: json['processed_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'original_url': originalUrl,
      'processed_url': processedUrl,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
