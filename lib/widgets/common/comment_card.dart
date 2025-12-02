import 'package:flutter/material.dart';

class CommentCard extends StatelessWidget {
  final String username;
  final String handle;
  final bool isVerified;
  final String content;
  final String timestamp;
  final String likes;
  final Color avatarColor;
  final String? avatarUrl;
  final VoidCallback? onLikeTap;

  const CommentCard({
    super.key,
    required this.username,
    required this.handle,
    required this.isVerified,
    required this.content,
    required this.timestamp,
    required this.likes,
    required this.avatarColor,
    this.avatarUrl,
    this.onLikeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: avatarColor,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
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
                    if (handle.isNotEmpty)
                      Text(
                        handle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Comment content
                    Text(
                      content,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Like and timestamp
                    Row(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.favorite_border,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              likes,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
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
    );
  }
}
