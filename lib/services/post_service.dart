import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment.dart';
import '../models/post.dart';
import 'firebase_service.dart';

/// Service for managing memory posts in Firestore
class PostService {
  final FirebaseService _firebaseService = FirebaseService.instance;

  /// Get all posts from Firestore
  Future<List<PostModel>> getAllPosts() async {
    try {
      final snapshot = await _firebaseService.postsCollection
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch posts: $e');
    }
  }

  /// Get posts for a specific user
  Future<List<PostModel>> getUserPosts(String userId) async {
    try {
      final snapshot = await _firebaseService.postsCollection
          .where('userId', isEqualTo: userId)
          .get();
      
      final posts = snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
      
      // Sort client-side to avoid composite index requirement
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    } catch (e) {
      throw Exception('Failed to fetch user posts: $e');
    }
  }

  /// Create a new post in Firestore (document id is generated; stored `id` field omitted)
  Future<void> createPost(PostModel post) async {
    try {
      final data = Map<String, dynamic>.from(post.toFirestore());
      data.remove('id');
      await _firebaseService.postsCollection.add(data);
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    try {
      await _firebaseService.postsCollection.doc(postId).delete();
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  /// Update a post
  Future<void> updatePost(String postId, Map<String, dynamic> data) async {
    try {
      await _firebaseService.postsCollection.doc(postId).update({
        ...data,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update post: $e');
    }
  }

  /// Like a post
  Future<void> likePost(String postId, String userId) async {
    try {
      // Add to likes collection
      await _firebaseService.likesCollection.add({
        'postId': postId,
        'userId': userId,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Increment likes count on post
      await _firebaseService.postsCollection.doc(postId).update({
        'likesCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to like post: $e');
    }
  }

  /// Unlike a post
  Future<void> unlikePost(String postId, String userId) async {
    try {
      // Remove from likes collection
      final likesSnapshot = await _firebaseService.likesCollection
          .where('postId', isEqualTo: postId)
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in likesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Decrement likes count on post
      await _firebaseService.postsCollection.doc(postId).update({
        'likesCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Failed to unlike post: $e');
    }
  }

  /// Check if a post is liked by a user
  Future<bool> isPostLiked(String postId, String userId) async {
    try {
      final likesSnapshot = await _firebaseService.likesCollection
          .where('postId', isEqualTo: postId)
          .where('userId', isEqualTo: userId)
          .get();

      return likesSnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check if post is liked: $e');
    }
  }

  /// Comments for a post (sorted client-side by createdAt)
  Future<List<CommentModel>> getCommentsForPost(String postId) async {
    try {
      final snapshot = await _firebaseService.commentsCollection
          .where('postId', isEqualTo: postId)
          .get();

      final list = snapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    } catch (e) {
      throw Exception('Failed to fetch comments: $e');
    }
  }

  /// Get posts by IDs (for loading specific user posts in profile)
  Future<List<PostModel>> getPostsByIds(List<String> postIds) async {
    try {
      if (postIds.isEmpty) return [];
      
      final posts = <PostModel>[];
      // Firestore 'in' queries are limited to 10 items, so batch them
      for (var i = 0; i < postIds.length; i += 10) {
        final batch = postIds.skip(i).take(10).toList();
        final snapshot = await _firebaseService.postsCollection
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        posts.addAll(snapshot.docs.map((doc) => PostModel.fromFirestore(doc)));
      }
      
      // Sort by createdAt descending
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    } catch (e) {
      throw Exception('Failed to fetch posts by IDs: $e');
    }
  }

  /// Get posts for user's feed (posts from followed users + own posts)
  Future<List<PostModel>> getFeedPosts(String userId, List<String> followingIds) async {
    try {
      final allPosts = <PostModel>[];
      
      // Get own posts
      final ownPosts = await getUserPosts(userId);
      allPosts.addAll(ownPosts);
      
      // Get public posts from followed users
      for (final followingId in followingIds) {
        try {
          final snapshot = await _firebaseService.postsCollection
              .where('userId', isEqualTo: followingId)
              .where('privacy', isEqualTo: 'public')
              .get();
          allPosts.addAll(snapshot.docs.map((doc) => PostModel.fromFirestore(doc)));
        } catch (e) {
          // Skip if query fails for this user
          continue;
        }
      }
      
      // Remove duplicates and sort
      final seenIds = <String>{};
      final uniquePosts = <PostModel>[];
      for (final post in allPosts) {
        if (!seenIds.contains(post.id)) {
          seenIds.add(post.id);
          uniquePosts.add(post);
        }
      }
      
      uniquePosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return uniquePosts;
    } catch (e) {
      throw Exception('Failed to fetch feed posts: $e');
    }
  }

  /// Check if a user is following another user
  Future<bool> isFollowing(String followerId, String followingId) async {
    try {
      final doc = await _firebaseService.followingCollection
          .doc('${followerId}_$followingId')
          .get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check follow status: $e');
    }
  }

  /// Follow a user
  Future<void> followUser(String followerId, String followingId) async {
    try {
      // Add to following collection
      await _firebaseService.followingCollection
          .doc('${followerId}_$followingId')
          .set({
        'followerId': followerId,
        'followingId': followingId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Add to followers collection
      await _firebaseService.followersCollection
          .doc('${followingId}_$followerId')
          .set({
        'followerId': followerId,
        'followingId': followingId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Update user counts
      await _firebaseService.usersCollection.doc(followerId).update({
        'followingCount': FieldValue.increment(1),
      });
      await _firebaseService.usersCollection.doc(followingId).update({
        'followersCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to follow user: $e');
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser(String followerId, String followingId) async {
    try {
      // Remove from following collection
      await _firebaseService.followingCollection
          .doc('${followerId}_$followingId')
          .delete();
      
      // Remove from followers collection
      await _firebaseService.followersCollection
          .doc('${followingId}_$followerId')
          .delete();
      
      // Update user counts
      await _firebaseService.usersCollection.doc(followerId).update({
        'followingCount': FieldValue.increment(-1),
      });
      await _firebaseService.usersCollection.doc(followingId).update({
        'followersCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Failed to unfollow user: $e');
    }
  }

  /// Get list of user IDs that a user is following
  Future<List<String>> getFollowingIds(String userId) async {
    try {
      final snapshot = await _firebaseService.followingCollection
          .where('followerId', isEqualTo: userId)
          .get();
      return snapshot.docs.map((doc) => doc.data()['followingId'] as String).toList();
    } catch (e) {
      throw Exception('Failed to get following list: $e');
    }
  }

  /// Share/repost a post (creates a new post with shared post metadata)
  Future<void> sharePost({
    required String originalPostId,
    required String sharerUserId,
    required String sharerUsername,
    String? sharerProfileImage,
  }) async {
    try {
      // Get the original post
      final originalDoc = await _firebaseService.postsCollection.doc(originalPostId).get();
      if (!originalDoc.exists) {
        throw Exception('Original post not found');
      }
      
      final originalPost = PostModel.fromFirestore(originalDoc);
      
      // Create a shared post
      final sharedPost = PostModel(
        id: '',
        userId: sharerUserId,  // The sharer is now the "author" of this post
        username: sharerUsername,
        userProfileImage: sharerProfileImage,
        title: originalPost.title,
        content: originalPost.content,
        imageUrl: originalPost.imageUrl,
        latitude: originalPost.latitude,
        longitude: originalPost.longitude,
        likesCount: 0,  // Shared posts start with 0 likes
        commentsCount: 0,  // Shared posts start with 0 comments
        createdAt: DateTime.now(),
        privacy: PostPrivacy.public,  // Shared posts are always public
        sharedWith: const [],
        sharedByUserId: sharerUserId,
        sharedByUsername: sharerUsername,
        sharedByUserProfileImage: sharerProfileImage,
        originalPostId: originalPostId,
        isSharedPost: true,
      );
      
      // Save the shared post
      final data = Map<String, dynamic>.from(sharedPost.toFirestore());
      data.remove('id');
      await _firebaseService.postsCollection.add(data);
    } catch (e) {
      throw Exception('Failed to share post: $e');
    }
  }

  /// Add a comment and increment post commentsCount
  Future<void> addComment(CommentModel comment) async {
    try {
      final data = comment.toFirestore();
      data.remove('id');
      await _firebaseService.commentsCollection.add(data);
      await _firebaseService.postsCollection.doc(comment.postId).update({
        'commentsCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }
}
