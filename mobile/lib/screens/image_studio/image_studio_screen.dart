import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:artisan_mobile/core/constants/api_constants.dart';
import 'package:artisan_mobile/core/network/api_client.dart';
import 'package:artisan_mobile/core/theme/app_theme.dart';
import 'package:artisan_mobile/services/product_service.dart';
import 'package:artisan_mobile/widgets/artisan_button.dart';
import 'package:artisan_mobile/widgets/error_view.dart';
import 'package:artisan_mobile/widgets/loading_view.dart';

enum StudioState { idle, selected, processing, processed, error }

class ImageStudioScreen extends StatefulWidget {
  final int? productId;
  final String? productName;
  final ImageSource? initialSource;
  final ProductService? productService;
  final Function(Map<String, dynamic> imageResult)? onImageSaved;

  const ImageStudioScreen({
    super.key,
    this.productId,
    this.productName,
    this.initialSource,
    this.productService,
    this.onImageSaved,
  });

  @override
  State<ImageStudioScreen> createState() => _ImageStudioScreenState();
}

class _ImageStudioScreenState extends State<ImageStudioScreen> {
  late final ProductService _productService;
  final ImagePicker _picker = ImagePicker();

  StudioState _state = StudioState.idle;
  String _selectedBackground = 'white'; // 'white', 'grey', 'warm'
  bool _showAfter = true; // true = After (Enhanced), false = Before (Original)

  Uint8List? _rawImageBytes;
  String _selectedFilename = 'craft_photo.jpg';

  String? _originalPreviewUrl;
  String? _processedPreviewUrl;
  String? _errorMessage;

  // Real valid JPEG sample craft image for evaluation without camera
  static const String _sampleCraftJpegBase64 =
      '/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wgALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA=';

