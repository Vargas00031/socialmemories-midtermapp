import 'package:cloud_firestore/cloud_firestore.dart';

/// [CLASS] UserModel
/// [PURPOSE] Model representing a user with social features
/// [FUNCTIONALITY] Contains user data, friends/followers lists, and social stats
class UserModel {
  
  // [FIELDS] User basic information
  final String uid;                              // [FIELD] Unique user identifier
  final String username;                            // [FIELD] Display username
  final String email;                               // [FIELD] User email address
  final String? profileImageUrl;                    // [FIELD] Profile image URL (legacy)
  final String? profileImageBase64;                 // [FIELD] Profile image as base64 data
  final String? bio;                                // [FIELD] User bio/description

  /// When false, profile is hidden from user search (others cannot find this account).
  final bool accountPublic;
  
  // [FIELDS] Social statistics
  final int followersCount;                        // [FIELD] Number of followers
  final int followingCount;                        // [FIELD] Number of following
  
  // [FIELDS] Social relationships
  final List<String> followers;                    // [FIELD] List of follower user IDs
  final List<String> following;                     // [FIELD] List of following user IDs
  final List<String> friends;                      // [FIELD] List of friend user IDs (mutual follows)
  
  // [FIELDS] Timestamps
  final DateTime createdAt;                        // [FIELD] Account creation time
  final DateTime lastActive;                       // [FIELD] Last activity time

  const UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.profileImageUrl,
    this.profileImageBase64,
    this.bio,
    required this.followersCount,
    required this.followingCount,
    required this.createdAt,
    required this.lastActive,
    this.followers = const [],                     // [FIELD] Default empty followers list
    this.following = const [],                     // [FIELD] Default empty following list
    this.friends = const [],                      // [FIELD] Default empty friends list
    this.accountPublic = true,
  });

  /// [FACTORY] fromMap - Create UserModel from map data
  factory UserModel.fromMap(Map<String, dynamic> map) {
    // [HELPER] Parse date from Timestamp or String
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.parse(date);
      return DateTime.now();
    }

    final emailStr = map['email'] as String? ?? '';
    final rawUsername = map['username'] as String?;
    final resolvedUsername = (rawUsername != null && rawUsername.trim().isNotEmpty)
        ? rawUsername
        : (emailStr.contains('@') ? emailStr.split('@').first : '');

    final vis = map['accountVisibility'];
    final explicitPublic = map['accountPublic'];
    final accountPublic = explicitPublic is bool
        ? explicitPublic
        : (vis is String ? vis.toLowerCase() != 'private' : true);

    return UserModel(
      uid: map['uid'] ?? '',
      username: resolvedUsername,
      email: emailStr,
      profileImageUrl: map['profileImageUrl'] ?? map['profileImage'],
      profileImageBase64: map['profileImageBase64'],
      bio: map['bio'],
      followersCount: map['followersCount'] ?? 0,
      followingCount: map['followingCount'] ?? 0,
      createdAt: parseDate(map['createdAt']),
      lastActive: parseDate(map['lastActive']),
      followers: List<String>.from(map['followers'] ?? []),   // [FIELD] Parse followers list
      following: List<String>.from(map['following'] ?? []),    // [FIELD] Parse following list
      friends: List<String>.from(map['friends'] ?? []),       // [FIELD] Parse friends list
      accountPublic: accountPublic,
    );
  }

  /// [FACTORY] fromFirestore - Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data).copyWith(uid: doc.id);
  }

  /// [METHOD] copyWith - Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? username,
    String? email,
    String? profileImageUrl,
    String? profileImageBase64,
    String? bio,
    int? followersCount,
    int? followingCount,
    DateTime? createdAt,
    DateTime? lastActive,
    List<String>? followers,                    // [FIELD] Updated followers list
    List<String>? following,                     // [FIELD] Updated following list
    List<String>? friends,                      // [FIELD] Updated friends list
    bool? accountPublic,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      profileImageBase64: profileImageBase64 ?? this.profileImageBase64,
      bio: bio ?? this.bio,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      followers: followers ?? this.followers,            // [FIELD] Use new followers or existing
      following: following ?? this.following,             // [FIELD] Use new following or existing
      friends: friends ?? this.friends,                  // [FIELD] Use new friends or existing
      accountPublic: accountPublic ?? this.accountPublic,
    );
  }

  /// [METHOD] toMap - Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'profileImageBase64': profileImageBase64,
      'bio': bio,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'followers': followers,                           // [FIELD] Store followers list
      'following': following,                            // [FIELD] Store following list
      'friends': friends,                               // [FIELD] Store friends list
      'accountVisibility': accountPublic ? 'public' : 'private',
    };
  }

  /// [METHOD] toFirestore - Convert to Firestore map with Timestamps
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'profileImageBase64': profileImageBase64,
      'bio': bio,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
      'followers': followers,                           // [FIELD] Store followers list
      'following': following,                            // [FIELD] Store following list
      'friends': friends,                               // [FIELD] Store friends list
      'accountVisibility': accountPublic ? 'public' : 'private',
    };
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, username: $username, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.uid == uid &&
        other.username == username &&
        other.email == email;
  }

  @override
  int get hashCode => uid.hashCode ^ username.hashCode ^ email.hashCode;
}
