import 'dart:io';                                      // [IMPORT] File handling for local profile images
import 'package:flutter/foundation.dart' show kIsWeb; // [IMPORT] Web-safe profile image
import 'package:flutter/material.dart';                // [IMPORT] Flutter UI framework
import 'package:flutter_map/flutter_map.dart';        // [IMPORT] OpenStreetMap Flutter widget
import 'package:latlong2/latlong.dart';               // [IMPORT] Latitude/Longitude coordinates
import 'package:provider/provider.dart';              // [IMPORT] State management provider access
import '../models/post.dart';                         // [IMPORT] Post data model for memory pins
import '../providers/post_provider.dart';            // [IMPORT] Post data provider for memories
import '../providers/map_provider.dart';             // [IMPORT] Map state provider
import '../providers/user_provider.dart';            // [IMPORT] User authentication provider
import '../widgets/memory_bottom_sheet.dart';       // [IMPORT] Memory details bottom sheet widget
import '../widgets/floating_action_button.dart';     // [IMPORT] Custom FAB widget (unused import)
import '../screens/create_memory_screen.dart';       // [IMPORT] Screen for creating new memories
import '../screens/profile_screen.dart';            // [IMPORT] Profile screen navigation
import '../screens/feed_screen.dart';               // [IMPORT] Feed screen navigation
import '../screens/simple_login_screen.dart';       // [IMPORT] Login screen for logout

/// Web cannot load arbitrary file paths; avoid [Image.file] there so MapScreen still builds.
Widget _mapAppBarAvatar(UserProvider userProvider) {
  final profileUrl = userProvider.userProfileImage;
  final base64Image = userProvider.userProfileImageBase64;
  
  // Priority 1: Base64 image
  if (base64Image != null && base64Image.isNotEmpty) {
    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(base64Decode(base64Image), width: 32, height: 32, fit: BoxFit.cover),
      );
    } catch (e) {
      debugPrint('Error displaying base64 profile image: $e');
    }
  }
  
  // Priority 2: Network URL
  if (profileUrl != null && profileUrl.isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        profileUrl,
        width: 32,
        height: 32,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Color(0xFF66BB6A), size: 16),
      ),
    );
  }
  
  // Priority 3: App logo as fallback
  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Image.asset('assets/images/app_logo.png', width: 32, height: 32, fit: BoxFit.cover),
  );
}

/// [CLASS] MapScreen
/// [PURPOSE] StatefulWidget displaying OpenStreetMap with memory pins
/// [FUNCTIONALITY] Shows map, memory markers, user profile, navigation to create/view memories
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});                       // [CONSTRUCTOR] Creates map screen

  @override
  State<MapScreen> createState() => _MapScreenState();  // [METHOD] Creates state instance
}

/// [CLASS] _MapScreenState
/// [PURPOSE] State management for MapScreen
/// [FUNCTIONALITY] Manages map display, memory pins, search, bottom navigation
class _MapScreenState extends State<MapScreen> {
  
  // [FIELD] _selectedIndex - Currently selected bottom nav tab (0=Map, 1=Feed, 2=Profile)
  int _selectedIndex = 0;
  
  // [FIELD] _searchController - Text controller for search input
  final TextEditingController _searchController = TextEditingController();
  
  // [FIELD] _filteredPosts - List of posts currently displayed on map (filtered by search)
  List<PostModel> _filteredPosts = [];

