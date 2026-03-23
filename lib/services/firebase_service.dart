import 'package:firebase_auth/firebase_auth.dart';     // [IMPORT] Firebase Authentication service
import 'package:firebase_core/firebase_core.dart';      // [IMPORT] Firebase Core initialization
import 'package:cloud_firestore/cloud_firestore.dart';  // [IMPORT] Cloud Firestore database
import 'package:firebase_storage/firebase_storage.dart';  // [IMPORT] Firebase Storage for files
import '../firebase_options.dart';                     // [IMPORT] Firebase configuration options

/// [CLASS] FirebaseService
/// [PURPOSE] Singleton service to manage Firebase initialization and provide access to Firebase services
/// [FUNCTIONALITY] Initializes Firebase, provides access to Auth, Firestore, Storage, and collection references
/// [PATTERN] Singleton - only one instance exists throughout the app
class FirebaseService {
  
  // [CONSTRUCTOR] Private constructor for singleton pattern
  FirebaseService._();
  
  // [FIELD] _instance - Single instance of FirebaseService (null until first access)
  static FirebaseService? _instance;
  
  // [GETTER] instance - Returns singleton instance, creates if null
  static FirebaseService get instance => _instance ??= FirebaseService._();

  /// [FUNCTION] initializeFirebase
  /// [PARAMS] None
  /// [RETURNS] Future<void>
  /// [PURPOSE] Initialize Firebase app with platform-specific options
  /// [STEP 1] Call Firebase.initializeApp with current platform options
  /// [STEP 2] Print success message
  /// [STEP 3] Handle and rethrow errors
  Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,  // [CONFIG] Platform-specific Firebase config
      );
      print('Firebase initialized successfully');       // [LOG] Success message
    } catch (e) {                                     // [CATCH] Handle initialization error
      print('Failed to initialize Firebase: $e');      // [LOG] Error message
      rethrow;                                         // [THROW] Propagate error to caller
    }
  }

  /// [GETTER] auth
  /// [RETURNS] FirebaseAuth instance
  /// [PURPOSE] Access Firebase Authentication service
  FirebaseAuth get auth => FirebaseAuth.instance;

  /// [GETTER] firestore
  /// [RETURNS] FirebaseFirestore instance
  /// [PURPOSE] Access Cloud Firestore database
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  /// [GETTER] storage
  /// [RETURNS] FirebaseStorage instance
  /// [PURPOSE] Access Firebase Storage for file uploads
  FirebaseStorage get storage => FirebaseStorage.instance;

  /// [GETTER] usersCollection
  /// [RETURNS] CollectionReference for 'users' collection
  /// [PURPOSE] Reference to Firestore users collection for user data
  CollectionReference<Map<String, dynamic>> get usersCollection => 
      firestore.collection('users');                    // [COLLECTION] Users data

  /// [GETTER] postsCollection
  /// [RETURNS] CollectionReference for 'posts' collection
  /// [PURPOSE] Reference to Firestore posts collection for memory posts
  CollectionReference<Map<String, dynamic>> get postsCollection => 
      firestore.collection('posts');                   // [COLLECTION] Memory posts

  /// [GETTER] commentsCollection
  /// [RETURNS] CollectionReference for 'comments' collection
  /// [PURPOSE] Reference to Firestore comments collection for post comments
  CollectionReference<Map<String, dynamic>> get commentsCollection => 
      firestore.collection('comments');               // [COLLECTION] Post comments

  /// [GETTER] followersCollection
  /// [RETURNS] CollectionReference for 'followers' collection
  /// [PURPOSE] Reference to Firestore followers collection for follower relationships
  CollectionReference<Map<String, dynamic>> get followersCollection => 
      firestore.collection('followers');              // [COLLECTION] Follower relationships

  /// [GETTER] followingCollection
  /// [RETURNS] CollectionReference for 'following' collection
  /// [PURPOSE] Reference to Firestore following collection for following relationships
  CollectionReference<Map<String, dynamic>> get followingCollection => 
      firestore.collection('following');              // [COLLECTION] Following relationships

  /// [GETTER] likesCollection
  /// [RETURNS] CollectionReference for 'likes' collection
  /// [PURPOSE] Reference to Firestore likes collection for post likes
  CollectionReference<Map<String, dynamic>> get likesCollection => 
      firestore.collection('likes');                  // [COLLECTION] Post likes
}
