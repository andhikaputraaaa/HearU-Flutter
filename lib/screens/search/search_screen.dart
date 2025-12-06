import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../services/user_service.dart';
import '../../services/post_service.dart';
import '../profile/other_profile_screen.dart';
import '../post/post_detail_screen.dart';
import '../../widgets/common/post_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final Function(String)? onViewOtherProfile;
  final VoidCallback? onGoToProfile;

  const SearchScreen({super.key, this.onViewOtherProfile, this.onGoToProfile});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService();
  final PostService _postService = PostService();

  List<UserModel> _userResults = [];
  List<PostModel> _postResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _userResults = [];
        _postResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      // Search users and posts in parallel
      final results = await Future.wait([
        _userService.searchUsers(query),
        _postService.searchPosts(query),
      ]);

      setState(() {
        _userResults = results[0] as List<UserModel>;
        _postResults = results[1] as List<PostModel>;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
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

  void _navigateToProfile(String userId) {
    final currentUserId = _userService.getCurrentUserId();
    if (userId == currentUserId) {
      // Go to own profile
      if (widget.onGoToProfile != null) {
        widget.onGoToProfile!();
      }
    } else {
      // Navigate to other user's profile
      if (widget.onViewOtherProfile != null) {
        widget.onViewOtherProfile!(userId);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtherProfileScreen(userId: userId),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          // Custom header
          Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: const Text(
                      'Pencarian',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(color: Colors.grey[300], height: 1),
                ],
              ),
            ),
          ),
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari pengguna atau postingan...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00BCD4)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
              onSubmitted: _performSearch,
            ),
          ),
          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF00BCD4),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF00BCD4),
              tabs: const [
                Tab(text: 'Pengguna'),
                Tab(text: 'Postingan'),
              ],
            ),
          ),
          // Results
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildUserResults(), _buildPostResults()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Cari pengguna berdasarkan',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            Text(
              'username atau display name',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_userResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Pengguna tidak ditemukan',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: _userResults.length,
      itemBuilder: (context, index) {
        final user = _userResults[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: user.avatarUrl != null
                ? CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(user.avatarUrl!),
                  )
                : CircleAvatar(
                    radius: 28,
                    backgroundColor: _getAvatarColor(user.id),
                    child: Text(
                      (user.displayName ?? user.username)[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
            title: Text(
              user.displayName ?? user.username,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: Text(
              '@${user.username}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            onTap: () => _navigateToProfile(user.id),
          ),
        );
      },
    );
  }

  Widget _buildPostResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Cari postingan berdasarkan',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            Text(
              'kata kunci atau konten',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_postResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Postingan tidak ditemukan',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: _postResults.length,
      itemBuilder: (context, index) {
        final post = _postResults[index];
        final displayName = post.isAnonymous
            ? 'Anonim'
            : post.user?.displayName ?? post.user?.username ?? 'Unknown';
        final handle = post.isAnonymous
            ? ''
            : '@${post.user?.username ?? 'unknown'}';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: PostCard(
            username: displayName,
            handle: handle,
            isVerified: false,
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
              // Refresh search results after like/unlike
              await _performSearch(_searchController.text);
            },
            onAvatarTap: () {
              if (!post.isAnonymous) {
                _navigateToProfile(post.userId);
              }
            },
          ),
        );
      },
    );
  }
}
