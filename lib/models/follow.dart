import 'package:cloud_firestore/cloud_firestore.dart';

/// Follow model representing a follow relationship
class FollowModel {

  const FollowModel({
    required this.id,
    required this.followerId,
    required this.followingId,
    required this.createdAt,
  });

  /// Create from map
  factory FollowModel.fromMap(Map<String, dynamic> map) {
    return FollowModel(
      id: map['id'] ?? '',
      followerId: map['followerId'] ?? '',
      followingId: map['followingId'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Create from Firestore document
  factory FollowModel.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FollowModel.fromMap(data).copyWith(id: doc.id);
  }
  final String id;
  final String followerId;
  final String followingId;
  final DateTime createdAt;

  /// Create a copy with updated fields
  FollowModel copyWith({
    String? id,
    String? followerId,
    String? followingId,
    DateTime? createdAt,
  }) => FollowModel(
      id: id ?? this.id,
      followerId: followerId ?? this.followerId,
      followingId: followingId ?? this.followingId,
      createdAt: createdAt ?? this.createdAt,
    );

  /// Convert to map for storage
  Map<String, dynamic> toMap() => {
      'id': id,
      'followerId': followerId,
      'followingId': followingId,
      'createdAt': createdAt.toIso8601String(),
    };

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() => toMap();

  @override
  String toString() => 'FollowModel(id: $id, followerId: $followerId, followingId: $followingId)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FollowModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Like model representing a like on a post
class LikeModel {

  const LikeModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.createdAt,
  });

  /// Create from map
  factory LikeModel.fromMap(Map<String, dynamic> map) {
    return LikeModel(
      id: map['id'] ?? '',
      postId: map['postId'] ?? '',
      userId: map['userId'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Create from Firestore document
  factory LikeModel.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return LikeModel.fromMap(data).copyWith(id: doc.id);
  }
  final String id;
  final String postId;
  final String userId;
  final DateTime createdAt;

  /// Create a copy with updated fields
  LikeModel copyWith({
    String? id,
    String? postId,
    String? userId,
    DateTime? createdAt,
  }) => LikeModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );

  /// Convert to map for storage
  Map<String, dynamic> toMap() => {
      'id': id,
      'postId': postId,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
    };

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() => toMap();

  @override
  String toString() => 'LikeModel(id: $id, postId: $postId, userId: $userId)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LikeModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
