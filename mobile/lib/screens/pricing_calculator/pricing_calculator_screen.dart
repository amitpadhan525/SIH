import 'package:flutter/material.dart';
import 'package:artisan_mobile/core/theme/app_theme.dart';
import 'package:artisan_mobile/core/utils/currency_formatter.dart';
import 'package:artisan_mobile/services/product_service.dart';

class PricingCalculatorScreen extends StatefulWidget {
  final String category;
  final int? initialDays;
  final ProductService? productService;

  const PricingCalculatorScreen({
    super.key,
    this.category = 'Handicraft',
    this.initialDays,
    this.productService,
  });

  @override
  State<PricingCalculatorScreen> createState() => _PricingCalculatorScreenState();
}

class _PricingCalculatorScreenState extends State<PricingCalculatorScreen> {
  late final ProductService _productService;
  late final TextEditingController _materialCostController;
  late final TextEditingController _hoursController;
  late final TextEditingController _hourlyRateController;
  late final TextEditingController _packagingController;

  String _selectedComplexity = 'medium';
  String _selectedTierKey = 'recommended';
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _pricingResult;

  @override
  void initState() {
    super.initState();
    _productService = widget.productService ?? ProductService();
    final initialHours = widget.initialDays != null ? (widget.initialDays! * 6).toString() : '8';
    _materialCostController = TextEditingController(text: '350');
    _hoursController = TextEditingController(text: initialHours);
    _hourlyRateController = TextEditingController(text: '90');
    _packagingController = TextEditingController(text: '50');

    _calculateLivePricing();
  }

  @override
  void dispose() {
    _materialCostController.dispose();
    _hoursController.dispose();
    _hourlyRateController.dispose();
    _packagingController.dispose();
    super.dispose();
  }

  Future<void> _calculateLivePricing() async {
    final matCost = double.tryParse(_materialCostController.text.trim()) ?? 0.0;
    final hours = double.tryParse(_hoursController.text.trim()) ?? 0.0;
    final rate = double.tryParse(_hourlyRateController.text.trim()) ?? 90.0;
    final pkg = double.tryParse(_packagingController.text.trim()) ?? 50.0;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final request = {
        'category': widget.category,
        'cost_breakdown': {
          'material_cost': matCost,
          'labor_hours': hours,
          'hourly_rate': rate,
          'overhead_cost': 40.0,
          'packaging_and_shipping': pkg,
        },
        'craft_complexity': _selectedComplexity,
        'market_channel': 'direct_to_consumer',
      };

      final response = await _productService.calculatePricing(request);
      setState(() {
        _pricingResult = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to calculate price: $e';
        _isLoading = false;
      });
    }
  }

  void _applySelectedPrice() {
    if (_pricingResult == null) return;
    final tiers = _pricingResult!['tiers'] as Map<String, dynamic>?;
    final selectedTier = tiers?[_selectedTierKey] as Map<String, dynamic>?;
    final price = selectedTier?['price']?.toString() ?? _pricingResult!['suggested_price']?.toString() ?? '';

    Navigator.of(context).pop(price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic Pricing Assistant'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          if (_pricingResult != null)
            TextButton.icon(
              onPressed: _applySelectedPrice,
              icon: const Icon(Icons.check_circle, color: AppColors.primary),
              label: const Text(
                'Apply',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cost Input Form Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calculate_outlined, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Cost & Labor Calculator (${widget.category})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Material Cost Input
                    const Text('Raw Materials Cost (₹)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _materialCostController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        prefixText: '₹ ',
                        hintText: 'e.g. 350',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onChanged: (_) => _calculateLivePricing(),
                    ),
                    const SizedBox(height: 12),

                    // Labor Hours & Hourly Wage Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Work Hours Spent', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _hoursController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  suffixText: 'hrs',
                                  hintText: 'e.g. 8',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                onChanged: (_) => _calculateLivePricing(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Living Wage Rate', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _hourlyRateController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  prefixText: '₹ ',
                                  suffixText: '/hr',
                                  hintText: '90',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                onChanged: (_) => _calculateLivePricing(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick Hour Chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildQuickHourChip('2 hrs', '2'),
                        _buildQuickHourChip('4 hrs', '4'),
                        _buildQuickHourChip('1 day (6h)', '6'),
                        _buildQuickHourChip('3 days (18h)', '18'),
                        _buildQuickHourChip('7 days (42h)', '42'),
                        _buildQuickHourChip('14 days (84h)', '84'),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Craft Complexity
                    const Text('Craft Intricacy / Skill Level', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildComplexityChip('Simple', 'low'),
                        _buildComplexityChip('Standard (15% bonus)', 'medium'),
                        _buildComplexityChip('Intricate (30% bonus)', 'high'),
                        _buildComplexityChip('Masterpiece (50% bonus)', 'masterpiece'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade800, fontSize: 13)),
              ),
            ],

            if (_pricingResult != null) ...[
              const SizedBox(height: 20),

              // Benchmark banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.insights, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Market Benchmark Range: ${_pricingResult!['category_benchmark_range']}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Recommended Price Tiers',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),

              // 3-Tier Cards
              _buildTierCard('fair_base', Icons.shield_outlined, Colors.teal),
              const SizedBox(height: 10),
              _buildTierCard('recommended', Icons.star_rounded, AppColors.primary, isHighlighted: true),
              const SizedBox(height: 10),
              _buildTierCard('premium', Icons.workspace_premium_outlined, Colors.purple),

              const SizedBox(height: 16),

              // Explanation Card
              Card(
                elevation: 1,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cost & Earnings Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 6),
                      Text(
                        _pricingResult!['pricing_explanation'] ?? '',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Apply Selected Price Button
              ElevatedButton.icon(
                onPressed: _applySelectedPrice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text(
                  'Apply Selected Price to Product',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickHourChip(String label, String hoursVal) {
    final isSelected = _hoursController.text == hoursVal;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      selectedColor: AppColors.primaryLight,
      onSelected: (sel) {
        if (sel) {
          _hoursController.text = hoursVal;
          _calculateLivePricing();
        }
      },
    );
  }

  Widget _buildComplexityChip(String label, String val) {
    final isSelected = _selectedComplexity == val;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      selectedColor: AppColors.primaryLight,
      onSelected: (sel) {
        if (sel) {
          setState(() {
            _selectedComplexity = val;
          });
          _calculateLivePricing();
        }
      },
    );
  }

  Widget _buildTierCard(String tierKey, IconData icon, Color color, {bool isHighlighted = false}) {
    final tiers = _pricingResult!['tiers'] as Map<String, dynamic>? ?? {};
    final tier = tiers[tierKey] as Map<String, dynamic>?;
    if (tier == null) return const SizedBox.shrink();

    final isSelected = _selectedTierKey == tierKey;
    final price = tier['price']?.toString() ?? '0';
    final margin = tier['margin_percent']?.toString() ?? '0';
    final profit = tier['artisan_profit']?.toString() ?? '0';
    final rationale = tier['rationale']?.toString() ?? '';
    final name = tier['name']?.toString() ?? '';

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTierKey = tierKey;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isSelected ? color : AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  CurrencyFormatter.format(price),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+$margin% Margin',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Artisan Profit: ₹$profit',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              rationale,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}
