import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';

class EnhancedLocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialAddress;

  const EnhancedLocationPickerScreen({
    super.key,
    this.initialLocation,
    this.initialAddress,
  });

  @override
  State<EnhancedLocationPickerScreen> createState() => _EnhancedLocationPickerScreenState();
}

class _EnhancedLocationPickerScreenState extends State<EnhancedLocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(30.0444, 31.2357); // Cairo default
  String? _address;
  String? _detailedAddress;
  bool _isLoading = false;
  bool _isLoadingLocation = true;
  final TextEditingController _searchController = TextEditingController();
  List<Location> _searchResults = [];
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _center = widget.initialLocation!;
      _address = widget.initialAddress;
      _isLoadingLocation = false;
    } else {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        _showLocationServiceDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          _showPermissionDeniedDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        _showPermissionDeniedForeverDialog();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _center = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _center, zoom: 16),
        ),
      );

      _getAddressFromCoordinates(_center);
    } catch (e) {
      print('Error getting location: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  void _onCameraMove(CameraPosition position) {
    _center = position.target;
  }

  Future<void> _onCameraIdle() async {
    await _getAddressFromCoordinates(_center);
  }

  Future<void> _getAddressFromCoordinates(LatLng position) async {
    setState(() => _isLoading = true);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        // Short address for display
        String shortAddress = [
          place.street,
          place.locality,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        // Detailed address
        String fullAddress = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        setState(() {
          _address = shortAddress.isNotEmpty ? shortAddress : 'Unknown location';
          _detailedAddress = fullAddress.isNotEmpty ? fullAddress : null;
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      setState(() {
        _address = 'Unable to get address';
        _detailedAddress = null;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    try {
      List<Location> locations = await locationFromAddress(query);
      setState(() {
        _searchResults = locations.take(5).toList();
        _showSearchResults = true;
      });
    } catch (e) {
      print('Search error: $e');
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
    }
  }

  void _moveToLocation(Location location) {
    final newPosition = LatLng(location.latitude, location.longitude);
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: newPosition, zoom: 16),
      ),
    );
    setState(() {
      _center = newPosition;
      _showSearchResults = false;
      _searchController.clear();
    });
    _getAddressFromCoordinates(newPosition);
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text('Please enable location services to use this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission Denied'),
        content: const Text('Location permission is required to show your current location.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text('Please enable location permission in app settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _confirmLocation() {
    if (_address != null) {
      Navigator.pop(context, {
        'address': _address!,
        'detailedAddress': _detailedAddress,
        'latitude': _center.latitude,
        'longitude': _center.longitude,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 15),
            onMapCreated: (controller) {
              _mapController = controller;
              if (!_isLoadingLocation && widget.initialLocation == null) {
                _getAddressFromCoordinates(_center);
              }
            },
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
          ),

          // Center pin marker
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  size: 50.sp,
                  color: const Color(0xFF7E1E8F),
                  shadows: const [
                    Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                SizedBox(height: 50.h),
              ],
            ),
          ),

          // Top search bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    margin: REdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back, size: 24.sp),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search location...',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(fontSize: 14.sp),
                                ),
                                onChanged: (value) {
                                  if (value.length > 2) {
                                    _searchLocation(value);
                                  }
                                },
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.clear, size: 20.sp),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchResults = [];
                                    _showSearchResults = false;
                                  });
                                },
                              ),
                            IconButton(
                              icon: Icon(Icons.search, size: 24.sp),
                              onPressed: () => _searchLocation(_searchController.text),
                            ),
                          ],
                        ),
                        if (_showSearchResults && _searchResults.isNotEmpty)
                          Container(
                            constraints: BoxConstraints(maxHeight: 200.h),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: _searchResults.length,
                              separatorBuilder: (_, __) => Divider(height: 1),
                              itemBuilder: (context, index) {
                                final location = _searchResults[index];
                                return ListTile(
                                  leading: Icon(Icons.place, color: const Color(0xFF7E1E8F)),
                                  title: Text(
                                    '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                                    style: TextStyle(fontSize: 13.sp),
                                  ),
                                  onTap: () => _moveToLocation(location),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom address card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: REdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Title
                      Row(
                        children: [
                          Icon(Icons.location_on, color: const Color(0xFF7E1E8F), size: 20.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'Selected Location',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),

                      // Address
                      if (_isLoading)
                        Row(
                          children: [
                            SizedBox(
                              width: 16.w,
                              height: 16.h,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              'Getting address...',
                              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                            ),
                          ],
                        )
                      else if (_address != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _address!,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_detailedAddress != null) ...[
                              SizedBox(height: 4.h),
                              Text(
                                _detailedAddress!,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),

                      SizedBox(height: 20.h),

                      // Confirm button
                      GestureDetector(
                        onTap: _isLoading ? null : _confirmLocation,
                        child: Container(
                          width: double.infinity,
                          height: 50.h,
                          decoration: BoxDecoration(
                            gradient: _isLoading
                                ? null
                                : const LinearGradient(
                              colors: [Color(0xFF7E1E8F), Color(0xFFB24DB8)],
                            ),
                            color: _isLoading ? Colors.grey[300] : null,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Center(
                            child: Text(
                              'Confirm Location',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // My location button
          Positioned(
            right: 16,
            bottom: 220.h,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _getCurrentLocation,
              child: _isLoadingLocation
                  ? SizedBox(
                width: 20.w,
                height: 20.h,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Icon(Icons.my_location, color: const Color(0xFF7E1E8F)),
            ),
          ),
        ],
      ),
    );
  }
}