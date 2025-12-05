import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:barter/model/exchange_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ExchangesScreen extends StatefulWidget {
  const ExchangesScreen({super.key});

  @override
  State<ExchangesScreen> createState() => _ExchangesScreenState();
}

class _ExchangesScreenState extends State<ExchangesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final userId = FirebaseService.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180.h,
              floating: true,
              pinned: true,
              snap: true,
              elevation: 0,
              backgroundColor: ColorsManager.gradientStart,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ColorsManager.gradientStart,
                      ColorsManager.gradientEnd,
                    ],
                  ),
                ),
                child: FlexibleSpaceBar(
                  title: Text(
                    'My Exchanges',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                  centerTitle: true,
                  titlePadding: EdgeInsetsDirectional.only(start: 16.w, bottom: 80.h),
                  background: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Icon(
                          Icons.swap_horiz_rounded,
                          size: 150.sp,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(70.h),
                child: Container(
                  margin: REdgeInsets.fromLTRB(16, 0, 16, 12),
                  padding: REdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25.r),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(21.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: ColorsManager.purple,
                    unselectedLabelColor: Colors.white,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13.sp,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Pending'),
                      Tab(text: 'Active'),
                      Tab(text: 'History'),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAllUserExchangesByStatus([ExchangeStatus.pending]),
            _buildAllUserExchangesByStatus([ExchangeStatus.accepted]),
            _buildAllUserExchangesByStatus([ExchangeStatus.completed, ExchangeStatus.cancelled]),
          ],
        ),
      ),
    );
  }

  Widget _buildAllUserExchangesByStatus(List<ExchangeStatus> statuses) {
    return StreamBuilder<List<ExchangeModel>>(
      stream: FirebaseService.getUserExchangesStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(ColorsManager.purpleFor(context)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final exchanges = snapshot.data!
            .where((exchange) => statuses.contains(exchange.status))
            .toList();

        if (exchanges.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: REdgeInsets.all(16),
          itemCount: exchanges.length,
          itemBuilder: (context, index) {
            return _buildExchangeCard(exchanges[index], index);
          },
        );
      },
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
              color: ColorsManager.purpleFor(context).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.swap_horiz_rounded,
              size: 64.sp,
              color: ColorsManager.purpleFor(context),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'No Exchanges Yet',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: ColorsManager.textFor(context),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Your exchanges will appear here',
            style: TextStyle(
              color: ColorsManager.textSecondaryFor(context),
              fontSize: 16.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeCard(ExchangeModel exchange, int index) {
    final isProposer = exchange.proposedBy == userId;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: REdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: ColorsManager.cardFor(context),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: ColorsManager.shadowFor(context),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _viewExchangeDetails(exchange),
            borderRadius: BorderRadius.circular(20.r),
            child: Padding(
              padding: REdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: REdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: exchange.status.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: exchange.status.color.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              exchange.status.icon,
                              size: 14.sp,
                              color: exchange.status.color,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              exchange.status.displayName,
                              style: TextStyle(
                                color: exchange.status.color,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatDate(exchange.proposedAt),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: ColorsManager.textSecondaryFor(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      _buildItemThumbnail(
                        isProposer ? exchange.itemOffered : exchange.itemRequested,
                        'You Offer',
                        true,
                      ),
                      Padding(
                        padding: REdgeInsets.symmetric(horizontal: 12),
                        child: Container(
                          padding: REdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ColorsManager.backgroundFor(context),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: ColorsManager.shadowFor(context),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.swap_horiz_rounded,
                            color: ColorsManager.purpleFor(context),
                            size: 24.sp,
                          ),
                        ),
                      ),
                      _buildItemThumbnail(
                        isProposer ? exchange.itemRequested : exchange.itemOffered,
                        'You Receive',
                        false,
                      ),
                    ],
                  ),
                  if (exchange.notes != null && exchange.notes!.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    Container(
                      width: double.infinity,
                      padding: REdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ColorsManager.backgroundFor(context),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.format_quote_rounded,
                            size: 20.sp,
                            color: ColorsManager.purpleFor(context).withOpacity(0.5),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              exchange.notes!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: ColorsManager.textSecondaryFor(context),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemThumbnail(ExchangeItem item, String label, bool isOutgoing) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 100.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: ColorsManager.shadowFor(context),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: ColorsManager.shimmerBaseFor(context),
                      child: Icon(
                        Icons.image_not_supported_rounded,
                        color: ColorsManager.textSecondaryFor(context),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: ColorsManager.textFor(context),
            ),
          ),
        ],
      ),
    );
  }

  void _viewExchangeDetails(ExchangeModel exchange) {
    Navigator.pushNamed(
      context,
      '/exchange-detail',
      arguments: exchange.id,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}