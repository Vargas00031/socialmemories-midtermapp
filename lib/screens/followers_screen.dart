import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/firebase_service.dart';
import 'user_profile_screen.dart';

/// Screen to display list of followers or following users
class FollowersScreen extends StatefulWidget {
  final String userId;
  final bool isFollowers; // true for followers, false for following

  const FollowersScreen({
    super.key,
    required this.userId,
    this.isFollowers = true,
  });

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  final FirebaseService _firebaseService = FirebaseService.instance;
  List<UserModel> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    
    try {
      final users = <UserModel>[];
      
      if (widget.isFollowers) {
        // Load followers
        final snapshot = await _firebaseService.followersCollection
            .where('followingId', isEqualTo: widget.userId)
            .get();
        
        for (final doc in snapshot.docs) {
          final followerId = doc.data()['followerId'] as String;
          final userDoc = await _firebaseService.usersCollection.doc(followerId).get();
          if (userDoc.exists) {
            users.add(UserModel.fromFirestore(userDoc));
          }
        }
      } else {
        // Load following
        final snapshot = await _firebaseService.followingCollection
            .where('followerId', isEqualTo: widget.userId)
            .get();
        
        for (final doc in snapshot.docs) {
          final followingId = doc.data()['followingId'] as String;
          final userDoc = await _firebaseService.usersCollection.doc(followingId).get();
          if (userDoc.exists) {
            users.add(UserModel.fromFirestore(userDoc));
          }
        }
      }
      
      setState(() => _users = users);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFollowers ? 'Followers' : 'Following'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF66BB6A)))
          : _users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.isFollowers ? Icons.people_outline : Icons.person_add,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No ${widget.isFollowers ? 'followers' : 'following'} yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFE8F5E9),
                        backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                            ? NetworkImage(user.profileImageUrl!)
                            : null,
                        child: user.profileImageUrl == null || user.profileImageUrl!.isEmpty
                            ? const Icon(Icons.person, color: Color(0xFF66BB6A))
                            : null,
                      ),
                      title: Text(
                        user.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      subtitle: user.bio != null && user.bio!.isNotEmpty
                          ? Text(
                              user.bio!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfileScreen(user: user),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
