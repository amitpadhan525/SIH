import 'package:flutter/material.dart';
import 'package:artisan_mobile/core/theme/app_theme.dart';
import 'package:artisan_mobile/services/product_service.dart';
import 'package:artisan_mobile/widgets/artisan_button.dart';

class LoginScreen extends StatefulWidget {
  final ProductService? productService;

  const LoginScreen({super.key, this.productService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final ProductService _productService;
  final _phoneController = TextEditingController(text: '+91 9876543210');
  final _otpController = TextEditingController(text: '123456');
  final _passwordController = TextEditingController();

  bool _isOtpMode = true;
  bool _otpSent = false;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _productService = widget.productService ?? ProductService();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Please enter your phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _productService.sendOtp(phone);
      if (mounted) {
        setState(() {
          _otpSent = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'OTP sent successfully! (Demo: 123456)'),
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

  Future<void> _handleVerifyOtp() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      setState(() => _errorMessage = 'Please enter the 6-digit OTP code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _productService.verifyOtp(phone, otp);
      if (mounted) {
        final token = res['access_token'] as String?;
        if (token != null) {
          _productService.setAuthToken(token);
        }
        setState(() {
          _currentUser = {
            'phone': res['phone'] ?? phone,
            'full_name': res['name'] ?? 'Artisan User',
            'role': res['role'] ?? 'artisan',
            'craft_category': 'Traditional Crafts',
            'state': 'India',
            'artisan_id': res['artisan_id'],
            'verified': true,
          };
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged in successfully! Namaste 🙏'),
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

  Future<void> _handleQuickDemoLogin() async {
    setState(() {
      _phoneController.text = '+91 9876543210';
      _otpController.text = '123456';
    });
    await _handleVerifyOtp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artisan Profile & Login'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _currentUser != null ? _buildProfileView() : _buildLoginForm(),
      ),
    );
  }

  Widget _buildProfileView() {
    final user = _currentUser!;
    final name = user['full_name']?.toString() ?? 'Artisan User';
    final phone = user['phone']?.toString() ?? '';
    final craft = user['craft_category']?.toString() ?? 'Handicrafts';
    final state = user['state']?.toString() ?? 'India';
    final role = user['role']?.toString() ?? 'artisan';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder, width: 1.2),
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryLight,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Verified $role'.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              _buildProfileRow('Phone', phone, Icons.phone_android_rounded),
              const SizedBox(height: 10),
              _buildProfileRow('Craft Tradition', craft, Icons.palette_outlined),
              const SizedBox(height: 10),
              _buildProfileRow('State / Region', state, Icons.location_on_outlined),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ArtisanButton(
          label: 'Continue to Dashboard',
          icon: Icons.dashboard_rounded,
          onPressed: () => Navigator.pop(context, true),
        ),
        const SizedBox(height: 12),
        ArtisanButton(
          label: 'Switch Account / Logout',
          icon: Icons.logout_rounded,
          isOutlined: true,
          onPressed: () {
            setState(() {
              _currentUser = null;
              _otpSent = false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildProfileRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const Text(
          'Artisan Access 🌾',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Log in with your registered mobile phone or test with one tap.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        // Quick SIH Demo Evaluator Button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFD54F)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.stars_rounded, color: Color(0xFFF57F17), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'SIH Evaluator Quick Access',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Auto-authenticates as registered Master Artisan Meera Devi (Jaipur Blue Pottery).',
                style: TextStyle(fontSize: 12, color: Color(0xFF5D4037)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.bolt_rounded),
                  label: const Text('One-Tap Demo Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleQuickDemoLogin,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Error message
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

        // Tab Selector
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('📱 Phone OTP')),
                selected: _isOtpMode,
                onSelected: (val) => setState(() => _isOtpMode = true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('🔑 Password')),
                selected: !_isOtpMode,
                onSelected: (val) => setState(() => _isOtpMode = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Phone Input
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Mobile Phone Number',
            hintText: '+91 9876543210',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        if (_isOtpMode) ...[
          if (_otpSent) ...[
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Enter 6-Digit OTP',
                hintText: '123456',
                prefixIcon: Icon(Icons.lock_clock_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ArtisanButton(
              label: 'Verify OTP & Enter',
              icon: Icons.check_circle_outline,
              isLoading: _isLoading,
              onPressed: _handleVerifyOtp,
            ),
          ] else ...[
            ArtisanButton(
              label: 'Send OTP SMS',
              icon: Icons.send_rounded,
              isLoading: _isLoading,
              onPressed: _handleSendOtp,
            ),
          ],
        ] else ...[
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Artisan Password',
              prefixIcon: Icon(Icons.password_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ArtisanButton(
            label: 'Login with Password',
            icon: Icons.login_rounded,
            isLoading: _isLoading,
            onPressed: () async {
              if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
                setState(() => _errorMessage = 'Please enter phone and password');
                return;
              }
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              try {
                final res = await _productService.login(
                  _phoneController.text.trim(),
                  _passwordController.text.trim(),
                );
                if (mounted) {
                  final token = res['access_token'] as String?;
                  if (token != null) {
                    _productService.setAuthToken(token);
                  }
                  setState(() {
                    _currentUser = {
                      'phone': res['phone'] ?? _phoneController.text.trim(),
                      'full_name': res['name'] ?? 'Artisan User',
                      'role': res['role'] ?? 'artisan',
                      'craft_category': 'Traditional Crafts',
                      'state': 'India',
                      'artisan_id': res['artisan_id'],
                      'verified': true,
                    };
                    _isLoading = false;
                  });
                }
              } catch (e) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _errorMessage = e.toString().replaceAll('Exception: ', '');
                  });
                }
              }
            },
          ),
        ],
      ],
    );
  }
}
