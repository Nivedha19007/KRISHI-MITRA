import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../data/models/post_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/community_repository.dart';
import '../../core/widgets/responsive_center.dart';
import 'create_post_screen.dart';

class CommunityFeedScreen extends ConsumerStatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  ConsumerState<CommunityFeedScreen> createState() =>
      _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends ConsumerState<CommunityFeedScreen> {
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
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

  final Map<String, TextEditingController> _replyControllers = {};

  @override
  void dispose() {
    for (var c in _replyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final posts = ref.watch(communityProvider);
    final isFarmer = currentUser.role == UserRole.farmer;
    final l10n = context.l10n;

    final filteredPosts = _selectedCategory == 'All'
        ? posts
        : posts
              .where(
                (p) =>
                    p.category.toLowerCase() == _selectedCategory.toLowerCase(),
              )
              .toList();

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
          if (isFarmer)
            IconButton(
              icon: const Icon(Icons.post_add),
              tooltip: l10n.community,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                );
              },
            ),
        ],
      ),
      body: ResponsiveCenter(
        maxWidth: 1000,
        child: Column(
          children: [
            // Category Selector Chips
            Container(
              height: 52,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = cat == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(cat == 'All' ? l10n.allCommodities : cat),
                      selected: isSelected,
                      selectedColor: AppColors.primaryGreen,
                      backgroundColor: AppColors.mintBg,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),

            // Feed List
            Expanded(
              child: filteredPosts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.forum_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.noDataFound,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredPosts.length,
                      itemBuilder: (context, index) {
                        final post = filteredPosts[index];
                        final isLiked = post.likedByUids.contains(
                          currentUser.uid,
                        );
                        _replyControllers.putIfAbsent(
                          post.id,
                          () => TextEditingController(),
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Author Info Row
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.primaryGreen,
                                      child: Text(
                                        post.farmerName.isNotEmpty
                                            ? post.farmerName[0]
                                            : 'F',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            post.farmerName,
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            '${post.farmerDistrict}, ${post.farmerState}',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.mintBg,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.primaryGreen
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Text(
                                        post.category,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryGreen,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Post Body Text
                                Text(
                                  post.content,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    height: 1.4,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Photo Attachment
                                if (post.imageUrl != null &&
                                    post.imageUrl!.isNotEmpty) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      post.imageUrl!,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        height: 150,
                                        color: AppColors.mintBg,
                                        child: const Center(
                                          child: Icon(
                                            Icons.image,
                                            size: 48,
                                            color: AppColors.primaryGreen,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                // Like & Reply Row
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        isLiked
                                            ? Icons.thumb_up
                                            : Icons.thumb_up_outlined,
                                        color: isLiked
                                            ? AppColors.primaryGreen
                                            : AppColors.textSecondary,
                                      ),
                                      onPressed: () {
                                        ref
                                            .read(communityProvider.notifier)
                                            .likePost(post.id, currentUser.uid);
                                      },
                                    ),
                                    Text(
                                      '${post.likesCount} ${l10n.helpful}',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    const Icon(
                                      Icons.mode_comment_outlined,
                                      size: 20,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${post.comments.length} ${l10n.replies}',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),

                                // Replies List Preview
                                if (post.comments.isNotEmpty) ...[
                                  const Divider(),
                                  ...post.comments.map(
                                    (comment) => Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.mintBg.withValues(
                                          alpha: 0.6,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.primaryGreen
                                              .withValues(alpha: 0.15),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                comment.farmerName,
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: AppColors.primaryGreen,
                                                ),
                                              ),
                                              Text(
                                                l10n.farmerReply,
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: AppColors.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            comment.content,
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],

                                // Reply Input Box
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _replyControllers[post.id],
                                        decoration: InputDecoration(
                                          hintText: l10n.replyHint,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.send,
                                        color: AppColors.primaryGreen,
                                      ),
                                      onPressed: () {
                                        final text = _replyControllers[post.id]
                                            ?.text
                                            .trim();
                                        if (text != null && text.isNotEmpty) {
                                          ref
                                              .read(communityProvider.notifier)
                                              .addComment(
                                                post.id,
                                                CommentModel(
                                                  id: 'c_${DateTime.now().millisecondsSinceEpoch}',
                                                  farmerId: currentUser.uid,
                                                  farmerName: currentUser.name,
                                                  farmerAvatar: '',
                                                  content: text,
                                                ),
                                              );
                                          _replyControllers[post.id]?.clear();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: isFarmer
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primaryGreen,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                );
              },
              icon: const Icon(Icons.edit, color: Colors.white),
              label: Text(
                'Create Discussion',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }
}
