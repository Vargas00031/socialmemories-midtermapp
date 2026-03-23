import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/comment.dart';
import '../models/post.dart';
import '../services/post_service.dart';

/// ChangeNotifier provider for memory posts (Firestore via [PostService]).
class PostProvider extends ChangeNotifier {
  final PostService _postService = PostService();

  List<PostModel> _posts = [];
  List<Marker> _markers = [];
  bool _isLoading = false;
  String? _error;

  List<PostModel> get posts => _posts;
  List<Marker> get markers => _markers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPosts({bool silent = false}) async {
    if (!silent) _setLoading(true);
    try {
      _posts = await _postService.getAllPosts();
      _createMarkers();
      _setError(null);
    } catch (e) {
      _setError('Failed to load posts: $e');
    } finally {
      if (!silent) _setLoading(false);
    }
  }

  Future<void> loadUserPosts(String userId) async {
    _setLoading(true);
    try {
      _posts = await _postService.getUserPosts(userId);
      _createMarkers();
      _setError(null);
    } catch (e) {
      _setError('Failed to load user posts: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadFeedPosts(String userId, List<String> followingIds) async {
    _setLoading(true);
    try {
      _posts = await _postService.getFeedPosts(userId, followingIds);
      _createMarkers();
      _setError(null);
    } catch (e) {
      _setError('Failed to load feed posts: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createPost({
    required String userId,
    required String username,
    required String title,
    required String content,
    required double latitude,
    required double longitude,
    String? userProfileImage,
    String? userProfileImageBase64,
    String? imageUrl,
    String? imageDataBase64,
    PostPrivacy privacy = PostPrivacy.public,
    List<String> sharedWith = const [],
  }) async {
    _setLoading(true);
    try {
      final post = PostModel(
        id: '',
        userId: userId,
        username: username,
        userProfileImage: userProfileImage,
        userProfileImageBase64: userProfileImageBase64,
        title: title,
        content: content,
        imageUrl: imageUrl,
        imageDataBase64: imageDataBase64,
        latitude: latitude,
        longitude: longitude,
        likesCount: 0,
        commentsCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        privacy: privacy,
        sharedWith: sharedWith,
      );

      await _postService.createPost(post);
      await loadPosts();
      _setError(null);
    } catch (e) {
      _setError('Failed to create post: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updatePost(String postId, Map<String, dynamic> data) async {
    try {
      await _postService.updatePost(postId, data);
      await loadPosts();
    } catch (e) {
      _setError('Failed to update post: $e');
    }
  }

  Future<void> deletePost(String postId) async {
    _setLoading(true);
    try {
      await _postService.deletePost(postId);
      await loadPosts();
    } catch (e) {
      _setError('Failed to delete post: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> likePost(String postId, String userId) async {
    try {
      if (await _postService.isPostLiked(postId, userId)) return;
      await _postService.likePost(postId, userId);
      await loadPosts(silent: true);
    } catch (e) {
      _setError('Failed to like post: $e');
    }
  }

  Future<void> unlikePost(String postId, String userId) async {
    try {
      if (!await _postService.isPostLiked(postId, userId)) return;
      await _postService.unlikePost(postId, userId);
      await loadPosts(silent: true);
    } catch (e) {
      _setError('Failed to unlike post: $e');
    }
  }

  Future<bool> isPostLiked(String postId, String userId) async {
    try {
      return await _postService.isPostLiked(postId, userId);
    } catch (e) {
      _setError('Failed to check like status: $e');
      return false;
    }
  }

  Future<List<CommentModel>> getComments(String postId) async {
    try {
      return await _postService.getCommentsForPost(postId);
    } catch (e) {
      _setError('Failed to load comments: $e');
      return [];
    }
  }

  Future<void> addComment({
    required String postId,
    required String userId,
    required String username,
    required String content,
    String? userProfileImage,
  }) async {
    try {
      final comment = CommentModel(
        id: '',
        postId: postId,
        userId: userId,
        username: username,
        userProfileImage: userProfileImage,
        content: content.trim(),
        createdAt: DateTime.now(),
      );
      await _postService.addComment(comment);
      await loadPosts(silent: true);
    } catch (e) {
      _setError('Failed to add comment: $e');
    }
  }

  /// Share/repost a post
  Future<void> sharePost(String postId, String userId, String username, String? userProfileImage) async {
    _setLoading(true);
    try {
      await _postService.sharePost(
        originalPostId: postId,
        sharerUserId: userId,
        sharerUsername: username,
        sharerProfileImage: userProfileImage,
      );
      await loadPosts();
      _setError(null);
    } catch (e) {
      _setError('Failed to share post: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _createMarkers() {
    _markers = _posts.map((post) {
      return Marker(
        point: LatLng(post.latitude, post.longitude),
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF66BB6A),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.place,
            color: Colors.white,
            size: 24,
          ),
        ),
      );
    }).toList();

    notifyListeners();
  }

  void clearError() {
    _setError(null);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
}
