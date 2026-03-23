import 'package:flutter/material.dart';
import '../screens/create_memory_screen.dart';

/// Custom floating action button for creating new memories
class CustomFloatingActionButton extends StatelessWidget {
  const CustomFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context) => FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreateMemoryScreen(),
          ),
        );
      },
      backgroundColor: const Color(0xFF66BB6A),
      child: const Icon(
        Icons.add,
        color: Colors.white,
        size: 28,
      ),
    );
}
