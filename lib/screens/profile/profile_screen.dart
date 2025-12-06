import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';
import '../../main.dart';
import '../../widgets/common/post_card.dart';
import '../post/post_detail_screen.dart';
import 'settings_screen.dart';

// User posts state notifier
class UserPostsNotifier extends StateNotifier<AsyncValue<List<PostModel>>> {
  final PostService _postService;
  final String? _userId;

  UserPostsNotifier(this._postService, this._userId)
    : super(const AsyncValue.loading()) {
    loadPosts();
  }

  Future<void> loadPosts() async {
    if (_userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final posts = await _postService.getUserPosts(_userId);
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

  Future<void> deletePost(String postId) async {
    try {
      await _postService.deletePost(postId);
      await loadPosts();
    } catch (e) {
      rethrow;
    }
  }
}

// Provider untuk mendapatkan postingan user saat ini
final userPostsProvider =
    StateNotifierProvider<UserPostsNotifier, AsyncValue<List<PostModel>>>((
      ref,
    ) {
      final userId = supabase.auth.currentUser?.id;
      final postService = ref.watch(postServiceProvider);
      return UserPostsNotifier(postService, userId);
    });

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.onRefreshRequested});

  final void Function(VoidCallback)? onRefreshRequested;

  @override
  ConsumerState<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ScrollController _scrollController = ScrollController();

  // Method untuk refresh data dari luar (parent widget)
  Future<void> refreshData() async {
    ref.invalidate(currentUserProfileProvider);
    await ref.read(userPostsProvider.notifier).loadPosts();
    _scrollToTop();
  }

  @override
  void initState() {
    super.initState();
    // Register callback untuk refresh dari parent
    widget.onRefreshRequested?.call(refreshData);
  }

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

  void _showDeleteDialog(BuildContext context, String postId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Hapus Postingan',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, postId);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Postingan'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus postingan ini? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(userPostsProvider.notifier).deletePost(postId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Postingan berhasil dihapus'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus postingan: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final userPostsAsync = ref.watch(userPostsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: 'Pengaturan',
          ),
        ],
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
              ref.invalidate(currentUserProfileProvider);
              await ref.read(userPostsProvider.notifier).loadPosts();
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
                        // Followers & Following
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatItem(
                              count: userProfile.followersCount,
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
                              count: userProfile.followingCount,
                              label: 'Mengikuti',
                            ),
                          ],
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

                  // User Posts (filtered from all posts)
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
                          final isAnonymous = post.isAnonymous;
                          final displayName = isAnonymous
                              ? 'Anonim'
                              : (userProfile.displayName ??
                                    userProfile.username);
                          final username = isAnonymous
                              ? ''
                              : '@${userProfile.username}';

                          return PostCard(
                            username: displayName,
                            handle: username,
                            isVerified: false,
                            content: post.content,
                            timestamp: _formatTimestamp(post.createdAt),
                            likesCount: post.likesCount,
                            commentsCount: post.commentsCount,
                            isLiked: post.isLiked,
                            avatarColor: isAnonymous
                                ? Colors.grey
                                : _getAvatarColor(userProfile.id),
                            isAnonymous: isAnonymous,
                            avatarUrl: isAnonymous
                                ? null
                                : userProfile.avatarUrl,
                            showDeleteButton: true,
                            onDeleteTap: () =>
                                _showDeleteDialog(context, post.id),
                            onTap: () async {
                              // No action needed for 'go_to_profile' since we're already on profile
                              await Navigator.push<String>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PostDetailScreen(post: post),
                                ),
                              );
                            },
                            onLikeTap: () async {
                              await ref
                                  .read(userPostsProvider.notifier)
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
