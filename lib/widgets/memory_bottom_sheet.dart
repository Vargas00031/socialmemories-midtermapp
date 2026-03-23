import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post.dart';
import '../services/download_service.dart';

/// [CLASS] MemoryBottomSheet
/// [PURPOSE] StatelessWidget for displaying memory details in bottom sheet
/// [FUNCTIONALITY] Shows full post content with share functionality
class MemoryBottomSheet extends StatelessWidget {
  final PostModel post;                             // [PARAM] Post data to display

  const MemoryBottomSheet({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // [UI] Handle bar
          Container(
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          
          // [UI] Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // [UI] Title
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // [UI] Content
                  Text(
                    post.content,
                    style: const TextStyle(fontSize: 16),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // [UI] Image
                  if (post.imageDataBase64 != null && post.imageDataBase64!.isNotEmpty)
                    ClipRRect(
                      child: Image.memory(
                        base64Decode(post.imageDataBase64!),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    )
                  else if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                    ClipRRect(
                      child: Image.network(
                        post.imageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // [UI] Stats
                  Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text('${post.likesCount} likes'),
                      const Spacer(),
                      Icon(Icons.comment, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text('${post.commentsCount} comments'),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // [UI] Action buttons
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _shareMemory(),
                            icon: const Icon(Icons.share),
                            label: const Text('Share'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF66BB6A),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _downloadImage(),
                            icon: const Icon(Icons.download),
                            label: const Text('Download'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// [FUNCTION] _shareMemory
  /// [PARAMS] None
  /// [RETURNS] Future<void>
  /// [PURPOSE] Share memory content using native sharing
  Future<void> _shareMemory() async {
    final text = '''
📍 ${post.title}
${post.content}
Shared from Social Memories 💚
''';    
    await Share.share(text, subject: post.title);
  }

  /// [FUNCTION] _downloadImage
  /// [PARAMS] None
  /// [RETURNS] Future<void>
  /// [PURPOSE] Download post image with progress dialog
  Future<void> _downloadImage() async {
    if (post.imageDataBase64 == null && post.imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No image available to download'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Generate filename from post title and timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedName = post.title.replaceAll(RegExp(r'[^\w\s]'), '_').toLowerCase();
    final fileName = '${sanitizedName}_$timestamp.jpg';

    String downloadUrl = '';
    String? imageData;

    if (post.imageDataBase64 != null && post.imageDataBase64!.isNotEmpty) {
      // For base64 images, we need to convert back to bytes
      try {
        final bytes = base64Decode(post.imageDataBase64!);
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsBytes(bytes);
        downloadUrl = tempFile.path;
        imageData = post.imageDataBase64!;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to prepare image: $e')),
        );
        return;
      }
    } else if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
      downloadUrl = post.imageUrl!;
    }

    if (downloadUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No image available to download'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show download dialog
    await DownloadDialog.show(
      context: context,
      url: downloadUrl,
      fileName: fileName,
      title: 'Download Image',
    );
  }
}
