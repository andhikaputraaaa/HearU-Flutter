import 'package:flutter/material.dart';

class CommentCard extends StatelessWidget {
  final String username;
  final String handle;
  final bool isVerified;
  final String content;
  final String timestamp;
  final int likesCount;
  final bool isLiked;
  final Color avatarColor;
  final String? avatarUrl;
  final VoidCallback? onLikeTap;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onDeleteTap;
  final bool showDeleteButton;

  const CommentCard({
    super.key,
    required this.username,
    required this.handle,
    required this.isVerified,
    required this.content,
    required this.timestamp,
    required this.likesCount,
    required this.isLiked,
    required this.avatarColor,
    this.avatarUrl,
    this.onLikeTap,
    this.onAvatarTap,
    this.onDeleteTap,
    this.showDeleteButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              GestureDetector(
                onTap: onAvatarTap,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: avatarColor,
                  backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                      ? NetworkImage(avatarUrl!) as ImageProvider
                      : null,
                  child: (avatarUrl == null || avatarUrl!.isEmpty)
                      ? Text(
                          username.isNotEmpty ? username[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username row
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              if (isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified,
                                  color: Color(0xFF00BCD4),
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Delete button
                        if (showDeleteButton)
                          GestureDetector(
                            onTap: onDeleteTap,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.more_vert,
                                color: Colors.grey[600],
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (handle.isNotEmpty)
                      Text(
                        handle,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    const SizedBox(height: 8),
                    // Comment content
                    Text(
                      content,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    // Like and timestamp
                    Row(
                      children: [
                        InkWell(
                          onTap: onLikeTap,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 18,
                                  color: isLiked
                                      ? Colors.red
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$likesCount Suka',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isLiked
                                        ? Colors.red
                                        : Colors.grey[600],
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
                        Text(
                          timestamp,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
