import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/community_repository.dart';
import '../../core/widgets/responsive_center.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String _selectedCategory = 'Ask Questions';
  String? _selectedImagePath;
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = [
    'Ask Questions',
    'Share Problems',
    'Share Machinery',
    'Share Seeds',
    'Share Fertilizers',
    'Share Pesticides',
    'Government Schemes',
    'Weather Discussions',
    'Market Discussions',
  ];

  @override
  void dispose() {
    _contentController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImagePath = pickedFile.path;
          _imageUrlController.text = pickedFile.path;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Photo selected successfully via ${source == ImageSource.camera ? 'Camera' : 'Gallery'}!',
              ),
              backgroundColor: AppColors.primaryGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access image picker: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload Photo',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.mintBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt, color: AppColors.primaryGreen),
                  ),
                  title: Text(
                    'Take Photo with Camera',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.mintBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library, color: AppColors.primaryGreen),
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submitPost() {
    if (_contentController.text.trim().isEmpty) return;

    final currentUser = ref.read(currentUserProvider);
    final l10n = context.l10n;

    final effectiveImage = (_selectedImagePath != null && _selectedImagePath!.isNotEmpty)
        ? _selectedImagePath
        : (_imageUrlController.text.trim().isNotEmpty ? _imageUrlController.text.trim() : null);

    final newPost = PostModel(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      farmerId: currentUser.uid,
      farmerName: currentUser.name.isNotEmpty ? currentUser.name : 'Arun Kumar',
      farmerState: currentUser.state.isNotEmpty
          ? currentUser.state
          : 'Tamil Nadu',
      farmerDistrict: currentUser.district.isNotEmpty
          ? currentUser.district
          : 'Coimbatore',
      category: _selectedCategory,
      content: _contentController.text.trim(),
      imageUrl: effectiveImage,
    );

    ref.read(communityProvider.notifier).createPost(newPost);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.success),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.community,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _submitPost,
            child: Text(
              l10n.confirm.toUpperCase(),
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: ResponsiveCenter(
        maxWidth: 800,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: '${l10n.category} *',
                  prefixIcon: const Icon(
                    Icons.category,
                    color: AppColors.primaryGreen,
                  ),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _contentController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: '${l10n.tagline}...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              // Upload Card (replacing toggle switch with direct Upload feature)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.add_a_photo_outlined,
                                color: AppColors.primaryGreen,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Upload Photo',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          if (_selectedImagePath != null && _selectedImagePath!.isNotEmpty)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedImagePath = null;
                                  _imageUrlController.clear();
                                });
                              },
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              label: Text(
                                'Remove',
                                style: GoogleFonts.inter(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Attach a photo of your crop, equipment, or question to get quick community help.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),

                      if (_selectedImagePath != null && _selectedImagePath!.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              _selectedImagePath!.startsWith('http')
                                  ? Image.network(
                                      _selectedImagePath!,
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        height: 180,
                                        color: AppColors.mintBg,
                                        child: const Center(
                                          child: Icon(Icons.broken_image, color: Colors.grey),
                                        ),
                                      ),
                                    )
                                  : Image.file(
                                      File(_selectedImagePath!),
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        height: 180,
                                        color: AppColors.mintBg,
                                        child: const Center(
                                          child: Icon(Icons.broken_image, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: InkWell(
                                  onTap: _showImageSourceDialog,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit, size: 14, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text(
                                          'Change',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        InkWell(
                          onTap: _showImageSourceDialog,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.mintBg.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primaryGreen.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryGreen.withValues(alpha: 0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 32,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Upload',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap to choose Camera or Gallery',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: Text(
                    l10n.confirm.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _submitPost,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
