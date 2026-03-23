import 'package:cloud_firestore/cloud_firestore.dart';

/// Comment model representing a comment on a post
class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String? userProfileImage;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
    this.userProfileImage,
    this.updatedAt,
  });

  /// Create from map
  factory CommentModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) {
        return DateTime.tryParse(v) ?? DateTime.now();
      }
      return DateTime.now();
    }

    DateTime? parseDateNullable(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return CommentModel(
      id: map['id'] ?? '',
      postId: map['postId'] ?? '',
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      userProfileImage: map['userProfileImage'],
      content: map['content'] ?? '',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDateNullable(map['updatedAt']),
    );
  }

  factory CommentModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    return CommentModel.fromMap({...map, 'id': doc.id});
  }

  /// Create a copy with updated fields
  CommentModel copyWith({
    String? id,
    String? postId,
    String? userId,
    String? username,
    String? userProfileImage,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      CommentModel(
        id: id ?? this.id,
        postId: postId ?? this.postId,
        userId: userId ?? this.userId,
        username: username ?? this.username,
        userProfileImage: userProfileImage ?? this.userProfileImage,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Convert to map for storage
  Map<String, dynamic> toMap() => {
        'id': id,
        'postId': postId,
        'userId': userId,
        'username': username,
        'userProfileImage': userProfileImage,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  Map<String, dynamic> toFirestore() => {
        'postId': postId,
        'userId': userId,
        'username': username,
        'userProfileImage': userProfileImage,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  String toString() => 'CommentModel(id: $id, postId: $postId, userId: $userId)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CommentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