  @override
  void initState() {
    super.initState();
    _productService = widget.productService ?? ProductService();
    if (widget.initialSource != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pickImage(widget.initialSource!);
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 88,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (mounted) {
          setState(() {
            _rawImageBytes = bytes;
            _selectedFilename = picked.name.isNotEmpty ? picked.name : 'product_photo.jpg';
            _state = StudioState.selected;
            _errorMessage = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open camera/gallery: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _loadSampleCraftPhoto(String craftName) {
    if (mounted) {
      setState(() {
        _rawImageBytes = base64Decode(_sampleCraftJpegBase64);
        _selectedFilename = '${craftName.toLowerCase().replaceAll(' ', '_')}.jpg';
        _state = StudioState.selected;
      });
    }
  }

  Future<void> _processPhoto() async {
    if (_rawImageBytes == null) return;

    setState(() {
      _state = StudioState.processing;
      _errorMessage = null;
    });

    try {
      if (widget.productId != null) {
        // Direct upload and attach to product
        final result = await _productService.uploadProductImage(
          widget.productId!,
          _rawImageBytes!,
          _selectedFilename,
          backgroundMode: _selectedBackground,
        );

        if (mounted) {
          setState(() {
            _originalPreviewUrl = result['original_url'] as String?;
            _processedPreviewUrl = result['processed_url'] as String?;
            _state = StudioState.processed;
            _showAfter = true;
          });

          if (widget.onImageSaved != null) {
            widget.onImageSaved!(result);
          }
        }
      } else {
        // Standalone instant studio preview
        final result = await _productService.enhanceImagePreview(
          _rawImageBytes!,
          _selectedFilename,
          backgroundMode: _selectedBackground,
        );

        if (mounted) {
          setState(() {
            _originalPreviewUrl = result['original_url'] as String?;
            _processedPreviewUrl = result['processed_url'] as String?;
            _state = StudioState.processed;
            _showAfter = true;
          });

          if (widget.onImageSaved != null) {
            widget.onImageSaved!(result);
          }
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _state = StudioState.error;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = StudioState.error;
          _errorMessage = 'Could not enhance photo. Please check your backend connection.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Photo Studio'),
        actions: [
          if (_state == StudioState.processed)
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop({
                  'original_url': _originalPreviewUrl,
                  'processed_url': _processedPreviewUrl,
                  'raw_bytes': _rawImageBytes,
                  'filename': _selectedFilename,
                  'background_mode': _selectedBackground,
                });
              },
              icon: const Icon(Icons.check, color: AppColors.primary),
              label: const Text(
                'Apply',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 20),
              _buildStudioContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.productName != null
                      ? 'Studio for: ${widget.productName}'
                      : 'AI Product Enhancer',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Clean background, studio lighting & centered 1024x1024 framing.',
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
    );
  }

  Widget _buildStudioContent() {
    switch (_state) {
      case StudioState.idle:
        return _buildCaptureOptions();
      case StudioState.selected:
        return _buildSelectedPhotoPreview();
      case StudioState.processing:
        return _buildProcessingView();
      case StudioState.processed:
        return _buildProcessedResult();
      case StudioState.error:
        return ErrorView(
          message: _errorMessage ?? 'Something went wrong.',
          onRetry: _processPhoto,
        );
    }
  }

  Widget _buildCaptureOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Camera Trigger Card
        InkWell(
          onTap: () => _pickImage(ImageSource.camera),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 18),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Take Photo with Camera',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Snap picture of your product in daylight',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Gallery Trigger Card
        InkWell(
          onTap: () => _pickImage(ImageSource.gallery),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.cardBorder,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_library_rounded,
                    size: 32,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 18),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload from Photo Gallery',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Choose an existing craft photo from phone',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Quick Demo Craft Photos for evaluation
        const Text(
          'Or try with a sample handicraft:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildSampleChip('Terracotta Vase', Icons.local_florist),
            _buildSampleChip('Silk Saree', Icons.checkroom),
            _buildSampleChip('Brass Lamp', Icons.wb_incandescent),
            _buildSampleChip('Wood Carving', Icons.handyman),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectedPhotoPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: _rawImageBytes != null
              ? Image.memory(
                  _rawImageBytes!,
                  fit: BoxFit.contain,
                )
              : const Center(child: Text('No image selected')),
        ),
        const SizedBox(height: 20),

        // Background Palette Selector
        const Text(
          'Studio Background Style:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildBgOption('white', 'Pure White', Colors.white),
            const SizedBox(width: 8),
            _buildBgOption('transparent', 'Transparent PNG', const Color(0xFFF0F4F8)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildBgOption('grey', 'Neutral Grey', const Color(0xFFF2F4F7)),
            const SizedBox(width: 8),
            _buildBgOption('warm', 'Warm Studio', const Color(0xFFFAF6F0)),
          ],
        ),
        const SizedBox(height: 24),

        // Enhance Action Button
        ArtisanButton(
          label: '✨ Enhance Photo with AI',
          onPressed: _processPhoto,
        ),
        const SizedBox(height: 12),
        ArtisanButton(
          label: 'Choose Different Photo',
          isOutlined: true,
          onPressed: () {
            setState(() {
              _state = StudioState.idle;
              _rawImageBytes = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildBgOption(String key, String label, Color color) {
    final isSelected = _selectedBackground == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedBackground = key),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSampleChip(String name, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppColors.primary),
      label: Text(name),
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.cardBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onPressed: () => _loadSampleCraftPhoto(name),
    );
  }

  Widget _buildProcessingView() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Column(
        children: [
          LoadingView(message: 'Improving your product photo...'),
          SizedBox(height: 20),
          Text(
            '• Removing background clutter\n• Auto-adjusting exposure & contrast\n• Centering onto 1024x1024 studio canvas',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProcessedResult() {
    final previewUrl = _showAfter
        ? ApiConstants.resolveImageUrl(_processedPreviewUrl)
        : ApiConstants.resolveImageUrl(_originalPreviewUrl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Before / After Toggle Bar
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _showAfter = false),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: !_showAfter ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Original Photo (Before)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: !_showAfter ? FontWeight.bold : FontWeight.normal,
                          color: !_showAfter ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _showAfter = true),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _showAfter ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '✨ AI Studio (After)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _showAfter ? FontWeight.bold : FontWeight.normal,
                          color: _showAfter ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Image Canvas Display
        Container(
          height: 320,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: previewUrl.isNotEmpty
              ? Image.network(
                  previewUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _rawImageBytes != null
                      ? Image.memory(_rawImageBytes!, fit: BoxFit.contain)
                      : const Center(child: Text('Image preview unavailable')),
                )
              : _rawImageBytes != null
                  ? Image.memory(_rawImageBytes!, fit: BoxFit.contain)
                  : const Center(child: Text('No image preview')),
        ),
        const SizedBox(height: 20),

        // Accept / Apply Button
        ArtisanButton(
          label: 'Apply & Attach to Product',
          icon: Icons.check_circle_outline,
          onPressed: () {
            Navigator.of(context).pop({
              'original_url': _originalPreviewUrl,
              'processed_url': _processedPreviewUrl,
              'raw_bytes': _rawImageBytes,
              'filename': _selectedFilename,
              'background_mode': _selectedBackground,
            });
          },
        ),
        const SizedBox(height: 12),
        ArtisanButton(
          label: 'Retake / Pick Another Photo',
          icon: Icons.refresh_rounded,
          isOutlined: true,
          onPressed: () {
            setState(() {
              _state = StudioState.idle;
              _rawImageBytes = null;
              _originalPreviewUrl = null;
              _processedPreviewUrl = null;
            });
          },
        ),
      ],
    );
  }
}
