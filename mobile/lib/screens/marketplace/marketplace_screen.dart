import 'package:flutter/material.dart';
import 'package:artisan_mobile/core/constants/api_constants.dart';
import 'package:artisan_mobile/core/theme/app_theme.dart';
import 'package:artisan_mobile/models/marketplace_product.dart';
import 'package:artisan_mobile/screens/marketplace/marketplace_product_detail_screen.dart';
import 'package:artisan_mobile/services/product_service.dart';

class MarketplaceScreen extends StatefulWidget {
  final ProductService? productService;

  const MarketplaceScreen({super.key, this.productService});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  late final ProductService _productService;
  final TextEditingController _searchController = TextEditingController();

  List<MarketplaceProduct> _products = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategory = 'All';
  double? _minPrice;
  double? _maxPrice;

  final List<String> _categories = [
    'All',
    'Handloom & Textiles',
    'Pottery & Ceramics',
    'Metal Craft',
    'Tribal Painting',
    'Bamboo & Woodcraft',
    'Traditional Jewelry',
  ];

  @override
  void initState() {
    super.initState();
    _productService = widget.productService ?? ProductService();
    _fetchMarketplaceProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMarketplaceProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final query = _searchController.text.trim();
      final cat = _selectedCategory == 'All' ? null : _selectedCategory;

      final rawList = await _productService.getMarketplaceProducts(
        query: query.isNotEmpty ? query : null,
        category: cat,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      );

      final parsed = rawList.map((m) => MarketplaceProduct.fromJson(m)).toList();

      if (mounted) {
        setState(() {
          _products = parsed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load marketplace products: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _openPriceFilterDialog() {
    final minController = TextEditingController(
      text: _minPrice != null ? _minPrice!.toStringAsFixed(0) : '',
    );
    final maxController = TextEditingController(
      text: _maxPrice != null ? _maxPrice!.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter by Price (₹)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minimum Price (₹)',
                prefixIcon: Icon(Icons.currency_rupee),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: maxController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Maximum Price (₹)',
                prefixIcon: Icon(Icons.currency_rupee),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _minPrice = null;
                _maxPrice = null;
              });
              Navigator.pop(ctx);
              _fetchMarketplaceProducts();
            },
            child: const Text('Reset'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _minPrice = double.tryParse(minController.text.trim());
                _maxPrice = double.tryParse(maxController.text.trim());
              });
              Navigator.pop(ctx);
              _fetchMarketplaceProducts();
            },
            child: const Text('Apply Filter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyer Discovery Marketplace'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              color: (_minPrice != null || _maxPrice != null)
                  ? AppColors.primary
                  : null,
            ),
            tooltip: 'Filter by Price',
            onPressed: _openPriceFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _fetchMarketplaceProducts,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMarketplaceProducts,
        color: AppColors.primary,
        child: Column(
          children: [
            // Search Input Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _fetchMarketplaceProducts(),
                decoration: InputDecoration(
                  hintText: 'Search products, crafts, or materials...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _fetchMarketplaceProducts();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF4F6F8),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Horizontal Category Selector
            Container(
              height: 48,
              color: Colors.white,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, idx) {
                  final cat = _categories[idx];
                  final isSelected = cat == _selectedCategory;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                    backgroundColor: const Color(0xFFF0F4F8),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = cat);
                        _fetchMarketplaceProducts();
                      }
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),

            // Active Price Filter Banner
            if (_minPrice != null || _maxPrice != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: AppColors.primaryLight,
                child: Row(
                  children: [
                    const Icon(Icons.filter_alt_outlined, size: 16, color: AppColors.primaryDark),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Price range: ₹${_minPrice?.toStringAsFixed(0) ?? '0'} – ₹${_maxPrice?.toStringAsFixed(0) ?? 'Any'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _minPrice = null;
                          _maxPrice = null;
                        });
                        _fetchMarketplaceProducts();
                      },
                      child: const Icon(Icons.close_rounded, size: 16, color: AppColors.primaryDark),
                    ),
                  ],
                ),
              ),
            ],

            // Products Grid / List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: _fetchMarketplaceProducts,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _products.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.storefront_outlined,
                                      size: 56,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'No crafts match your search.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Try different keywords or clear filters to see more artisan products.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.72,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                              ),
                              itemCount: _products.length,
                              itemBuilder: (ctx, idx) {
                                final p = _products[idx];
                                return _buildProductCard(p);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(MarketplaceProduct p) {
    final hasImage = p.imageUrls.isNotEmpty;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MarketplaceProductDetailScreen(
              product: p,
              productService: _productService,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image / Thumbnail
            Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.4),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: hasImage
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      child: Image.network(
                        ApiConstants.resolveImageUrl(p.imageUrls.first),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.image_outlined, size: 36, color: Colors.grey),
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.storefront_rounded, size: 40, color: AppColors.primary),
                    ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'By ${p.artisanName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '₹${p.price ?? '0.00'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Inquire',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
