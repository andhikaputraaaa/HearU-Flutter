import '../main.dart';
import '../models/post_model.dart';
import '../core/constants/supabase_constants.dart';
import 'notification_service.dart';

class PostService {
  final NotificationService _notificationService = NotificationService();
  // Create post
  Future<PostModel> createPost({
    required String content,
    required bool isAnonymous,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await supabase
          .from(SupabaseConstants.postsTable)
          .insert({
            'user_id': userId,
            'content': content,
            'is_anonymous': isAnonymous,
          })
          .select('*, users(*)')
          .single();

      return PostModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get all posts (home feed)
  Future<List<PostModel>> getPosts({int limit = 20, int offset = 0}) async {
    try {
      final userId = supabase.auth.currentUser?.id;

      final response = await supabase
          .from(SupabaseConstants.postsTable)
          .select('''
            *,
            users(*),
            likes(count),
            comments(count)
          ''')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final posts = (response as List).map((json) {
        // Count likes and comments
        final likesCount = json['likes']?[0]?['count'] ?? 0;
        final commentsCount = json['comments']?[0]?['count'] ?? 0;

        return PostModel.fromJson({
          ...json,
          'likes_count': likesCount,
          'comments_count': commentsCount,
        });
      }).toList();

      // Check if current user liked each post
      if (userId != null) {
        final postIds = posts.map((p) => p.id).toList();
        final userLikes = await supabase
            .from(SupabaseConstants.likesTable)
            .select('post_id')
            .eq('user_id', userId)
            .inFilter('post_id', postIds);

        final likedPostIds = (userLikes as List)
            .map((like) => like['post_id'] as String)
            .toSet();

        return posts.map((post) {
          return post.copyWith(isLiked: likedPostIds.contains(post.id));
        }).toList();
      }

      return posts;
    } catch (e) {
      rethrow;
    }
  }

  // Get user posts
  Future<List<PostModel>> getUserPosts(String userId) async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;

      final response = await supabase
          .from(SupabaseConstants.postsTable)
          .select('''
            *,
            users(*),
            likes(count),
            comments(count)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final posts = (response as List).map((json) {
        final likesCount = json['likes']?[0]?['count'] ?? 0;
        final commentsCount = json['comments']?[0]?['count'] ?? 0;

        return PostModel.fromJson({
          ...json,
          'likes_count': likesCount,
          'comments_count': commentsCount,
        });
      }).toList();

      // Check if current user liked each post
      if (currentUserId != null && posts.isNotEmpty) {
        final postIds = posts.map((p) => p.id).toList();
        final userLikes = await supabase
            .from(SupabaseConstants.likesTable)
            .select('post_id')
            .eq('user_id', currentUserId)
            .inFilter('post_id', postIds);

        final likedPostIds = (userLikes as List)
            .map((like) => like['post_id'] as String)
            .toSet();

        return posts.map((post) {
          return post.copyWith(isLiked: likedPostIds.contains(post.id));
        }).toList();
      }

      return posts;
    } catch (e) {
      rethrow;
    }
  }

  // Get posts from following users only
  Future<List<PostModel>> getFollowingPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Get list of users that current user is following
      final followingResponse = await supabase
          .from('followers')
          .select('following_id')
          .eq('follower_id', userId);

      final followingIds = (followingResponse as List)
          .map((f) => f['following_id'] as String)
          .toList();

      if (followingIds.isEmpty) {
        return [];
      }

      // Get posts from following users (exclude anonymous posts)
      final response = await supabase
          .from(SupabaseConstants.postsTable)
          .select('''
            *,
            users(*),
            likes(count),
            comments(count)
          ''')
          .inFilter('user_id', followingIds)
          .eq('is_anonymous', false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final posts = (response as List).map((json) {
        final likesCount = json['likes']?[0]?['count'] ?? 0;
        final commentsCount = json['comments']?[0]?['count'] ?? 0;

        return PostModel.fromJson({
          ...json,
          'likes_count': likesCount,
          'comments_count': commentsCount,
        });
      }).toList();

      // Check if current user liked each post
      final postIds = posts.map((p) => p.id).toList();
      if (postIds.isNotEmpty) {
        final userLikes = await supabase
            .from(SupabaseConstants.likesTable)
            .select('post_id')
            .eq('user_id', userId)
            .inFilter('post_id', postIds);

        final likedPostIds = (userLikes as List)
            .map((like) => like['post_id'] as String)
            .toSet();

        return posts.map((post) {
          return post.copyWith(isLiked: likedPostIds.contains(post.id));
        }).toList();
      }

      return posts;
    } catch (e) {
      rethrow;
    }
  }

  // Like post
  Future<void> likePost(String postId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Check if already liked to prevent duplicate
      final existingLike = await supabase
          .from(SupabaseConstants.likesTable)
          .select('id')
          .eq('user_id', userId)
          .eq('post_id', postId)
          .maybeSingle();

      // If already liked, just return without error
      if (existingLike != null) {
        return;
      }

      await supabase.from(SupabaseConstants.likesTable).insert({
        'user_id': userId,
        'post_id': postId,
      });

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
          type: 'like',
          postId: postId,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Unlike post
  Future<void> unlikePost(String postId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await supabase
          .from(SupabaseConstants.likesTable)
          .delete()
          .eq('user_id', userId)
          .eq('post_id', postId);

      // Delete notification
      await _notificationService.deleteNotification(
        actorId: userId,
        type: 'like',
        postId: postId,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Delete post
  Future<void> deletePost(String postId) async {
    try {
      await supabase
          .from(SupabaseConstants.postsTable)
          .delete()
          .eq('id', postId);
    } catch (e) {
      rethrow;
    }
  }

  // Search posts by content
  Future<List<PostModel>> searchPosts(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final userId = supabase.auth.currentUser?.id;

      final response = await supabase
          .from(SupabaseConstants.postsTable)
          .select('''
            *,
            users(*),
            likes(count),
            comments(count)
          ''')
          .ilike('content', '%$query%')
          .order('created_at', ascending: false)
          .limit(50);

      final posts = (response as List).map((json) {
        final likesCount = json['likes']?[0]?['count'] ?? 0;
        final commentsCount = json['comments']?[0]?['count'] ?? 0;

        return PostModel.fromJson({
          ...json,
          'likes_count': likesCount,
          'comments_count': commentsCount,
        });
      }).toList();

      // Check if current user liked each post
      if (userId != null && posts.isNotEmpty) {
        final postIds = posts.map((p) => p.id).toList();
        final userLikes = await supabase
            .from(SupabaseConstants.likesTable)
            .select('post_id')
            .eq('user_id', userId)
            .inFilter('post_id', postIds);

        final likedPostIds = (userLikes as List)
            .map((like) => like['post_id'] as String)
            .toSet();

        return posts.map((post) {
          return post.copyWith(isLiked: likedPostIds.contains(post.id));
        }).toList();
      }

      return posts;
    } catch (e) {
      return [];
    }
  }
}
