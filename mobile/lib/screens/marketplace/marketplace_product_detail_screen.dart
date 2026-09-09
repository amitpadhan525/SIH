import 'package:flutter/material.dart';
import 'package:artisan_mobile/core/constants/api_constants.dart';
import 'package:artisan_mobile/core/theme/app_theme.dart';
import 'package:artisan_mobile/models/marketplace_product.dart';
import 'package:artisan_mobile/services/product_service.dart';
import 'package:artisan_mobile/widgets/artisan_button.dart';

class MarketplaceProductDetailScreen extends StatefulWidget {
  final MarketplaceProduct product;
  final ProductService? productService;

  const MarketplaceProductDetailScreen({
    super.key,
    required this.product,
    this.productService,
  });

  @override
  State<MarketplaceProductDetailScreen> createState() => _MarketplaceProductDetailScreenState();
}

class _MarketplaceProductDetailScreenState extends State<MarketplaceProductDetailScreen> {
  late final ProductService _productService;
  int _selectedImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _productService = widget.productService ?? ProductService();
  }

  void _openInquiryBottomSheet() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final qtyController = TextEditingController(text: '10');
    final targetPriceController = TextEditingController();
    final messageController = TextEditingController();
    String selectedBuyerType = 'wholesale_b2b';
    bool isSubmitting = false;
    final rootContext = context;

    showModalBottomSheet(
      context: rootContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (builderCtx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(builderCtx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              '💼 Send Business Inquiry',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(modalCtx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Direct wholesale or retail inquiry for "${widget.product.name}"',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Buyer Name
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Your Name or Business *',
                          hintText: 'e.g. Priya Sharma (FabIndia Sourcing)',
                          prefixIcon: Icon(Icons.business_center_outlined, size: 20),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().length < 2) {
                            return 'Please enter your name or company name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Email
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address *',
                          hintText: 'name@company.com',
                          prefixIcon: Icon(Icons.email_outlined, size: 20),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || !val.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Phone
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone *',
                          hintText: '+91 98765 43210',
                          prefixIcon: Icon(Icons.phone_outlined, size: 20),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().length < 5) {
                            return 'Enter phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Buyer Type
                      DropdownButtonFormField<String>(
                        value: selectedBuyerType,
                        decoration: const InputDecoration(
                          labelText: 'Buyer Type',
                          prefixIcon: Icon(Icons.category_outlined, size: 20),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'wholesale_b2b',
                            child: Text('Wholesale B2B'),
                          ),
                          DropdownMenuItem(
                            value: 'export',
                            child: Text('Exporter'),
                          ),
                          DropdownMenuItem(
                            value: 'institutional',
                            child: Text('Corporate Gifting'),
                          ),
                          DropdownMenuItem(
                            value: 'retail',
                            child: Text('Individual Buyer'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedBuyerType = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Quantity
                      TextFormField(
                        controller: qtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity (Units) *',
                          prefixIcon: Icon(Icons.format_list_numbered, size: 20),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          final n = int.tryParse(val ?? '');
                          if (n == null || n < 1) {
                            return 'Min quantity is 1';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Target Price
                      TextFormField(
                        controller: targetPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Target Price per Unit (Optional)',
                          hintText: 'Listed: ₹${widget.product.price ?? '0.00'}',
                          prefixIcon: const Icon(Icons.currency_rupee, size: 20),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Message
                      TextFormField(
                        controller: messageController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Message for Artisan',
                          hintText: 'Describe your required delivery timeline, customized colors, or packaging preferences...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Submit Button
                      ArtisanButton(
                        label: isSubmitting ? 'Sending Inquiry...' : 'Submit Business Inquiry',
                        icon: Icons.send_rounded,
                        isLoading: isSubmitting,
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() => isSubmitting = true);

                                try {
                                  final payload = <String, dynamic>{
                                    'buyer_name': nameController.text.trim(),
                                    'buyer_email': emailController.text.trim(),
                                    'buyer_phone': phoneController.text.trim(),
                                    'buyer_type': selectedBuyerType,
                                    'quantity': int.tryParse(qtyController.text.trim()) ?? 1,
                                    'message': messageController.text.trim().isNotEmpty
                                        ? messageController.text.trim()
                                        : 'Inquiry submitted for ${widget.product.name}',
                                  };

                                  if (targetPriceController.text.trim().isNotEmpty) {
                                    final tp = double.tryParse(targetPriceController.text.trim());
                                    if (tp != null) payload['target_price'] = tp;
                                  }

                                  await _productService.submitProductInquiry(
                                    widget.product.id,
                                    payload,
                                  );

                                  if (!mounted) return;
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ Inquiry sent successfully! The artisan will review your request.'),
                                      backgroundColor: AppColors.success,
                                      duration: Duration(seconds: 4),
                                    ),
                                  );
                                } catch (e) {
                                  setModalState(() => isSubmitting = false);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to submit inquiry: $e'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final images = p.imageUrls;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          p.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Direct Price',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  Text(
                    '₹${p.price ?? '0.00'}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ArtisanButton(
                  label: 'Send Inquiry',
                  icon: Icons.send_rounded,
                  onPressed: _openInquiryBottomSheet,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel / Preview
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: images.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        ApiConstants.resolveImageUrl(images[_selectedImageIndex]),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.storefront_rounded,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
            ),
            if (images.length > 1) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, idx) {
                    final isSelected = idx == _selectedImageIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedImageIndex = idx),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.cardBorder,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.network(
                            ApiConstants.resolveImageUrl(images[idx]),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 20),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Category and Verified Badge
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    p.category,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, size: 14, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Verified Handmade',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Product Title
            Text(
              p.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Material & Location
            if (p.material != null && p.material!.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.texture_rounded, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Material: ${p.material}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Origin: ${p.displayLocation}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Description Card
            const Text(
              'About This Craft',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Text(
                p.description != null && p.description!.isNotEmpty
                    ? p.description!
                    : 'Authentic handcrafted piece made with traditional techniques preserved across generations.',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Safe Public Artisan Information Card
            const Text(
              'Artisan / Creator',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEADBCE)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.artisanName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${p.craftType ?? p.category} • ${p.displayLocation}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (p.artisanBio != null && p.artisanBio!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            p.artisanBio!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
