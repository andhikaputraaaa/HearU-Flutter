import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final String username;
  final String handle;
  final bool isVerified;
  final String content;
  final String timestamp;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final Color avatarColor;
  final bool isAnonymous;
  final String? avatarUrl;
  final VoidCallback? onTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onDeleteTap;
  final bool showDeleteButton;

  const PostCard({
    super.key,
    required this.username,
    required this.handle,
    required this.isVerified,
    required this.content,
    required this.timestamp,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.avatarColor,
    this.isAnonymous = false,
    this.avatarUrl,
    this.onTap,
    this.onLikeTap,
    this.onAvatarTap,
    this.onDeleteTap,
    this.showDeleteButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info row
                Row(
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: isAnonymous ? null : onAvatarTap,
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: avatarColor,
                        backgroundImage:
                            (!isAnonymous &&
                                avatarUrl != null &&
                                avatarUrl!.isNotEmpty)
                            ? NetworkImage(avatarUrl!) as ImageProvider
                            : null,
                        child: isAnonymous
                            ? const Icon(Icons.person, color: Colors.white)
                            : (avatarUrl == null || avatarUrl!.isEmpty)
                            ? Text(
                                username.isNotEmpty
                                    ? username[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Username and handle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified,
                                  color: Color(0xFF00BCD4),
                                  size: 18,
                                ),
                              ],
                            ],
                          ),
                          if (handle.isNotEmpty)
                            Text(
                              handle,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    // Delete button
                    if (showDeleteButton)
                      GestureDetector(
                        onTap: onDeleteTap,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.more_vert,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Post content
                Text(
                  content,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 8),
                // Timestamp
                Text(
                  timestamp,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 12),
                // Actions (like and comment)
                Row(
                  children: [
                    InkWell(
                      onTap: onLikeTap,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$likesCount Suka',
                              style: TextStyle(
                                color: isLiked ? Colors.red : Colors.grey[600],
                                fontSize: 14,
                                fontWeight: isLiked
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$commentsCount Komentar',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
