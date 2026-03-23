import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Download service for handling file downloads with progress tracking
class DownloadService {
  /// Download a file from URL to local storage
  static Future<String?> downloadFile({
    required String url,
    required String fileName,
    required Function(double) onProgress,
    required Function(String) onComplete,
    required Function(String) onError,
  }) async {
    try {
      // Show initial progress
      onProgress(0.0);

      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode != 200) {
        onError('Failed to download file: HTTP ${response.statusCode}');
        return null;
      }

      // Get total file size from headers
      final totalBytes = response.contentLength ?? 0;
      
      // Get app's documents directory
      Directory? directory;
      if (kIsWeb) {
        // Web: Use downloads directory (user will be prompted to save)
        onError('Web downloads are handled by browser');
        return null;
      } else {
        // Mobile: Use app's documents directory
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        onError('Could not access storage directory');
        return null;
      }

      final filePath = path.join(directory.path, fileName);
      final file = File(filePath);

      // Download file with progress tracking
      final bytes = <int>[];
      int downloadedBytes = 0;

      final content = response.bodyBytes;
      if (content != null) {
        for (int i = 0; i < content.length; i++) {
          bytes.add(content[i]);
          downloadedBytes++;

          // Update progress every 100KB or at the end
          if (downloadedBytes % 102400 == 0 || downloadedBytes == content.length) {
            final progress = totalBytes > 0 ? downloadedBytes / totalBytes : 1.0;
            onProgress(progress);
          }

          // Small delay to prevent UI freezing
          if (i % 1000 == 0) {
            await Future.delayed(const Duration(milliseconds: 1));
          }
        }

        // Write to file
        await file.writeAsBytes(bytes);
      }

      onComplete(filePath);
      return filePath;
    } catch (e) {
      onError('Download failed: ${e.toString()}');
      return null;
    }
  }

  /// Get available storage space
  static Future<int> getAvailableStorageSpace() async {
    if (kIsWeb) {
      return 0; // Web storage varies by browser
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      if (directory == null) return 0;

      final files = await directory.list().toList();
      int totalSize = 0;
      
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          totalSize += stat.size;
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Format file size for display
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
}
