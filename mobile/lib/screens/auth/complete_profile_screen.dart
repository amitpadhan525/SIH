import 'package:flutter/material.dart';
import 'package:artisan_mobile/core/constants/location_data.dart';
import 'package:artisan_mobile/core/theme/app_theme.dart';
import 'package:artisan_mobile/services/auth_service.dart';
import 'package:artisan_mobile/widgets/artisan_button.dart';

class CompleteProfileScreen extends StatefulWidget {
  final AuthService? authService;

  const CompleteProfileScreen({super.key, this.authService});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  late final AuthService _authService;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  String? _selectedCategory = LocationData.craftCategories.first;
  String? _selectedLanguage = LocationData.preferredLanguages.first;

  // Existing user metadata preservation
  String? _existingState;
  String? _existingDistrict;
  String? _existingArtisanName;
  String? _existingArtisanType;
  int? _existingExperienceYears;
  String? _existingDescription;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();

    final user = _authService.currentUser;
    if (user != null) {
      final existingName = user['full_name']?.toString() ?? user['name']?.toString() ?? '';
      // Only prefill if not generic placeholder
      if (existingName.isNotEmpty && !existingName.startsWith('Artisan ')) {
        _nameController.text = existingName;
      }
      if (user['craft_category'] != null && LocationData.craftCategories.contains(user['craft_category'])) {
        _selectedCategory = user['craft_category'];
      }
      if (user['preferred_language'] != null && LocationData.preferredLanguages.contains(user['preferred_language'])) {
        _selectedLanguage = user['preferred_language'];
      }

      // Preserve existing optional / location data if already on account
      _existingState = user['state']?.toString();
      _existingDistrict = user['district']?.toString();
      _existingArtisanName = user['artisan_name']?.toString();
      _existingArtisanType = user['artisan_type']?.toString();
      if (user['experience_years'] != null) {
        _existingExperienceYears = int.tryParse(user['experience_years'].toString());
      }
      _existingDescription = user['description']?.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final fullName = _nameController.text.trim();
    if (fullName.isEmpty) {
      setState(() => _errorMessage = 'Please enter your name');
      return;
    }

    if (_selectedCategory == null) {
      setState(() => _errorMessage = 'Please select what you make');
      return;
    }

    if (_selectedLanguage == null) {
      setState(() => _errorMessage = 'Please select your preferred language');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final payload = <String, dynamic>{
        'full_name': fullName,
        'craft_category': _selectedCategory,
        'preferred_language': _selectedLanguage ?? 'Hindi',
      };

      // Preserve existing profile details if previously provided
      if (_existingState != null && _existingState!.isNotEmpty) {
        payload['state'] = _existingState;
      }
      if (_existingDistrict != null && _existingDistrict!.isNotEmpty) {
        payload['district'] = _existingDistrict;
      }
      if (_existingArtisanName != null && _existingArtisanName!.isNotEmpty) {
        payload['artisan_name'] = _existingArtisanName;
      }
      if (_existingArtisanType != null && _existingArtisanType!.isNotEmpty) {
        payload['artisan_type'] = _existingArtisanType;
      }
      if (_existingExperienceYears != null) {
        payload['experience_years'] = _existingExperienceYears;
      }
      if (_existingDescription != null && _existingDescription!.isNotEmpty) {
        payload['description'] = _existingDescription;
      }

      await _authService.updateProfile(payload);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome to your Artisan Studio! 🌾'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: const Text('Tell Us About You'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            tooltip: 'Log Out',
            onPressed: _isLoading ? null : () => _authService.logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step Progress Indicator
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text(
                              'Profile',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '•',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.palette_outlined, size: 16, color: AppColors.textSecondary),
                            SizedBox(width: 6),
                            Text(
                              'Studio',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Header Title & Subtitle
                    const Text(
                      'Tell Us About You',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Just a few details to personalize your Artisan Studio.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Error banner
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Card Container for Form Fields
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Full Name (Required)
                          const Text(
                            'Full Name *',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            enabled: !_isLoading,
                            textCapitalization: TextCapitalization.words,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              hintText: 'e.g. Sunita Devi',
                              prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter your name' : null,
                          ),
                          const SizedBox(height: 20),

                          // 2. What do you make? (Craft Category)
                          const Text(
                            'What do you make? *',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.category_outlined, color: AppColors.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            items: LocationData.craftCategories.map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Text(cat, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              );
                            }).toList(),
                            onChanged: _isLoading ? null : (val) => setState(() => _selectedCategory = val),
                            validator: (val) => val == null ? 'Please select what you make' : null,
                          ),
                          const SizedBox(height: 20),

                          // 3. Preferred Language (Required)
                          const Text(
                            'Preferred Language *',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedLanguage,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.translate_rounded, color: AppColors.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            items: LocationData.preferredLanguages.map((lang) {
                              return DropdownMenuItem(
                                value: lang,
                                child: Text(lang, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              );
                            }).toList(),
                            onChanged: _isLoading ? null : (val) => setState(() => _selectedLanguage = val),
                            validator: (val) => val == null ? 'Please select your preferred language' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Helper info text
                    Center(
                      child: Text(
                        'Optional details can be added later from your Profile.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary.withOpacity(0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Primary Button: Continue to Artisan Studio →
                    ArtisanButton(
                      label: 'Continue to Artisan Studio →',
                      isLoading: _isLoading,
                      onPressed: _handleSaveProfile,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
