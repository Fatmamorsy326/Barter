import 'package:barter/core/resources/colors_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(30.0444, 31.2357); // Cairo, Egypt as default
  String? _address;
  bool _isLoadingAddress = false;
  bool _isLoadingLocation = true;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  late AnimationController _markerAnimController;
  late Animation<double> _markerAnimation;

  @override
  void initState() {
    super.initState();
    _markerAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _markerAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _markerAnimController, curve: Curves.easeOutBack),
    );
    _markerAnimController.forward();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _markerAnimController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showSnackBar('Location services are disabled', Icons.location_off);
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            _showSnackBar('Location permission denied', Icons.location_disabled);
          }
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showSnackBar('Location permission permanently denied', Icons.block);
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _center = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _center, zoom: 15),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error getting location', Icons.error_outline);
      }
      setState(() => _isLoadingLocation = false);
    }
  }

  void _onCameraMove(CameraPosition position) {
    _center = position.target;
    _markerAnimController.reverse().then((_) => _markerAnimController.forward());
  }

  void _onCameraIdle() async {
    setState(() => _isLoadingAddress = true);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _center.latitude,
        _center.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        String formattedAddress = _formatAddress(place);
        setState(() {
          _address = formattedAddress;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _address = '${_center.latitude.toStringAsFixed(6)}, ${_center.longitude.toStringAsFixed(6)}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAddress = false);
      }
    }
  }

  String _formatAddress(Placemark place) {
    List<String> parts = [];
    if (place.street != null && place.street!.isNotEmpty) parts.add(place.street!);
    if (place.subLocality != null && place.subLocality!.isNotEmpty) parts.add(place.subLocality!);
    if (place.locality != null && place.locality!.isNotEmpty) parts.add(place.locality!);
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty && parts.length < 3) {
      parts.add(place.administrativeArea!);
    }
    return parts.isNotEmpty ? parts.join(', ') : 'Unknown location';
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _searchLocation(query);
      }
    });
  }

  Future<void> _searchLocation(String query) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty && mounted) {
        final location = locations.first;
        final newCenter = LatLng(location.latitude, location.longitude);
        setState(() => _center = newCenter);
        
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: newCenter, zoom: 15),
          ),
        );
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Location not found', Icons.search_off);
      }
    }
  }

  void _showSnackBar(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: ColorsManager.purple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: REdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 15),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Custom AppBar with Search
          _buildAppBar(),

          // Center Marker
          Center(
            child: AnimatedBuilder(
              animation: _markerAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _markerAnimation.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: REdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [ColorsManager.gradientStart, ColorsManager.gradientEnd],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: ColorsManager.purple.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(Icons.location_on, size: 32.sp, color: Colors.white),
                      ),
                      SizedBox(height: 40.h),
                    ],
                  ),
                );
              },
            ),
          ),

          // Address Card
          if (_address != null) _buildAddressCard(),

          // Recenter FAB
          Positioned(
            right: 16.w,
            bottom: 180.h,
            child: FloatingActionButton(
              heroTag: 'recenter',
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _getCurrentLocation,
              child: _isLoadingLocation
                  ? SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ColorsManager.purple,
                      ),
                    )
                  : Icon(Icons.my_location, color: ColorsManager.purple, size: 20.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SafeArea(
      child: Container(
        margin: REdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded, color: ColorsManager.purple),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search location...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15.sp),
                ),
                style: TextStyle(fontSize: 15.sp),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear, color: Colors.grey[400]),
                onPressed: () {
                  _searchController.clear();
                  FocusScope.of(context).unfocus();
                },
              ),
            Container(
              margin: REdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ColorsManager.gradientStart, ColorsManager.gradientEnd],
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: IconButton(
                icon: Icon(Icons.search, color: Colors.white, size: 20.sp),
                onPressed: () {
                  if (_searchController.text.isNotEmpty) {
                    _searchLocation(_searchController.text);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    return Positioned(
      bottom: 16.h,
      left: 16.w,
      right: 16.w,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: REdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: REdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [ColorsManager.gradientStart, ColorsManager.gradientEnd],
                          ),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(Icons.location_on, color: Colors.white, size: 18.sp),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected Location',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            _isLoadingAddress
                                ? SizedBox(
                                    width: double.infinity,
                                    child: LinearProgressIndicator(
                                      backgroundColor: Colors.grey[200],
                                      color: ColorsManager.purple,
                                      minHeight: 2.h,
                                    ),
                                  )
                                : Text(
                                    _address!,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  GestureDetector(
                    onTap: () => Navigator.pop(context, _address),
                    child: Container(
                      width: double.infinity,
                      padding: REdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [ColorsManager.gradientStart, ColorsManager.gradientEnd],
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                            color: ColorsManager.purple.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'Confirm Location',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
