// Create this file: lib/features/map/items_map_view_screen.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:barter/model/item_model.dart';
import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/core/routes_manager/routes.dart';

class ItemsMapViewScreen extends StatefulWidget {
  final List<ItemModel> items;

  const ItemsMapViewScreen({super.key, required this.items});

  @override
  State<ItemsMapViewScreen> createState() => _ItemsMapViewScreenState();
}

class _ItemsMapViewScreenState extends State<ItemsMapViewScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  ItemModel? _selectedItem;
  LatLng? _currentLocation;
  bool _isLoadingLocation = true;
  double _radiusKm = 10.0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _createMarkers();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLocation!, zoom: 12),
        ),
      );
    } catch (e) {
      print('Error getting location: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  void _createMarkers() {
    final markers = <Marker>{};

    for (final item in widget.items) {
      if (item.latitude != null && item.longitude != null) {
        // Check if item is within radius
        if (_currentLocation != null) {
          final distance = Geolocator.distanceBetween(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
            item.latitude!,
            item.longitude!,
          ) / 1000;

          if (distance > _radiusKm) continue;
        }

        markers.add(
          Marker(
            markerId: MarkerId(item.id),
            position: LatLng(item.latitude!, item.longitude!),
            onTap: () => setState(() => _selectedItem = item),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _selectedItem?.id == item.id
                  ? BitmapDescriptor.hueViolet
                  : BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: item.title,
              snippet: item.location,
            ),
          ),
        );
      }
    }

    setState(() => _markers = markers);
  }

  void _updateRadius(double newRadius) {
    setState(() => _radiusKm = newRadius);
    _createMarkers();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? const LatLng(30.0444, 31.2357),
              zoom: 12,
            ),
            markers: _markers,
            circles: _currentLocation != null
                ? {
              Circle(
                circleId: const CircleId('search_radius'),
                center: _currentLocation!,
                radius: _radiusKm * 1000,
                fillColor: ColorsManager.purple.withOpacity(0.1),
                strokeColor: ColorsManager.purple,
                strokeWidth: 2,
              ),
            }
                : {},
            onMapCreated: (controller) => _mapController = controller,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Top app bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: REdgeInsets.all(16),
                padding: REdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [ColorsManager.darkGradientStart, ColorsManager.darkGradientEnd]
                        : [ColorsManager.gradientStart, ColorsManager.gradientEnd],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Container(
                        padding: REdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: 8.w),
                    Icon(Icons.map, color: Colors.white, size: 22.sp),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'Items Near You',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: REdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.tune,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                      ),
                      onPressed: _showFilterDialog,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Selected item card
          if (_selectedItem != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildItemCard(_selectedItem!),
            ),

          // Control buttons
          Positioned(
            right: 16,
            bottom: _selectedItem != null ? 180.h : 80.h,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  heroTag: 'location',
                  backgroundColor: ColorsManager.cardFor(context),
                  onPressed: () {
                    if (_currentLocation != null) {
                      _mapController?.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(target: _currentLocation!, zoom: 12),
                        ),
                      );
                    }
                  },
                  child: Icon(Icons.my_location, color: ColorsManager.purple),
                ),
                SizedBox(height: 10.h),
                FloatingActionButton(
                  mini: true,
                  heroTag: 'refresh',
                  backgroundColor: ColorsManager.cardFor(context),
                  onPressed: _createMarkers,
                  child: Icon(Icons.refresh, color: ColorsManager.purple),
                ),
              ],
            ),
          ),

          // Loading indicator
          if (_isLoadingLocation)
            Container(
              color: Colors.black26,
              child: Center(
                child: Container(
                  padding: REdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: ColorsManager.cardFor(context),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: ColorsManager.purple),
                      SizedBox(height: 16.h),
                      Text(
                        'Getting your location...',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemCard(ItemModel item) {
    final distance = _currentLocation != null
        ? item.distanceFrom(_currentLocation!.latitude, _currentLocation!.longitude)
        : null;

    return Container(
      margin: REdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsManager.cardFor(context),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: REdgeInsets.only(top: 10),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: ColorsManager.dividerFor(context),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          ListTile(
            contentPadding: REdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Image.network(
                item.imageUrls.first,
                width: 70.w,
                height: 70.h,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 70.w,
                  height: 70.h,
                  color: ColorsManager.purpleSoft,
                  child: Icon(Icons.image, color: ColorsManager.purple),
                ),
              ),
            ),
            title: Text(
              item.title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14.sp, color: ColorsManager.grey),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        item.location,
                        style: TextStyle(fontSize: 12.sp, color: ColorsManager.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (distance != null) ...[
                  SizedBox(height: 4.h),
                  Container(
                    padding: REdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ColorsManager.purpleSoft,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.near_me, size: 12.sp, color: ColorsManager.purple),
                        SizedBox(width: 4.w),
                        Text(
                          item.getFormattedDistance(
                            _currentLocation!.latitude,
                            _currentLocation!.longitude,
                          ) ?? '',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: ColorsManager.purple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              icon: Container(
                padding: REdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ColorsManager.dividerFor(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 18.sp),
              ),
              onPressed: () => setState(() => _selectedItem = null),
            ),
          ),

          Padding(
            padding: REdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        Routes.itemDetail,
                        arguments: item,
                      );
                    },
                    icon: Icon(Icons.visibility, size: 18.sp),
                    label: const Text('View Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsManager.purple,
                      foregroundColor: Colors.white,
                      padding: REdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: ColorsManager.purple, width: 2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: IconButton(
                    onPressed: () {
                      // Open in navigation app
                      // You can implement this using url_launcher
                    },
                    icon: Icon(Icons.directions, color: ColorsManager.purple),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColorsManager.cardFor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          'Filter by Distance',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: ColorsManager.textFor(context),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Show items within ${_radiusKm.toStringAsFixed(0)} km',
              style: TextStyle(
                fontSize: 14.sp,
                color: ColorsManager.textSecondaryFor(context),
              ),
            ),
            Slider(
              value: _radiusKm,
              min: 1,
              max: 50,
              divisions: 49,
              label: '${_radiusKm.toStringAsFixed(0)} km',
              activeColor: ColorsManager.purple,
              onChanged: (value) {
                setState(() => _radiusKm = value);
                _createMarkers();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: TextStyle(
                color: ColorsManager.purple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}