  /// [FUNCTION] initState
  /// [PARAMS] None
  /// [RETURNS] void
  /// [PURPOSE] Initialize widget, load user data and map after first frame
  /// [STEP 1] Call parent initState
  /// [STEP 2] Schedule post-frame callback to load data
  /// [STEP 3] Load user data from UserProvider
  /// [STEP 4] Initialize map with posts
  @override
  void initState() {
    super.initState();                                  // [STEP 1] Initialize parent state
    
    // [STEP 2] Schedule data loading after first frame builds
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {                                  // [CHECK] Ensure widget still exists
        // [STEP 3] Load user authentication state
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.loadUserData();
        
        // [STEP 4] Initialize map with memory posts
        _initializeMap();
      }
    });
  }

  /// [FUNCTION] _initializeMap
  /// [PARAMS] None
  /// [RETURNS] Future<void>
  /// [PURPOSE] Initialize map position and load memory posts
  /// [STEP 1] Get MapProvider for map state
  /// [STEP 2] Get PostProvider for memory posts
  /// [STEP 3] Initialize map position
  /// [STEP 4] Load all posts from provider
  /// [STEP 5] Update state with loaded posts
  Future<void> _initializeMap() async {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);   // [STEP 1] Get map provider
    final postProvider = Provider.of<PostProvider>(context, listen: false); // [STEP 2] Get post provider

    await mapProvider.initializeMap();               // [STEP 3] Set initial map position
    await postProvider.loadPosts();                  // [STEP 4] Load memory posts

    setState(() {
      _filteredPosts = postProvider.posts;           // [STEP 5] Display all posts initially
    });
  }

  /// [FUNCTION] _refreshPosts
  /// [PARAMS] None
  /// [RETURNS] Future<void>
  /// [PURPOSE] Refresh memory posts from data source
  /// [STEP 1] Get PostProvider
  /// [STEP 2] Reload posts
  /// [STEP 3] Update state with refreshed posts
  Future<void> _refreshPosts() async {
    final postProvider = Provider.of<PostProvider>(context, listen: false);  // [STEP 1] Get post provider
    await postProvider.loadPosts();                   // [STEP 2] Reload posts

    setState(() {
      _filteredPosts = postProvider.posts;            // [STEP 3] Update displayed posts
    });
  }

  /// [FUNCTION] _searchMemories
  /// [PARAMS] query - Search text string
  /// [RETURNS] void
  /// [PURPOSE] Filter displayed memories based on search query
  /// [STEP 1] Get PostProvider for all posts
  /// [STEP 2] If query empty, show all posts
  /// [STEP 3] If query not empty, filter by title/content/username
  void _searchMemories(String query) {
    final postProvider = Provider.of<PostProvider>(context, listen: false);  // [STEP 1] Get all posts

    if (query.isEmpty) {                              // [CHECK] Empty query
      setState(() {
        _filteredPosts = postProvider.posts;         // [STEP 2] Show all posts
      });
    } else {                                          // [CHECK] Has search query
      setState(() {
        // [STEP 3] Filter posts by search terms
        _filteredPosts = postProvider.posts.where((post) =>
        post.title.toLowerCase().contains(query.toLowerCase()) ||      // [MATCH] Title contains query
            post.content.toLowerCase().contains(query.toLowerCase()) ||  // [MATCH] Content contains query
            post.username.toLowerCase().contains(query.toLowerCase())   // [MATCH] Username contains query
        ).toList();
      });
    }
  }

  /// [FUNCTION] _showMemoryDetails
  /// [PARAMS] post - PostModel to display details for
  /// [RETURNS] void
  /// [PURPOSE] Show memory details in bottom sheet modal
  void _showMemoryDetails(PostModel post) {
    showModalBottomSheet(
      context: context,                               // [CONTEXT] Build context
      backgroundColor: Colors.transparent,            // [STYLE] Transparent background
      isScrollControlled: true,                       // [BEHAVIOR] Allow full height
      builder: (context) => MemoryBottomSheet(        // [WIDGET] Memory details sheet
        post: post,                                   // [DATA] Memory post data
      ),
    );
  }

  /// [FUNCTION] build
  /// [PARAMS] context - BuildContext for widget tree
  /// [RETURNS] Widget - The map screen UI
  /// [PURPOSE] Build the visual interface for the map with memory pins
  @override
  Widget build(BuildContext context) {
    // [GET] Access MapProvider for map state
    final mapProvider = Provider.of<MapProvider>(context);
    // [GET] Access UserProvider for user authentication
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      // [UI] App bar with map title
      appBar: AppBar(
        title: const Text(                              // [UI] Title text
          'Social Memories Map',
          style: TextStyle(
            color: Color(0xFF2E7D32),                  // [STYLE] Dark green
            fontWeight: FontWeight.bold,               // [STYLE] Bold text
          ),
        ),
        backgroundColor: Colors.transparent,          // [STYLE] Transparent background
        elevation: 0,                                   // [STYLE] No shadow
        centerTitle: true,                            // [STYLE] Center title
        actions: [
          // [UI] Profile avatar in app bar - now clickable
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFE8F5E9),
              child: _mapAppBarAvatar(userProvider),
            ),
          ),
          const SizedBox(width: 10),                   // [UI] Spacing
          
          // [UI BUTTON] Logout button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),  // [UI] Red logout icon
            onPressed: () async {                        // [ACTION] Logout user
              await userProvider.logout();              // [STEP 1] Call logout
              Navigator.pushReplacement(               // [STEP 2] Navigate to login
                context,
                MaterialPageRoute(
                  builder: (context) => const SimpleLoginScreen(),  // [NAVIGATE] Go to login
                ),
              );
            },
          ),
        ],
      ),

      // [UI BODY] FlutterMap widget for OpenStreetMap
      body: FlutterMap(
        mapController: mapProvider.mapController,       // [CONTROLLER] Map controller
        options: MapOptions(
          initialCenter: mapProvider.initialPosition,   // [POS] Initial map center
          initialZoom: 14,                              // [ZOOM] Initial zoom level
        ),
        children: [
          // [LAYER] OpenStreetMap tile layer
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',  // [URL] OSM tile URL
            userAgentPackageName: 'com.example.social_memories',  // [ID] App identifier for OSM
          ),
          
          // [LAYER] Memory pin markers
          MarkerLayer(
            markers: _filteredPosts.map((post) => Marker(  // [MAP] Convert posts to markers
              point: LatLng(post.latitude, post.longitude),  // [POS] Post coordinates
              width: 40,                                  // [STYLE] Marker width
              height: 40,                                 // [STYLE] Marker height
              child: GestureDetector(
                onTap: () => _showMemoryDetails(post),   // [ACTION] Tap to show details
                child: Container(
                  decoration: BoxDecoration(
                    // [COLOR] Green for current user, light green for others
                    color: post.userId == userProvider.userId
                        ? const Color(0xFF2E7D32)       // [STYLE] Dark green for own posts
                        : const Color(0xFF66BB6A),       // [STYLE] Light green for others
                    borderRadius: BorderRadius.circular(20),  // [STYLE] Rounded marker
                  ),
                  child: const Icon(
                    Icons.place,                         // [ICON] Location pin
                    color: Colors.white,                // [STYLE] White icon
                    size: 24,                           // [STYLE] Icon size
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),

      // [UI FAB] Column with location and add buttons
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Location button
          FloatingActionButton(
            heroTag: "location",
            backgroundColor: const Color(0xFF2196F3),      // [STYLE] Blue button
            child: const Icon(Icons.my_location),         // [ICON] Location icon
            onPressed: () async {                          // [ACTION] Go to current location
              final mapProvider = Provider.of<MapProvider>(context, listen: false);
              await mapProvider.goToCurrentLocation();
            },
          ),
          const SizedBox(height: 16),                    // [SPACING] Between buttons
          
          // Add memory button
          FloatingActionButton(
            heroTag: "add",
            backgroundColor: const Color(0xFF66BB6A),      // [STYLE] Green button
            child: const Icon(Icons.add),                  // [ICON] Plus icon
            onPressed: () async {                          // [ACTION] Create new memory
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateMemoryScreen(),  // [NAVIGATE] Create memory
                ),
              );

              // [REFRESH] Reload posts after creating memory
              _refreshPosts();
            },
          ),
        ],
      ),

      // [UI NAV] Bottom navigation bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,                 // [STATE] Selected tab index
        onTap: (index) async {                        // [ACTION] Tab selected
          setState(() {
            _selectedIndex = index;                   // [UPDATE] Update selected index
          });

          // [SWITCH] Handle navigation based on tab
          switch (index) {
            case 0:                                   // [TAB] Map
              await _refreshPosts();                  // [ACTION] Refresh posts
              break;
            case 1:                                   // [TAB] Feed
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FeedScreen(),  // [NAVIGATE] Go to feed
                ),
              );
              break;
            case 2:                                   // [TAB] Profile
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),  // [NAVIGATE] Go to profile
                ),
              );
              break;
          }
        },
        items: const [                                // [ITEMS] Navigation items
          BottomNavigationBarItem(
            icon: Icon(Icons.map),                     // [ICON] Map icon
            label: 'Map',                               // [LABEL] Map tab
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.feed),                     // [ICON] Feed icon
            label: 'Feed',                              // [LABEL] Feed tab
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),                   // [ICON] Person icon
            label: 'Profile',                          // [LABEL] Profile tab
          ),
        ],
      ),
    );
  }
}