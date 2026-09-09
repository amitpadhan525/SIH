import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:artisan_mobile/core/constants/api_constants.dart';
import 'package:artisan_mobile/core/theme/app_theme.dart';
import 'package:artisan_mobile/core/utils/currency_formatter.dart';
import 'package:artisan_mobile/models/product.dart';
import 'package:artisan_mobile/screens/image_studio/image_studio_screen.dart';
import 'package:artisan_mobile/services/product_service.dart';
import 'package:artisan_mobile/widgets/artisan_button.dart';
import 'package:artisan_mobile/widgets/error_view.dart';
import 'package:artisan_mobile/widgets/loading_view.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  final ProductService? productService;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.productService,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final ProductService _productService;
  Product? _product;
  List<Map<String, dynamic>> _images = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isEditing = false;
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _materialController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  String _selectedCategory = 'Handicraft';
  String _selectedStatus = 'draft';

  final List<String> _categories = [
    'Handicraft',
    'Textiles',
    'Pottery',
    'Woodwork',
    'Jewelry',
    'Paintings',
    'Sculpture',
    'Leather',
    'Metalwork',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _productService = widget.productService ?? ProductService();
    _nameController = TextEditingController();
    _materialController = TextEditingController();
    _priceController = TextEditingController();
    _descriptionController = TextEditingController();
    _fetchProduct();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _materialController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchProduct() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final product = await _productService.getProduct(widget.productId);
      final images = await _productService.getProductImages(widget.productId);
      if (mounted) {
        setState(() {
          _product = product;
          _images = images;
          _populateControllers(product);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _openImageStudio() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => ImageStudioScreen(
          productId: widget.productId,
          productName: _product?.name,
          productService: _productService,
        ),
      ),
    );

    if (result != null && mounted) {
      _fetchProduct();
    }
  }

  Future<void> _deleteImage(int imageId) async {
    try {
      await _productService.deleteProductImage(widget.productId, imageId);
      if (mounted) {
        _fetchProduct();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Studio photo removed.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete photo: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _populateControllers(Product product) {
    _nameController.text = product.name;
    _materialController.text = product.material ?? '';
    _priceController.text = product.price ?? '';
    _descriptionController.text = product.description ?? '';
    if (_categories.contains(product.category)) {
      _selectedCategory = product.category;
    } else {
      _selectedCategory = 'Other';
    }
    _selectedStatus = product.status;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? cleanPrice;
      if (_priceController.text.trim().isNotEmpty) {
        final parsed = double.tryParse(_priceController.text.trim());
        if (parsed != null) {
          cleanPrice = parsed.toStringAsFixed(2);
        }
      }

      final updatedProduct = _product!.copyWith(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        material: _materialController.text.trim().isNotEmpty
            ? _materialController.text.trim()
            : null,
        price: cleanPrice,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        status: _selectedStatus,
      );

      final saved = await _productService.updateProduct(
        widget.productId,
        updatedProduct,
      );

      if (mounted) {
        setState(() {
          _product = saved;
          _populateControllers(saved);
          _isEditing = false;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product updated successfully! ✨'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text(
          'Are you sure you want to delete "${_product?.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(100, 44),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      _executeDelete();
    }
  }

  Future<void> _executeDelete() async {
    setState(() => _isDeleting = true);

    try {
      await _productService.deleteProduct(widget.productId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted.'),
            backgroundColor: AppColors.textPrimary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isDeleting = false);
      }
    }
  }

  void _showExportDialog(String type) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      Map<String, dynamic> data;
      String title;
      String subtitle;

      if (type == 'ondc') {
        title = 'ONDC Protocol JSON Export';
        subtitle = 'Standard Beckn/ONDC retail item schema';
        data = await _productService.getOndcExport(widget.productId);
      } else {
        title = 'GeM Bulk Procurement Catalog';
        subtitle = 'Government e-Marketplace procurement spec';
        data = await _productService.getGemExport(widget.productId);
      }

      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog

        final formattedJson = const JsonEncoder.withIndent('  ').convert(data);

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.code_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  Container(
                    height: 240,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        formattedJson,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Color(0xFF38BDF8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy JSON'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: formattedJson));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied payload to clipboard! 📋'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export catalog: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: const LoadingView(message: 'Loading product details...'),
      );
    }

    if (_errorMessage != null || _product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: ErrorView(
          message: _errorMessage ?? 'Product not found',
          onRetry: _fetchProduct,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Product Details'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Product',
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _isEditing ? _buildEditForm() : _buildDetailView(),
      ),
    );
  }

  Widget _buildDetailView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image / Illustration / Studio Gallery Banner
        if (_images.isNotEmpty)
          _buildImageGallery()
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.camera_enhance_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 10),
                const Text(
                  'No studio photo attached yet',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Enhance lighting & remove clutter with AI Studio',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: _openImageStudio,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Open Photo Studio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(180, 42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),

        // Title and Status
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _product!.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            _buildStatusBadge(_product!.status),
          ],
        ),
        const SizedBox(height: 12),

        // Price
        Text(
          CurrencyFormatter.format(_product!.price),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 24),

        // Details Cards
        _buildInfoTile('Category', _product!.category, Icons.category_outlined),
        if (_product!.material != null && _product!.material!.isNotEmpty)
          _buildInfoTile(
              'Material', _product!.material!, Icons.texture_outlined),
        if (_product!.description != null && _product!.description!.isNotEmpty)
          _buildInfoTile('Description', _product!.description!,
              Icons.description_outlined),
        const SizedBox(height: 20),

        // Marketplace Protocols Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.hub_outlined, color: Color(0xFF16A34A), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Marketplace & Govt Protocols',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Export real-time standard schemas for ONDC and GeM Public Procurement.',
                style: TextStyle(fontSize: 12, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                      label: const Text('ONDC JSON', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF15803D),
                        side: const BorderSide(color: Color(0xFF16A34A)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _showExportDialog('ondc'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.account_balance_outlined, size: 16),
                      label: const Text('GeM Govt', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF15803D),
                        side: const BorderSide(color: Color(0xFF16A34A)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _showExportDialog('gem'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Edit and Delete Actions
        ArtisanButton(
          label: 'Edit Product Info',
          icon: Icons.edit_outlined,
          onPressed: () => setState(() => _isEditing = true),
        ),
        const SizedBox(height: 12),

        ArtisanButton(
          label: 'Delete Product',
          icon: Icons.delete_outline_rounded,
          isOutlined: true,
          color: AppColors.error,
          isLoading: _isDeleting,
          onPressed: _confirmDelete,
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Name *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            validator: (val) => val == null || val.trim().isEmpty
                ? 'Name cannot be empty'
                : null,
          ),
          const SizedBox(height: 16),

          const Text(
            'Category *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            items: _categories
                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedCategory = val);
            },
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Price (₹)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(prefixText: '₹ '),
                      validator: (val) {
                        if (val != null && val.trim().isNotEmpty) {
                          final p = double.tryParse(val.trim());
                          if (p == null) return 'Invalid number';
                          if (p < 0) return 'Must be positive';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Material',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _materialController,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            'Description',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          const Text(
            'Status',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            items: const [
              DropdownMenuItem(value: 'draft', child: Text('Draft')),
              DropdownMenuItem(value: 'published', child: Text('Published')),
              DropdownMenuItem(value: 'archived', child: Text('Archived')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedStatus = val);
            },
          ),
          const SizedBox(height: 28),

          ArtisanButton(
            label: 'Save Changes',
            icon: Icons.check,
            isLoading: _isSaving,
            onPressed: _saveChanges,
          ),
          const SizedBox(height: 12),

          ArtisanButton(
            label: 'Cancel',
            isOutlined: true,
            onPressed: () {
              setState(() {
                _isEditing = false;
                _populateControllers(_product!);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    switch (status.toLowerCase()) {
      case 'published':
        bg = AppColors.statusPublishedBg;
        text = AppColors.statusPublishedText;
        break;
      case 'archived':
        bg = AppColors.statusArchivedBg;
        text = AppColors.statusArchivedText;
        break;
      case 'draft':
      default:
        bg = AppColors.statusDraftBg;
        text = AppColors.statusDraftText;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _images.length + 1,
            itemBuilder: (context, index) {
              if (index == _images.length) {
                // Add photo action card
                return Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: InkWell(
                    onTap: _openImageStudio,
                    borderRadius: BorderRadius.circular(16),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 32),
                        SizedBox(height: 8),
                        Text(
                          'Add Photo',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final img = _images[index];
              final imgId = img['id'] as int? ?? 0;
              final procUrl = ApiConstants.resolveImageUrl(img['processed_url'] as String?);
              final origUrl = ApiConstants.resolveImageUrl(img['original_url'] as String?);
              final displayUrl = procUrl.isNotEmpty ? procUrl : origUrl;

              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      displayUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFF0F4F8),
                        child: const Center(
                          child: Icon(Icons.broken_image, color: AppColors.textMuted),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _deleteImage(imgId),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                    if (procUrl.isNotEmpty)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'STUDIO AI',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
