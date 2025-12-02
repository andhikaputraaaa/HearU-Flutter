import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/follower_service.dart';

// Follower service provider
final followerServiceProvider = Provider<FollowerService>((ref) {
  return FollowerService();
});

// Follow state for a specific user
class FollowState {
  final bool isFollowing;
  final int followersCount;
  final int followingCount;
  final bool isLoading;

  FollowState({
    this.isFollowing = false,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isLoading = false,
  });

  FollowState copyWith({
    bool? isFollowing,
    int? followersCount,
    int? followingCount,
    bool? isLoading,
  }) {
    return FollowState(
      isFollowing: isFollowing ?? this.isFollowing,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Follow notifier for a specific user
class FollowNotifier extends StateNotifier<FollowState> {
  final FollowerService _followerService;
  final String userId;

  FollowNotifier(this._followerService, this.userId) : super(FollowState()) {
    loadFollowState();
  }

  Future<void> loadFollowState() async {
    try {
      final stats = await _followerService.getUserFollowStats(userId);
      state = FollowState(
        isFollowing: stats['is_following'] as bool,
        followersCount: stats['followers_count'] as int,
        followingCount: stats['following_count'] as int,
      );
    } catch (e) {
      // Keep current state on error
    }
  }

  Future<void> toggleFollow() async {
    if (state.isLoading) return;

    // Optimistic update
    final wasFollowing = state.isFollowing;
    state = state.copyWith(
      isLoading: true,
      isFollowing: !wasFollowing,
      followersCount: wasFollowing
          ? state.followersCount - 1
          : state.followersCount + 1,
    );

    try {
      if (wasFollowing) {
        await _followerService.unfollowUser(userId);
      } else {
        await _followerService.followUser(userId);
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      // Revert on error
      state = state.copyWith(
        isLoading: false,
        isFollowing: wasFollowing,
        followersCount: wasFollowing
            ? state.followersCount + 1
            : state.followersCount - 1,
      );
      rethrow;
    }
  }
}

// Follow provider factory for specific user
final followProvider =
    StateNotifierProvider.family<FollowNotifier, FollowState, String>((
      ref,
      userId,
    ) {
      final followerService = ref.watch(followerServiceProvider);
      return FollowNotifier(followerService, userId);
    });
