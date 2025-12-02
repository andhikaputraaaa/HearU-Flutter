import '../main.dart';
import '../models/comment_model.dart';
import '../core/constants/supabase_constants.dart';
import 'notification_service.dart';

class CommentService {
  final NotificationService _notificationService = NotificationService();

  // Create comment
  Future<CommentModel> createComment({
    required String postId,
    required String content,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await supabase
          .from(SupabaseConstants.commentsTable)
          .insert({'post_id': postId, 'user_id': userId, 'content': content})
          .select('*, users(*)')
          .single();

      final comment = CommentModel.fromJson(response);

      // Get post owner and create notification
      final postResponse = await supabase
          .from('posts')
          .select('user_id')
          .eq('id', postId)
          .single();

      final postOwnerId = postResponse['user_id'] as String;

      if (postOwnerId != userId) {
        await _notificationService.createNotification(
          userId: postOwnerId,
          actorId: userId,
          type: 'comment',
          postId: postId,
          commentId: comment.id,
        );
      }

      return comment;
    } catch (e) {
      rethrow;
    }
  }

  // Get comments for a post
  Future<List<CommentModel>> getComments(String postId) async {
    try {
      final userId = supabase.auth.currentUser?.id;

      final response = await supabase
          .from(SupabaseConstants.commentsTable)
          .select('*, users(*)')
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      // Get comment IDs
      final commentIds = (response as List)
          .map((c) => c['id'] as String)
          .toList();

      // Fetch likes count for each comment
      final likesCountResponse = await supabase
          .from('comment_likes')
          .select('comment_id')
          .inFilter('comment_id', commentIds);

      // Count likes per comment
      final likesCountMap = <String, int>{};
      for (final like in likesCountResponse as List) {
        final commentId = like['comment_id'] as String;
        likesCountMap[commentId] = (likesCountMap[commentId] ?? 0) + 1;
      }

      // Fetch user's likes if logged in
      Set<String> userLikedComments = {};
      if (userId != null) {
        final userLikesResponse = await supabase
            .from('comment_likes')
            .select('comment_id')
            .eq('user_id', userId)
            .inFilter('comment_id', commentIds);

        userLikedComments = (userLikesResponse as List)
            .map((like) => like['comment_id'] as String)
            .toSet();
      }

      return response.map((json) {
        final commentId = json['id'] as String;
        return CommentModel.fromJson({
          ...json,
          'likes_count': likesCountMap[commentId] ?? 0,
          'is_liked': userLikedComments.contains(commentId),
        });
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Delete comment
  Future<void> deleteComment(String commentId) async {
    try {
      await supabase
          .from(SupabaseConstants.commentsTable)
          .delete()
          .eq('id', commentId);
    } catch (e) {
      rethrow;
    }
  }

  // Like comment
  Future<void> likeComment(String commentId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await supabase.from('comment_likes').insert({
        'user_id': userId,
        'comment_id': commentId,
      });

      // Get comment owner and post_id for notification
      final commentResponse = await supabase
          .from('comments')
          .select('user_id, post_id')
          .eq('id', commentId)
          .single();

      final commentOwnerId = commentResponse['user_id'] as String;
      final postId = commentResponse['post_id'] as String?;

      // Create notification if not liking own comment
      if (commentOwnerId != userId) {
        await _notificationService.createNotification(
          userId: commentOwnerId,
          actorId: userId,
          type: 'comment_like',
          postId: postId,
          commentId: commentId,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Unlike comment
  Future<void> unlikeComment(String commentId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await supabase
          .from('comment_likes')
          .delete()
          .eq('user_id', userId)
          .eq('comment_id', commentId);

      // Delete the notification
      await _notificationService.deleteNotification(
        actorId: userId,
        type: 'comment_like',
        commentId: commentId,
      );
    } catch (e) {
      rethrow;
    }
  }
}
