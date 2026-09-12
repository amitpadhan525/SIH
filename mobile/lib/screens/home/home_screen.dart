import 'package:flutter/material.dart';
import 'package:artisan_mobile/core/constants/api_constants.dart';
import 'package:artisan_mobile/core/theme/app_theme.dart';
import 'package:artisan_mobile/models/product.dart';
import 'package:artisan_mobile/screens/add_product/add_product_screen.dart';
import 'package:artisan_mobile/screens/inquiries/inquiries_screen.dart';
import 'package:artisan_mobile/screens/marketplace/marketplace_screen.dart';
import 'package:artisan_mobile/screens/products/products_screen.dart';
import 'package:artisan_mobile/screens/profile/edit_profile_screen.dart';
import 'package:artisan_mobile/services/auth_service.dart';
import 'package:artisan_mobile/services/product_service.dart';
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
  int _inquiryCount = 0;
  bool _isLoading = true;
  int _currentNavIndex = 0;

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
      int inqCount = 0;
      if (isConnected) {
        final artisanId = _authService.currentArtisanId;
        products = await _productService.getProducts(artisanId: artisanId);
        try {
          final inqs = await _productService.getArtisanInquiries(artisanId ?? ApiConstants.defaultArtisanId);
          inqCount = inqs.length;
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _productCount = products.length;
          _inquiryCount = inqCount;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      _loadDashboardData();
    }
  }

  void _navigateToProducts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductsScreen(
          productService: _productService,
          authService: _authService,
        ),
      ),
    );
    _loadDashboardData();
  }

  void _navigateToInquiries() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InquiriesScreen(
          productService: _productService,
          authService: _authService,
        ),
      ),
    );
    _loadDashboardData();
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
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryLight,
                    border: Border.all(color: AppColors.primary, width: 2),
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
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEADBCE)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Craft', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text(
                        _authService.currentCraftCategory ?? 'Handicraft',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Location', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text(
                        (_authService.currentDistrict != null && _authService.currentState != null)
                            ? '${_authService.currentDistrict}, ${_authService.currentState}'
                            : (_authService.currentState ?? 'Not set (Tap Edit Profile)'),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
            const SizedBox(height: 12),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
              title: const Text('Edit Profile & Location', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              subtitle: const Text('Update location, craft, brand, and experience', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.primary),
              onTap: () async {
                Navigator.pop(ctx);
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(authService: _authService),
                  ),
                );
                if (updated == true && mounted) {
                  setState(() {});
                }
              },
            ),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.tune_rounded, color: AppColors.textSecondary),
              title: const Text('Server Settings (Advanced)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
              onTap: () {
                Navigator.pop(ctx);
                _showServerConfigDialog();
              },
            ),
            const Divider(),
            const SizedBox(height: 8),
            ArtisanButton(
              label: 'Log Out',
              icon: Icons.logout_rounded,
              isOutlined: true,
              onPressed: () {
                Navigator.pop(ctx);
                _authService.logout();
              },
            ),
            const SizedBox(height: 8),
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
              'Enter server base URL for local testing:',
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
                  label: const Text('USB (127.0.0.1)'),
                  onPressed: () => controller.text = 'http://127.0.0.1:8000',
                ),
                ActionChip(
                  label: const Text('Wi-Fi (10.133.121.165)'),
                  onPressed: () => controller.text = 'http://10.133.121.165:8000',
                ),
                ActionChip(
                  label: const Text('Emulator (10.0.2.2)'),
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
            child: const Text('Save'),
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
            icon: const Icon(Icons.account_circle_outlined, size: 28),
            tooltip: 'Artisan Profile',
            onPressed: _showProfileModal,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentNavIndex,
        onDestinationSelected: (index) {
          setState(() => _currentNavIndex = index);
          if (index == 1) {
            _navigateToProducts();
          } else if (index == 2) {
            _navigateToMarketplace();
          } else if (index == 3) {
            _navigateToInquiries();
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'My Products',
          ),
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Marketplace',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _inquiryCount > 0,
              label: Text('$_inquiryCount'),
              child: const Icon(Icons.chat_bubble_outline_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: _inquiryCount > 0,
              label: Text('$_inquiryCount'),
              child: const Icon(Icons.chat_bubble_rounded),
            ),
            label: 'Messages',
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
              // Friendly Artisan Greeting
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
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
                        const SizedBox(height: 4),
                        const Text(
                          'Show your crafts to buyers across India with AI.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ================================================
              // MAIN HERO ACTION CARD: ADD NEW PRODUCT
              // ================================================
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _navigateToAddProduct,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.mic_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Add New Product',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Take a photo and speak about your product.\nAI creates your description & fair price.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.92),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primaryDark,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _navigateToAddProduct,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle_outline_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Start (Add Product)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ================================================
              // QUICK STATS & DIRECTORY
              // ================================================
              Row(
                children: [
                  // My Products Card
                  Expanded(
                    child: InkWell(
                      onTap: _navigateToProducts,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder, width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(height: 12),
                            _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(
                                    '$_productCount Products',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                  ),
                            const SizedBox(height: 2),
                            const Text('View All Products', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Buyer Messages Card
                  Expanded(
                    child: InkWell(
                      onTap: _navigateToInquiries,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder, width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.chat_bubble_rounded, color: Colors.green.shade800, size: 24),
                            ),
                            const SizedBox(height: 12),
                            _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(
                                    '$_inquiryCount Messages',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                  ),
                            const SizedBox(height: 2),
                            const Text('Buyer Inquiries', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Marketplace Discovery Card
              InkWell(
                onTap: _navigateToMarketplace,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.storefront_rounded, color: Color(0xFF16A34A), size: 28),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Buyer Discovery Marketplace',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF15803D),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'See how buyers across India view and discover your crafts',
                              style: TextStyle(fontSize: 12, color: Color(0xFF374151)),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: Color(0xFF16A34A)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Simple Artisan Tip
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEADBCE)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💡', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Speak in your mother tongue (Odia, Hindi, or English). Tell the app about the materials, colors, and days taken to make your craft.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF5D4037),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

