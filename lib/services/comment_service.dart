import '../main.dart';
import '../models/comment_model.dart';
import '../core/constants/supabase_constants.dart';

class CommentService {
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
          .insert({
            'post_id': postId,
            'user_id': userId,
            'content': content,
          })
          .select('*, users(*)')
          .single();

      return CommentModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get comments for a post
  Future<List<CommentModel>> getComments(String postId) async {
    try {
      final response = await supabase
          .from(SupabaseConstants.commentsTable)
          .select('*, users(*)')
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => CommentModel.fromJson(json))
          .toList();
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
    } catch (e) {
      rethrow;
    }
  }
}
