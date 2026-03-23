import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/post.dart';
import '../providers/post_provider.dart';
import '../providers/user_provider.dart';
import '../services/post_service.dart';
import '../widgets/post_card.dart';

/// [CLASS] UserProfileScreen
/// [PURPOSE] StatefulWidget displaying user profile with privacy settings
/// [FUNCTIONALITY] Shows user info, posts, and follow options based on privacy
class UserProfileScreen extends StatefulWidget {
  final UserModel user;                             // [PARAM] User to display

  const UserProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

/// [CLASS] _UserProfileScreenState
/// [PURPOSE] State management for UserProfileScreen
class _UserProfileScreenState extends State<UserProfileScreen> {
  List<PostModel> _userPosts = [];
  bool _isLoading = false;
  bool _isFollowing = false;
  final PostService _postService = PostService();

  @override
  void initState() {
    super.initState();
    _loadUserPosts();
    _checkFollowStatus();
  }

  /// [FUNCTION] _loadUserPosts
  /// [RETURNS] Future<void>
  /// [PURPOSE] Load user's posts directly from Firestore with privacy filtering
  Future<void> _loadUserPosts() async {
    setState(() => _isLoading = true);
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.userId;
      
      // Get all posts for this user directly from Firestore
      final allUserPosts = await _postService.getUserPosts(widget.user.uid);
      
      if (widget.user.uid == currentUser) {
        // [SHOW] Own posts - show all
        _userPosts = allUserPosts;
      } else {
        // [SHOW] Other user's posts - respect privacy
        _userPosts = allUserPosts.where((post) {
          switch (post.privacy) {
            case PostPrivacy.public:
              return true; // [SHOW] Public posts to everyone
            case PostPrivacy.friends:
              // [SHOW] Only if following
              return _isFollowing;
            case PostPrivacy.private:
              // [SHOW] Only if shared with current user
              return post.sharedWith.contains(currentUser);
          }
        }).toList();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading posts: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// [FUNCTION] _checkFollowStatus
  /// [RETURNS] Future<void>
  /// [PURPOSE] Check if current user follows this user using Firestore
  Future<void> _checkFollowStatus() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserId = userProvider.userId;
    
    if (widget.user.uid == currentUserId) {
      setState(() => _isFollowing = false);
      return;
    }
    
    try {
      final isFollowing = await _postService.isFollowing(currentUserId, widget.user.uid);
      setState(() => _isFollowing = isFollowing);
    } catch (e) {
      setState(() => _isFollowing = false);
    }
  }

  /// [FUNCTION] _toggleFollow
  /// [RETURNS] Future<void>
  /// [PURPOSE] Follow/unfollow user using Firestore
  Future<void> _toggleFollow() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserId = userProvider.userId;
    
    if (widget.user.uid == currentUserId) {
      return; // [SKIP] Cannot follow self
    }
    
    setState(() => _isLoading = true);
    
    try {
      if (_isFollowing) {
        await _postService.unfollowUser(currentUserId, widget.user.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unfollowed user')),
          );
        }
      } else {
        await _postService.followUser(currentUserId, widget.user.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Now following user')),
          );
        }
      }
      
      setState(() => _isFollowing = !_isFollowing);
      
      // Reload posts to update privacy-filtered content
      await _loadUserPosts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = Provider.of<UserProvider>(context).userId;
    final isSelf = widget.user.uid == currentUid;
    final isPrivateToViewer = !widget.user.accountPublic && !isSelf;

    if (isPrivateToViewer) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 72, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'This account is private',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'This user is not discoverable in search and their profile is hidden.',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('@${widget.user.username}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!isSelf) ...[
            // [BUTTON] Follow/Unfollow button
            ElevatedButton.icon(
              onPressed: _toggleFollow,
              icon: Icon(_isFollowing ? Icons.person_remove : Icons.person_add),
              label: Text(_isFollowing ? 'Following' : 'Follow'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing ? Colors.grey : const Color(0xFF66BB6A),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // [UI] User info header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // [AVATAR] User profile picture
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFFE8F5E9),
                  backgroundImage: widget.user.profileImageUrl != null && widget.user.profileImageUrl!.isNotEmpty
                      ? NetworkImage(widget.user.profileImageUrl!)
                      : null,
                  child: widget.user.profileImageUrl == null || widget.user.profileImageUrl!.isEmpty
                      ? const Icon(
                          Icons.person,
                          color: Color(0xFF66BB6A),
                          size: 40,
                        )
                      : null,
                ),
                
                const SizedBox(width: 16),
                
                // [INFO] User details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.username,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      if (widget.user.bio != null && widget.user.bio!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.user.bio!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      
                      // [STATS] User stats
                      Row(
                        children: [
                          Icon(Icons.people, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.user.followersCount} followers',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.person_add, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.user.followingCount} following',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.user.accountPublic ? Icons.public : Icons.lock_outline,
                              size: 16,
                              color: const Color(0xFF2E7D32),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.user.accountPublic ? 'Public account' : 'Private account',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // [UI] Posts section
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF66BB6A),
                    ),
                  )
                : _userPosts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No memories to show',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Nothing public here yet, or posts are restricted by privacy.',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _userPosts.length,
                        itemBuilder: (context, index) {
                          return PostCard(post: _userPosts[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
