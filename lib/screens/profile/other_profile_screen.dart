import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/post_provider.dart';
import '../../providers/follower_provider.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../services/user_service.dart';
import '../../services/post_service.dart';
import '../../widgets/common/post_card.dart';
import '../post/post_detail_screen.dart';

// Provider untuk mendapatkan profil user lain berdasarkan userId
final otherUserProfileProvider = FutureProvider.family<UserModel?, String>((
  ref,
  userId,
) async {
  final userService = UserService();
  return await userService.getUserById(userId);
});

// Other user posts state notifier
class OtherUserPostsNotifier
    extends StateNotifier<AsyncValue<List<PostModel>>> {
  final PostService _postService;
  final String _userId;

  OtherUserPostsNotifier(this._postService, this._userId)
    : super(const AsyncValue.loading()) {
    loadPosts();
  }

  Future<void> loadPosts() async {
    state = const AsyncValue.loading();
    try {
      final allPosts = await _postService.getUserPosts(_userId);
      // Filter out anonymous posts for other user's profile
      final posts = allPosts.where((post) => !post.isAnonymous).toList();
      state = AsyncValue.data(posts);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
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
}

// Provider untuk mendapatkan postingan user lain (non-anonymous)
final otherUserPostsProvider =
    StateNotifierProvider.family<
      OtherUserPostsNotifier,
      AsyncValue<List<PostModel>>,
      String
    >((ref, userId) {
      final postService = ref.watch(postServiceProvider);
      return OtherUserPostsNotifier(postService, userId);
    });

class OtherProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  final VoidCallback? onBack;
  final Function(String)? onViewOtherProfile;

  const OtherProfileScreen({
    super.key,
    required this.userId,
    this.onBack,
    this.onViewOtherProfile,
  });

  @override
  ConsumerState<OtherProfileScreen> createState() => _OtherProfileScreenState();
}

class _OtherProfileScreenState extends ConsumerState<OtherProfileScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return DateFormat('HH:mm  dd MMMM yyyy', 'id_ID').format(timestamp);
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  Color _getAvatarColor(String visibleId) {
    final hash = visibleId.hashCode;
    final colors = [
      Colors.black,
      const Color(0xFF0D47A1),
      const Color(0xFFE65100),
      const Color(0xFF1B5E20),
      const Color(0xFF4A148C),
      const Color(0xFFB71C1C),
    ];
    return colors[hash.abs() % colors.length];
  }

  Widget _buildStatItem({required int count, required String label}) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(otherUserProfileProvider(widget.userId));
    final userPostsAsync = ref.watch(otherUserPostsProvider(widget.userId));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        centerTitle: true,
        title: GestureDetector(
          onTap: _scrollToTop,
          child: const Text(
            'Profil',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[300], height: 1),
        ),
      ),
      body: userProfileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Gagal memuat profil',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        data: (userProfile) {
          if (userProfile == null) {
            return const Center(child: Text('User tidak ditemukan'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(otherUserProfileProvider(widget.userId));
              await ref
                  .read(otherUserPostsProvider(widget.userId).notifier)
                  .loadPosts();
            },
            color: const Color(0xFF00BCD4),
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Profile Header Section
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        // Banner Image
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.bottomCenter,
                          children: [
                            // Banner
                            Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                image:
                                    (userProfile.bannerUrl != null &&
                                        userProfile.bannerUrl!.isNotEmpty)
                                    ? DecorationImage(
                                        image: NetworkImage(
                                          userProfile.bannerUrl!,
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : const DecorationImage(
                                        image: AssetImage(
                                          'assets/images/default_banner.jpg',
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            // Avatar
                            Positioned(
                              bottom: -40,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundColor: _getAvatarColor(
                                    userProfile.id,
                                  ),
                                  backgroundImage:
                                      (userProfile.avatarUrl != null &&
                                          userProfile.avatarUrl!.isNotEmpty)
                                      ? NetworkImage(userProfile.avatarUrl!)
                                      : null,
                                  child:
                                      (userProfile.avatarUrl == null ||
                                          userProfile.avatarUrl!.isEmpty)
                                      ? Text(
                                          userProfile.username.isNotEmpty
                                              ? userProfile.username[0]
                                                    .toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),
                        // Display Name
                        Text(
                          userProfile.displayName ?? userProfile.username,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Username
                        Text(
                          '@${userProfile.username}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Followers & Following with Follow State
                        Consumer(
                          builder: (context, ref, child) {
                            final followState = ref.watch(
                              followProvider(widget.userId),
                            );
                            return Column(
                              children: [
                                // Followers & Following Stats
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildStatItem(
                                      count: followState.followersCount,
                                      label: 'Pengikut',
                                    ),
                                    Container(
                                      width: 1,
                                      height: 20,
                                      color: Colors.grey[300],
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                      ),
                                    ),
                                    _buildStatItem(
                                      count: followState.followingCount,
                                      label: 'Mengikuti',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Follow/Unfollow Button
                                Material(
                                  color: followState.isFollowing
                                      ? Colors.grey[200]
                                      : const Color(0xFF00BCD4),
                                  borderRadius: BorderRadius.circular(20),
                                  child: InkWell(
                                    onTap: followState.isLoading
                                        ? null
                                        : () {
                                            ref
                                                .read(
                                                  followProvider(
                                                    widget.userId,
                                                  ).notifier,
                                                )
                                                .toggleFollow();
                                          },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      width: 120,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: followState.isFollowing
                                            ? Border.all(
                                                color: Colors.grey[400]!,
                                              )
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: followState.isLoading
                                          ? SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(
                                                      followState.isFollowing
                                                          ? Colors.grey[600]!
                                                          : Colors.white,
                                                    ),
                                              ),
                                            )
                                          : Text(
                                              followState.isFollowing
                                                  ? 'Mengikuti'
                                                  : 'Ikuti',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: followState.isFollowing
                                                    ? Colors.black87
                                                    : Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        // Bio
                        if (userProfile.bio != null &&
                            userProfile.bio!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              userProfile.bio!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // Postingan Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    color: Colors.white,
                    margin: const EdgeInsets.only(top: 8),
                    child: const Center(
                      child: Text(
                        'Postingan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),

                  // User Posts (filtered - exclude anonymous posts)
                  userPostsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF00BCD4),
                          ),
                        ),
                      ),
                    ),
                    error: (error, stack) => Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'Gagal memuat postingan',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                    data: (userPosts) {
                      if (userPosts.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.post_add,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Belum ada postingan',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: userPosts.length,
                        cacheExtent: 500,
                        addAutomaticKeepAlives: true,
                        addRepaintBoundaries: true,
                        itemBuilder: (context, index) {
                          final post = userPosts[index];
                          final displayName =
                              userProfile.displayName ?? userProfile.username;
                          final username = '@${userProfile.username}';

                          return PostCard(
                            username: displayName,
                            handle: username,
                            isVerified: false,
                            content: post.content,
                            timestamp: _formatTimestamp(post.createdAt),
                            likesCount: post.likesCount,
                            commentsCount: post.commentsCount,
                            isLiked: post.isLiked,
                            avatarColor: _getAvatarColor(userProfile.id),
                            isAnonymous: false,
                            avatarUrl: userProfile.avatarUrl,
                            onTap: () async {
                              final result = await Navigator.push<String>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PostDetailScreen(post: post),
                                ),
                              );
                              // Handle navigation back with profile request
                              // OtherProfileScreen doesn't need to handle own profile navigation
                              // since clicking on posts in this screen are already this user's posts
                              if (result == 'go_to_profile' &&
                                  widget.onBack != null) {
                                widget.onBack!();
                              }
                            },
                            onLikeTap: () async {
                              await ref
                                  .read(
                                    otherUserPostsProvider(
                                      widget.userId,
                                    ).notifier,
                                  )
                                  .toggleLike(post.id, post.isLiked);
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
