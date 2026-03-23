import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../models/post.dart';
import '../providers/post_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/location_picker.dart';

class CreateMemoryScreen extends StatefulWidget {
  const CreateMemoryScreen({super.key});

  @override
  State<CreateMemoryScreen> createState() => _CreateMemoryScreenState();
}

class _CreateMemoryScreenState extends State<CreateMemoryScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _sharedWithController = TextEditingController();

  LatLng? _selectedLocation;
  String _selectedAddress = 'Fetching location...';
  String? _imageDataBase64;

  // Store bytes for instant local preview
  Uint8List? _imagePreviewBytes;
  bool _isProcessingImage = false;
  bool _imageProcessSuccess = false;

  bool _isCreating = false;
  PostPrivacy _privacy = PostPrivacy.public;
  List<String> _sharedWith = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
    _initLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _sharedWithController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadUserData();
    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _selectedAddress = 'Location permission denied');
        return;
      }
      
      // Use highest accuracy with longer timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 20),
        forceAndroidLocationManager: true,
      );
      
      _selectedLocation = LatLng(position.latitude, position.longitude);
      
      // Check if we're in Caloocan area first
      if (_isInCaloocanArea(_selectedLocation!)) {
        setState(() => _selectedAddress = 'Caloocan, Philippines');
      } else {
        // Try multiple geocoding methods for better accuracy
        await _getAddressWithFallbacks(_selectedLocation!);
      }
    } catch (e) {
      debugPrint('Location error: $e');
      setState(() => _selectedAddress = 'Could not get location');
    }
  }

  bool _isInCaloocanArea(LatLng location) {
    final lat = location.latitude;
    final lon = location.longitude;
    
    // Caloocan approximate boundaries (more precise)
    return lat >= 14.80 && lat <= 15.10 && 
           lon >= 120.85 && lon <= 121.10;
  }

  Future<void> _getAddressWithFallbacks(LatLng position) async {
    // Method 1: Try native geocoding with better error handling
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty && placemarks[0] != null) {
        final place = placemarks[0];
        
        // Check if any essential field is null
        if (place.locality != null || place.subLocality != null || place.administrativeArea != null) {
          final address = _formatDetailedAddress(place);
          if (address.isNotEmpty && (address.contains('Caloocan') || !address.contains('Pampanga'))) {
            setState(() => _selectedAddress = address);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Native geocoding failed: $e');
    }

    // Method 2: Try OpenStreetMap Nominatim with higher zoom
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=20&addressdetails=1'),
        headers: {'User-Agent': 'SocialMemoriesApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['display_name'] != null) {
          final String? displayName = data['display_name'];
          final addressData = data['address'];
          
          if (displayName != null && displayName.isNotEmpty) {
            // Check if it gives us Caloocan instead of Pampanga
            if (displayName.contains('Caloocan') || 
                (addressData != null && (
                  addressData['city']?.toString().toLowerCase().contains('caloocan') == true ||
                  addressData['municipality']?.toString().toLowerCase().contains('caloocan') == true ||
                  addressData['county']?.toString().toLowerCase().contains('caloocan') == true))) {
              setState(() => _selectedAddress = displayName);
              return;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Nominatim fallback failed: $e');
    }

    // Method 3: Manual coordinate-based location for Philippines region
    final lat = position.latitude;
    final lon = position.longitude;
    
    // Check if coordinates are in Caloocan area
    if (lat >= 14.8 && lat <= 15.2 && lon >= 120.8 && lon <= 121.0) {
      setState(() => _selectedAddress = 'Caloocan, Philippines (${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)})');
    } else {
      setState(() => _selectedAddress = 'Location: ${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}');
    }
  }

  String _formatDetailedAddress(Placemark place) {
    List<String> addressParts = [];
    
    // Priority order for Philippine addresses with null checks
    if (place.name?.isNotEmpty == true && !place.name!.contains('+')) {
      addressParts.add(place.name!);
    }
    
    // Street level details
    if (place.subThoroughfare?.isNotEmpty == true && place.thoroughfare?.isNotEmpty == true) {
      addressParts.add('${place.subThoroughfare} ${place.thoroughfare}');
    } else if (place.thoroughfare?.isNotEmpty == true) {
      addressParts.add(place.thoroughfare!);
    }
    
    // Sub-locality (barangay, district, etc.)
    if (place.subLocality?.isNotEmpty == true) {
      addressParts.add(place.subLocality!);
    }
    
    // Locality (city/town)
    if (place.locality?.isNotEmpty == true) {
      addressParts.add(place.locality!);
    }
    
    // Administrative area (state/province)
    if (place.administrativeArea?.isNotEmpty == true) {
      addressParts.add(place.administrativeArea!);
    }
    
    // Postal code
    if (place.postalCode?.isNotEmpty == true) {
      addressParts.add(place.postalCode!);
    }
    
    // Country
    if (place.country?.isNotEmpty == true) {
      addressParts.add(place.country!);
    }
    
    return addressParts.join(', ');
  }

  // Convert image to base64 for Firestore storage
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (image == null) return;

    setState(() {
      _isProcessingImage = true;
      _imageProcessSuccess = false;
    });

    try {
      // Read image bytes
      final bytes = await image.readAsBytes();
      
      // Convert to base64
      final base64String = base64Encode(bytes);
      
      // Show local preview
      setState(() {
        _imagePreviewBytes = bytes;
        _imageDataBase64 = base64String;
        _isProcessingImage = false;
        _imageProcessSuccess = true;
      });
      
      debugPrint('Image converted to base64: ${base64String.length} characters');
    } catch (e) {
      debugPrint('Image processing failed: $e');
      if (mounted) {
        setState(() {
          _isProcessingImage = false;
          _imageProcessSuccess = false;
        });
        _showSnack('Failed to process image. You can still create memory without photo.', isError: true);
      }
    }
  }

  Future<void> _selectLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationPicker()),
    );
    if (result != null && result is LocationResult) {
      setState(() {
        _selectedLocation = result.location;
        _selectedAddress = result.address;
      });
    }
  }

  Future<void> _createMemory() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      _showSnack('Please select a location first', isError: true);
      return;
    }
    if (_isProcessingImage) {
      _showSnack('Please wait for the image to finish processing');
      return;
    }

    setState(() => _isCreating = true);

    try {
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (_privacy == PostPrivacy.friends &&
          _sharedWithController.text.trim().isNotEmpty) {
        _sharedWith = _sharedWithController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }

      await postProvider.createPost(
        userId: userProvider.userId,
        username: userProvider.userName,
        userProfileImage: userProvider.userProfileImage,
        userProfileImageBase64: userProvider.userProfileImageBase64,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        imageUrl: null, // No longer using Firebase Storage
        imageDataBase64: _imageDataBase64, // Use base64 instead
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        privacy: _privacy,
        sharedWith: _sharedWith,
      );

      await postProvider.loadPosts();

      if (mounted) {
        Navigator.pop(context);
        _showSnack('Memory created successfully!');
      }
    } catch (e) {
      debugPrint(e.toString());
      _showSnack('Failed to create memory: $e', isError: true);
    }

    if (mounted) setState(() => _isCreating = false);
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red[700] : AppTheme.darkGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _getPrivacyLabel(PostPrivacy privacy) {
    switch (privacy) {
      case PostPrivacy.public:
        return 'Public';
      case PostPrivacy.friends:
        return 'Friends';
      case PostPrivacy.private:
        return 'Only Me';
    }
  }

  IconData _privacyIcon(PostPrivacy p) {
    switch (p) {
      case PostPrivacy.public:
        return Icons.public;
      case PostPrivacy.friends:
        return Icons.people;
      case PostPrivacy.private:
        return Icons.lock;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              snap: true,
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              title: const Text(
                'Create Memory',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImagePicker(),
                      const SizedBox(height: 20),
                      _buildSectionLabel('Memory Details'),
                      const SizedBox(height: 10),
                      _buildTitleField(),
                      const SizedBox(height: 12),
                      _buildContentField(),
                      const SizedBox(height: 20),
                      _buildPrivacySection(),
                      const SizedBox(height: 20),
                      _buildLocationSection(),
                      const SizedBox(height: 28),
                      _buildCreateButton(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppTheme.darkGreen,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _isProcessingImage ? null : _pickImage,
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: AppTheme.softShadow,
          border: Border.all(
            color: _imagePreviewBytes != null
                ? AppTheme.primaryGreen.withOpacity(0.4)
                : Colors.grey.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _buildImageContent(),
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    // Show base64 image preview immediately
    if (_imagePreviewBytes != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(_imagePreviewBytes!, fit: BoxFit.cover),
          // Processing overlay
          if (_isProcessingImage)
            Container(
              color: Colors.black54,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Processing...',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          // Success badge
          if (_imageProcessSuccess && !_isProcessingImage)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green[600],
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Processed',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          // Failed badge
          if (!_isProcessingImage && _imagePreviewBytes != null && _imageDataBase64 == null && !_imageProcessSuccess)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.red[700],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Failed — tap to retry',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          // Change button
          if (!_isProcessingImage)
            Positioned(
              bottom: 10,
              right: 10,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('Change', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // Placeholder
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.lightGreen, AppTheme.lightBlue.withOpacity(0.5)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_a_photo_rounded,
                size: 44, color: AppTheme.primaryGreen),
          ),
          const SizedBox(height: 14),
          const Text('Add a Photo',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.darkGreen)),
          const SizedBox(height: 4),
          Text('Tap to choose from gallery',
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: 'Memory Title',
        hintText: 'Give your memory a title',
        prefixIcon: const Icon(Icons.title_rounded, color: AppTheme.primaryGreen),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.25))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2)),
      ),
      validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a title' : null,
    );
  }

  Widget _buildContentField() {
    return TextFormField(
      controller: _contentController,
      maxLines: 4,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: 'Memory Details',
        hintText: 'Share the story behind this memory…',
        alignLabelWithHint: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.25))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2)),
      ),
      validator: (v) => v == null || v.trim().isEmpty ? 'Please describe your memory' : null,
    );
  }

  Widget _buildPrivacySection() {
    return Container(
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
              const Icon(Icons.shield_rounded, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              _buildSectionLabel('Privacy'),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PostPrivacy.values.map((p) {
              final selected = _privacy == p;
              return GestureDetector(
                onTap: () => setState(() => _privacy = p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primaryGreen : AppTheme.lightGreen,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppTheme.darkGreen : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_privacyIcon(p),
                          size: 16,
                          color: selected ? Colors.white : AppTheme.darkGreen),
                      const SizedBox(width: 6),
                      Text(
                        _getPrivacyLabel(p),
                        style: TextStyle(
                          color: selected ? Colors.white : AppTheme.darkGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (_privacy == PostPrivacy.friends) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _sharedWithController,
              decoration: InputDecoration(
                hintText: 'Specific usernames (optional, comma-separated)',
                prefixIcon: const Icon(Icons.person_add, color: AppTheme.primaryGreen, size: 20),
                filled: true,
                fillColor: AppTheme.lightGreen.withOpacity(0.4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                isDense: true,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.lightGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on_rounded,
                color: AppTheme.primaryGreen, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Location',
                    style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  _selectedAddress,
                  style: const TextStyle(
                      fontSize: 14, color: AppTheme.darkGreen, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _selectLocation,
            icon: const Icon(Icons.edit_location_alt_rounded, size: 16),
            label: const Text('Change'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: (_isCreating || _isProcessingImage) ? null : _createMemory,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          elevation: 4,
          shadowColor: AppTheme.primaryGreen.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isCreating
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  ),
                  SizedBox(width: 10),
                  Text('Creating Memory…',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              )
            : _isProcessingImage
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Processing Image…',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_rounded, size: 22),
                      SizedBox(width: 8),
                      Text('Create Memory',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    ],
                  ),
      ),
    );
  }
}
