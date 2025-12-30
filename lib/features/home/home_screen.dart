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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ItemCategory? _selectedCategory;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Location features
  Position? _currentPosition;
  double _radiusKm = 10.0;
  bool _showNearbyOnly = false;
  bool _isLoadingLocation = true;
  int _refreshKey = 0; // Add this to force rebuild

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
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(context),
        ],
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
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
      floatingActionButton: _buildFloatingActions(),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      floating: true,
      snap: true,
      expandedHeight: 80.h,
      leading: IconButton(
        icon: Container(
          padding: REdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(Icons.menu_rounded, color: Colors.white, size: 20.sp),
        ),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
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
          titlePadding: REdgeInsets.only(left: 70, bottom: 16),
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
        Container(
          margin: REdgeInsets.only(right: 16),
          child: ExchangeNotificationBadge(
            onTap: () => Navigator.pushNamed(context, Routes.exchangesList),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: ColorsManager.cardFor(context),
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: REdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 24, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [ColorsManager.darkGradientStart, ColorsManager.darkGradientEnd]
                    : [ColorsManager.gradientStart, ColorsManager.gradientEnd],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: REdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(
                    Icons.swap_horizontal_circle_rounded,
                    color: Colors.white,
                    size: 32.sp,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Barter',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Discover & Exchange',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable content
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // View Options Section
                Padding(
                  padding: REdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VIEW OPTIONS',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: ColorsManager.textSecondaryFor(context),
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // All Items
                      _buildDrawerItem(
                        icon: Icons.grid_view_rounded,
                        title: 'All Items',
                        subtitle: 'Browse everything',
                        isSelected: !_showNearbyOnly,
                        onTap: () {
                          setState(() => _showNearbyOnly = false);
                          Navigator.pop(context);
                        },
                      ),

                      // Nearby Items
                      _buildDrawerItem(
                        icon: Icons.near_me,
                        title: 'Nearby Items',
                        subtitle: _currentPosition != null
                            ? 'Within ${_radiusKm.toStringAsFixed(0)}km'
                            : 'Enable location',
                        isSelected: _showNearbyOnly,
                        trailing: _currentPosition != null
                            ? Icon(Icons.chevron_right, color: _showNearbyOnly ? Colors.white : ColorsManager.purple, size: 20.sp)
                            : null,
                        onTap: () {
                          if (_currentPosition != null) {
                            setState(() => _showNearbyOnly = true);
                            Navigator.pop(context);
                            // Show distance slider
                            Future.delayed(Duration(milliseconds: 300), () {
                              _showDistanceSheet();
                            });
                          } else {
                            Navigator.pop(context);
                            _showLocationPermissionDialog();
                          }
                        },
                      ),

                      // Map View
                      _buildDrawerItem(
                        icon: Icons.map_rounded,
                        title: 'Map View',
                        subtitle: 'See items on map',
                        onTap: () async {
                          Navigator.pop(context);
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
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, color: ColorsManager.dividerFor(context)),

                // Quick Actions
                Padding(
                  padding: REdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QUICK ACTIONS',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: ColorsManager.textSecondaryFor(context),
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 12.h),

                      _buildDrawerItem(
                        icon: Icons.refresh_rounded,
                        title: 'Refresh',
                        subtitle: 'Update items list',
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => _refreshKey++);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // App Info at bottom
          Container(
            padding: REdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorsManager.dividerFor(context).withOpacity(0.3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16.sp,
                  color: ColorsManager.textSecondaryFor(context),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: ColorsManager.textSecondaryFor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isSelected = false,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: REdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(colors: ColorsManager.gradientFor(context))
            : null,
        color: isSelected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: REdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: REdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.2)
                : ColorsManager.purpleSoftFor(context),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : ColorsManager.purpleFor(context),
            size: 20.sp,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : ColorsManager.textFor(context),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11.sp,
            color: isSelected
                ? Colors.white.withOpacity(0.9)
                : ColorsManager.textSecondaryFor(context),
          ),
        ),
        trailing: trailing,
      ),
    );
  }

  Widget _buildFloatingActions() {
    // Remove FAB completely as it's now in drawer
    return SizedBox.shrink();
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
            onTap: _showDistanceSheet,
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
    // Key is used to force rebuild when distance changes
    if (_showNearbyOnly && _currentPosition != null) {
      return FutureBuilder<List<ItemModel>>(
        key: ValueKey('nearby_$_radiusKm$_refreshKey'), // This forces rebuild
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
          items = _filterItemsBySearch(items);

          if (items.isEmpty) {
            return _buildEmptyNearbyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _refreshKey++);
            },
            color: ColorsManager.purple,
            backgroundColor: ColorsManager.cardFor(context),
            child: GridView.builder(
              padding: REdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
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
            physics: const AlwaysScrollableScrollPhysics(),
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

  void _showDistanceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        double tempRadius = _radiusKm;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
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

                      Row(
                        children: [
                          Container(
                            padding: REdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: ColorsManager.gradientFor(context),
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              Icons.radar,
                              color: Colors.white,
                              size: 20.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'Search Radius',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: ColorsManager.textFor(context),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),

                      Container(
                        padding: REdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ColorsManager.purpleSoftFor(context),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on,
                              color: ColorsManager.purpleFor(context),
                              size: 24.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              '${tempRadius.toStringAsFixed(0)} km',
                              style: TextStyle(
                                fontSize: 32.sp,
                                fontWeight: FontWeight.w900,
                                color: ColorsManager.purpleFor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),

                      Row(
                        children: [
                          Text(
                            '1 km',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: ColorsManager.textSecondaryFor(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: tempRadius,
                              min: 1,
                              max: 50,
                              divisions: 49,
                              activeColor: ColorsManager.purple,
                              inactiveColor: ColorsManager.dividerFor(context),
                              onChanged: (value) {
                                setModalState(() => tempRadius = value);
                              },
                            ),
                          ),
                          Text(
                            '50 km',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: ColorsManager.textSecondaryFor(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => _radiusKm = tempRadius);
                            Navigator.pop(ctx);
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
                            'Apply Radius',
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
            );
          },
        );
      },
    );
  }

  void _showFilterSheet() {
    // Remove this method - not needed anymore
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColorsManager.cardFor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Icon(Icons.location_off, color: ColorsManager.purple),
            SizedBox(width: 12.w),
            Text(
              'Location Required',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Please enable location services to see nearby items.',
          style: TextStyle(
            fontSize: 14.sp,
            color: ColorsManager.textSecondaryFor(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: ColorsManager.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _getCurrentLocation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsManager.purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  void _openItemDetail(ItemModel item) {
    Navigator.pushNamed(context, Routes.itemDetail, arguments: item);
  }
}