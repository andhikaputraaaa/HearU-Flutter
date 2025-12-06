import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/user_model.dart';
import '../core/constants/supabase_constants.dart';
import 'follower_service.dart';

class UserService {
  final FollowerService _followerService = FollowerService();

  // Get user by ID with follower stats
  Future<UserModel?> getUserById(String userId) async {
    try {
      final response = await supabase
          .from(SupabaseConstants.usersTable)
          .select()
          .eq('id', userId)
          .single();

      // Get follower stats
      final stats = await _followerService.getUserFollowStats(userId);

      return UserModel.fromJson({
        ...response,
        'followers_count': stats['followers_count'],
        'following_count': stats['following_count'],
        'is_following': stats['is_following'],
      });
    } catch (e) {
      return null;
    }
  }

  // Get current user profile
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      return await getUserById(userId);
    } catch (e) {
      return null;
    }
  }

  // Upload image to Supabase Storage
  Future<String> uploadImage(File file, String bucket, String path) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final fileExt = file.path.split('.').last;
      final fileName =
          '$path/$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await supabase.storage
          .from(bucket)
          .upload(
            fileName,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final imageUrl = supabase.storage.from(bucket).getPublicUrl(fileName);
      return imageUrl;
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<UserModel> updateProfile({
    String? username,
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? bannerUrl,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (displayName != null) updates['display_name'] = displayName;
      if (bio != null) updates['bio'] = bio;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (bannerUrl != null) updates['banner_url'] = bannerUrl;

      final response = await supabase
          .from(SupabaseConstants.usersTable)
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Check if username exists
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;
      final response = await supabase
          .from(SupabaseConstants.usersTable)
          .select('id')
          .eq('username', username)
          .maybeSingle();

      // Username is available if no result or it's the current user's username
      if (response == null) return true;
      return response['id'] == currentUserId;
    } catch (e) {
      return false;
    }
  }

  // Search users by username or display name
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final response = await supabase
          .from(SupabaseConstants.usersTable)
          .select()
          .or('username.ilike.%$query%,display_name.ilike.%$query%')
          .order('username')
          .limit(50);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get current user ID
  String? getCurrentUserId() {
    return supabase.auth.currentUser?.id;
  }
}
