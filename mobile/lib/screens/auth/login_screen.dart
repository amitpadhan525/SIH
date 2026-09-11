import 'package:flutter/material.dart';
import 'package:artisan_mobile/core/theme/app_theme.dart';
import 'package:artisan_mobile/services/auth_service.dart';
import 'package:artisan_mobile/widgets/artisan_button.dart';
import 'package:artisan_mobile/widgets/server_config_dialog.dart';

class LoginScreen extends StatefulWidget {
  final AuthService? authService;

  const LoginScreen({super.key, this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthService _authService;
  final _phoneController = TextEditingController();
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
    String trimmed = input.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (trimmed.isEmpty) return '';
    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length == 10 && !trimmed.startsWith('+')) {
      return '+91$digitsOnly';
    }
    if (!trimmed.startsWith('+') && digitsOnly.isNotEmpty) {
      return '+$digitsOnly';
    }
    return trimmed;
  }

  Future<void> _handleSendOtp() async {
    final rawInput = _phoneController.text.trim();
    if (rawInput.isEmpty) {
      setState(() => _errorMessage = 'Please enter your mobile phone number');
      return;
    }

    final phone = _cleanPhone(rawInput);
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
          _otpController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent successfully to $phone'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artisan Login'),
        actions: [
          IconButton(
            tooltip: 'Server Address',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => showServerConfigDialog(context),
          ),
        ],
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
              'Enter your mobile phone number to log in or create your artisan profile with a secure One-Time Password (OTP).',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
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
              enabled: !_isLoading && !_otpSent,
              decoration: InputDecoration(
                labelText: 'Mobile Phone Number',
                hintText: 'Enter 10-digit mobile number',
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

