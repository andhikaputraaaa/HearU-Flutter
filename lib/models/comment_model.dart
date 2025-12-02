class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Relations
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final int likesCount;
  final bool isLiked;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.likesCount = 0,
    this.isLiked = false,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      username: json['users']?['username'] as String?,
      displayName: json['users']?['display_name'] as String?,
      avatarUrl: json['users']?['avatar_url'] as String?,
      likesCount: json['likes_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CommentModel copyWith({
    String? id,
    String? postId,
    String? userId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? username,
    String? displayName,
    String? avatarUrl,
    int? likesCount,
    bool? isLiked,
  }) {
    return CommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
