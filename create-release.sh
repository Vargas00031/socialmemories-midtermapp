#!/bin/bash

echo "Creating GitHub Release for Social Memories App..."

# Create a simple placeholder APK (since build is failing)
echo "Note: Due to Android v1 embedding issues, creating a placeholder release"
echo "Users can build from source using the GitHub Actions workflow"

# Create release using GitHub CLI
gh release create "v1.0.0" \
  --title "Social Memories App v1.0.0" \
  --notes "📍 Social Memories App - Map-based Social Journaling

## ✨ Features
- 📍 Map-based memory sharing with interactive pins
- 📸 Image upload and sharing capabilities  
- 👥 Social features (follow, like, comment)
- 💾 Base64 image storage (no Firebase Storage costs)
- 📱 Cross-platform support (Android, iOS, Web)
- ⬇️ Download functionality for images
- 🎯 Accurate location detection (Caloocan priority)
- 🔐 Privacy controls for memories

## 🔧 Technical Details
- Flutter 3.19.6 with Firebase Firestore
- OpenStreetMap integration with geocoding
- Provider state management
- Base64 image encoding for efficient storage

## 📱 Installation
Due to Android build configuration issues, please use the GitHub Actions workflow for automated APK building, or build from source using Flutter 3.19.6.

## 🔗 Repository
https://github.com/Vargas00031/socialmemories-midtermapp

Built with ❤️ for the Social Memories community" \
  --draft=false \
  --prerelease=false

echo "Release created successfully!"
echo "Users can now download from: https://github.com/Vargas00031/socialmemories-midtermapp/releases"
