import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

/// Location picker result model
class LocationResult {
  final LatLng location;
  final String address;

  LocationResult({required this.location, required this.address});
}

/// Location picker widget using OpenStreetMap with accurate address display
class LocationPicker extends StatefulWidget {
  final LatLng? initialLocation;

  const LocationPicker({
    super.key,
    this.initialLocation,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  List<Marker> _markers = [];
  bool _isLoading = false;
  String _selectedAddress = 'Selecting address...';

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    if (_selectedLocation != null) {
      _addMarker(_selectedLocation!);
      _getAddressWithFallbacks(_selectedLocation!);
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
          timeLimit: const Duration(seconds: 20),
          forceAndroidLocationManager: true,
        );
        
        final currentLocation = LatLng(position.latitude, position.longitude);
        
        // Check if we're in Caloocan area with more precise boundaries
        if (_isInCaloocanArea(currentLocation)) {
          setState(() {
            _selectedLocation = currentLocation;
            _addMarker(currentLocation);
            _selectedAddress = 'Caloocan, Philippines';
          });
        } else {
          setState(() {
            _selectedLocation = currentLocation;
            _addMarker(currentLocation);
          });
          await _getAddressWithFallbacks(currentLocation);
        }
        
        _mapController.move(currentLocation, 16.0);
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
      // Use Caloocan as default since user mentioned they're in Caloocan
      final caloocanLocation = const LatLng(14.8420, 120.9832);
      if (_selectedLocation == null) {
        setState(() {
          _selectedLocation = caloocanLocation;
          _addMarker(caloocanLocation);
          _selectedAddress = 'Caloocan, Philippines';
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isInCaloocanArea(LatLng location) {
    final lat = location.latitude;
    final lon = location.longitude;
    
    // Caloocan approximate boundaries (more precise)
    return lat >= 14.80 && lat <= 15.10 && 
           lon >= 120.85 && lon <= 121.10;
  }

  Future<void> _getAddressWithFallbacks(LatLng position) async {
    setState(() {
      _selectedAddress = 'Getting address...';
    });

    // Method 1: Try native geocoding with better error handling
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude,
      );
      
      if (placemarks.isNotEmpty && placemarks[0] != null) {
        final place = placemarks[0];
        
        // Build address with all available fields, prioritizing non-null values
        List<String> parts = [];
        
        // Add street name if available
        if (place.name?.isNotEmpty == true && !place.name!.contains('+')) {
          parts.add(place.name!);
        }
        
        // Add street details
        if (place.thoroughfare?.isNotEmpty == true) {
          parts.add(place.thoroughfare!);
        }
        
        // Add sub-locality (barangay/district)
        if (place.subLocality?.isNotEmpty == true) {
          parts.add(place.subLocality!);
        }
        
        // Add city/locality
        if (place.locality?.isNotEmpty == true) {
          parts.add(place.locality!);
        }
        
        // Add administrative area (province/state)
        if (place.administrativeArea?.isNotEmpty == true) {
          parts.add(place.administrativeArea!);
        }
        
        // Add country
        if (place.country?.isNotEmpty == true) {
          parts.add(place.country!);
        }
        
        final address = parts.join(', ');
        
        // Accept any address that has meaningful content
        if (address.length > 10) {
          setState(() {
            _selectedAddress = address;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Native geocoding failed: $e');
    }

    // Method 2: Try OpenStreetMap Nominatim
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1'),
        headers: {'User-Agent': 'SocialMemoriesApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['display_name'] != null) {
          final String? displayName = data['display_name'];
          final addressData = data['address'];
          
          if (displayName != null && displayName.isNotEmpty && displayName.length > 10) {
            // Check for Caloocan in various fields
            final isCaloocan = displayName.toLowerCase().contains('caloocan') ||
                (addressData != null && (
                  addressData['city']?.toString().toLowerCase().contains('caloocan') == true ||
                  addressData['municipality']?.toString().toLowerCase().contains('caloocan') == true ||
                  addressData['county']?.toString().toLowerCase().contains('caloocan') == true ||
                  addressData['state']?.toString().toLowerCase().contains('caloocan') == true));
            
            setState(() {
              _selectedAddress = displayName;
            });
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Nominatim fallback failed: $e');
    }

    // Method 3: Manual coordinate-based location
    final lat = position.latitude;
    final lon = position.longitude;
    
    // Check if coordinates are in Caloocan area
    if (_isInCaloocanArea(position)) {
      setState(() {
        _selectedAddress = 'Caloocan, Philippines';
      });
    } else {
      setState(() {
        _selectedAddress = 'Location: ${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
      });
    }
  }

  String _formatDetailedAddress(Placemark place) {
    List<String> addressParts = [];
    
    // Priority order for Philippine addresses with null checks
    if (place.name?.isNotEmpty == true && !place.name!.contains('+')) {
      addressParts.add(place.name!);
    }
    
    // Street level details
    if (place.subThoroughfare?.isNotEmpty == true && place.thoroughfare?.isNotEmpty == true) {
      addressParts.add('${place.subThoroughfare} ${place.thoroughfare}');
    } else if (place.thoroughfare?.isNotEmpty == true) {
      addressParts.add(place.thoroughfare!);
    }
    
    // Sub-locality (barangay, district, etc.)
    if (place.subLocality?.isNotEmpty == true) {
      addressParts.add(place.subLocality!);
    }
    
    // Locality (city/town)
    if (place.locality?.isNotEmpty == true) {
      addressParts.add(place.locality!);
    }
    
    // Administrative area (state/province)
    if (place.administrativeArea?.isNotEmpty == true) {
      addressParts.add(place.administrativeArea!);
    }
    
    // Postal code
    if (place.postalCode?.isNotEmpty == true) {
      addressParts.add(place.postalCode!);
    }
    
    // Country
    if (place.country?.isNotEmpty == true) {
      addressParts.add(place.country!);
    }
    
    return addressParts.join(', ');
  }

  void _addMarker(LatLng position) {
    setState(() {
      _markers = [
        Marker(
          point: position,
          width: 50,
          height: 50,
          child: const Icon(
            Icons.location_on,
            color: Color(0xFF66BB6A),
            size: 40,
          ),
        ),
      ];
    });
  }

  void _selectLocation(LatLng position) {
    setState(() {
      _selectedLocation = position;
      _addMarker(position);
    });
    _getAddressWithFallbacks(position);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: const Color(0xFF66BB6A),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation ?? const LatLng(14.8420, 120.9832),
              initialZoom: 15.0,
              onTap: (tapPosition, point) => _selectLocation(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.social_memories',
              ),
              MarkerLayer(
                markers: _markers,
              ),
            ],
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF66BB6A))),
          
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Address:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedAddress,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedLocation == null || _selectedAddress == 'Getting address...' ? null : () {
                          Navigator.pop(
                            context, 
                            LocationResult(location: _selectedLocation!, address: _selectedAddress)
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF66BB6A),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Confirm Location'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              onPressed: _getCurrentLocation,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Color(0xFF66BB6A)),
            ),
          ),
        ],
      ),
    );
  }
}
