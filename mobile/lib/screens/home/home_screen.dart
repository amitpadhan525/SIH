import 'package:flutter/material.dart';
import 'package:artisan_mobile/core/constants/api_constants.dart';
import 'package:artisan_mobile/core/theme/app_theme.dart';
import 'package:artisan_mobile/models/product.dart';
import 'package:artisan_mobile/screens/add_product/add_product_screen.dart';
import 'package:artisan_mobile/screens/inquiries/inquiries_screen.dart';
import 'package:artisan_mobile/screens/marketplace/marketplace_screen.dart';
import 'package:artisan_mobile/screens/products/products_screen.dart';
import 'package:artisan_mobile/services/auth_service.dart';
import 'package:artisan_mobile/services/product_service.dart';
import 'package:artisan_mobile/services/sync_service.dart';
import 'package:artisan_mobile/widgets/artisan_button.dart';

class HomeScreen extends StatefulWidget {
  final ProductService? productService;
  final AuthService? authService;

  const HomeScreen({super.key, this.productService, this.authService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ProductService _productService;
  late final AuthService _authService;
  int _productCount = 0;
  bool _isLoading = true;
  bool _isDbConnected = false;

  @override
  void initState() {
    super.initState();
    _productService = widget.productService ?? ProductService();
    _authService = widget.authService ?? AuthService(apiClient: _productService.apiClient);
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final isConnected = await _productService.checkDatabaseHealth();
      List<Product> products = [];
      if (isConnected) {
        final artisanId = _authService.currentArtisanId;
        products = await _productService.getProducts(artisanId: artisanId);
      }

      if (mounted) {
        setState(() {
          _isDbConnected = isConnected;
          _productCount = products.length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isDbConnected = false;
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToAddProduct() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreen(productService: _productService),
      ),
    );

    if (result == true) {
      _loadDashboardData();
    }
  }

  void _navigateToProducts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductsScreen(productService: _productService),
      ),
    );
    _loadDashboardData();
  }

  void _navigateToInquiries() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InquiriesScreen(productService: _productService),
      ),
    );
  }

  void _navigateToMarketplace() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarketplaceScreen(productService: _productService),
      ),
    );
  }

  void _showProfileModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryLight,
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _authService.currentArtisanName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _authService.currentArtisanPhone,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Craft Category', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text(
                        _authService.currentCraftCategory ?? 'Handicraft',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Location', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text(
                        '${_authService.currentDistrict ?? ''}, ${_authService.currentState ?? 'India'}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Language', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text(
                        _authService.currentPreferredLanguage ?? 'Hindi',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            ArtisanButton(
              label: 'Logout from Artisan Studio',
              icon: Icons.logout_rounded,
              isOutlined: true,
              onPressed: () {
                Navigator.pop(ctx);
                _authService.logout();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showServerConfigDialog() {
    final controller = TextEditingController(text: ApiConstants.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backend Server Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your computer backend URL (or use defaults):',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Server Base URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('USB: 127.0.0.1:8000'),
                  onPressed: () => controller.text = 'http://127.0.0.1:8000',
                ),
                ActionChip(
                  label: const Text('Wi-Fi: 10.133.121.165:8000'),
                  onPressed: () => controller.text = 'http://10.133.121.165:8000',
                ),
                ActionChip(
                  label: const Text('Emulator: 10.0.2.2:8000'),
                  onPressed: () => controller.text = 'http://10.0.2.2:8000',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                ApiConstants.customBaseUrl = newUrl;
                Navigator.pop(ctx);
                _loadDashboardData();
              }
            },
            child: const Text('Save & Test'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artisan Studio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Artisan Profile / Account',
            onPressed: _showProfileModal,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Status',
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Greeting
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Namaste, ${_authService.currentArtisanName} 🙏',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Welcome to your digital handicraft catalog. Manage products and reach buyers effortlessly.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Connection status badge
                    InkWell(
                      onTap: () => _showServerConfigDialog(),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isDbConnected
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isDbConnected
                                    ? 'Connected (${ApiConstants.baseUrl})'
                                    : 'Offline / Tap to configure server',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _isDbConnected
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ),
                            const Icon(Icons.settings_outlined, size: 16, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    if (SyncService().hasPendingActions) ...[
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.sync_rounded, size: 16, color: AppColors.primary),
                        label: Text(
                          'Sync (${SyncService().pendingCount})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        onPressed: () async {
                          final artisanId = _authService.currentArtisanId ?? ApiConstants.defaultArtisanId;
                          final res = await SyncService().flushQueue(_productService, artisanId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res['message']?.toString() ?? 'Offline changes synced!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            _loadDashboardData();
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick Stats Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          size: 32,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'My Products',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.primary),
                                    ),
                                  )
                                : Text(
                                    '$_productCount Products',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              const Text(
                'Actions',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              ArtisanButton(
                label: 'Add New Product',
                icon: Icons.add_circle_outline_rounded,
                onPressed: _navigateToAddProduct,
              ),
              const SizedBox(height: 12),

              ArtisanButton(
                label: 'View All Products',
                icon: Icons.inventory_2_outlined,
                isOutlined: true,
                onPressed: _navigateToProducts,
              ),
              const SizedBox(height: 12),

              ArtisanButton(
                label: 'Buyer Leads & Inquiries',
                icon: Icons.mark_email_unread_outlined,
                isOutlined: true,
                onPressed: _navigateToInquiries,
              ),
              const SizedBox(height: 12),

              ArtisanButton(
                label: '🌐 Buyer Discovery Marketplace',
                icon: Icons.storefront_rounded,
                isOutlined: true,
                onPressed: _navigateToMarketplace,
              ),
              const SizedBox(height: 32),

              // Artisan Tip
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Color(0xFF1E88E5),
                      size: 22,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tip: You can create products as "Draft" and publish them when you are ready.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF37474F),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
