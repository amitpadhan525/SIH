import 'package:flutter/material.dart';
import 'package:artisan_mobile/core/constants/api_constants.dart';
import 'package:artisan_mobile/core/theme/app_theme.dart';
import 'package:artisan_mobile/core/network/api_client.dart';

void showServerConfigDialog(BuildContext context, {VoidCallback? onSaved}) {
  showDialog(
    context: context,
    builder: (ctx) => ServerConfigDialog(onSaved: onSaved),
  );
}

class ServerConfigDialog extends StatefulWidget {
  final VoidCallback? onSaved;

  const ServerConfigDialog({super.key, this.onSaved});

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late final TextEditingController _controller;
  bool _isTesting = false;
  String? _testResult;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ApiConstants.baseUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final targetUrl = _controller.text.trim();
    if (targetUrl.isEmpty) return;

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final client = ApiClient();
    try {
      final healthUrl = targetUrl.endsWith('/')
          ? '${targetUrl}health/db'
          : '$targetUrl/health/db';
      final res = await client.get(healthUrl, timeout: const Duration(seconds: 4));
      if (mounted) {
        if (res is Map && res['database'] == 'connected') {
          setState(() {
            _isTesting = false;
            _isSuccess = true;
            _testResult = '✓ Connected successfully to backend!';
          });
        } else {
          setState(() {
            _isTesting = false;
            _isSuccess = false;
            _testResult = '⚠ Server responded but database not connected.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _isSuccess = false;
          _testResult = '✕ Cannot reach server at this URL.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.tune_rounded, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Server Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the backend server IP/URL for your network:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Server Base URL',
                hintText: 'http://10.111.166.31:8000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: _isTesting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.network_check_rounded, color: AppColors.primary),
                  tooltip: 'Test Connection',
                  onPressed: _isTesting ? null : _testConnection,
                ),
              ),
            ),
            if (_testResult != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _isSuccess ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _testResult!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            const Text(
              'Quick Presets:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Static Tunnel (Cloud)'),
                  avatar: const Icon(Icons.cloud_done_rounded, size: 16),
                  onPressed: () {
                    _controller.text = ApiConstants.staticTunnelUrl;
                    _testConnection();
                  },
                ),
                ActionChip(
                  label: const Text('Wi-Fi (10.233.61.31)'),
                  avatar: const Icon(Icons.wifi_rounded, size: 16),
                  onPressed: () {
                    _controller.text = 'http://10.233.61.31:8000';
                    _testConnection();
                  },
                ),
                ActionChip(
                  label: const Text('Localhost (127.0.0.1)'),
                  avatar: const Icon(Icons.computer_rounded, size: 16),
                  onPressed: () {
                    _controller.text = 'http://127.0.0.1:8000';
                    _testConnection();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            final newUrl = _controller.text.trim();
            if (newUrl.isNotEmpty) {
              ApiConstants.customBaseUrl = newUrl;
              Navigator.pop(context);
              widget.onSaved?.call();
            }
          },
          child: const Text('Save & Apply'),
        ),
      ],
    );
  }
}
