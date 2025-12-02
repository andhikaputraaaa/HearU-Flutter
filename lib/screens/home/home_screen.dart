import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/common/post_card.dart';
import '../../providers/post_provider.dart';
import '../post/post_detail_screen.dart';
import 'package:intl/intl.dart';

// This is now a content widget without navbar
class HomeScreenContent extends ConsumerStatefulWidget {
  const HomeScreenContent({super.key});

  @override
  ConsumerState<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends ConsumerState<HomeScreenContent> {
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

  Color _getAvatarColor(String userId) {
    // Generate color based on userId hash
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

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(postsProvider);

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
      body: postsAsync.when(
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
                    'Belum ada postingan',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Jadilah yang pertama membuat postingan!',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
                final isVerified =
                    false; // Set to false for now, can add field later

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
                  avatarUrl: post.isAnonymous ? null : post.user?.avatarUrl,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailScreen(post: post),
                      ),
                    );
                  },
                  onLikeTap: () async {
                    await ref.read(postsProvider.notifier).toggleLike(post.id, post.isLiked);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// Keep backward compatibility - redirect to MainScreen
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This will be replaced by MainScreen in app.dart
    return const HomeScreenContent();
  }
}
