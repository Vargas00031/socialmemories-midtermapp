import 'package:cloud_firestore/cloud_firestore.dart';

/// [ENUM] PostPrivacy
/// [PURPOSE] Enum for post privacy settings
enum PostPrivacy {
  public,   // [VALUE] Visible to everyone
  friends,  // [VALUE] Visible only to friends/followers
  private,  // [VALUE] Visible only to the author
}

/// [CLASS] PostModel
/// [PURPOSE] Model representing a memory post with social features
/// [FUNCTIONALITY] Contains post data, privacy settings, and sharing options
class PostModel {

  const PostModel({
    required this.id,
    required this.userId,
    required this.username,
    this.userProfileImage,
    this.userProfileImageBase64,
    required this.title,
    required this.content,
    this.imageUrl,
    this.imageDataBase64,
    required this.latitude,
    required this.longitude,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    this.updatedAt,
    this.privacy = PostPrivacy.public,           // [FIELD] Post privacy setting (default: public)
    this.sharedWith = const [],                     // [FIELD] List of user IDs post is shared with
    this.sharedByUserId,                           // [FIELD] User who shared this post (for reposts)
    this.sharedByUsername,                         // [FIELD] Username of user who shared this post
    this.sharedByUserProfileImage,                  // [FIELD] Profile image of user who shared
    this.sharedByUserProfileImageBase64,             // [FIELD] Profile image base64 of user who shared
    this.originalPostId,                           // [FIELD] Original post ID (for reposts)
    this.isSharedPost = false,                     // [FIELD] Whether this is a shared post
  });

  /// [FACTORY] fromMap - Create PostModel from map data
  factory PostModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseDateNullable(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    PostPrivacy parsePrivacy(dynamic v) {
      if (v == null) return PostPrivacy.public;
      if (v is String) {
        return PostPrivacy.values.firstWhere(
          (e) => e.name == v,
          orElse: () => PostPrivacy.public,
        );
      }
      try {
        return PostPrivacy.values.firstWhere(
          (e) => e.toString() == 'PostPrivacy.$v',
        );
      } catch (_) {
        return PostPrivacy.public;
      }
    }

    return PostModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      userProfileImage: map['userProfileImage'] ?? map['profileImage'], // Fallback to profileImage
      userProfileImageBase64: map['userProfileImageBase64'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'],
      imageDataBase64: map['imageDataBase64'],
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      likesCount: (map['likesCount'] is int)
          ? map['likesCount'] as int
          : int.tryParse('${map['likesCount']}') ?? 0,
      commentsCount: (map['commentsCount'] is int)
          ? map['commentsCount'] as int
          : int.tryParse('${map['commentsCount']}') ?? 0,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDateNullable(map['updatedAt']),
      privacy: parsePrivacy(map['privacy']),
      sharedWith: List<String>.from(map['sharedWith'] ?? []),  // [FIELD] Parse shared list
      sharedByUserId: map['sharedByUserId'],
      sharedByUsername: map['sharedByUsername'],
      sharedByUserProfileImage: map['sharedByUserProfileImage'],
      sharedByUserProfileImageBase64: map['sharedByUserProfileImageBase64'],
      originalPostId: map['originalPostId'],
      isSharedPost: map['isSharedPost'] ?? false,
    );
  }

  /// [FACTORY] fromFirestore - Create PostModel from Firestore document
  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PostModel.fromMap(data).copyWith(id: doc.id);
  }
  
  // [FIELDS] Post data fields
  final String id;                              // [FIELD] Unique post identifier
  final String userId;                           // [FIELD] Author user ID
  final String username;                         // [FIELD] Author display name
  final String? userProfileImage;                // [FIELD] Author profile image URL (legacy)
  final String? userProfileImageBase64;           // [FIELD] Author profile image as base64 data
  final String title;                            // [FIELD] Post title
  final String content;                          // [FIELD] Post content/description
  final String? imageUrl;                        // [FIELD] Memory image URL (legacy)
  final String? imageDataBase64;                 // [FIELD] Memory image as base64 data
  final double latitude;                         // [FIELD] Memory location latitude
  final double longitude;                        // [FIELD] Memory location longitude
  final int likesCount;                          // [FIELD] Number of likes
  final int commentsCount;                       // [FIELD] Number of comments
  final DateTime createdAt;                       // [FIELD] Creation timestamp
  final DateTime? updatedAt;                      // [FIELD] Last update timestamp
  final PostPrivacy privacy;                      // [FIELD] Post privacy setting
  final List<String> sharedWith;                 // [FIELD] List of user IDs post is shared with
  final String? sharedByUserId;                   // [FIELD] User who shared this post (for reposts)
  final String? sharedByUsername;                 // [FIELD] Username of user who shared this post
  final String? sharedByUserProfileImage;          // [FIELD] Profile image of user who shared
  final String? sharedByUserProfileImageBase64;     // [FIELD] Profile image base64 of user who shared
  final String? originalPostId;                   // [FIELD] Original post ID (for reposts)
  final bool isSharedPost;                        // [FIELD] Whether this is a shared post

  /// [METHOD] copyWith - Create a copy with updated fields
  PostModel copyWith({
    String? id,
    String? userId,
    String? username,
    String? userProfileImage,
    String? userProfileImageBase64,
    String? title,
    String? content,
    String? imageUrl,
    String? imageDataBase64,
    double? latitude,
    double? longitude,
    int? likesCount,
    int? commentsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    PostPrivacy? privacy,                        // [FIELD] Updated privacy setting
    List<String>? sharedWith,                     // [FIELD] Updated shared list
    String? sharedByUserId,
    String? sharedByUsername,
    String? sharedByUserProfileImage,
    String? sharedByUserProfileImageBase64,
    String? originalPostId,
    bool? isSharedPost,
  }) => PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      userProfileImageBase64: userProfileImageBase64 ?? this.userProfileImageBase64,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      imageDataBase64: imageDataBase64 ?? this.imageDataBase64,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      privacy: privacy ?? this.privacy,              // [FIELD] Use new privacy or existing
      sharedWith: sharedWith ?? this.sharedWith,      // [FIELD] Use new shared list or existing
      sharedByUserId: sharedByUserId ?? this.sharedByUserId,
      sharedByUsername: sharedByUsername ?? this.sharedByUsername,
      sharedByUserProfileImage: sharedByUserProfileImage ?? this.sharedByUserProfileImage,
      sharedByUserProfileImageBase64: sharedByUserProfileImageBase64 ?? this.sharedByUserProfileImageBase64,
      originalPostId: originalPostId ?? this.originalPostId,
      isSharedPost: isSharedPost ?? this.isSharedPost,
    );

  /// [METHOD] toMap - Convert to map for storage
  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'username': username,
    'userProfileImage': userProfileImage,
    'userProfileImageBase64': userProfileImageBase64,
    'title': title,
    'content': content,
    'imageUrl': imageUrl,
    'imageDataBase64': imageDataBase64,
    'latitude': latitude,
    'longitude': longitude,
    'likesCount': likesCount,
    'commentsCount': commentsCount,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'privacy': privacy.name,                       // [FIELD] Store privacy as string
    'sharedWith': sharedWith,                      // [FIELD] Store shared list
    'sharedByUserId': sharedByUserId,
    'sharedByUsername': sharedByUsername,
    'sharedByUserProfileImage': sharedByUserProfileImage,
    'sharedByUserProfileImageBase64': sharedByUserProfileImageBase64,
    'originalPostId': originalPostId,
    'isSharedPost': isSharedPost,
  };

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() => toMap();

  @override
  String toString() => 'PostModel(id: $id, title: $title, userId: $userId)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
