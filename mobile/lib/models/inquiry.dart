class Inquiry {
  final int id;
  final int productId;
  final String productName;
  final String? productPrice;
  final String? productImage;
  final String buyerName;
  final String buyerEmail;
  final String buyerPhone;
  final String buyerType;
  final int quantity;
  final String? targetPrice;
  final String? message;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Inquiry({
    required this.id,
    required this.productId,
    required this.productName,
    this.productPrice,
    this.productImage,
    required this.buyerName,
    required this.buyerEmail,
    required this.buyerPhone,
    required this.buyerType,
    required this.quantity,
    this.targetPrice,
    this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Inquiry.fromJson(Map<String, dynamic> json) {
    return Inquiry(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      productName: json['product_name'] as String? ?? 'Product #${json['product_id']}',
      productPrice: json['product_price']?.toString(),
      productImage: json['product_image_url'] as String?,
      buyerName: json['buyer_name'] as String? ?? 'Anonymous Buyer',
      buyerEmail: json['buyer_email'] as String? ?? '',
      buyerPhone: json['buyer_phone'] as String? ?? '',
      buyerType: json['buyer_type'] as String? ?? 'wholesale_b2b',
      quantity: json['quantity'] as int? ?? 1,
      targetPrice: json['target_price']?.toString(),
      message: json['message'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Inquiry copyWith({
    String? status,
  }) {
    return Inquiry(
      id: id,
      productId: productId,
      productName: productName,
      productPrice: productPrice,
      productImage: productImage,
      buyerName: buyerName,
      buyerEmail: buyerEmail,
      buyerPhone: buyerPhone,
      buyerType: buyerType,
      quantity: quantity,
      targetPrice: targetPrice,
      message: message,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
