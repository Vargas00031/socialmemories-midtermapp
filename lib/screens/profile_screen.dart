import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/post_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/post_card.dart';
import '../theme/app_theme.dart';
import 'simple_login_screen.dart';
import 'map_screen.dart';
import 'followers_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _bioController = TextEditingController();
  bool _isEditingBio = false;

  // FIX: store bytes for instant local preview while uploading
  Uint8List? _pendingAvatarBytes;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.loadUserData();
        if (userProvider.currentUser?.bio != null) {
          _bioController.text = userProvider.currentUser!.bio!;
        }
        _loadUserMemories();
      }
    });
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUserMemories() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    await postProvider.loadUserPosts(userProvider.userId);
  }

  // FIX: uses readAsBytes() → putData() so it works on web AND mobile
  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null || !mounted) return;

      // Show local preview immediately
      final bytes = await image.readAsBytes();
      setState(() {
        _pendingAvatarBytes = bytes;
        _isUploadingAvatar = true;
      });

      // Upload using base64 (no Firebase Storage)
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final success = await userProvider.updateProfileImageBase64(bytes);

      if (!mounted) return;
      setState(() {
        _isUploadingAvatar = false;
        _pendingAvatarBytes = null;
      });

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update profile picture'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
          _pendingAvatarBytes = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _saveBio() async {
    await Provider.of<UserProvider>(context, listen: false)
        .updateBio(_bioController.text.trim());
    if (mounted) setState(() => _isEditingBio = false);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final postProvider = Provider.of<PostProvider>(context);
    final user = userProvider.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(color: AppTheme.darkGreen, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            tooltip: 'Logout',
            onPressed: () async {
              await userProvider.logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SimpleLoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute<void>(builder: (_) => const MapScreen()),
          );
        },
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.map_rounded, color: Colors.white),
        label: const Text('Go to Map', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserMemories,
        color: AppTheme.primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ── Gradient header card ──
              _buildProfileHeader(user, userProvider),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBioSection(user),
                    const SizedBox(height: 16),
                    _buildPrivacyCard(user, userProvider),
                    const SizedBox(height: 16),
                    _buildStatsRow(user, postProvider),
                    const SizedBox(height: 20),
                    const Divider(height: 1, thickness: 1),
                    const SizedBox(height: 20),
                    const Text(
                      'My Memories',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkGreen),
                    ),
                    const SizedBox(height: 12),
                    _buildMemoriesList(postProvider),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(dynamic user, UserProvider userProvider) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.lightGreen, AppTheme.cream],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          // Avatar with upload overlay
          Stack(
            alignment: Alignment.center,
            children: [
              // Avatar circle
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryGreen, width: 3),
                  boxShadow: AppTheme.mediumShadow,
                ),
                child: ClipOval(
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: _buildAvatarImage(user),
                  ),
                ),
              ),
              // Upload progress overlay
              if (_isUploadingAvatar)
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ),
              // Camera button (bottom-right)
              if (!_isUploadingAvatar)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Username
          Text(
            user?.username ?? 'Loading...',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGreen,
            ),
          ),
          if (user?.email != null && !user!.email.contains('@local.app')) ...[
            const SizedBox(height: 4),
            Text(
              user.email,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  // FIX: show pending bytes first (immediate feedback), then fall back to network URL
  Widget _buildAvatarImage(dynamic user) {
    // Priority 1: pending upload bytes (instant preview)
    if (_pendingAvatarBytes != null) {
      return Image.memory(_pendingAvatarBytes!, fit: BoxFit.cover);
    }

    // Priority 2: base64 image from Firestore
    final base64Image = user?.profileImageBase64;
    if (base64Image != null && base64Image.isNotEmpty) {
      try {
        return Image.memory(base64Decode(base64Image), fit: BoxFit.cover);
      } catch (e) {
        debugPrint('Error displaying base64 profile image: $e');
      }
    }

    // Priority 3: existing network URL (fallback)
    final profileUrl = user?.profileImageUrl;
    if (profileUrl != null && profileUrl.isNotEmpty) {
      return Image.network(
        profileUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _avatarPlaceholder(),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            color: AppTheme.lightGreen,
            child: const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primaryGreen, strokeWidth: 2),
            ),
          );
        },
      );
    }

    return _avatarPlaceholder();
  }

  Widget _avatarPlaceholder() {
    return Container(
      color: AppTheme.lightGreen,
      child: const Icon(Icons.person_rounded,
          size: 60, color: AppTheme.primaryGreen),
    );
  }

  Widget _buildBioSection(dynamic user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppTheme.primaryGreen, size: 18),
              const SizedBox(width: 6),
              const Text('About Me',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.darkGreen)),
              const Spacer(),
              if (!_isEditingBio)
                TextButton.icon(
                  onPressed: () => setState(() => _isEditingBio = true),
                  icon: const Icon(Icons.edit_rounded, size: 14),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isEditingBio)
            Column(
              children: [
                TextField(
                  controller: _bioController,
                  maxLines: 3,
                  maxLength: 200,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Tell us about yourself…',
                    filled: true,
                    fillColor: AppTheme.lightGreen.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _isEditingBio = false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveBio,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            )
          else
            GestureDetector(
              onTap: () => setState(() => _isEditingBio = true),
              child: Text(
                (user?.bio != null && user!.bio!.isNotEmpty)
                    ? user.bio!
                    : 'Tap to add a bio…',
                style: TextStyle(
                  color: (user?.bio != null && user!.bio!.isNotEmpty)
                      ? Colors.grey[800]
                      : Colors.grey[400],
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard(dynamic user, UserProvider userProvider) {
    final isPublic = user?.accountPublic ?? true;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.lightGreen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_person_rounded,
                  color: AppTheme.primaryGreen, size: 18),
              const SizedBox(width: 6),
              const Text('Account Privacy',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.darkGreen)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isPublic
                ? 'Public — Others can find you in Search.'
                : 'Private — Your profile is hidden from Search.',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          const SizedBox(height: 10),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                  value: true,
                  label: Text('Public'),
                  icon: Icon(Icons.public, size: 16)),
              ButtonSegment<bool>(
                  value: false,
                  label: Text('Private'),
                  icon: Icon(Icons.lock_outline, size: 16)),
            ],
            selected: {isPublic},
            onSelectionChanged: (Set<bool> next) async {
              if (user == null) return;
              await userProvider.updateAccountPrivacy(accountPublic: next.first);
              if (mounted) setState(() {});
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppTheme.primaryGreen;
                }
                return null;
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(dynamic user, PostProvider postProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStat('Memories', postProvider.posts.length, icon: Icons.photo_library_rounded),
          _buildStatDivider(),
          _buildStat(
            'Followers',
            user?.followersCount ?? 0,
            icon: Icons.people_rounded,
            onTap: () => _showFollowers(user?.uid ?? ''),
          ),
          _buildStatDivider(),
          _buildStat(
            'Following',
            user?.followingCount ?? 0,
            icon: Icons.person_add_rounded,
            onTap: () => _showFollowing(user?.uid ?? ''),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 40, width: 1, color: Colors.grey[200]);
  }

  Widget _buildMemoriesList(PostProvider postProvider) {
    if (postProvider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }
    if (postProvider.posts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          children: [
            Icon(Icons.photo_album_outlined, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'No memories yet',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[500]),
            ),
            const SizedBox(height: 4),
            Text('Start pinning your memories on the map!',
                style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          ],
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: postProvider.posts.length,
      itemBuilder: (context, index) =>
          PostCard(post: postProvider.posts[index]),
    );
  }

  void _showFollowers(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => FollowersScreen(userId: userId, isFollowers: true)),
    );
  }

  void _showFollowing(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => FollowersScreen(userId: userId, isFollowers: false)),
    );
  }

  Widget _buildStat(String label, int value,
      {VoidCallback? onTap, required IconData icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon,
              size: 20,
              color: onTap != null ? AppTheme.primaryGreen : Colors.grey[400]),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: onTap != null ? AppTheme.darkGreen : Colors.grey[700],
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              decoration:
                  onTap != null ? TextDecoration.underline : null,
            ),
          ),
        ],
      ),
    );
  }
}
