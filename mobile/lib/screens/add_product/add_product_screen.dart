import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:artisan_mobile/core/constants/api_constants.dart';
import 'package:artisan_mobile/core/theme/app_theme.dart';
import 'package:artisan_mobile/models/product.dart';
import 'package:artisan_mobile/screens/image_studio/image_studio_screen.dart';
import 'package:artisan_mobile/screens/pricing_calculator/pricing_calculator_screen.dart';
import 'package:artisan_mobile/screens/voice_catalog/voice_catalog_screen.dart';
import 'package:artisan_mobile/services/product_service.dart';
import 'package:artisan_mobile/widgets/artisan_button.dart';

class AddProductScreen extends StatefulWidget {
  final ProductService? productService;

  const AddProductScreen({super.key, this.productService});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ProductService _productService;

  final _nameController = TextEditingController();
  final _materialController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Handicraft';
  String _selectedStatus = 'draft';
  bool _isSubmitting = false;

  Map<String, dynamic>? _studioPhotoResult;

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _materialController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _openPhotoStudio({ImageSource? source}) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => ImageStudioScreen(
          productName: _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : 'New Craft',
          initialSource: source,
          productService: _productService,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _studioPhotoResult = result;
      });
    }
  }

  void _openVoiceCatalog() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => VoiceCatalogScreen(
          productService: _productService,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (result['name'] != null && result['name'].toString().isNotEmpty) {
          _nameController.text = result['name'].toString();
        }
        if (result['materials'] != null && result['materials'].toString().isNotEmpty) {
          _materialController.text = result['materials'].toString();
        }
        if (result['description'] != null && result['description'].toString().isNotEmpty) {
          _descriptionController.text = result['description'].toString();
        }
        if (result['category'] != null) {
          final cat = result['category'].toString();
          if (_categories.contains(cat)) {
            _selectedCategory = cat;
          } else if (cat.contains('Textile') || cat.contains('Saree')) {
            _selectedCategory = 'Textiles';
          } else if (cat.contains('Pottery') || cat.contains('Clay')) {
            _selectedCategory = 'Pottery';
          } else if (cat.contains('Metal') || cat.contains('Brass')) {
            _selectedCategory = 'Metalwork';
          } else if (cat.contains('Painting') || cat.contains('Art')) {
            _selectedCategory = 'Paintings';
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auto-filled product details from voice transcript! ✨'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _openPricingCalculator() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => PricingCalculatorScreen(
          category: _selectedCategory,
          productService: _productService,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _priceController.text = result;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fair price ₹$result applied! 💡'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Clean and format price string with decimal representation
      String? cleanPrice;
      if (_priceController.text.trim().isNotEmpty) {
        final parsed = double.tryParse(_priceController.text.trim());
        if (parsed != null) {
          cleanPrice = parsed.toStringAsFixed(2);
        }
      }

      final newProduct = Product(
        artisanId: ApiConstants.defaultArtisanId,
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

      final created = await _productService.createProduct(newProduct);

      // If user took a studio photo, attach it to the newly created product
      if (_studioPhotoResult != null && created.id != null) {
        final rawBytes = _studioPhotoResult!['raw_bytes'] as List<int>?;
        final filename = _studioPhotoResult!['filename'] as String? ?? 'product_photo.jpg';
        final bgMode = _studioPhotoResult!['background_mode'] as String? ?? 'white';
        if (rawBytes != null && rawBytes.isNotEmpty) {
          try {
            await _productService.uploadProductImage(
              created.id!,
              rawBytes,
              filename,
              backgroundMode: bgMode,
            );
          } catch (uploadErr) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Product created, but photo upload failed: $uploadErr'),
                  backgroundColor: Colors.orange.shade800,
                ),
              );
              Navigator.pop(context, true);
              return;
            }
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product created successfully! 🎉'),
            backgroundColor: AppColors.success,
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
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Studio Quick Trigger
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _studioPhotoResult != null ? AppColors.statusPublishedBg : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _studioPhotoResult != null ? AppColors.statusPublishedText : AppColors.primary.withOpacity(0.3),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _studioPhotoResult != null ? AppColors.statusPublishedText : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _studioPhotoResult != null ? Icons.check : Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _studioPhotoResult != null ? 'Studio Photo Attached ✨' : 'Product Photo Studio',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _studioPhotoResult != null
                                    ? '1024x1024 enhanced studio photo ready'
                                    : 'Auto background removal & lighting',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.camera_alt_outlined, size: 16),
                            label: const Text('Camera', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _openPhotoStudio(source: ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.photo_library_outlined, size: 16),
                            label: const Text('Gallery', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _openPhotoStudio(source: ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // AI Voice Auto-Cataloger Trigger
              InkWell(
                onTap: _openVoiceCatalog,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.amber.shade400,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade800,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mic_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Speak to Auto-Fill Details 🎙️',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Speak in Hindi, Odia, or English — AI extracts verified facts',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Product Name Field
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
                decoration: const InputDecoration(
                  hintText: 'e.g. Handmade Silk Scarf',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Category Selector
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
                decoration: const InputDecoration(),
                items: _categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCategory = val);
                  }
                },
              ),
              const SizedBox(height: 18),

              // Price and Material Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price Field
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Price (₹)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            InkWell(
                              onTap: _openPricingCalculator,
                              child: const Text(
                                '💡 AI Calculate',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            prefixText: '₹ ',
                          ),
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty) {
                              final parsed = double.tryParse(value.trim());
                              if (parsed == null) {
                                return 'Invalid number';
                              }
                              if (parsed < 0) {
                                return 'Must be positive';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Material Field
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
                          decoration: const InputDecoration(
                            hintText: 'e.g. Pure Cotton',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Description Field
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
                decoration: const InputDecoration(
                  hintText: 'Describe craft techniques, story, dimensions...',
                ),
              ),
              const SizedBox(height: 18),

              // Initial Status Selector
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
                decoration: const InputDecoration(),
                items: const [
                  DropdownMenuItem(value: 'draft', child: Text('Draft (Private)')),
                  DropdownMenuItem(value: 'published', child: Text('Published (Live)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedStatus = val);
                  }
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              ArtisanButton(
                label: 'Save Product',
                icon: Icons.check_circle_outline_rounded,
                isLoading: _isSubmitting,
                onPressed: _submitProduct,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
