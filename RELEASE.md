# 📍 Social Memories App - Release v1.0.0

## 🎉 About This Release

This is the initial release of the Social Memories app - a map-based social journaling application where users can share personal memories by placing pins on a map.

## ✨ Key Features

### 📍 Core Functionality
- **Interactive Map** - Place memories with precise location pins
- **Memory Management** - Create, edit, and delete memories
- **Social Features** - Follow users, like and comment on memories
- **Privacy Controls** - Public/private memory settings

### 📸 Image System
- **Base64 Storage** - All images stored as base64 in Firestore
- **No Firebase Storage** - Reduces costs and improves performance
- **Instant Loading** - Images display immediately without delays
- **Download Support** - Save images to device storage

### 🎯 Location Features
- **High-Precision GPS** - Uses `LocationAccuracy.bestForNavigation`
- **Multiple Geocoding** - Native → Nominatim → Manual fallbacks
- **Caloocan Detection** - Automatic detection for Caloocan area
- **Complete Addresses** - Proper Philippine address formatting

### 📱 Platform Support
- **Cross-Platform** - Android, iOS, and Web compatibility
- **Responsive Design** - Adapts to different screen sizes
- **Material Design** - Modern, consistent UI/UX

## 🔧 Technical Specifications

- **Framework**: Flutter 3.19.6
- **Backend**: Firebase Firestore
- **Authentication**: Firebase Auth
- **Mapping**: OpenStreetMap (free, open-source)
- **State Management**: Provider pattern
- **Image Storage**: Base64 encoding in Firestore

## 📱 Installation

### ⚠️ Important Note
Due to Android build configuration issues with Flutter 3.41.5, automated APK building is handled via GitHub Actions.

### 🚀 Automated Build (Recommended)
1. Go to: [GitHub Actions](https://github.com/Vargas00031/socialmemories-midtermapp/actions)
2. Wait for build to complete (2-3 minutes)
3. Download APK from Releases page

### 🔧 Manual Build (Advanced)
If automated build fails, you can build manually:

```bash
# Use Flutter 3.19.6 for compatibility
git clone https://github.com/Vargas00031/socialmemories-midtermapp.git
cd socialmemories-midtermapp
flutter downgrade 3.19.6
flutter build apk --release --no-shrink
```

## 📥 Download Options

### 📱 From GitHub Releases (Recommended)
1. Visit: [Releases Page](https://github.com/Vargas00031/socialmemories-midtermapp/releases)
2. Download: `social-memories-apk.apk`
3. Install on Android device
4. Enable location permissions

### 🔗 Repository
- **Source Code**: https://github.com/Vargas00031/socialmemories-midtermapp
- **Issues**: https://github.com/Vargas00031/socialmemories-midtermapp/issues
- **Discussions**: https://github.com/Vargas00031/socialmemories-midtermapp/discussions

## 🐛 Known Issues

### ⚠️ Android Build Issue
- **Problem**: "Build failed due to use of deleted Android v1 embedding"
- **Solution**: Use GitHub Actions for automated builds
- **Status**: GitHub Actions workflow configured and ready

### 📱 Location Accuracy
- **Problem**: Location may show wrong area initially
- **Solution**: Enable high-accuracy GPS and wait for satellite lock
- **Status**: Multiple geocoding fallbacks implemented

## 🔐 Privacy & Security

- **Authentication**: Firebase Auth with secure token management
- **Data Storage**: Firebase Firestore with base64 image encoding
- **Privacy**: User-controlled memory visibility settings
- **Local Storage**: SharedPreferences for offline access

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 License

This project is licensed under the MIT License.

---

**Built with ❤️ for the Social Memories community**

*Version 1.0.0 - Initial Release*
