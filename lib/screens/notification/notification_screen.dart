import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import '../profile/other_profile_screen.dart';
import '../post/post_detail_screen.dart';
import '../../providers/post_provider.dart';
import '../../main.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  final Function(String)? onViewOtherProfile;
  final VoidCallback? onGoToProfile;
  final bool showAppBar;

  const NotificationScreen({
    super.key,
    this.onViewOtherProfile,
    this.onGoToProfile,
    this.showAppBar = true,
  });

  @override
  ConsumerState<NotificationScreen> createState() => NotificationScreenState();
}

class NotificationScreenState extends ConsumerState<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).loadNotifications();
    });
  }

  void refreshData() {
    ref.read(notificationProvider.notifier).loadNotifications();
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }

  Color _getAvatarColor(String oderId) {
    final hash = oderId.hashCode;
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

  Widget _buildNotificationIcon(NotificationModel notification) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case 'follow':
        icon = Icons.person_add;
        color = Colors.blue;
        break;
      case 'like':
        icon = Icons.favorite;
        color = Colors.red;
        break;
      case 'comment':
        icon = Icons.comment;
        color = Colors.green;
        break;
      case 'comment_like':
        icon = Icons.thumb_up;
        color = Colors.orange;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 14),
    );
  }

  void _handleNotificationTap(NotificationModel notification) async {
    switch (notification.type) {
      case 'follow':
        _navigateToProfile(notification.actorId);
        break;
      case 'like':
        if (notification.postId != null) {
          await _navigateToPostDetail(notification.postId!);
        }
        break;
      case 'comment':
        if (notification.postId != null) {
          await _navigateToPostDetail(notification.postId!);
        }
        break;
      case 'comment_like':
        if (notification.postId != null) {
          await _navigateToPostDetail(notification.postId!);
        }
        break;
    }
  }

  void _navigateToProfile(String userId) {
    final currentUserId = supabase.auth.currentUser?.id;
    if (userId == currentUserId) {
      if (widget.onGoToProfile != null) {
        widget.onGoToProfile!();
      }
    } else {
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

  Future<void> _navigateToPostDetail(String postId) async {
    final postsState = ref.read(postsProvider);

    postsState.when(
      data: (posts) {
        try {
          final post = posts.firstWhere((p) => p.id == postId);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(post: post),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Postingan tidak ditemukan')),
          );
        }
      },
      loading: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Memuat postingan...')));
      },
      error: (e, _) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationProvider);

    Widget body = notificationState.isLoading
        ? const Center(child: CircularProgressIndicator())
        : notificationState.notifications.isEmpty
        ? _buildEmptyState()
        : RefreshIndicator(
            onRefresh: () async {
              await ref.read(notificationProvider.notifier).loadNotifications();
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              itemCount: notificationState.notifications.length,
              itemBuilder: (context, index) {
                final notification = notificationState.notifications[index];
                return _buildNotificationItem(notification);
              },
            ),
          );

    if (!widget.showAppBar) {
      return Container(
        color: Colors.grey[100],
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: const Text(
                        'Notifikasi',
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
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[300], height: 1),
        ),
      ),
      body: body,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada notifikasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aktivitas terbaru akan muncul di sini',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    final displayName =
        notification.actorDisplayName ??
        notification.actorUsername ??
        'Pengguna';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: notification.isRead
            ? Colors.white
            : Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? Colors.grey.withOpacity(0.2)
              : Colors.blue.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            notification.actorAvatarUrl != null
                ? CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(notification.actorAvatarUrl!),
                  )
                : CircleAvatar(
                    radius: 24,
                    backgroundColor: _getAvatarColor(notification.actorId),
                    child: Text(
                      displayName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
            Positioned(
              bottom: -4,
              right: -4,
              child: _buildNotificationIcon(notification),
            ),
          ],
        ),
        title: Text(
          notification.message,
          style: TextStyle(
            fontSize: 14,
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notification.postContent != null) ...[
              const SizedBox(height: 4),
              Text(
                notification.postContent!.length > 50
                    ? '${notification.postContent!.substring(0, 50)}...'
                    : notification.postContent!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(notification.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        onTap: () => _handleNotificationTap(notification),
      ),
    );
  }
}
