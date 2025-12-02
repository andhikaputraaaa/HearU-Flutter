import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all notifications for current user
  Future<List<NotificationModel>> getNotifications() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('notifications')
          .select('''
            *,
            actor:actor_id(username, display_name, avatar_url),
            post:post_id(content)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      // If join fails, try simple query
      final response = await _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    }
  }

  // Get unread notification count
  Future<int> getUnreadCount() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;

    final response = await _supabase
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);

    return (response as List).length;
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  // Mark single notification as read
  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  // Create notification (called when someone follows, likes, or comments)
  Future<void> createNotification({
    required String userId,
    required String actorId,
    required String type,
    String? postId,
    String? commentId,
  }) async {
    // Don't create notification for own actions
    if (userId == actorId) return;

    await _supabase.from('notifications').insert({
      'user_id': userId,
      'actor_id': actorId,
      'type': type,
      'post_id': postId,
      'comment_id': commentId,
      'is_read': false,
    });
  }

  // Delete notification (e.g., when unfollowing or unliking)
  Future<void> deleteNotification({
    required String actorId,
    required String type,
    String? postId,
    String? commentId,
  }) async {
    var query = _supabase
        .from('notifications')
        .delete()
        .eq('actor_id', actorId)
        .eq('type', type);

    if (postId != null) {
      query = query.eq('post_id', postId);
    }

    if (commentId != null) {
      query = query.eq('comment_id', commentId);
    }

    await query;
  }
}
