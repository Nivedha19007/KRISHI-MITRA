import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
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
  final _imageUrlController = TextEditingController(
    text: 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=600',
  );
  String _selectedCategory = 'Ask Questions';
  bool _hasImage = false;

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

  void _submitPost() {
    if (_contentController.text.trim().isEmpty) return;

    final currentUser = ref.read(currentUserProvider);

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
      imageUrl: _hasImage ? _imageUrlController.text.trim() : null,
    );

    ref.read(communityProvider.notifier).createPost(newPost);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Discussion post published to Farmer Community!'),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Discussion Post',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _submitPost,
            child: Text(
              'POST',
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
                decoration: const InputDecoration(
                  labelText: 'Discussion Category *',
                  prefixIcon: Icon(
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
                decoration: const InputDecoration(
                  hintText:
                      'Describe your crop question, problem, seeds, machinery share, or market observation...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Attach Photo / Sample Image',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Switch(
                            value: _hasImage,
                            activeThumbColor: AppColors.primaryGreen,
                            onChanged: (v) => setState(() => _hasImage = v),
                          ),
                        ],
                      ),
                      if (_hasImage) ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: _imageUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Image URL',
                            prefixIcon: Icon(
                              Icons.link,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _imageUrlController.text,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox(),
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
                    'PUBLISH TO COMMUNITY',
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
