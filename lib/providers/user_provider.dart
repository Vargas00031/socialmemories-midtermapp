import 'dart:convert';                                   // [IMPORT] Base64 encoding
import 'dart:io';                                      // [IMPORT] File handling for image files
import 'dart:typed_data';                              // [IMPORT] Uint8List for cross-platform image bytes
import 'package:flutter/foundation.dart';              // [IMPORT] Flutter foundation for ChangeNotifier
import 'package:firebase_auth/firebase_auth.dart';      // [IMPORT] Firebase Authentication
import 'package:cloud_firestore/cloud_firestore.dart'; // [IMPORT] Firestore user profile sync
import 'package:shared_preferences/shared_preferences.dart';  // [IMPORT] Local storage
import '../models/user.dart';                          // [IMPORT] User data model
import '../utils/constants.dart';                     // [IMPORT] App constants for storage keys
import '../services/firebase_service.dart';           // [IMPORT] Firebase services
import 'package:firebase_storage/firebase_storage.dart'; // [IMPORT] Firebase Storage SettableMetadata

/// [CLASS] UserProvider
/// [PURPOSE] ChangeNotifier provider for user authentication and profile state
/// [FUNCTIONALITY] Manages login state, user data, profile image, bio, syncs with Firebase
/// [STORAGE] Uses SharedPreferences for local persistence, Firebase Auth for authentication
class UserProvider extends ChangeNotifier {
  
  // [FIELD] _currentUser - Currently logged in user model (null if not logged in)
  UserModel? _currentUser;
  
  // [FIELD] _isLoading - Loading state flag for async operations
  bool _isLoading = true;
  
  // [FIELD] _error - Error message from last operation (null if no error)
  String? _error;

  /// [CONSTRUCTOR] UserProvider
  /// [PURPOSE] Initialize provider and load saved user data
  UserProvider() {
    _init();                                            // [CALL] Initialize provider data
  }

  /// [FUNCTION] _init
  /// [PARAMS] None
  /// [RETURNS] Future<void>
  /// [PURPOSE] Initialize provider by loading saved user data
  /// [STEP 1] Load user data from storage
  /// [STEP 2] Set loading complete
  /// [STEP 3] Notify listeners of state change
  Future<void> _init() async {
    await loadUserData();                               // [STEP 1] Load saved user data
    _isLoading = false;                                 // [STEP 2] Mark loading complete
    notifyListeners();                                  // [STEP 3] Update all listeners
  }

  // [GETTERS] Public getters for private fields
  
  // [GETTER] currentUser - Returns current user model or null
  UserModel? get currentUser => _currentUser;
  
  // [GETTER] userName - Returns username or 'Guest' if not logged in
  String get userName => _currentUser?.username ?? 'Guest';
  
  // [GETTER] userId - Returns user UID or 'guest' if not logged in
  String get userId => _currentUser?.uid ?? 'guest';
  
  // [GETTER] userProfileImage - Returns profile image URL/path or null
  String? get userProfileImage => _currentUser?.profileImageUrl;
  
  // [GETTER] userProfileImageBase64 - Returns profile image base64 data or null
  String? get userProfileImageBase64 => _currentUser?.profileImageBase64;

  // [GETTER] isLoggedIn - Returns true if user is logged in
  bool get isLoggedIn => _currentUser != null;
  
  // [GETTER] isLoading - Returns current loading state
  bool get isLoading => _isLoading;
  
  // [GETTER] error - Returns current error message or null
  String? get error => _error;

