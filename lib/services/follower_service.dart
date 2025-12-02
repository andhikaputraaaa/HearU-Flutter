import '../main.dart';
import 'notification_service.dart';

class FollowerService {
  final NotificationService _notificationService = NotificationService();

  // Follow a user
  Future<void> followUser(String targetUserId) async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await supabase.from('followers').insert({
        'follower_id': currentUserId,
        'following_id': targetUserId,
      });

      // Create follow notification
      await _notificationService.createNotification(
        userId: targetUserId,
        actorId: currentUserId,
        type: 'follow',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Unfollow a user
  Future<void> unfollowUser(String targetUserId) async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await supabase
          .from('followers')
          .delete()
          .eq('follower_id', currentUserId)
          .eq('following_id', targetUserId);

      // Delete follow notification
      await _notificationService.deleteNotification(
        actorId: currentUserId,
        type: 'follow',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Check if current user is following a target user
  Future<bool> isFollowing(String targetUserId) async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) return false;

      final response = await supabase
          .from('followers')
          .select('id')
          .eq('follower_id', currentUserId)
          .eq('following_id', targetUserId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Get followers count for a user
  Future<int> getFollowersCount(String userId) async {
    try {
      final response = await supabase
          .from('followers')
          .select('id')
          .eq('following_id', userId);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  // Get following count for a user
  Future<int> getFollowingCount(String userId) async {
    try {
      final response = await supabase
          .from('followers')
          .select('id')
          .eq('follower_id', userId);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  // Get user stats (followers count, following count, isFollowing)
  Future<Map<String, dynamic>> getUserFollowStats(String userId) async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;

      // Get followers count
      final followersResponse = await supabase
          .from('followers')
          .select('id')
          .eq('following_id', userId);
      final followersCount = (followersResponse as List).length;

      // Get following count
      final followingResponse = await supabase
          .from('followers')
          .select('id')
          .eq('follower_id', userId);
      final followingCount = (followingResponse as List).length;

      // Check if current user is following this user
      bool isFollowing = false;
      if (currentUserId != null && currentUserId != userId) {
        final followingCheck = await supabase
            .from('followers')
            .select('id')
            .eq('follower_id', currentUserId)
            .eq('following_id', userId)
            .maybeSingle();
        isFollowing = followingCheck != null;
      }

      return {
        'followers_count': followersCount,
        'following_count': followingCount,
        'is_following': isFollowing,
      };
    } catch (e) {
      return {
        'followers_count': 0,
        'following_count': 0,
        'is_following': false,
      };
    }
  }
}
