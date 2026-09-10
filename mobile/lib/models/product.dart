class Product {
  final int? id;
  final int artisanId;
  final String name;
  final String category;
  final String? description;
  final String? material;
  // Monetary value stored as exact decimal string (e.g. "650.00") to avoid IEEE-754 floating-point inaccuracies
  final String? price;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> imageUrls;

  const Product({
    this.id,
    required this.artisanId,
    required this.name,
    required this.category,
    this.description,
    this.material,
    this.price,
    this.status = 'draft',
    this.createdAt,
    this.updatedAt,
    this.imageUrls = const [],
  });

  /// Factory constructor to safely parse backend ProductRead JSON payload
  factory Product.fromJson(Map<String, dynamic> json) {
    // Safely extract price representation without precision loss
    String? parsedPrice;
    if (json['price'] != null) {
      parsedPrice = json['price'].toString();
    }

    // Extract images if present
    final List<String> images = [];
    if (json['images'] is List) {
      for (final img in json['images']) {
        if (img is Map) {
          final url = img['original_url'] ?? img['processed_url'] ?? img['url'] ?? img['image_url'];
          if (url != null && url.toString().trim().isNotEmpty) {
            images.add(url.toString().trim());
          }
        } else if (img != null && img.toString().trim().isNotEmpty) {
          images.add(img.toString().trim());
        }
      }
    } else if (json['image_urls'] is List) {
      for (final img in json['image_urls']) {
        if (img != null && img.toString().trim().isNotEmpty) {
          images.add(img.toString().trim());
        }
      }
    } else if (json['image_url'] != null && json['image_url'].toString().trim().isNotEmpty) {
      images.add(json['image_url'].toString().trim());
    }

    return Product(
      id: json['id'] as int?,
      artisanId: json['artisan_id'] as int? ?? 1,
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String?,
      material: json['material'] as String?,
      price: parsedPrice,
      status: json['status'] as String? ?? 'draft',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      imageUrls: images,
    );
  }

  /// Serializes payload for POST /products (ProductCreate schema)
  Map<String, dynamic> toCreateJson() {
    return {
      'artisan_id': artisanId,
      'name': name.trim(),
      'category': category.trim(),
      'description': description?.trim().isEmpty == true ? null : description?.trim(),
      'material': material?.trim().isEmpty == true ? null : material?.trim(),
      'price': price != null && price!.trim().isNotEmpty ? price!.trim() : null,
      'status': status.trim().toLowerCase(),
    };
  }

  /// Serializes payload for PUT /products/{id} (ProductUpdate schema)
  /// Explicitly excludes immutable fields (id and artisan_id)
  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name.trim(),
      'category': category.trim(),
      'description': description?.trim().isEmpty == true ? null : description?.trim(),
      'material': material?.trim().isEmpty == true ? null : material?.trim(),
      'price': price != null && price!.trim().isNotEmpty ? price!.trim() : null,
      'status': status.trim().toLowerCase(),
    };
  }

  Product copyWith({
    int? id,
    int? artisanId,
    String? name,
    String? category,
    String? description,
    String? material,
    String? price,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? imageUrls,
  }) {
    return Product(
      id: id ?? this.id,
      artisanId: artisanId ?? this.artisanId,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      material: material ?? this.material,
      price: price ?? this.price,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }
}
