import 'dart:async';
import 'dart:math';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/follow.dart';
import '../models/user.dart';

/// Mock data service for demo purposes without Firebase
class MockDataService {
  factory MockDataService() => _instance;
  MockDataService._internal();
  static final MockDataService _instance = MockDataService._internal();

  final List<PostModel> _posts = [];
  final List<CommentModel> _comments = [];
  final List<LikeModel> _likes = [];
  final List<FollowModel> _follows = [];
  final List<UserModel> _users = [];

  // Initialize with some demo data
  void initialize() {
    _createDemoData();
  }

  void _createDemoData() {
    // Create demo user
    final demoUser = UserModel(
      uid: 'anonymous_user',
      username: 'Anonymous User',
      email: 'anonymous@example.com',
      bio: 'Exploring memories around the world',
      followersCount: 0,
      followingCount: 0,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastActive: DateTime.now(),
      accountPublic: true,
    );
    _users.add(demoUser);

    // Create demo posts
    final random = Random();
    final locations = [
      {'lat': 37.7749, 'lng': -122.4194, 'name': 'San Francisco'},
      {'lat': 40.7128, 'lng': -74.0060, 'name': 'New York'},
      {'lat': 51.5074, 'lng': -0.1278, 'name': 'London'},
      {'lat': 48.8566, 'lng': 2.3522, 'name': 'Paris'},
      {'lat': 35.6762, 'lng': 139.6503, 'name': 'Tokyo'},
    ];

    for (var i = 0; i < 5; i++) {
      final location = locations[i];
      final post = PostModel(
        id: 'post_$i',
        userId: 'anonymous_user',
        username: 'Anonymous User',
        title: 'Memory from ${location['name']}',
        content: 'This is a beautiful memory from ${location['name']}. The weather was perfect and the experience was unforgettable. I will always cherish this moment and hope to return here someday.',
        latitude: location['lat']! as double,
        longitude: location['lng']! as double,
        likesCount: random.nextInt(50),
        commentsCount: random.nextInt(20),
        createdAt: DateTime.now().subtract(Duration(days: random.nextInt(30))),
        updatedAt: DateTime.now().subtract(Duration(days: random.nextInt(30))),
      );
      _posts.add(post);
    }
  }

  // Posts
  Future<List<PostModel>> getAllPosts() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _posts;
  }

  Future<List<PostModel>> getUserPosts(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _posts.where((post) => post.userId == userId).toList();
  }

  Future<void> createPost(PostModel post) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newPost = post.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _posts.add(newPost);
  }

  Future<void> updatePost(String postId, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _posts.indexWhere((post) => post.id == postId);
    if (index != -1) {
      final currentPost = _posts[index];
      _posts[index] = currentPost.copyWith(
        title: data['title'] ?? currentPost.title,
        content: data['content'] ?? currentPost.content,
        updatedAt: DateTime.now(),
      );
    }
  }

  Future<void> deletePost(String postId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _posts.removeWhere((post) => post.id == postId);
  }

  // Comments
  Future<List<CommentModel>> getPostComments(String postId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _comments.where((comment) => comment.postId == postId).toList();
  }

  Future<void> addComment(CommentModel comment) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newComment = comment.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _comments.add(newComment);

    // Update post comments count
    final postIndex = _posts.indexWhere((post) => post.id == comment.postId);
    if (postIndex != -1) {
      _posts[postIndex] = _posts[postIndex].copyWith(
        commentsCount: _posts[postIndex].commentsCount + 1,
      );
    }
  }

  Future<void> deleteComment(String commentId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _comments.removeWhere((comment) => comment.id == commentId);
  }

  // Likes
  Future<bool> isPostLiked(String postId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _likes.any((like) => like.postId == postId && like.userId == userId);
  }

  Future<void> likePost(String postId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final like = LikeModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postId: postId,
      userId: userId,
      createdAt: DateTime.now(),
    );
    _likes.add(like);

    // Update post likes count
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex != -1) {
      _posts[postIndex] = _posts[postIndex].copyWith(
        likesCount: _posts[postIndex].likesCount + 1,
      );
    }
  }

  Future<void> unlikePost(String postId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _likes.removeWhere((like) => like.postId == postId && like.userId == userId);

    // Update post likes count
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex != -1 && _posts[postIndex].likesCount > 0) {
      _posts[postIndex] = _posts[postIndex].copyWith(
        likesCount: _posts[postIndex].likesCount - 1,
      );
    }
  }

  // Follows
  Future<bool> isFollowing(String followerId, String followingId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _follows.any((follow) => 
        follow.followerId == followerId && follow.followingId == followingId);
  }

  Future<void> followUser(String followerId, String followingId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final follow = FollowModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      followerId: followerId,
      followingId: followingId,
      createdAt: DateTime.now(),
    );
    _follows.add(follow);
  }

  Future<void> unfollowUser(String followerId, String followingId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _follows.removeWhere((follow) => 
        follow.followerId == followerId && follow.followingId == followingId);
  }

  Future<int> getFollowersCount(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _follows.where((follow) => follow.followingId == userId).length;
  }

  Future<int> getFollowingCount(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _follows.where((follow) => follow.followerId == userId).length;
  }

  // Users
  Future<UserModel?> getUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _users.firstWhere((user) => user.uid == userId);
    } catch (e) {
      return null;
    }
  }

  Future<List<PostModel>> getLikedPosts(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final likedPostIds = _likes
        .where((like) => like.userId == userId)
        .map((like) => like.postId)
        .toSet();
    
    return _posts.where((post) => likedPostIds.contains(post.id)).toList();
  }
}
