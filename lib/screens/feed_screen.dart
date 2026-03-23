import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../providers/post_provider.dart';
import '../providers/user_provider.dart';
import '../services/firebase_service.dart';
import '../services/post_service.dart';
import '../widgets/post_card.dart';
import 'create_memory_screen.dart';
import 'user_profile_screen.dart';

/// Feed screen showing a list of recent memory posts
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<PostModel> _filteredPosts = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Load user data immediately
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.loadUserData();
        _loadPosts();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    
    // Load following list first
    await userProvider.loadUserData();
    final followingIds = await PostService().getFollowingIds(userProvider.userId);
    
    // Load feed posts (own posts + followed users' public posts)
    await postProvider.loadFeedPosts(userProvider.userId, followingIds);
    
    if (mounted) {
      setState(() {
        _filteredPosts = postProvider.posts;
      });
    }
  }

  static const Duration _searchQueryTimeout = Duration(seconds: 15);

  /// Runs Firestore prefix queries in parallel with timeouts so one slow query cannot hang the UI.
  Future<List<UserModel>> _searchUsers(String query, String viewerUid) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final users = FirebaseService.instance.usersCollection;

    Future<List<UserModel>> runPrefixQuery(
      Query<Map<String, dynamic>> query,
    ) async {
      try {
        final snap = await query.get().timeout(_searchQueryTimeout);
        return snap.docs.map(UserModel.fromFirestore).toList();
      } on TimeoutException catch (e) {
        debugPrint('User search timed out: $e');
        return [];
      } catch (e) {
        debugPrint('User search query failed: $e');
        return [];
      }
    }

    try {
      final lower = users
          .where('usernameLower', isGreaterThanOrEqualTo: q)
          .where('usernameLower', isLessThanOrEqualTo: '$q\uf8ff')
          .limit(20);
      final email = users
          .where('email', isGreaterThanOrEqualTo: q)
          .where('email', isLessThanOrEqualTo: '$q\uf8ff')
          .limit(20);
      final legacyName = users
          .where('username', isGreaterThanOrEqualTo: q)
          .where('username', isLessThanOrEqualTo: '$q\uf8ff')
          .limit(20);

      final chunks = await Future.wait([
        runPrefixQuery(lower),
        runPrefixQuery(email),
        runPrefixQuery(legacyName),
      ]);

      final merged = <String, UserModel>{};
      for (final list in chunks) {
        for (final u in list) {
          merged[u.uid] = u;
        }
      }

      final out = merged.values.where((u) {
        if (u.accountPublic) return true;
        return u.uid == viewerUid;
      }).toList();

      out.sort((a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));
      return out;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching users: $e')),
        );
      }
      return [];
    }
  }

  void _searchMemories(String query) {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    
    setState(() {
      _isSearching = query.isNotEmpty;
    });

    if (query.isEmpty) {
      setState(() {
        _filteredPosts = postProvider.posts;
      });
    } else {
      setState(() {
        _filteredPosts = postProvider.posts.where((post) {
          final titleMatch = post.title.toLowerCase().contains(query.toLowerCase());
          final contentMatch = post.content.toLowerCase().contains(query.toLowerCase());
          final userMatch = post.username.toLowerCase().contains(query.toLowerCase());
          return titleMatch || contentMatch || userMatch;
        }).toList();
      });
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('What would you like to search?'),
            const SizedBox(height: 16),
            // [BUTTON] Search memories
            ListTile(
              leading: const Icon(Icons.search, color: Color(0xFF66BB6A)),
              title: const Text('Search Memories'),
              subtitle: const Text('Search by title, content, or username'),
              onTap: () {
                Navigator.pop(context);
                _showMemoriesSearch();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_search, color: Colors.blue),
              title: const Text('Search Users'),
              subtitle: const Text('Search users by username'),
              onTap: () {
                Navigator.pop(context);
                _showUsersSearch();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// [FUNCTION] _showMemoriesSearch
  /// [RETURNS] void
  /// [PURPOSE] Show memories search dialog
  void _showMemoriesSearch() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Memories'),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search by title, content, or username...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search, color: Color(0xFF66BB6A)),
          ),
          onChanged: _searchMemories,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              _searchMemories('');
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  /// [FUNCTION] _showUsersSearch
  /// [RETURNS] void
  /// [PURPOSE] Show users search dialog with results
  void _showUsersSearch() {
    final userSearchController = TextEditingController();
    final feedContext = context;
    List<UserModel> searchResults = [];
    bool isSearching = false;
    bool hasSearched = false;
    int requestId = 0;

    Future<void> runSearch(StateSetter setDialogState) async {
      final text = userSearchController.text.trim();
      if (text.isEmpty) return;

      final viewerUid = Provider.of<UserProvider>(feedContext, listen: false).userId;

      final myRequestId = ++requestId;
      setDialogState(() {
        isSearching = true;
        hasSearched = false;
      });
      List<UserModel> results = [];

      // Safety: if a Firestore query never resolves on web for some reason,
      // the dialog must stop loading.
      Timer? safetyTimer;
      safetyTimer = Timer(const Duration(seconds: 25), () {
        if (myRequestId != requestId) return;
        if (!feedContext.mounted) return;
        setDialogState(() {
          isSearching = false;
          searchResults = results;
          hasSearched = true;
        });
      });

      try {
        results = await _searchUsers(text, viewerUid);
      } finally {
        safetyTimer?.cancel();
        if (feedContext.mounted && myRequestId == requestId) {
          setDialogState(() {
            isSearching = false;
            searchResults = results;
            hasSearched = true;
          });
        }
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (statefulContext, setDialogState) => AlertDialog(
          title: const Text('Search Users'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                TextField(
                  controller: userSearchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Username or email…',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person_search, color: Color(0xFF66BB6A)),
                    suffixIcon: isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () => runSearch(setDialogState),
                          ),
                  ),
                  onSubmitted: (_) => runSearch(setDialogState),
                ),
                
                const SizedBox(height: 16),
                
                Expanded(
                  child: isSearching
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF66BB6A),
                          ),
                        )
                      : searchResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                hasSearched
                                    ? 'No users found'
                                    : 'Enter a username or email to search',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final user = searchResults[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFE8F5E9),
                                backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                                    ? NetworkImage(user.profileImageUrl!)
                                    : null,
                                child: user.profileImageUrl == null || user.profileImageUrl!.isEmpty
                                    ? const Icon(Icons.person, color: Color(0xFF66BB6A))
                                    : null,
                              ),
                              title: Text(user.username),
                              subtitle: Text(
                                user.bio ?? 'No bio available',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${user.followersCount}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.pop(dialogContext);
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (!feedContext.mounted) return;
                                  Navigator.of(feedContext).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => UserProfileScreen(user: user),
                                    ),
                                  );
                                });
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.feed,
                    size: 24,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Social Memories Feed',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF2E7D32)),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        color: const Color(0xFF66BB6A),
        child: postProvider.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF66BB6A),
                ),
              )
            : postProvider.error != null
                ? Center(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Error loading memories',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              postProvider.error!,
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadPosts,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF66BB6A),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : _filteredPosts.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isSearching ? Icons.search_off : Icons.feed_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _isSearching ? 'No memories found' : 'No memories yet',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isSearching 
                                      ? 'Try different search terms'
                                      : 'Be the first to share a memory!',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (!_isSearching) ...[
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const CreateMemoryScreen(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF66BB6A),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Create Memory'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          // Search results indicator
                          if (_isSearching)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              color: const Color(0xFFE8F5E9),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.search,
                                    color: Color(0xFF66BB6A),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_filteredPosts.length} memories found',
                                    style: const TextStyle(
                                      color: Color(0xFF2E7D32),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      _searchMemories('');
                                    },
                                    child: const Text('Clear'),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Posts list
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredPosts.length,
                              itemBuilder: (context, index) {
                                final post = _filteredPosts[index];
                                return PostCard(
                                  post: post,
                                  onTap: () => _showPostDetails(post),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }
  
  /// Show post details in a bottom sheet
  void _showPostDetails(PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 150, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Post content
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFE8F5E9),
                    backgroundImage: post.userProfileImage != null && post.userProfileImage!.isNotEmpty
                        ? NetworkImage(post.userProfileImage!)
                        : null,
                    child: post.userProfileImage == null || post.userProfileImage!.isEmpty
                        ? const Icon(Icons.person, color: Color(0xFF66BB6A), size: 24)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        Text(
                          _formatDate(post.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Title
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Content
              Text(
                post.content,
                style: const TextStyle(fontSize: 16),
              ),
              
              const SizedBox(height: 16),
              
              // Image
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    post.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.image, size: 50, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Location info
              Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF66BB6A)),
                  const SizedBox(width: 8),
                  Text(
                    'Lat: ${post.latitude.toStringAsFixed(4)}, Lng: ${post.longitude.toStringAsFixed(4)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Stats
              Row(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.red, size: 20),
                      const SizedBox(width: 4),
                      Text('${post.likesCount}'),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Row(
                    children: [
                      const Icon(Icons.comment, color: Color(0xFF66BB6A), size: 20),
                      const SizedBox(width: 4),
                      Text('${post.commentsCount}'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

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
}