  /// [FUNCTION] loadUserData
  /// [PARAMS] None
  /// [RETURNS] Future<void>
  /// [PURPOSE] Load user data from SharedPreferences and sync with Firebase Auth
  /// [STEP 1] Check if user is logged in via Firebase Auth
  /// [STEP 2] If Firebase user exists, load from Firebase and save to SharedPreferences
  /// [STEP 3] If no Firebase user, try to load from SharedPreferences (fallback)
  Future<void> loadUserData() async {
    try {
      // [STEP 1] Check Firebase Auth current user
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {                       // [CHECK] Firebase user exists
        final prefs = await SharedPreferences.getInstance();
        final savedBio = prefs.getString('user_bio');
        final savedImage = prefs.getString(AppConstants.userProfileImageKey);

        final email = firebaseUser.email ?? '';
        final docRef = FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid);
        final doc = await docRef.get();
        final data = doc.data();

        if (!doc.exists || data == null || (data['email'] == null && data['username'] == null)) {
          final fallbackName =
              firebaseUser.displayName ?? (email.contains('@') ? email.split('@').first : email);
          await docRef.set({
            'uid': firebaseUser.uid,
            'email': email,
            'username': fallbackName,
            'usernameLower': fallbackName.toLowerCase(),
            'profileImageUrl': savedImage ?? '',
            'bio': savedBio ?? '',
            'followersCount': 0,
            'followingCount': 0,
            'createdAt': Timestamp.now(),
            'lastActive': Timestamp.now(),
            'accountVisibility': 'public',
          }, SetOptions(merge: true));
        }

        final d0 = data;
        if (d0 != null &&
            d0['usernameLower'] == null &&
            (d0['username'] != null || d0['email'] != null)) {
          final un = (d0['username'] as String?)?.trim().isNotEmpty == true
              ? d0['username'] as String
              : (email.contains('@') ? email.split('@').first : 'User');
          await docRef.set({
            'username': un,
            'usernameLower': un.toLowerCase(),
          }, SetOptions(merge: true));
        }

        final fresh = await docRef.get();
        if (fresh.exists && fresh.data() != null) {
          _currentUser = UserModel.fromFirestore(fresh);
          final d = fresh.data()!;
          final fsImage = (d['profileImageUrl'] ?? d['profileImage']) as String?;
          final fsBase64Image = d['profileImageBase64'] as String?;
          
          // Handle both URL and base64 profile images
          if ((fsImage == null || fsImage.isEmpty) &&
              savedImage != null &&
              savedImage.isNotEmpty) {
            _currentUser = _currentUser!.copyWith(profileImageUrl: savedImage);
          }
          
          // Handle base64 image from Firestore
          if (fsBase64Image != null && fsBase64Image.isNotEmpty) {
            _currentUser = _currentUser!.copyWith(profileImageBase64: fsBase64Image);
          }
          
          if ((d['bio'] == null || (d['bio'] as String?)?.isEmpty == true) &&
              savedBio != null &&
              savedBio.isNotEmpty) {
            _currentUser = _currentUser!.copyWith(bio: savedBio);
          }
        } else {
          final fallbackName =
              firebaseUser.displayName ?? (email.contains('@') ? email.split('@').first : email);
          _currentUser = UserModel(
            uid: firebaseUser.uid,
            username: fallbackName,
            email: email,
            bio: savedBio,
            profileImageUrl: savedImage,
            followersCount: 0,
            followingCount: 0,
            createdAt: DateTime.now(),
            lastActive: DateTime.now(),
            accountPublic: true,
          );
        }

        await prefs.setBool(AppConstants.isLoggedInKey, true);
        await prefs.setString(AppConstants.userNameKey, _currentUser!.username);
        return;
      }

      // [STEP 3] No Firebase user - try SharedPreferences fallback
      final prefs = await SharedPreferences.getInstance();  // [GET] Local storage

      final isLoggedIn = prefs.getBool(AppConstants.isLoggedInKey) ?? false;  // [GET] Login flag
      final savedName = prefs.getString(AppConstants.userNameKey);           // [GET] Username
      final savedBio = prefs.getString('user_bio');                          // [GET] Bio
      final savedImage = prefs.getString(AppConstants.userProfileImageKey);  // [GET] Image URL
      final savedBase64Image = prefs.getString('user_profile_image_base64');  // [GET] Base64 Image

      if (isLoggedIn && savedName != null) {          // [CHECK] Valid local session
        final docId = savedName.toLowerCase().replaceAll(' ', '_');  // [PROCESS] Create ID from name

        // [CREATE] Build UserModel from local data
        _currentUser = UserModel(
          uid: docId,                                  // [FIELD] Generated UID from name
          username: savedName,                        // [FIELD] Saved username
          email: '$docId@local.app',                 // [FIELD] Generated email
          bio: savedBio,                              // [FIELD] Saved bio
          profileImageUrl: savedImage,                // [FIELD] Saved image URL
          profileImageBase64: savedBase64Image,         // [FIELD] Saved base64 image
          followersCount: 0,                        // [FIELD] Default followers
          followingCount: 0,                        // [FIELD] Default following
          createdAt: DateTime.now(),                 // [FIELD] Current time
          lastActive: DateTime.now(),                 // [FIELD] Current time
          accountPublic: true,                       // [FIELD] Default public
        );
      }
    } catch (e) {                                     // [CATCH] Handle any errors
      debugPrint('Error loading user data: $e');     // [LOG] Print error
    }
  }

  /// [FUNCTION] login
  /// [PARAMS] name - Username or email for display
  /// [PARAMS] uid - Optional Firebase UID (uses generated ID if null)
  /// [RETURNS] Future<void>
  /// [PURPOSE] Log in user and save to SharedPreferences
  /// [STEP 1] Set loading state
  /// [STEP 2] Create UserModel with provided or generated UID
  /// [STEP 3] Save to SharedPreferences
  /// [STEP 4] Clear error or set error on failure
  /// [STEP 5] Reset loading state
  Future<void> login(String name, {String? uid}) async {
    _setLoading(true);                                  // [STEP 1] Show loading
    try {
      final docId = uid ?? name.toLowerCase().replaceAll(' ', '_');  // [PROCESS] Use UID or generate from name

      final prefs = await SharedPreferences.getInstance();  // [GET] Local storage
      final savedBio = prefs.getString('user_bio');           // [GET] Any saved bio
      final savedImage = prefs.getString(AppConstants.userProfileImageKey);  // [GET] Any saved image

      // [CREATE] Build UserModel for logged in user
      _currentUser = UserModel(
        uid: docId,                                    // [FIELD] User UID
        username: name,                               // [FIELD] Display name
        email: '$docId@local.app',                   // [FIELD] Generated email
        bio: savedBio,                                // [FIELD] Bio (may be null)
        profileImageUrl: savedImage,                // [FIELD] Image URL (may be null)
        followersCount: 0,                          // [FIELD] Default followers
        followingCount: 0,                        // [FIELD] Default following
        createdAt: DateTime.now(),                 // [FIELD] Creation time
        lastActive: DateTime.now(),               // [FIELD] Last active time
        accountPublic: true,
      );

      // [STEP 3] Save to SharedPreferences
      await prefs.setBool(AppConstants.isLoggedInKey, true);  // [SAVE] Login flag
      await prefs.setString(AppConstants.userNameKey, name);  // [SAVE] Username

      // [STEP 3A] Also save to Firestore
      final firebaseService = FirebaseService.instance;
      await firebaseService.usersCollection.doc(docId).set({
        'uid': docId,
        'username': name,
        'usernameLower': name.toLowerCase(),
        'email': '$docId@local.app',
        'profileImageUrl': savedImage ?? '',
        'bio': savedBio ?? '',
        'followersCount': 0,
        'followingCount': 0,
        'createdAt': Timestamp.now(),
        'lastActive': Timestamp.now(),
        'accountVisibility': 'public',
      }, SetOptions(merge: true));

      _setError(null);                                // [STEP 4A] Clear any error
    } catch (e) {                                     // [CATCH] Handle errors
      debugPrint('Login Error: $e');                 // [LOG] Print error
      _setError('Login failed');                     // [STEP 4B] Set error message
    } finally {
      _setLoading(false);                             // [STEP 5] Hide loading
    }
  }

  /// [FUNCTION] updateBio
  /// [PURPOSE] Save user bio to SharedPreferences and update user model
  /// [STEP 1] Check if user is logged in
  /// [STEP 2] Save bio to SharedPreferences
  /// [STEP 3] Update current user with new bio
  /// [STEP 4] Notify listeners of change
  /// [STEP 5] Handle errors
  Future<void> updateBio(String bio) async {
    if (_currentUser == null) return;                 // [STEP 1] Exit if no user

    try {
      final prefs = await SharedPreferences.getInstance();  // [GET] Local storage
      await prefs.setString('user_bio', bio);          // [STEP 2] Save bio

      // [STEP 3] Update user model with new bio
      _currentUser = _currentUser!.copyWith(bio: bio);
      notifyListeners();                                // [STEP 4] Update UI
    } catch (e) {                                     // [CATCH] Handle errors
      _setError('Failed to update bio: $e');          // [STEP 5] Set error
    }
  }

  /// [FUNCTION] uploadProfileImage
  /// [PARAMS] imageFile - File object containing the selected image
  /// [RETURNS] Future<void>
  /// [PURPOSE] Upload profile image to Firebase Storage and update user
  /// [STEP 1] Check if user exists
  /// [STEP 2] Set loading state
  /// [STEP 3] Upload image to Firebase Storage
  /// [STEP 4] Get download URL
  /// [STEP 5] Save URL to SharedPreferences and Firestore
  /// [STEP 6] Update user model
  /// [STEP 7] Notify listeners of change
  /// [STEP 8] Handle errors
  /// [STEP 9] Reset loading state
  Future<void> uploadProfileImage(File imageFile) async {
    if (_currentUser == null) return;                 // [STEP 1] Exit if no user

    _setLoading(true);                                // [STEP 2] Show loading

    try {
      // [STEP 3] Upload to Firebase Storage
      final firebaseService = FirebaseService.instance;
      final storageRef = firebaseService.storage
          .ref()
          .child('profile_images')
          .child('${_currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}');
      
      final uploadTask = await storageRef.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      // [STEP 4] Save URL to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userProfileImageKey, downloadUrl);

      // [STEP 5] Update Firestore document
      await firebaseService.usersCollection.doc(_currentUser!.uid).update({
        'profileImageUrl': downloadUrl,
      });

      // [STEP 6] Update user model with new image URL
      _currentUser = _currentUser!.copyWith(profileImageUrl: downloadUrl);
      notifyListeners();                              // [STEP 7] Update UI
    } catch (e) {                                   // [CATCH] Handle errors
      _setError('Failed to update image: $e');      // [STEP 8] Set error
    } finally {                                    // [FINALLY] Always reset loading
      _setLoading(false);                            // [STEP 9] Hide loading
    }
  }

  /// [FUNCTION] uploadProfileImageBytes
  /// [PARAMS] bytes - image data as Uint8List (works on web AND mobile)
  /// [PARAMS] filename - original filename for storage path
  /// [RETURNS] Future<bool> - true on success, false on failure
  /// [PURPOSE] Cross-platform profile image upload using raw bytes
  Future<bool> uploadProfileImageBytes(Uint8List bytes, String filename) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    try {
      final firebaseService = FirebaseService.instance;
      final storageRef = firebaseService.storage
          .ref()
          .child('profile_images')
          .child('${_currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}_$filename');

      final uploadTask = await storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userProfileImageKey, downloadUrl);

      await firebaseService.usersCollection.doc(_currentUser!.uid).update({
        'profileImageUrl': downloadUrl,
      });

      _currentUser = _currentUser!.copyWith(profileImageUrl: downloadUrl);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update image: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// [FUNCTION] updateProfileImageBase64
  /// [PARAMS] bytes - image data as Uint8List
  /// [RETURNS] Future<bool> - true on success, false on failure
  /// [PURPOSE] Simple method to update profile image as base64
  Future<bool> updateProfileImageBase64(Uint8List bytes) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    try {
      // Convert to base64
      final base64String = base64Encode(bytes);
      
      // Save to local storage for immediate access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_profile_image_base64', base64String);

      // Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).update({
        'profileImageBase64': base64String,
      });

      // Update user model
      _currentUser = _currentUser!.copyWith(
        profileImageBase64: base64String,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update profile image: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// [accountPublic] true = show in search; false = private account.
  Future<void> updateAccountPrivacy({required bool accountPublic}) async {
    final user = _currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'accountVisibility': accountPublic ? 'public' : 'private',
        },
        SetOptions(merge: true),
      );
      _currentUser = user.copyWith(accountPublic: accountPublic);
      notifyListeners();
    } catch (e) {
      _setError('Failed to update account privacy: $e');
    }
  }

  /// [FUNCTION] logout
  /// [PARAMS] None
  /// [RETURNS] Future<void>
  /// [PURPOSE] Log out user from app and Firebase, clear local storage
  /// [STEP 1] Get SharedPreferences
  /// [STEP 2] Clear login data from SharedPreferences
  /// [STEP 3] Sign out from Firebase Auth
  /// [STEP 4] Clear current user
  /// [STEP 5] Notify listeners of change
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();  // [STEP 1] Get local storage

    await prefs.remove(AppConstants.isLoggedInKey);      // [STEP 2A] Remove login flag
    await prefs.remove(AppConstants.userNameKey);       // [STEP 2B] Remove username

    await FirebaseAuth.instance.signOut();              // [STEP 3] Firebase sign out

    _currentUser = null;                                 // [STEP 4] Clear user
    notifyListeners();                                   // [STEP 5] Update UI
  }

  /// [FUNCTION] _setLoading
  /// [PARAMS] loading - Boolean loading state
  /// [RETURNS] void
  /// [PURPOSE] Set loading state and notify listeners
  void _setLoading(bool loading) {
    _isLoading = loading;                               // [SET] Update loading flag
    notifyListeners();                                  // [NOTIFY] Update UI
  }

  /// [FUNCTION] _setError
  /// [PARAMS] error - Error message string or null
  /// [RETURNS] void
  /// [PURPOSE] Set error message and notify listeners
  void _setError(String? error) {
    _error = error;                                     // [SET] Update error message
    notifyListeners();                                  // [NOTIFY] Update UI
  }
}