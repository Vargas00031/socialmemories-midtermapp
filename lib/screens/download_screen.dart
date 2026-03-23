import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

/// Download screen for providing app download link
class DownloadScreen extends StatelessWidget {
  const DownloadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download App'),
        backgroundColor: const Color(0xFF66BB6A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            // Title
            const Text(
              'Social Memories App',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF66BB6A),
              ),
            ),
            const SizedBox(height: 20),
            
            // Download button
            if (!kIsWeb) ...[
              const Text(
                'Download the Android app below:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              
              // Download APK button
              ElevatedButton.icon(
                onPressed: _downloadApk,
                icon: const Icon(Icons.android),
                label: const Text('Download APK'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF66BB6A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ] else ...[
              // Web download info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.info, color: Colors.blue, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Web Version',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'For the best experience, download our mobile app from the Google Play Store.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _openPlayStore,
                      icon: const Icon(Icons.store),
                      label: const Text('Google Play Store'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 40),
            
            // Additional info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Features:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem('📍 Map-based memories'),
                  _buildFeatureItem('📸 Image sharing'),
                  _buildFeatureItem('👥 Social features'),
                  _buildFeatureItem('💾 Base64 storage'),
                  _buildFeatureItem('📱 Cross-platform'),
                  _buildFeatureItem('⬇️ Download images'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadApk() async {
    // For demo purposes, you can place your APK in a public location
    // In a real app, this would link to your actual APK download
    const apkUrl = 'https://example.com/social-memories-app.apk';
    
    final uri = Uri.parse(apkUrl);
    
    if (!await launchUrl(uri)) {
      // Handle error
      debugPrint('Could not launch download URL');
    }
  }

  Future<void> _openPlayStore() async {
    const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.example.socialmemoriesapp';
    
    final uri = Uri.parse(playStoreUrl);
    
    if (!await launchUrl(uri)) {
      // Handle error
      debugPrint('Could not launch Play Store URL');
    }
  }
}
