class NotificationModel {
  final String id;
  final String userId; // User yang menerima notifikasi
  final String actorId; // User yang melakukan aksi
  final String type; // 'follow', 'like', 'comment'
  final String? postId; // ID post (untuk like dan comment)
  final String? commentId; // ID comment (untuk notifikasi comment)
  final bool isRead;
  final DateTime createdAt;

  // Data tambahan dari join
  final String? actorUsername;
  final String? actorDisplayName;
  final String? actorAvatarUrl;
  final String? postContent; // Preview konten post

  NotificationModel({
    required this.id,
    required this.userId,
    required this.actorId,
    required this.type,
    this.postId,
    this.commentId,
    required this.isRead,
    required this.createdAt,
    this.actorUsername,
    this.actorDisplayName,
    this.actorAvatarUrl,
    this.postContent,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'] as Map<String, dynamic>?;
    final post = json['post'] as Map<String, dynamic>?;

    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      actorId: json['actor_id'] as String,
      type: json['type'] as String,
      postId: json['post_id'] as String?,
      commentId: json['comment_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      actorUsername: actor?['username'] as String?,
      actorDisplayName: actor?['display_name'] as String?,
      actorAvatarUrl: actor?['avatar_url'] as String?,
      postContent: post?['content'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'actor_id': actorId,
      'type': type,
      'post_id': postId,
      'comment_id': commentId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? actorId,
    String? type,
    String? postId,
    String? commentId,
    bool? isRead,
    DateTime? createdAt,
    String? actorUsername,
    String? actorDisplayName,
    String? actorAvatarUrl,
    String? postContent,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      actorId: actorId ?? this.actorId,
      type: type ?? this.type,
      postId: postId ?? this.postId,
      commentId: commentId ?? this.commentId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      actorUsername: actorUsername ?? this.actorUsername,
      actorDisplayName: actorDisplayName ?? this.actorDisplayName,
      actorAvatarUrl: actorAvatarUrl ?? this.actorAvatarUrl,
      postContent: postContent ?? this.postContent,
    );
  }

  String get message {
    final name = actorDisplayName ?? actorUsername ?? 'Seseorang';
    switch (type) {
      case 'follow':
        return '$name mulai mengikuti Anda';
      case 'like':
        return '$name menyukai postingan Anda';
      case 'comment':
        return '$name mengomentari postingan Anda';
      case 'comment_like':
        return '$name menyukai komentar Anda';
      default:
        return '$name berinteraksi dengan Anda';
    }
  }

  IconType get iconType {
    switch (type) {
      case 'follow':
        return IconType.follow;
      case 'like':
        return IconType.like;
      case 'comment':
        return IconType.comment;
      case 'comment_like':
        return IconType.commentLike;
      default:
        return IconType.follow;
    }
  }
}

enum IconType { follow, like, comment, commentLike }
