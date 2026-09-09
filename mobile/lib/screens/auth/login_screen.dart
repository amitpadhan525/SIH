import 'package:flutter/material.dart';
import 'package:artisan_mobile/core/theme/app_theme.dart';
import 'package:artisan_mobile/services/auth_service.dart';
import 'package:artisan_mobile/widgets/artisan_button.dart';

class LoginScreen extends StatefulWidget {
  final AuthService? authService;

  const LoginScreen({super.key, this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthService _authService;
  final _phoneController = TextEditingController(text: '+91 9876543210');
  final _otpController = TextEditingController();

  bool _otpSent = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _receivedDemoOtp;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String _cleanPhone(String input) {
    return input.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  Future<void> _handleSendOtp({bool autoFillDemo = false}) async {
    final phone = _cleanPhone(_phoneController.text.trim());
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    if (digits.length < 10) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit mobile number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _authService.sendOtp(phone);
      if (mounted) {
        final demoOtp = res['demo_otp'] as String?;
        setState(() {
          _otpSent = true;
          _isLoading = false;
          _receivedDemoOtp = demoOtp;
          if (autoFillDemo && demoOtp != null && demoOtp.isNotEmpty) {
            _otpController.text = demoOtp;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              demoOtp != null
                  ? 'OTP generated! Demo code: $demoOtp'
                  : 'OTP sent to $phone',
            ),
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
    final phone = _cleanPhone(_phoneController.text.trim());
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit OTP code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.verifyOtp(phone, otp);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful! Welcome to Artisan Studio 🙏'),
            backgroundColor: AppColors.success,
          ),
        );

        // If popped as a route, return true; otherwise AuthGate handles reactive view change
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
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

  Future<void> _handleQuickDemoFlow() async {
    setState(() {
      _phoneController.text = '+91 9876543210';
      _errorMessage = null;
    });
    // Request real dynamic OTP from backend with auto-fill enabled
    await _handleSendOtp(autoFillDemo: true);
    if (_receivedDemoOtp != null && mounted) {
      await _handleVerifyOtp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artisan Login'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Artisan Authentication 🌾',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Log in with your mobile phone via secure One-Time Password (OTP).',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // SIH Evaluator Demo Box
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
                      Icon(Icons.stars_rounded, color: Color(0xFFF57F17), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'SIH Evaluator Demo Access',
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
                    'Automatically requests dynamic server OTP and authenticates with real backend verification.',
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
                      onPressed: _isLoading ? null : _handleQuickDemoFlow,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Error Message Display
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

            // Phone Input
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Mobile Phone Number',
                hintText: '+91 9876543210',
                prefixIcon: const Icon(Icons.phone_android_rounded),
                border: const OutlineInputBorder(),
                suffixIcon: _otpSent
                    ? TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => setState(() {
                                  _otpSent = false;
                                  _otpController.clear();
                                  _receivedDemoOtp = null;
                                }),
                        child: const Text('Change'),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // OTP Section
            if (_otpSent) ...[
              if (_receivedDemoOtp != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Server Demo OTP: $_receivedDemoOtp',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _otpController.text = _receivedDemoOtp!;
                        },
                        child: const Text('Fill OTP'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Enter 6-Digit OTP',
                  hintText: '6-digit code',
                  prefixIcon: Icon(Icons.lock_clock_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ArtisanButton(
                label: 'Verify OTP & Login',
                icon: Icons.check_circle_outline_rounded,
                isLoading: _isLoading,
                onPressed: _handleVerifyOtp,
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Resend OTP'),
                  onPressed: _isLoading ? null : () => _handleSendOtp(),
                ),
              ),
            ] else ...[
              ArtisanButton(
                label: 'Request OTP Code',
                icon: Icons.send_rounded,
                isLoading: _isLoading,
                onPressed: () => _handleSendOtp(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
