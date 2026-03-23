import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/download_service.dart';

/// Download dialog widget for downloading files with progress tracking
class DownloadDialog extends StatefulWidget {
  final String url;
  final String fileName;
  final String? title;

  const DownloadDialog({
    super.key,
    required this.url,
    required this.fileName,
    this.title,
  });

  @override
  State<DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<DownloadDialog> {
  double _downloadProgress = 0.0;
  bool _isDownloading = false;
  bool _isCompleted = false;
  String? _error;
  String? _filePath;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Row(
              children: [
                Icon(
                  _isCompleted ? Icons.check_circle : Icons.download,
                  color: _isCompleted ? Colors.green : Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title ?? 'Download File',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Progress or Status
            if (_isDownloading) ...[
              // Progress bar
              LinearProgressIndicator(
                value: _downloadProgress,
                backgroundColor: Colors.grey[300],
                valueColor: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                '${(_downloadProgress * 100).toStringAsFixed(1)}% - Downloading...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ] else if (_isCompleted) ...[
              // Success message
              Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 8),
              Text(
                'Download completed successfully!',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_filePath != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Saved to: ${_filePath!.split('/').last}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ] else if (_error != null) ...[
              // Error message
              Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
            ],
            
            const SizedBox(height: 20),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!_isDownloading && !_isCompleted) ...[
                  // Download button
                  ElevatedButton.icon(
                    onPressed: _startDownload,
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF66BB6A),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ] else ...[
                  // Close button
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startDownload() async {
    setState(() {
      _isDownloading = true;
      _error = null;
      _isCompleted = false;
      _filePath = null;
    });

    final filePath = await DownloadService.downloadFile(
      url: url,
      fileName: fileName,
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _downloadProgress = progress;
          });
        }
      },
      onComplete: (path) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _isCompleted = true;
            _filePath = path;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _error = error;
          });
        }
      },
    );

    if (mounted && filePath == null) {
      setState(() {
        _isDownloading = false;
        _error = 'Download failed';
      });
    }
  }

  /// Static method to show download dialog
  static Future<void> show({
    required BuildContext context,
    required String url,
    required String fileName,
    String? title,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => DownloadDialog(
        url: url,
        fileName: fileName,
        title: title,
      ),
    );
  }
}
