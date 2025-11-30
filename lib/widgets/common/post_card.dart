import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final String username;
  final String handle;
  final bool isVerified;
  final String content;
  final String timestamp;
  final String likes;
  final String comments;
  final Color avatarColor;
  final bool isAnonymous;
  final String? avatarUrl;

  const PostCard({
    super.key,
    required this.username,
    required this.handle,
    required this.isVerified,
    required this.content,
    required this.timestamp,
    required this.likes,
    required this.comments,
    required this.avatarColor,
    this.isAnonymous = false,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info row
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: avatarColor,
                  backgroundImage:
                      (!isAnonymous &&
                          avatarUrl != null &&
                          avatarUrl!.isNotEmpty)
                      ? NetworkImage(avatarUrl!)
                      : null,
                  child: isAnonymous
                      ? const Icon(Icons.person, color: Colors.white)
                      : (avatarUrl == null || avatarUrl!.isEmpty)
                      ? Text(
                          username.isNotEmpty ? username[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
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
              ],
            ),
            const SizedBox(height: 12),
            // Post content
            Text(content, style: const TextStyle(fontSize: 15, height: 1.4)),
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
                Icon(Icons.favorite_border, color: Colors.grey[600], size: 20),
                const SizedBox(width: 6),
                Text(
                  likes,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(width: 24),
                Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  comments,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
