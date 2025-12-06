import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';

// Post service provider
final postServiceProvider = Provider<PostService>((ref) {
  return PostService();
});

// Post filter enum
enum PostFilter { all, following }

// Post filter state provider
final postFilterProvider = StateProvider<PostFilter>((ref) => PostFilter.all);

// Posts list state notifier
class PostsNotifier extends StateNotifier<AsyncValue<List<PostModel>>> {
  final PostService _postService;
  final Ref _ref;

  PostsNotifier(this._postService, this._ref)
    : super(const AsyncValue.loading()) {
    loadPosts();
  }

  Future<void> loadPosts() async {
    state = const AsyncValue.loading();
    try {
      final filter = _ref.read(postFilterProvider);
      final posts = filter == PostFilter.following
          ? await _postService.getFollowingPosts()
          : await _postService.getPosts();
      state = AsyncValue.data(posts);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createPost({
    required String content,
    required bool isAnonymous,
  }) async {
    try {
      await _postService.createPost(content: content, isAnonymous: isAnonymous);
      // Reload posts after creating
      await loadPosts();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleLike(String postId, bool isCurrentlyLiked) async {
    // Optimistic update - update state immediately
    state.whenData((posts) {
      final updatedPosts = posts.map((post) {
        if (post.id == postId) {
          return post.copyWith(
            isLiked: !isCurrentlyLiked,
            likesCount: isCurrentlyLiked
                ? post.likesCount - 1
                : post.likesCount + 1,
          );
        }
        return post;
      }).toList();
      state = AsyncValue.data(updatedPosts);
    });

    try {
      if (isCurrentlyLiked) {
        await _postService.unlikePost(postId);
      } else {
        await _postService.likePost(postId);
      }
    } catch (e) {
      // Revert on error
      state.whenData((posts) {
        final revertedPosts = posts.map((post) {
          if (post.id == postId) {
            return post.copyWith(
              isLiked: isCurrentlyLiked,
              likesCount: isCurrentlyLiked
                  ? post.likesCount + 1
                  : post.likesCount - 1,
            );
          }
          return post;
        }).toList();
        state = AsyncValue.data(revertedPosts);
      });
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _postService.deletePost(postId);
      // Reload posts after deletion
      await loadPosts();
    } catch (e) {
      rethrow;
    }
  }
}

// Posts provider
final postsProvider =
    StateNotifierProvider<PostsNotifier, AsyncValue<List<PostModel>>>((ref) {
      final postService = ref.watch(postServiceProvider);
      return PostsNotifier(postService, ref);
    });
