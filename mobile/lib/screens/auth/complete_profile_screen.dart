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
  final _businessNameController = TextEditingController();
  final _experienceController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategory = LocationData.craftCategories.first;
  String? _selectedState = LocationData.states.first;
  String? _selectedDistrict;
  String? _selectedLanguage = LocationData.preferredLanguages.first;
  String? _selectedArtisanType;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();

    final user = _authService.currentUser;
    if (user != null) {
      final existingName = user['full_name']?.toString() ?? '';
      // Only prefill if not generic "Artisan XXXX" placeholder
      if (existingName.isNotEmpty && !existingName.startsWith('Artisan ')) {
        _nameController.text = existingName;
      }
      if (user['craft_category'] != null && LocationData.craftCategories.contains(user['craft_category'])) {
        _selectedCategory = user['craft_category'];
      }
      if (user['state'] != null && LocationData.states.contains(user['state'])) {
        _selectedState = user['state'];
      }
      if (user['preferred_language'] != null && LocationData.preferredLanguages.contains(user['preferred_language'])) {
        _selectedLanguage = user['preferred_language'];
      }
      if (user['artisan_type'] != null && LocationData.artisanTypes.contains(user['artisan_type'])) {
        _selectedArtisanType = user['artisan_type'];
      }
      if (user['artisan_name'] != null) {
        _businessNameController.text = user['artisan_name'].toString();
      }
      if (user['experience_years'] != null) {
        _experienceController.text = user['experience_years'].toString();
      }
      if (user['description'] != null) {
        _descriptionController.text = user['description'].toString();
      }
    }

    final availableDistricts = LocationData.getDistrictsForState(_selectedState!);
    _selectedDistrict = availableDistricts.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessNameController.dispose();
    _experienceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onStateChanged(String? newState) {
    if (newState == null || newState == _selectedState) return;
    setState(() {
      _selectedState = newState;
      final districts = LocationData.getDistrictsForState(newState);
      _selectedDistrict = districts.first;
    });
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final fullName = _nameController.text.trim();
    if (fullName.isEmpty) {
      setState(() => _errorMessage = 'Please enter your full name');
      return;
    }

    if (_selectedCategory == null || _selectedState == null || _selectedDistrict == null) {
      setState(() => _errorMessage = 'Please select your craft, state, and district');
      return;
    }

    int? expYears;
    if (_experienceController.text.trim().isNotEmpty) {
      expYears = int.tryParse(_experienceController.text.trim());
      if (expYears == null || expYears < 0) {
        setState(() => _errorMessage = 'Years of experience must be a valid non-negative number');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final payload = {
        'full_name': fullName,
        'craft_category': _selectedCategory,
        'state': _selectedState,
        'district': _selectedDistrict,
        'preferred_language': _selectedLanguage ?? 'Hindi',
        'artisan_name': _businessNameController.text.trim().isNotEmpty ? _businessNameController.text.trim() : null,
        'artisan_type': _selectedArtisanType,
        'experience_years': expYears,
        'description': _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
      };

      await _authService.updateProfile(payload);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully! Welcome to your Studio 🌾'),
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
    final availableDistricts = LocationData.getDistrictsForState(_selectedState ?? LocationData.states.first);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log Out',
            onPressed: _isLoading ? null : () => _authService.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_pin_rounded, color: AppColors.primary, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Step 2: Tell Us About Your Craft',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Welcome! Enter your craft and location details to personalize your AI tools and marketplace catalog.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.brown.shade800,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Error banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 1. Full Name (Required)
              const Text(
                'Full Name *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  hintText: 'e.g. Sunita Devi or Ramesh Sahoo',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Full Name is required' : null,
              ),
              const SizedBox(height: 18),

              // 2. Craft Category (Required)
              const Text(
                'Craft Category *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items: LocationData.craftCategories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: _isLoading ? null : (val) => setState(() => _selectedCategory = val),
                validator: (val) => val == null ? 'Please select a craft category' : null,
              ),
              const SizedBox(height: 18),

              // 3. State & District (Required)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'State *',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedState,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          items: LocationData.states.map((st) {
                            return DropdownMenuItem(value: st, child: Text(st, overflow: TextOverflow.ellipsis));
                          }).toList(),
                          onChanged: _isLoading ? null : _onStateChanged,
                          validator: (val) => val == null ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'District *',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: availableDistricts.contains(_selectedDistrict) ? _selectedDistrict : availableDistricts.first,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          items: availableDistricts.map((dst) {
                            return DropdownMenuItem(value: dst, child: Text(dst, overflow: TextOverflow.ellipsis));
                          }).toList(),
                          onChanged: _isLoading ? null : (val) => setState(() => _selectedDistrict = val),
                          validator: (val) => val == null ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 4. Preferred Language (Required)
              const Text(
                'Preferred Language *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedLanguage,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.translate_rounded),
                  border: OutlineInputBorder(),
                ),
                items: LocationData.preferredLanguages.map((lang) {
                  return DropdownMenuItem(value: lang, child: Text(lang));
                }).toList(),
                onChanged: _isLoading ? null : (val) => setState(() => _selectedLanguage = val),
                validator: (val) => val == null ? 'Please select your preferred language' : null,
              ),
              const SizedBox(height: 24),

              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Optional Information',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // 5. Artisan / Business Brand Name (Optional)
              const Text(
                'Artisan / Business Brand Name',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _businessNameController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  hintText: 'e.g. Sambalpuri Handloom House',
                  prefixIcon: Icon(Icons.storefront_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),

              // 6. Artisan Type (Optional)
              const Text(
                'Artisan Type',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedArtisanType,
                hint: const Text('Select type (e.g. Individual / SHG)'),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.groups_outlined),
                  border: OutlineInputBorder(),
                ),
                items: LocationData.artisanTypes.map((t) {
                  return DropdownMenuItem(value: t, child: Text(t));
                }).toList(),
                onChanged: _isLoading ? null : (val) => setState(() => _selectedArtisanType = val),
              ),
              const SizedBox(height: 18),

              // 7. Years of Experience (Optional)
              const Text(
                'Years of Experience',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _experienceController,
                keyboardType: TextInputType.number,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  hintText: 'e.g. 10',
                  prefixIcon: Icon(Icons.history_edu_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),

              // 8. About Your Craft (Optional)
              const Text(
                'About Your Craft',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  hintText: 'Briefly describe the techniques, raw materials, or heritage of your craft...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 28),

              // Submit Button
              ArtisanButton(
                label: 'Save & Enter Studio',
                icon: Icons.check_circle_outline_rounded,
                isLoading: _isLoading,
                onPressed: _handleSaveProfile,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
