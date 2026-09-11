import 'package:flutter/material.dart';
import 'package:artisan_mobile/core/constants/api_constants.dart';
import 'package:artisan_mobile/core/theme/app_theme.dart';
import 'package:artisan_mobile/core/utils/currency_formatter.dart';
import 'package:artisan_mobile/models/inquiry.dart';
import 'package:artisan_mobile/services/auth_service.dart';
import 'package:artisan_mobile/services/product_service.dart';

class InquiriesScreen extends StatefulWidget {
  final ProductService? productService;
  final AuthService? authService;

  const InquiriesScreen({
    super.key,
    this.productService,
    this.authService,
  });

  @override
  State<InquiriesScreen> createState() => _InquiriesScreenState();
}

class _InquiriesScreenState extends State<InquiriesScreen> {
  late final ProductService _productService;
  late final AuthService _authService;
  List<Inquiry> _inquiries = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _productService = widget.productService ?? ProductService();
    _authService = widget.authService ?? AuthService();
    _fetchInquiries();
  }

  Future<void> _fetchInquiries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final artisanId = _authService.currentArtisanId ?? ApiConstants.defaultArtisanId;
      final rawList = await _productService.getArtisanInquiries(
        artisanId,
        status: _selectedFilter == 'all' ? null : _selectedFilter,
      );
      setState(() {
        _inquiries = rawList.map((j) => Inquiry.fromJson(j)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load messages. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(Inquiry inquiry, String newStatus) async {
    try {
      await _productService.updateInquiryStatus(inquiry.id, newStatus);
      setState(() {
        final index = _inquiries.indexWhere((i) => i.id == inquiry.id);
        if (index != -1) {
          _inquiries[index] = inquiry.copyWith(status: newStatus);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lead status updated to ${newStatus.toUpperCase()}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update status. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _simulateCall(String phone, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.phone_in_talk, color: Colors.white),
            const SizedBox(width: 8),
            Text('Calling $name ($phone)...'),
          ],
        ),
        backgroundColor: AppColors.primaryDark,
      ),
    );
  }

  void _simulateWhatsApp(String phone, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.chat_bubble_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text('Opening WhatsApp chat with $name...'),
          ],
        ),
        backgroundColor: const Color(0xFF25D366),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyer Leads & Inquiries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchInquiries,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Contacted', 'contacted'),
                const SizedBox(width: 8),
                _buildFilterChip('Accepted', 'accepted'),
                const SizedBox(width: 8),
                _buildFilterChip('Declined', 'declined'),
              ],
            ),
          ),
          const Divider(height: 1),

          // Inquiries Feed
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                              const SizedBox(height: 12),
                              Text(_errorMessage!, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchInquiries,
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _inquiries.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No buyer inquiries yet',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'When buyers on ONDC, GeM, or online marketplaces request bulk orders, they will appear here.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchInquiries,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _inquiries.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                return _buildInquiryCard(_inquiries[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      selectedColor: AppColors.primaryLight,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
          _fetchInquiries();
        }
      },
    );
  }

  Widget _buildInquiryCard(Inquiry inq) {
    final statusColor = _getStatusColor(inq.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Buyer & Status Badge
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    inq.buyerName.isNotEmpty ? inq.buyerName[0].toUpperCase() : 'B',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inq.buyerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        '${inq.buyerType.toUpperCase().replaceAll('_', ' ')} • ${inq.buyerPhone}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    inq.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Product Requested
            Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    inq.productName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Quantity & Target Price Row
            Row(
              children: [
                Text(
                  'Quantity: ${inq.quantity} units',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 16),
                if (inq.targetPrice != null)
                  Text(
                    'Target Price: ${CurrencyFormatter.format(inq.targetPrice)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
              ],
            ),

            if (inq.message != null && inq.message!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  '"${inq.message}"',
                  style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey.shade800),
                ),
              ),
            ],
            const SizedBox(height: 14),

            // Quick Call & WhatsApp Action Bar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _simulateCall(inq.buyerPhone, inq.buyerName),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2E7D32),
                      side: const BorderSide(color: Color(0xFF2E7D32)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.chat_rounded, size: 16),
                    label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _simulateWhatsApp(inq.buyerPhone, inq.buyerName),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Status Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (inq.status == 'pending') ...[
                  OutlinedButton.icon(
                    onPressed: () => _updateStatus(inq, 'declined'),
                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                    label: const Text('Decline', style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _updateStatus(inq, 'contacted'),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Mark Contacted', style: TextStyle(fontSize: 12)),
                  ),
                ] else if (inq.status == 'contacted') ...[
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(inq, 'accepted'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                    icon: const Icon(Icons.verified, size: 16),
                    label: const Text('Accept Deal', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade800;
      case 'contacted':
        return Colors.blue.shade800;
      case 'accepted':
        return Colors.green.shade800;
      case 'declined':
        return Colors.red.shade800;
      default:
        return Colors.grey.shade700;
    }
  }
}

