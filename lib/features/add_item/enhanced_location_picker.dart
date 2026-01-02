import 'package:barter/core/resources/colors_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

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
  List<Map<String, dynamic>> _searchResults = []; // Changed to store both location and address
  bool _showSearchResults = false;
  Timer? _searchDebounce;
  bool _isSearchingResults = false;

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
        _isSearchingResults = false;
      });
      return;
    }

    setState(() => _isSearchingResults = true);

    try {
      List<Location> locations = await locationFromAddress(query);
      
      List<Map<String, dynamic>> results = [];
      
      // Get addresses for the first few results to show names
      for (var location in locations.take(8)) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );
          
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            String address = [
              place.name,
              place.locality,
              place.administrativeArea,
            ].where((e) => e != null && e.isNotEmpty).join(', ');
            
            results.add({
              'location': location,
              'address': address.isNotEmpty ? address : '${location.latitude}, ${location.longitude}',
              'fullPlacemark': place,
            });
          }
        } catch (e) {
          results.add({
            'location': location,
            'address': '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
          });
        }
      }

      setState(() {
        _searchResults = results;
        _showSearchResults = true;
      });
    } catch (e) {
      print('Search error: $e');
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
    } finally {
      setState(() => _isSearchingResults = false);
    }
  }

  void _moveToLocation(Map<String, dynamic> result) {
    final Location location = result['location'];
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
      // If we already have the address from search, use it
      if (result['address'] != null) {
        _address = result['address'];
        if (result['fullPlacemark'] != null) {
          final Placemark p = result['fullPlacemark'];
          _detailedAddress = [
            p.street,
            p.subLocality,
            p.locality,
            p.administrativeArea,
            p.country,
          ].where((e) => e != null && e.isNotEmpty).join(', ');
        }
      }
    });
    
    if (result['address'] == null) {
      _getAddressFromCoordinates(newPosition);
    }
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
                                  prefixIcon: _isSearchingResults 
                                    ? Container(
                                        padding: REdgeInsets.all(12),
                                        width: 48.w,
                                        height: 48.h,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : null,
                                ),
                                onChanged: (value) {
                                  if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
                                  _searchDebounce = Timer(const Duration(milliseconds: 600), () {
                                    if (value.length > 2) {
                                      _searchLocation(value);
                                    } else if (value.isEmpty) {
                                      setState(() {
                                        _searchResults = [];
                                        _showSearchResults = false;
                                      });
                                    }
                                  });
                                },
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.clear, size: 20.sp),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchDebounce?.cancel();
                                  setState(() {
                                    _searchResults = [];
                                    _showSearchResults = false;
                                    _isSearchingResults = false;
                                  });
                                },
                              ),
                            IconButton(
                              icon: Icon(Icons.search, size: 24.sp),
                              onPressed: () {
                                _searchDebounce?.cancel();
                                _searchLocation(_searchController.text);
                              },
                            ),
                          ],
                        ),
                        if (_showSearchResults && _searchResults.isNotEmpty)
                          Container(
                            constraints: BoxConstraints(maxHeight: 350.h),
                            decoration: BoxDecoration(
                              border: Border(top: BorderSide(color: Colors.grey[200]!)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: REdgeInsets.fromLTRB(16, 12, 16, 8),
                                  child: Text(
                                    'SEARCH RESULTS',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w800,
                                      color: ColorsManager.purple,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    itemCount: _searchResults.length,
                                    separatorBuilder: (_, __) => Divider(height: 1, indent: 52.w, color: Colors.grey[100]),
                                    itemBuilder: (context, index) {
                                      final result = _searchResults[index];
                                      return ListTile(
                                        contentPadding: REdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                        leading: Container(
                                          padding: REdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: ColorsManager.purpleSoft.withOpacity(0.5),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.place_rounded, color: ColorsManager.purple, size: 20.sp),
                                        ),
                                        title: Text(
                                          result['address'],
                                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.black87),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          '${result['location'].latitude.toStringAsFixed(4)}, ${result['location'].longitude.toStringAsFixed(4)}',
                                          style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                                        ),
                                        onTap: () => _moveToLocation(result),
                                      );
                                    },
                                  ),
                                ),
                               ],
                             ),
                           ),
                        if (_showSearchResults && _searchResults.isEmpty && !_isSearchingResults && _searchController.text.isNotEmpty)
                          Container(
                            padding: REdgeInsets.all(32),
                            width: double.infinity,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off_rounded, size: 48.sp, color: Colors.grey[300]),
                                SizedBox(height: 12.h),
                                Text(
                                  'No locations found',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 14.sp, fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  'Try a different or more specific search',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 12.sp),
                                ),
                              ],
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