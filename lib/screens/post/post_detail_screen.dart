import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/post_model.dart';
import '../../widgets/common/post_card.dart';
import '../../widgets/common/comment_card.dart';
import '../../providers/comment_provider.dart';
import '../../providers/post_provider.dart';
import '../../main.dart';
import 'package:intl/intl.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final PostModel post;

  const PostDetailScreen({
    super.key,
    required this.post,
  });

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
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
  void _handleAddComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus login untuk berkomentar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref
          .read(commentsProvider(widget.post.id).notifier)
          .addComment(_commentController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Komentar berhasil ditambahkan!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        _commentController.clear();
        _commentFocus.unfocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan komentar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.post.isAnonymous
        ? 'Anonim'
        : widget.post.user?.username ?? 'Unknown';
    final handle = widget.post.isAnonymous
        ? ''
        : '@${widget.post.user?.username ?? 'unknown'}';
    final isVerified = false;

    // Get comments from provider
    final commentsAsync = ref.watch(commentsProvider(widget.post.id));
    
    // Get updated post data from posts provider
    final postsAsync = ref.watch(postsProvider);
    final currentPost = postsAsync.maybeWhen(
      data: (posts) => posts.firstWhere(
        (p) => p.id == widget.post.id,
        orElse: () => widget.post,
      ),
      orElse: () => widget.post,
    );

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Postingan',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[300],
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              children: [
                // Post Card with dynamic counter
                PostCard(
                  username: username,
                  handle: handle,
                  isVerified: isVerified,
                  content: currentPost.content,
                  timestamp: _formatTimestamp(currentPost.createdAt),
                  likesCount: currentPost.likesCount,
                  commentsCount: commentsAsync.maybeWhen(
                    data: (comments) => comments.length,
                    orElse: () => currentPost.commentsCount,
                  ),
                  isLiked: currentPost.isLiked,
                  avatarColor: currentPost.isAnonymous
                      ? Colors.grey
                      : _getAvatarColor(currentPost.userId),
                  isAnonymous: currentPost.isAnonymous,
                  onLikeTap: () async {
                    // Call toggleLike from post provider
                    await ref.read(postsProvider.notifier).toggleLike(currentPost.id, currentPost.isLiked);
                  },
                ),
                const SizedBox(height: 8),
                
                // Comments Section Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.white,
                  child: const Center(
                    child: Text(
                      'Semua Komentar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                
                Container(
                  height: 1,
                  color: Colors.grey[300],
                ),

                // Comments List
                commentsAsync.when(
                  loading: () => Container(
                    padding: const EdgeInsets.all(32),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
                      ),
                    ),
                  ),
                  error: (error, stack) => Container(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                        const SizedBox(height: 12),
                        Text(
                          'Gagal memuat komentar',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            ref.invalidate(commentsProvider(widget.post.id));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BCD4),
                          ),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                  data: (comments) {
                    if (comments.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.comment_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada komentar',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Jadilah yang pertama berkomentar!',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: comments.map((comment) {
                        final displayName = comment.displayName ?? comment.username ?? 'Unknown';
                        final handle = '@${comment.username ?? 'unknown'}';
                        
                        return CommentCard(
                          username: displayName,
                          handle: handle,
                          isVerified: false,
                          content: comment.content,
                          timestamp: _formatTimestamp(comment.createdAt),
                          likes: '${comment.likesCount} Suka',
                          avatarColor: _getAvatarColor(comment.userId),
                          avatarUrl: comment.avatarUrl,
                          onLikeTap: () {
                            ref
                                .read(commentsProvider(widget.post.id).notifier)
                                .toggleLike(comment.id, comment.isLiked);
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),

          // Comment Input Field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      focusNode: _commentFocus,
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleAddComment(),
                      decoration: InputDecoration(
                        hintText: 'Tulis komentar...',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 15,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(
                            color: Color(0xFF00BCD4),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: _isSubmitting 
                        ? Colors.grey 
                        : const Color(0xFF00BCD4),
                    borderRadius: BorderRadius.circular(25),
                    child: InkWell(
                      onTap: _isSubmitting ? null : _handleAddComment,
                      borderRadius: BorderRadius.circular(25),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
