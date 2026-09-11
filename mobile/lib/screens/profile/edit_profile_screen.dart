import 'package:flutter/material.dart';
import 'package:artisan_mobile/core/constants/location_data.dart';
import 'package:artisan_mobile/core/theme/app_theme.dart';
import 'package:artisan_mobile/services/auth_service.dart';
import 'package:artisan_mobile/widgets/artisan_button.dart';

class EditProfileScreen extends StatefulWidget {
  final AuthService? authService;

  const EditProfileScreen({super.key, this.authService});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final AuthService _authService;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _experienceController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategory;
  String? _selectedState;
  String? _selectedDistrict;
  String? _selectedLanguage;
  String? _selectedArtisanType;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();

    final user = _authService.currentUser;
    if (user != null) {
      final existingName = user['full_name']?.toString() ?? user['name']?.toString() ?? '';
      if (existingName.isNotEmpty && !existingName.startsWith('Artisan ')) {
        _nameController.text = existingName;
      }
      if (user['craft_category'] != null && LocationData.craftCategories.contains(user['craft_category'])) {
        _selectedCategory = user['craft_category'];
      } else {
        _selectedCategory = LocationData.craftCategories.first;
      }

      if (user['preferred_language'] != null && LocationData.preferredLanguages.contains(user['preferred_language'])) {
        _selectedLanguage = user['preferred_language'];
      } else {
        _selectedLanguage = LocationData.preferredLanguages.first;
      }

      if (user['state'] != null && LocationData.states.contains(user['state'])) {
        _selectedState = user['state'];
      } else {
        _selectedState = LocationData.states.first;
      }

      final availableDistricts = LocationData.getDistrictsForState(_selectedState!);
      if (user['district'] != null && availableDistricts.contains(user['district'])) {
        _selectedDistrict = user['district'];
      } else {
        _selectedDistrict = availableDistricts.first;
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
    } else {
      _selectedCategory = LocationData.craftCategories.first;
      _selectedLanguage = LocationData.preferredLanguages.first;
      _selectedState = LocationData.states.first;
      _selectedDistrict = LocationData.getDistrictsForState(_selectedState!).first;
    }
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

    int? expYears;
    if (_experienceController.text.trim().isNotEmpty) {
      expYears = int.tryParse(_experienceController.text.trim());
      if (expYears == null || expYears < 0) {
        setState(() => _errorMessage = 'Years of experience must be a valid number');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final payload = <String, dynamic>{
        'full_name': fullName,
        'craft_category': _selectedCategory ?? LocationData.craftCategories.first,
        'preferred_language': _selectedLanguage ?? 'Hindi',
        'state': _selectedState,
        'district': _selectedDistrict,
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
            content: Text('Profile updated successfully! ✨'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
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
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                // Core Information Section
                _buildSectionHeader('Basic Details', Icons.badge_outlined),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Full Name *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        enabled: !_isLoading,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Sunita Devi',
                          prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Full Name is required' : null,
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Craft Category *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.category_outlined, color: AppColors.primary),
                          border: OutlineInputBorder(),
                        ),
                        items: LocationData.craftCategories.map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: _isLoading ? null : (val) => setState(() => _selectedCategory = val),
                        validator: (val) => val == null ? 'Please select a craft category' : null,
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Preferred Language *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedLanguage,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.translate_rounded, color: AppColors.primary),
                          border: OutlineInputBorder(),
                        ),
                        items: LocationData.preferredLanguages.map((lang) {
                          return DropdownMenuItem(value: lang, child: Text(lang));
                        }).toList(),
                        onChanged: _isLoading ? null : (val) => setState(() => _selectedLanguage = val),
                        validator: (val) => val == null ? 'Please select your preferred language' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Location Section
                _buildSectionHeader('Location Details', Icons.location_on_outlined),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'State',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
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
                              'District',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
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
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Craft & Business Details Section
                _buildSectionHeader('Craft & Experience (Optional)', Icons.workspace_premium_outlined),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Artisan / Business Brand Name',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _businessNameController,
                        enabled: !_isLoading,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Sambalpuri Handloom House',
                          prefixIcon: Icon(Icons.storefront_outlined, color: AppColors.primary),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Artisan Type',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedArtisanType,
                        hint: const Text('Select type (e.g. Individual / SHG)'),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.groups_outlined, color: AppColors.primary),
                          border: OutlineInputBorder(),
                        ),
                        items: LocationData.artisanTypes.map((t) {
                          return DropdownMenuItem(value: t, child: Text(t));
                        }).toList(),
                        onChanged: _isLoading ? null : (val) => setState(() => _selectedArtisanType = val),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Years of Experience',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _experienceController,
                        keyboardType: TextInputType.number,
                        enabled: !_isLoading,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 10',
                          prefixIcon: Icon(Icons.history_edu_rounded, color: AppColors.primary),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'About Your Craft',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        enabled: !_isLoading,
                        decoration: const InputDecoration(
                          hintText: 'Describe your heritage, techniques, and materials...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Save Button
                ArtisanButton(
                  label: 'Save Changes',
                  icon: Icons.check_circle_outline_rounded,
                  isLoading: _isLoading,
                  onPressed: _handleSaveProfile,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.black.withOpacity(0.06)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
