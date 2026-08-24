import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../datasources/sample_data.dart';

class CommunityRepository {
  final List<PostModel> _posts = List.from(SampleData.samplePosts);

  List<PostModel> getPosts({String? category}) {
    if (category == null || category == 'All') return List.unmodifiable(_posts);
    return _posts.where((p) => p.category == category).toList();
  }

  void addPost(PostModel post) {
    _posts.insert(0, post);
  }

  void toggleLike(String postId, String userId) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      final liked = post.likedByUids.contains(userId);
      final newLikes = liked
          ? post.likedByUids.where((id) => id != userId).toList()
          : [...post.likedByUids, userId];
      _posts[index] = PostModel(
        id: post.id,
        farmerId: post.farmerId,
        farmerName: post.farmerName,
        farmerState: post.farmerState,
        farmerDistrict: post.farmerDistrict,
        category: post.category,
        content: post.content,
        imageUrl: post.imageUrl,
        likesCount: newLikes.length,
        likedByUids: newLikes,
        comments: post.comments,
        createdAt: post.createdAt,
      );
    }
  }

  void addComment(String postId, CommentModel comment) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      _posts[index] = PostModel(
        id: post.id,
        farmerId: post.farmerId,
        farmerName: post.farmerName,
        farmerState: post.farmerState,
        farmerDistrict: post.farmerDistrict,
        category: post.category,
        content: post.content,
        imageUrl: post.imageUrl,
        likesCount: post.likesCount,
        likedByUids: post.likedByUids,
        comments: [...post.comments, comment],
        createdAt: post.createdAt,
      );
    }
  }
}

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository();
});

class CommunityNotifier extends StateNotifier<List<PostModel>> {
  final CommunityRepository _repo;

  CommunityNotifier(this._repo) : super(_repo.getPosts());

  void filterCategory(String? category) {
    state = _repo.getPosts(category: category);
  }

  void createPost(PostModel post) {
    _repo.addPost(post);
    state = _repo.getPosts();
  }

  void likePost(String postId, String userId) {
    _repo.toggleLike(postId, userId);
    state = _repo.getPosts();
  }

  void addComment(String postId, CommentModel comment) {
    _repo.addComment(postId, comment);
    state = _repo.getPosts();
  }
}

final communityProvider =
    StateNotifierProvider<CommunityNotifier, List<PostModel>>((ref) {
      return CommunityNotifier(ref.watch(communityRepositoryProvider));
    });
