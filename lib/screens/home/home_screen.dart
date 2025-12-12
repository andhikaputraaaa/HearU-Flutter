import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/common/post_card.dart';
import '../../providers/post_provider.dart';
import '../../main.dart';
import '../post/post_detail_screen.dart';
import 'package:intl/intl.dart';

class HomeScreenContent extends ConsumerStatefulWidget {
  final Function(String)? onViewOtherProfile;
  final VoidCallback? onViewOwnProfile;

  const HomeScreenContent({
    super.key,
    this.onViewOtherProfile,
    this.onViewOwnProfile,
  });

  @override
  ConsumerState<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends ConsumerState<HomeScreenContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    ref.listenManual(postFilterProvider, (previous, next) {
      if (previous != next) {
        ref.read(postsProvider.notifier).loadPosts();
      }
    });
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

  Color _getAvatarColor(String userId) {
    final hash = userId.hashCode;
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

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String postId) {
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
                  _confirmDelete(context, ref, postId);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String postId) {
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
                await ref.read(postsProvider.notifier).deletePost(postId);
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
    final postsAsync = ref.watch(postsProvider);
    final currentFilter = ref.watch(postFilterProvider);

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
          child: Image.asset(
            'assets/images/logo.png',
            height: 80,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.headset_rounded,
                color: Color(0xFF00BCD4),
                size: 50,
              );
            },
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[300], height: 1),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterButton(
                    'Semua',
                    PostFilter.all,
                    currentFilter,
                    ref,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFilterButton(
                    'Following',
                    PostFilter.following,
                    currentFilter,
                    ref,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: postsAsync.when(
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
                      'Gagal memuat postingan',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.refresh(postsProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BCD4),
                      ),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
              data: (posts) {
                if (posts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.post_add, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          currentFilter == PostFilter.following
                              ? 'Belum ada postingan dari Following'
                              : 'Belum ada postingan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentFilter == PostFilter.following
                              ? 'Follow pengguna untuk melihat postingan mereka'
                              : 'Jadilah yang pertama membuat postingan!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(postsProvider.notifier).loadPosts();
                  },
                  color: const Color(0xFF00BCD4),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 8, bottom: 100),
                    itemCount: posts.length,
                    cacheExtent: 500,
                    addAutomaticKeepAlives: true,
                    addRepaintBoundaries: true,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      final displayName = post.isAnonymous
                          ? 'Anonim'
                          : post.user?.displayName ??
                                post.user?.username ??
                                'Unknown';
                      final handle = post.isAnonymous
                          ? ''
                          : '@${post.user?.username ?? 'unknown'}';
                      final isVerified = false;
                      final isOwnPost =
                          post.userId == supabase.auth.currentUser?.id;

                      return PostCard(
                        username: displayName,
                        handle: handle,
                        isVerified: isVerified,
                        content: post.content,
                        timestamp: _formatTimestamp(post.createdAt),
                        likesCount: post.likesCount,
                        commentsCount: post.commentsCount,
                        isLiked: post.isLiked,
                        avatarColor: post.isAnonymous
                            ? Colors.grey
                            : _getAvatarColor(post.userId),
                        isAnonymous: post.isAnonymous,
                        avatarUrl: post.isAnonymous
                            ? null
                            : post.user?.avatarUrl,
                        showDeleteButton: isOwnPost,
                        onDeleteTap: isOwnPost
                            ? () => _showDeleteDialog(context, ref, post.id)
                            : null,
                        onTap: () async {
                          final result = await Navigator.push<String>(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PostDetailScreen(post: post),
                            ),
                          );
                          if (result == 'go_to_profile') {
                            widget.onViewOwnProfile?.call();
                          }
                        },
                        onLikeTap: () async {
                          await ref
                              .read(postsProvider.notifier)
                              .toggleLike(post.id, post.isLiked);
                        },
                        onAvatarTap: () {
                          if (!post.isAnonymous) {
                            if (post.userId == supabase.auth.currentUser?.id) {
                              widget.onViewOwnProfile?.call();
                            } else {
                              widget.onViewOtherProfile?.call(post.userId);
                            }
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(
    String label,
    PostFilter filter,
    PostFilter currentFilter,
    WidgetRef ref,
  ) {
    final isSelected = filter == currentFilter;
    return GestureDetector(
      onTap: () {
        if (filter != currentFilter) {
          ref.read(postFilterProvider.notifier).state = filter;
          ref.read(postsProvider.notifier).loadPosts();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00BCD4) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const HomeScreenContent();
  }
}
