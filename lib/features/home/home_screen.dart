import 'package:barter/core/extensions/extensions.dart';
import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/core/routes_manager/routes.dart';
import 'package:barter/core/widgets/exchange_notification_badge.dart';
import 'package:barter/core/widgets/item_card.dart';
import 'package:barter/core/widgets/shimmer_loading.dart';
import 'package:barter/features/map/item_map_view_screen.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:barter/l10n/app_localizations.dart';
import 'package:barter/model/item_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  ItemCategory? _selectedCategory;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Location features
  Position? _currentPosition;
  double _radiusKm = 10.0;
  bool _showNearbyOnly = false;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // Get location
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(context),
        ],
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Location status banner
              if (_isLoadingLocation)
                _buildLocationLoadingBanner()
              else if (_currentPosition != null && _showNearbyOnly)
                _buildLocationBanner(),

              _buildSearchBar(),
              _buildCategoryFilter(),
              Expanded(child: _buildItemsList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      floating: true,
      snap: true,
      automaticallyImplyLeading: false,
      expandedHeight: 80.h,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [ColorsManager.darkGradientStart, ColorsManager.darkGradientEnd]
                : [ColorsManager.gradientStart, ColorsManager.gradientEnd],
          ),
        ),
        child: FlexibleSpaceBar(
          titlePadding: REdgeInsets.only(left: 20, bottom: 16),
          title: Row(
            children: [
              Container(
                padding: REdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.swap_horizontal_circle_rounded,
                  color: Colors.white,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                AppLocalizations.of(context)!.home,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20.sp,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Nearby toggle button
        if (_currentPosition != null)
          IconButton(
            icon: Icon(
              _showNearbyOnly ? Icons.near_me : Icons.near_me_outlined,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _showNearbyOnly = !_showNearbyOnly),
            tooltip: 'Show nearby items',
          ),

        // Map view button
        IconButton(
          icon: const Icon(Icons.map, color: Colors.white),
          onPressed: () async {
            final items = await FirebaseService.getItemsForMap();
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemsMapViewScreen(items: items),
                ),
              );
            }
          },
          tooltip: 'Map view',
        ),

        // Filters button
        IconButton(
          icon: const Icon(Icons.tune, color: Colors.white),
          onPressed: _showFilterDialog,
          tooltip: 'Filters',
        ),

        Container(
          margin: REdgeInsets.only(right: 12),
          child: ExchangeNotificationBadge(
            onTap: () => Navigator.pushNamed(context, Routes.exchangesList),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationLoadingBanner() {
    return Container(
      width: double.infinity,
      padding: REdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorsManager.purpleSoftFor(context),
            ColorsManager.purpleSoftFor(context).withOpacity(0.5),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14.w,
            height: 14.h,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ColorsManager.purpleFor(context),
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            'Getting your location...',
            style: TextStyle(
              fontSize: 12.sp,
              color: ColorsManager.purpleFor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBanner() {
    return Container(
      width: double.infinity,
      padding: REdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorsManager.purpleSoftFor(context),
            ColorsManager.purpleSoftFor(context).withOpacity(0.5),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on,
            size: 16.sp,
            color: ColorsManager.purpleFor(context),
          ),
          SizedBox(width: 8.w),
          Text(
            'Showing items within ${_radiusKm.toStringAsFixed(0)}km',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: ColorsManager.purpleFor(context),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: _showFilterDialog,
            child: Container(
              padding: REdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ColorsManager.purpleFor(context).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Change',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: ColorsManager.purpleFor(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: REdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: ColorsManager.cardFor(context),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.shadowFor(context),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
          color: ColorsManager.textFor(context),
        ),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.search_items,
          hintStyle: TextStyle(
            color: ColorsManager.textSecondaryFor(context),
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Container(
            padding: REdgeInsets.all(12),
            child: Container(
              padding: REdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: ColorsManager.gradientFor(context),
                ),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 18.sp,
              ),
            ),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: Container(
              padding: REdgeInsets.all(4),
              decoration: BoxDecoration(
                color: ColorsManager.greyLight.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 16.sp,
                color: ColorsManager.grey,
              ),
            ),
            onPressed: () {
              _searchController.clear();
              setState(() {});
            },
          )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: REdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 50.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: REdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildCategoryChip(null, 'All'),
          ...ItemCategory.values.map(
                (cat) => _buildCategoryChip(cat, cat.name.capitalize()),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(ItemCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    final IconData chipIcon = category?.icon ?? Icons.grid_view_rounded;

    return Padding(
      padding: REdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = category),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: REdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
              colors: ColorsManager.gradientFor(context),
            )
                : null,
            color: isSelected ? null : ColorsManager.cardFor(context),
            borderRadius: BorderRadius.circular(25.r),
            border: isSelected
                ? null
                : Border.all(
              color: ColorsManager.dividerFor(context),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: ColorsManager.purple.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                chipIcon,
                size: 16.sp,
                color: isSelected ? Colors.white : ColorsManager.purpleFor(context),
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : ColorsManager.textSecondaryFor(context),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    // If showing nearby only and we have location
    if (_showNearbyOnly && _currentPosition != null) {
      return FutureBuilder<List<ItemModel>>(
        future: FirebaseService.getItemsNearLocation(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          radiusKm: _radiusKm,
          category: _selectedCategory,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerGrid();
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          var items = snapshot.data ?? [];

          // Apply search filter
          items = _filterItemsBySearch(items);

          if (items.isEmpty) {
            return _buildEmptyNearbyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            color: ColorsManager.purple,
            backgroundColor: ColorsManager.cardFor(context),
            child: GridView.builder(
              padding: REdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14.w,
                mainAxisSpacing: 14.h,
                childAspectRatio: 0.72,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return ItemCard(
                  item: items[index],
                  onTap: () => _openItemDetail(items[index]),
                  userLocation: _currentPosition,
                );
              },
            ),
          );
        },
      );
    }

    // Show all items (default stream)
    return StreamBuilder<List<ItemModel>>(
      stream: FirebaseService.getItemsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerGrid();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final items = snapshot.data ?? [];
        final filteredItems = _filterItems(items);

        if (filteredItems.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {},
          color: ColorsManager.purple,
          backgroundColor: ColorsManager.cardFor(context),
          child: GridView.builder(
            padding: REdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14.w,
              mainAxisSpacing: 14.h,
              childAspectRatio: 0.72,
            ),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              return ItemCard(
                item: filteredItems[index],
                onTap: () => _openItemDetail(filteredItems[index]),
                userLocation: _currentPosition,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: REdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14.w,
        mainAxisSpacing: 14.h,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const ShimmerItemCard(),
    );
  }

  Widget _buildEmptyNearbyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: REdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorsManager.purpleSoftFor(context),
                  ColorsManager.purpleSoftFor(context).withOpacity(0.5),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_off,
              size: 56.sp,
              color: ColorsManager.purpleFor(context),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'No items found nearby',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: ColorsManager.textFor(context),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Try increasing the search radius',
            style: TextStyle(
              fontSize: 14.sp,
              color: ColorsManager.textSecondaryFor(context),
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _radiusKm = _radiusKm < 50 ? _radiusKm + 10 : 10;
              });
            },
            icon: const Icon(Icons.add_location),
            label: Text('Increase to ${(_radiusKm + 10).toStringAsFixed(0)}km'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsManager.purple,
              foregroundColor: Colors.white,
              padding: REdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: REdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorsManager.purpleSoftFor(context),
                  ColorsManager.purpleSoftFor(context).withOpacity(0.5),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              size: 56.sp,
              color: ColorsManager.purpleFor(context),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            AppLocalizations.of(context)!.no_items_found,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: ColorsManager.textFor(context),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14.sp,
              color: ColorsManager.textSecondaryFor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: REdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ColorsManager.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 48.sp,
              color: ColorsManager.error,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: ColorsManager.textFor(context),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            error,
            style: TextStyle(
              fontSize: 12.sp,
              color: ColorsManager.textSecondaryFor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<ItemModel> _filterItems(List<ItemModel> items) {
    return items.where((item) {
      final matchesSearch = _searchController.text.isEmpty ||
          item.title.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          );
      final matchesCategory =
          _selectedCategory == null || item.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<ItemModel> _filterItemsBySearch(List<ItemModel> items) {
    if (_searchController.text.isEmpty) return items;

    return items.where((item) {
      return item.title.toLowerCase().contains(
        _searchController.text.toLowerCase(),
      );
    }).toList();
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: ColorsManager.cardFor(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SafeArea(
          child: Padding(
            padding: REdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: ColorsManager.dividerFor(context),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),

                // Title
                Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: ColorsManager.textFor(context),
                  ),
                ),
                SizedBox(height: 24.h),

                // Distance filter (only if location available)
                if (_currentPosition != null) ...[
                  Text(
                    'Distance',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: ColorsManager.textFor(context),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Text(
                        '${_radiusKm.toStringAsFixed(0)} km',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: ColorsManager.purple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _radiusKm,
                          min: 1,
                          max: 50,
                          divisions: 49,
                          activeColor: ColorsManager.purple,
                          inactiveColor: ColorsManager.dividerFor(context),
                          onChanged: (value) {
                            setState(() => _radiusKm = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                ],

                // Apply button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsManager.purple,
                      foregroundColor: Colors.white,
                      padding: REdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openItemDetail(ItemModel item) {
    Navigator.pushNamed(context, Routes.itemDetail, arguments: item);
  }
}