import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Helper functions for common operations throughout the app
class AppHelpers {
  /// Format date relative to current time
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '${weeks}w${weeks > 1 ? '' : ''} ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '${months}mo${months > 1 ? '' : ''} ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return '${years}y${years > 1 ? '' : ''} ago';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Format date in a readable format
  static String formatDate(DateTime date, {String? format}) {
    final dateFormat = format ?? AppConstants.dateFormat;
    return DateFormat(dateFormat).format(date);
  }

  /// Format time in a readable format
  static String formatTime(DateTime time) => DateFormat(AppConstants.timeFormat).format(time);

  /// Format date and time together
  static String formatDateTime(DateTime dateTime) => DateFormat(AppConstants.dateTimeFormat).format(dateTime);

  /// Validate email format
  static bool isValidEmail(String email) => RegExp(AppConstants.emailRegex).hasMatch(email);

  /// Validate username format
  static bool isValidUsername(String username) => RegExp(AppConstants.usernameRegex).hasMatch(username);

  /// Validate password strength
  static String? validatePassword(String password) {
    if (password.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }
    if (password.length > AppConstants.maxPasswordLength) {
      return 'Password must be less than ${AppConstants.maxPasswordLength} characters';
    }
    if (!password.contains(RegExp('[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!password.contains(RegExp('[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!password.contains(RegExp('[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  /// Validate username
  static String? validateUsername(String username) {
    if (username.isEmpty) {
      return 'Username is required';
    }
    if (username.length < AppConstants.minUsernameLength) {
      return 'Username must be at least ${AppConstants.minUsernameLength} characters';
    }
    if (username.length > AppConstants.maxUsernameLength) {
      return 'Username must be less than ${AppConstants.maxUsernameLength} characters';
    }
    if (!isValidUsername(username)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }

  /// Validate memory title
  static String? validateTitle(String title) {
    if (title.isEmpty) {
      return 'Title is required';
    }
    if (title.length < AppConstants.minTitleLength) {
      return 'Title must be at least ${AppConstants.minTitleLength} characters';
    }
    if (title.length > AppConstants.maxTitleLength) {
      return 'Title must be less than ${AppConstants.maxTitleLength} characters';
    }
    return null;
  }

  /// Validate memory content
  static String? validateContent(String content) {
    if (content.isEmpty) {
      return 'Content is required';
    }
    if (content.length < AppConstants.minContentLength) {
      return 'Content must be at least ${AppConstants.minContentLength} characters';
    }
    if (content.length > AppConstants.maxContentLength) {
      return 'Content must be less than ${AppConstants.maxContentLength} characters';
    }
    return null;
  }

  /// Validate bio
  static String? validateBio(String bio) {
    if (bio.length > AppConstants.maxBioLength) {
      return 'Bio must be less than ${AppConstants.maxBioLength} characters';
    }
    return null;
  }

  /// Format coordinates for display
  static String formatCoordinates(double latitude, double longitude) => 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';

  /// Truncate text to specified length
  static String truncateText(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) {
      return text;
    }
    return text.substring(0, maxLength - suffix.length) + suffix;
  }

  /// Capitalize first letter of each word
  static String capitalizeWords(String text) => text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');

  /// Get color for memory based on age
  static Color getMemoryColor(DateTime createdAt) {
    final now = DateTime.now();
    final daysOld = now.difference(createdAt).inDays;

    if (daysOld < 7) {
      return Colors.green; // Recent memories
    } else if (daysOld < 30) {
      return Colors.blue; // Recent-ish memories
    } else if (daysOld < 365) {
      return Colors.orange; // Older memories
    } else {
      return Colors.grey; // Very old memories
    }
  }

  /// Show snackbar with error handling
  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration? duration,
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? (isError ? Colors.red : Colors.green),
        duration: duration ?? const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show confirmation dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? Colors.red,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Show loading dialog
  static void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  /// Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Format number for display (e.g., 1.5K, 2.3M)
  static String formatNumber(int number) {
    if (number < 1000) {
      return number.toString();
    } else if (number < 1000000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else if (number < 1000000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else {
      return '${(number / 1000000000).toStringAsFixed(1)}B';
    }
  }

  /// Get file size in human readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Check if file is supported image format
  static bool isSupportedImageFormat(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    return AppConstants.supportedImageFormats.contains(extension);
  }

  /// Generate a random ID
  static String generateRandomId() => DateTime.now().millisecondsSinceEpoch.toString() +
        (DateTime.now().microsecond).toString();

  /// Debounce function for search
  static void debounce(VoidCallback callback, Duration duration) {
    Future.delayed(duration, callback);
  }
}
