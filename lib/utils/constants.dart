/// App-wide constants used throughout the application
class AppConstants {
  // App information
  static const String appName = 'Memory Map';
  static const String appVersion = '1.0.0';

  // Firebase collection names
  static const String usersCollection = 'users';
  static const String postsCollection = 'posts';
  static const String commentsCollection = 'comments';
  static const String likesCollection = 'likes';
  static const String followersCollection = 'followers';
  static const String followingCollection = 'following';

  // Storage paths
  static const String profileImagesPath = 'profile_images';
  static const String postImagesPath = 'post_images';

  // Validation constants
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 20;
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minTitleLength = 3;
  static const int maxTitleLength = 100;
  static const int minContentLength = 10;
  static const int maxContentLength = 1000;
  static const int maxBioLength = 200;

  // UI constants
  static const double defaultPadding = 16;
  static const double smallPadding = 8;
  static const double largePadding = 24;
  static const double defaultBorderRadius = 12;
  static const double cardBorderRadius = 16;
  static const double bottomSheetBorderRadius = 20;

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Image constraints
  static const double maxImageWidth = 800;
  static const double maxImageHeight = 600;
  static const int imageQuality = 80;

  // Map constants
  static const double defaultMapZoom = 14;
  static const double detailMapZoom = 15;
  static const double fitMapPadding = 100;

  // Pagination
  static const int defaultPageSize = 20;
  static const int searchResultLimit = 20;

  // Error messages
  static const String networkError = 'Network error. Please check your connection.';
  static const String unknownError = 'An unexpected error occurred. Please try again.';
  static const String authError = 'Authentication error. Please sign in again.';
  static const String permissionError = 'Permission denied. Please check your settings.';

  // Success messages
  static const String memoryCreated = 'Memory created successfully!';
  static const String profileUpdated = 'Profile updated successfully!';
  static const String passwordReset = 'Password reset email sent!';
  static const String commentAdded = 'Comment added successfully!';

  // Placeholder texts
  static const String usernameHint = 'Choose a username';
  static const String emailHint = 'Enter your email';
  static const String passwordHint = 'Create a password';
  static const String titleHint = 'Give your memory a title';
  static const String contentHint = 'Share your memory...';
  static const String bioHint = 'Tell us about yourself';
  static const String searchHint = 'Search memories...';

  // Empty state messages
  static const String noMemories = 'No memories yet';
  static const String noComments = 'No comments yet';
  static const String noFollowers = 'No followers yet';
  static const String noFollowing = 'Not following anyone yet';
  static const String noLikedMemories = 'No liked memories yet';

  // Loading messages
  static const String loadingMemories = 'Loading memories...';
  static const String loadingProfile = 'Loading profile...';
  static const String uploadingImage = 'Uploading image...';
  static const String creatingMemory = 'Creating memory...';

  // Date formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String timeFormat = 'h:mm a';
  static const String dateTimeFormat = 'MMM dd, yyyy • h:mm a';

  // Regex patterns
  static const String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String usernameRegex = r'^[a-zA-Z0-9_]{3,20}$';

  // Map marker colors
  static const double markerHueGreen = 120;
  static const double markerHueRed = 0;
  static const double markerHueBlue = 240;
  static const double markerHueYellow = 60;

  // Social limits
  static const int maxFollowers = 10000;
  static const int maxFollowing = 10000;
  static const int maxCommentsPerPost = 1000;
  static const int maxLikesPerPost = 10000;

  // Cache settings
  static const Duration cacheExpiration = Duration(hours: 1);
  static const int maxCacheSize = 100;

  // Location settings
  static const double locationAccuracyThreshold = 100; // meters
  static const Duration locationTimeout = Duration(seconds: 15);

  // Image upload settings
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'gif'];
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB

  // User preferences
  static const String isLoggedInKey = 'is_logged_in';
  static const String userNameKey = 'user_name';
  static const String userProfileImageKey = 'user_profile_image';

  // Notification channels
  static const String likesChannel = 'likes';
  static const String commentsChannel = 'comments';
  static const String followsChannel = 'follows';
  static const String memoriesChannel = 'memories';
}
