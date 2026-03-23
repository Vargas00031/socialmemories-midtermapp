# Social Memories (社会的記憶)

A beautiful map-based social journaling application where users can share personal memories by placing pins on a map. Built with Flutter for mobile and web platforms.

## Features

### Core Features
- **Authentication**: User registration and login with profile management
- **Map-Based Memory Sharing**: Place memories on Google Maps with location pins
- **Memory Creation**: Add journal entries with optional images and locations
- **Social Features**: Like, comment, and follow other users
- **Feed View**: Browse recent memories from all users
- **Profile Management**: View user profiles and their memories

### Technical Features
- **Cross-Platform**: Works on both mobile (Android/iOS) and web
- **Real-time Updates**: Live data synchronization with Firebase
- **Location Services**: GPS integration for current location
- **Image Upload**: Store and display memory photos
- **Responsive Design**: Ghibli-inspired UI with soft pastel colors

## Tech Stack

- **Frontend**: Flutter with Dart
- **Backend**: Firebase (Firestore, Authentication, Storage)
- **Maps**: Google Maps Flutter
- **State Management**: Provider pattern
- **UI**: Custom Ghibli-inspired theme

## Project Structure

```
lib/
├── models/           # Data models (User, Post, Comment, Follow)
├── services/         # Firebase and API services
├── providers/        # State management providers
├── screens/          # App screens (auth, map, profile, etc.)
├── widgets/          # Reusable UI components
├── theme/            # App theme and styling
└── utils/            # Utility functions
```

## Getting Started

### Prerequisites
- Flutter SDK (>=3.10.0)
- Firebase project
- Google Maps API key

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd memory_map_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project
   - Enable Authentication (Email/Password)
   - Set up Firestore database
   - Configure Firebase Storage
   - Download configuration files:
     - Android: `google-services.json` → `android/app/`
     - iOS: `GoogleService-Info.plist` → `ios/Runner/`
     - Web: Firebase config → `web/index.html`

4. **Google Maps Setup**
   - Get Google Maps API key from Google Cloud Console
   - Enable Maps SDK for Android, iOS, and Web
   - Add API key to:
     - Android: `android/app/src/main/AndroidManifest.xml`
     - iOS: `ios/Runner/AppDelegate.swift`
     - Web: `web/index.html`

5. **Update Firebase Configuration**
   - Edit `lib/firebase_options.dart` with your Firebase config
   - Replace placeholder API keys and project IDs

6. **Run the app**
   ```bash
   # For development
   flutter run

   # For web
   flutter run -d chrome

   # For Android
   flutter run -d android

   # For iOS
   flutter run -d ios
   ```

## Firebase Data Model

### Users Collection
```javascript
{
  uid: string,
  username: string,
  email: string,
  profileImageUrl?: string,
  bio?: string,
  followersCount: number,
  followingCount: number,
  createdAt: timestamp,
  lastActive: timestamp
}
```

### Posts Collection
```javascript
{
  userId: string,
  username: string,
  userProfileImage?: string,
  title: string,
  content: string,
  imageUrl?: string,
  latitude: number,
  longitude: number,
  likesCount: number,
  commentsCount: number,
  createdAt: timestamp,
  updatedAt?: timestamp
}
```

### Comments Collection
```javascript
{
  postId: string,
  userId: string,
  username: string,
  userProfileImage?: string,
  content: string,
  createdAt: timestamp,
  updatedAt?: timestamp
}
```

### Likes Collection
```javascript
{
  postId: string,
  userId: string,
  createdAt: timestamp
}
```

### Followers/Following Collections
```javascript
{
  followerId: string,
  followingId: string,
  createdAt: timestamp
}
```

## UI Design

The app features a Ghibli-inspired design with:
- **Color Palette**: Soft greens, sky blues, cream backgrounds
- **Components**: Rounded cards, gentle shadows, clean layouts
- **Typography**: Clean, minimal text styling
- **Animations**: Smooth transitions and micro-interactions

## Key Screens

1. **Login/Register**: User authentication with email/password
2. **Map Screen**: Main view with Google Maps and memory pins
3. **Create Memory**: Form to add new memories with location and images
4. **Profile Screen**: User profile with memories and stats
5. **Feed Screen**: List view of recent memories
6. **Memory Details**: Bottom sheet showing full memory information

## Social Features

- **Follow/Unfollow**: Connect with other users
- **Like/Unlike**: Show appreciation for memories
- **Comments**: Engage in discussions about memories
- **User Profiles**: View user information and their memories
- **Activity Tracking**: Monitor followers, following, and engagement

## Development Notes

### State Management
- Uses Provider pattern for state management
- Separate providers for auth, posts, map, and social features
- Reactive UI updates with ChangeNotifier

### Error Handling
- Comprehensive error handling throughout the app
- User-friendly error messages
- Graceful fallbacks for network issues

### Performance
- Efficient image caching with cached_network_image
- Lazy loading for large lists
- Optimized Firestore queries

### Security
- Firebase security rules for data protection
- Input validation and sanitization
- Secure file uploads

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Create an issue in the repository
- Check the documentation
- Review existing issues for solutions

## Future Enhancements

- [ ] Push notifications for new followers/likes
- [ ] Memory search and filtering
- [ ] Memory collections/categories
- [ ] Offline mode support
- [ ] Video memory support
- [ ] Memory sharing to social media
- [ ] Advanced privacy settings
- [ ] Memory analytics and insights
