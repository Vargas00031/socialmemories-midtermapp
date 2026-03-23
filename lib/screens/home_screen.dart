import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'map_screen.dart';
import 'simple_login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        backgroundColor: const Color(0xFF66BB6A),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const SimpleLoginScreen(),
                ),
              );
            },
          )
        ],
      ),
      body: Center(
        child: FutureBuilder(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            var userData = snapshot.data!;
            final profileImageRaw = userData['profileImageUrl'] ?? userData['profileImage'] ?? '';
            final profileImage = profileImageRaw is String ? profileImageRaw : '';
            final hasValidNetworkImage =
                profileImage.isNotEmpty && profileImage.startsWith('https');

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: hasValidNetworkImage
                      ? NetworkImage(profileImage)
                      : const AssetImage('assets/images/app_logo.png'),
                  child: !hasValidNetworkImage
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 20),
                Text(
                  userData['email'],
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 30),
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const MapScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map_rounded, color: Colors.white),
                      label: const Text('Go to Map', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF66BB6A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const DownloadScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Download App'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return const Icon(Icons.person, color: Color(0xFF66BB6A));
  }
}