import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comment_model.dart';
import '../services/comment_service.dart';

// Comment service provider
final commentServiceProvider = Provider<CommentService>((ref) {
  return CommentService();
});

// Comments for a specific post
class CommentsNotifier extends StateNotifier<AsyncValue<List<CommentModel>>> {
  final CommentService _commentService;
  final String postId;

  CommentsNotifier(this._commentService, this.postId)
    : super(const AsyncValue.loading()) {
    loadComments();
  }

  Future<void> loadComments() async {
    state = const AsyncValue.loading();
    try {
      final comments = await _commentService.getComments(postId);
      state = AsyncValue.data(comments);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addComment(String content) async {
    try {
      await _commentService.createComment(postId: postId, content: content);
      // Reload comments after adding
      await loadComments();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await _commentService.deleteComment(commentId);
      // Reload comments after deletion
      await loadComments();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleLike(String commentId, bool isCurrentlyLiked) async {
    // Optimistic update - update state immediately
    state.whenData((comments) {
      final updatedComments = comments.map((comment) {
        if (comment.id == commentId) {
          return comment.copyWith(
            isLiked: !isCurrentlyLiked,
            likesCount: isCurrentlyLiked
                ? comment.likesCount - 1
                : comment.likesCount + 1,
          );
        }
        return comment;
      }).toList();
      state = AsyncValue.data(updatedComments);
    });

    try {
      if (isCurrentlyLiked) {
        await _commentService.unlikeComment(commentId);
      } else {
        await _commentService.likeComment(commentId);
      }
    } catch (e) {
      // Revert on error
      state.whenData((comments) {
        final revertedComments = comments.map((comment) {
          if (comment.id == commentId) {
            return comment.copyWith(
              isLiked: isCurrentlyLiked,
              likesCount: isCurrentlyLiked
                  ? comment.likesCount + 1
                  : comment.likesCount - 1,
            );
          }
          return comment;
        }).toList();
        state = AsyncValue.data(revertedComments);
      });
      rethrow;
    }
  }
}

// Comments provider factory
final commentsProvider =
    StateNotifierProvider.family<
      CommentsNotifier,
      AsyncValue<List<CommentModel>>,
      String
    >((ref, postId) {
      final commentService = ref.watch(commentServiceProvider);
      return CommentsNotifier(commentService, postId);
    });
