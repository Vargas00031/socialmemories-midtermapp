import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

/// Provider for managing OpenStreetMap state and location services
class MapProvider with ChangeNotifier {
  final MapController _mapController = MapController();
  LatLng _initialPosition = const LatLng(14.8420, 120.9832); // Caloocan default
  Position? _currentPosition;
  bool _isLoading = false;
  String? _error;

  // Getters
  MapController get mapController => _mapController;
  LatLng get initialPosition => _initialPosition;
  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize map and get current location
  Future<void> initializeMap() async {
    _setLoading(true);
    try {
      await _getCurrentLocation();
      _setError(null);
    } catch (e) {
      _setError('Failed to initialize map: $e');
      // If location fails, we still want to show the map at default position
    } finally {
      _setLoading(false);
    }
  }

  /// Get current user location
  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // We can't throw here if we want to gracefully fall back
        debugPrint('Location services are disabled.');
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 20),
        forceAndroidLocationManager: true,
      );

      _currentPosition = position;
      _initialPosition = LatLng(position.latitude, position.longitude);
      
      // Move map to current location
      _mapController.move(_initialPosition, 14);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to get location: $e');
    }
  }

  /// Go to current location
  Future<void> goToCurrentLocation() async {
    _setLoading(true);
    try {
      await _getCurrentLocation();
    } catch (e) {
      _setError('Failed to get current location: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Move map to specific location
  void moveToLocation(LatLng location, {double? zoom}) {
    _mapController.move(location, zoom ?? 14.0);
  }

  /// Clear error
  void clearError() {
    _setError(null);
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error state
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
}
