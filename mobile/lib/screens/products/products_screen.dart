import 'package:flutter/material.dart';
import 'package:artisan_mobile/core/theme/app_theme.dart';
import 'package:artisan_mobile/models/product.dart';
import 'package:artisan_mobile/screens/add_product/add_product_screen.dart';
import 'package:artisan_mobile/screens/product_detail/product_detail_screen.dart';
import 'package:artisan_mobile/services/auth_service.dart';
import 'package:artisan_mobile/services/product_service.dart';
import 'package:artisan_mobile/widgets/artisan_button.dart';
import 'package:artisan_mobile/widgets/error_view.dart';
import 'package:artisan_mobile/widgets/loading_view.dart';
import 'package:artisan_mobile/widgets/product_card.dart';

class ProductsScreen extends StatefulWidget {
  final ProductService? productService;
  final AuthService? authService;

  const ProductsScreen({super.key, this.productService, this.authService});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late final ProductService _productService;
  late final AuthService _authService;
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _productService = widget.productService ?? ProductService();
    _authService = widget.authService ?? AuthService(apiClient: _productService.apiClient);
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final statusParam =
          _selectedStatusFilter == 'all' ? null : _selectedStatusFilter;
      final products = await _productService.getProducts(
        status: statusParam,
        artisanId: _authService.currentArtisanId,
        pageSize: 50,
      );

      if (mounted) {
        setState(() {
          _products = products;
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

  void _onStatusFilterSelected(String status) {
    if (_selectedStatusFilter != status) {
      setState(() {
        _selectedStatusFilter = status;
      });
      _fetchProducts();
    }
  }

  void _navigateToAddProduct() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreen(
          productService: _productService,
          authService: _authService,
        ),
      ),
    );

    if (result == true) {
      _fetchProducts();
    }
  }

  void _navigateToProductDetail(Product product) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(
          productId: product.id!,
          productService: _productService,
        ),
      ),
    );

    if (result == true) {
      _fetchProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddProduct,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Draft', 'draft'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Published', 'published'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Archived', 'archived'),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),

          // Main Content
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onStatusFilterSelected(value),
      backgroundColor: Colors.white,
      selectedColor: AppColors.primaryLight,
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.cardBorder,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingView(message: 'Loading products...');
    }

    if (_errorMessage != null) {
      return ErrorView(
        message: _errorMessage!,
        onRetry: _fetchProducts,
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No products yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Start by adding your first handcrafted product to your catalog.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 220,
                child: ArtisanButton(
                  label: 'Add Your First Product',
                  icon: Icons.add,
                  onPressed: _navigateToAddProduct,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchProducts,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return ProductCard(
            product: product,
            onTap: () => _navigateToProductDetail(product),
          );
        },
      ),
    );
  }
}
