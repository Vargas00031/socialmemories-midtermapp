import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/comment.dart';
import '../models/post.dart';
import '../providers/user_provider.dart';
import '../providers/post_provider.dart';
import 'memory_bottom_sheet.dart';

/// Card for a memory post with like and comment actions backed by Firestore.
class PostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onTap;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool? _liked;
  bool _checkingLike = true;

  PostModel get post => widget.post;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshLiked());
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      _liked = null;
      _checkingLike = true;
      _refreshLiked();
    }
  }

  Future<void> _refreshLiked() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final postProvider = Provider.of<PostProvider>(context, listen: false);

    if (!userProvider.isLoggedIn) {
      if (mounted) {
        setState(() {
          _liked = false;
          _checkingLike = false;
        });
      }
      return;
    }

    final liked = await postProvider.isPostLiked(post.id, userProvider.userId);
    if (mounted) {
      setState(() {
        _liked = liked;
        _checkingLike = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log in to like memories.')),
      );
      return;
    }

    final postProvider = Provider.of<PostProvider>(context, listen: false);
    final uid = userProvider.userId;

    if (_liked == true) {
      await postProvider.unlikePost(post.id, uid);
    } else {
      await postProvider.likePost(post.id, uid);
    }
    await _refreshLiked();
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _CommentsSheet(post: post),
    );
  }

  @override
  Widget build(BuildContext context) {
    final liked = _liked == true;

    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User header with profile image and username
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show shared by info if it's a shared post
                  if (post.isSharedPost && post.sharedByUsername != null) ...[
                    Row(
                      children: [
                        Icon(Icons.share, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Shared by ${post.sharedByUsername}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatTimestamp(post.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Original author info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFE8F5E9),
                        backgroundImage: _getProfileImageProvider(post.userProfileImage, post.userProfileImageBase64),
                        child: (post.userProfileImage == null || post.userProfileImage!.isEmpty) && 
                               (post.userProfileImageBase64 == null || post.userProfileImageBase64!.isEmpty)
                            ? const Icon(Icons.person, color: Color(0xFF66BB6A), size: 20)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.username.isNotEmpty ? post.username : 'Unknown User',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            if (!post.isSharedPost)
                              Text(
                                _formatTimestamp(post.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Privacy indicator
                      _buildPrivacyIcon(post.privacy),
                    ],
                  ),
                ],
              ),
            ),
            if (post.imageDataBase64 != null && post.imageDataBase64!.isNotEmpty)
              ClipRRect(
                child: Image.memory(
                  base64Decode(post.imageDataBase64!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Image not available', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  },
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              )
            else if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
              ClipRRect(
                child: Image.network(
                  post.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Image not available', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[100],
                      child: const Center(
                        child: CircularProgressIndicator(color: Color(0xFF66BB6A)),
                      ),
                    );
                  },
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Memory Location',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Text(
                    '${post.likesCount} likes',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _checkingLike ? null : _toggleLike,
                      icon: Icon(
                        liked ? Icons.favorite : Icons.favorite_border,
                        color: Colors.red,
                      ),
                      label: Text('${post.likesCount}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showComments(context),
                      icon: const Icon(Icons.comment, color: Colors.blue),
                      label: Text('${post.commentsCount}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _sharePost(post, context),
                      icon: const Icon(Icons.share, color: Color(0xFF66BB6A)),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF66BB6A),
                        side: const BorderSide(color: Color(0xFF66BB6A)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => MemoryBottomSheet(post: post),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF66BB6A),
                  ),
                  child: const Text('View Details', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _sharePost(PostModel post, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Memory'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this memory to your profile?'),
            const SizedBox(height: 16),
            const ListTile(
              leading: Icon(Icons.share, color: Color(0xFF66BB6A)),
              title: Text('Share to Profile'),
              subtitle: Text('This will appear on your profile with attribution to the original author'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performShare(post, context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF66BB6A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  Future<void> _performShare(PostModel post, BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to share memories.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final postProvider = Provider.of<PostProvider>(context, listen: false);
    
    try {
      await postProvider.sharePost(
        post.id,
        userProvider.userId,
        userProvider.userName,
        userProvider.userProfileImage,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Memory shared to your profile!'),
            backgroundColor: Color(0xFF66BB6A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Format timestamp to human-readable string
  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Build privacy indicator icon
  Widget _buildPrivacyIcon(PostPrivacy privacy) {
    IconData icon;
    String tooltip;
    Color color;

    switch (privacy) {
      case PostPrivacy.public:
        icon = Icons.public;
        tooltip = 'Public';
        color = Colors.green;
      case PostPrivacy.friends:
        icon = Icons.people;
        tooltip = 'Friends only';
        color = Colors.blue;
      case PostPrivacy.private:
        icon = Icons.lock;
        tooltip = 'Private';
        color = Colors.red;
    }

    return Tooltip(
      message: tooltip,
      child: Icon(icon, size: 18, color: color),
    );
  }

  /// Helper method to get profile image provider
  ImageProvider? _getProfileImageProvider(String? imageUrl, String? base64Data) {
    if (base64Data != null && base64Data.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(base64Data));
      } catch (e) {
        debugPrint('Error decoding base64 profile image: $e');
        return null;
      }
    }
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return NetworkImage(imageUrl);
    }
    return null;
  }
}

class _CommentsSheet extends StatefulWidget {
  final PostModel post;

  const _CommentsSheet({required this.post});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _controller = TextEditingController();
  List<CommentModel> _comments = [];
  bool _loading = true;

  PostModel get post => widget.post;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    final list = await postProvider.getComments(post.id);
    if (mounted) {
      setState(() {
        _comments = list;
        _loading = false;
      });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log in to comment.')),
      );
      return;
    }

    final postProvider = Provider.of<PostProvider>(context, listen: false);
    await postProvider.addComment(
      postId: post.id,
      userId: userProvider.userId,
      username: userProvider.userName,
      userProfileImage: userProvider.userProfileImage,
      content: text,
    );

    if (postProvider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(postProvider.error!)),
      );
      return;
    }

    _controller.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF66BB6A)),
                      )
                    : _comments.isEmpty
                        ? Center(
                            child: Text(
                              'No comments yet.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _comments.length,
                            itemBuilder: (context, i) {
                              final c = _comments[i];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFE8F5E9),
                                  child: Icon(Icons.person, color: Color(0xFF66BB6A)),
                                ),
                                title: Text(
                                  c.username,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(c.content),
                              );
                            },
                          ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Write a comment…',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _send,
                      icon: const Icon(Icons.send, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF66BB6A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
