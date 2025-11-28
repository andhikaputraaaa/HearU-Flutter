import 'user_model.dart';

class PostModel {
  final String id;
  final String userId;
  final String content;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Relations
  final UserModel? user;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;

  PostModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.isAnonymous,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      isAnonymous: json['is_anonymous'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      user: json['users'] != null 
          ? UserModel.fromJson(json['users'] as Map<String, dynamic>) 
          : null,
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'is_anonymous': isAnonymous,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PostModel copyWith({
    String? id,
    String? userId,
    String? content,
    bool? isAnonymous,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserModel? user,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}