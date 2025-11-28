import '../main.dart';
import '../models/user_model.dart';
import '../core/constants/supabase_constants.dart';

class UserService {
  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final response = await supabase
          .from(SupabaseConstants.usersTable)
          .select()
          .eq('id', userId)
          .single();

      return UserModel.fromJson(response);
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

  // Update user profile
  Future<UserModel> updateProfile({
    String? username,
    String? displayName,
    String? bio,
    String? avatarUrl,
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
      final response = await supabase
          .from(SupabaseConstants.usersTable)
          .select('id')
          .eq('username', username)
          .maybeSingle();

      return response == null;
    } catch (e) {
      return false;
    }
  }
}