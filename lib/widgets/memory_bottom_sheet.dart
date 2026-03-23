import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post.dart';
import '../widgets/download_dialog.dart';

/// [CLASS] MemoryBottomSheet
/// [PURPOSE] StatelessWidget for displaying memory details in bottom sheet
/// [FUNCTIONALITY] Shows full post content with share functionality
class MemoryBottomSheet extends StatelessWidget {
  final PostModel post;                             // [PARAM] Post data to display

  const MemoryBottomSheet({
    super.key,
    required this.post,
  });

  /// [FUNCTION] _shareMemory
  /// [PARAMS] BuildContext context
  /// [RETURNS] Future<void>
  /// [PURPOSE] Share memory content using native sharing
  Future<void> _shareMemory(BuildContext context) async {
    final text = '''
📍 ${post.title}
${post.content}
Shared from Social Memories 💚
''';    
    await Share.share(text, subject: post.title);
  }

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
                  
                  // [UI] Share button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _shareMemory(context),
                      icon: const Icon(Icons.share),
                      label: const Text('Share Memory'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF66BB6A),
                        foregroundColor: Colors.white,
                      ),
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
}
