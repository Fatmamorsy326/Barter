// ============================================
// FILE: lib/features/exchange/exchanges_screen.dart (FIXED)
// ============================================

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
      appBar: AppBar(
        title: const Text('My Exchanges'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllUserExchangesByStatus([ExchangeStatus.pending]),
          _buildAllUserExchangesByStatus([ExchangeStatus.accepted]),
          _buildAllUserExchangesByStatus([ExchangeStatus.completed, ExchangeStatus.cancelled]),
        ],
      ),
    );
  }

  // Unified widget for all tabs - shows all user's exchanges filtered by status
  Widget _buildAllUserExchangesByStatus(List<ExchangeStatus> statuses) {
    return StreamBuilder<List<ExchangeModel>>(
      stream: FirebaseService.getUserExchangesStream(userId),
      builder: (context, snapshot) {
        print('Tab ${statuses.map((s) => s.displayName).join(", ")} - ConnectionState: ${snapshot.connectionState}');
        print('Tab - Has data: ${snapshot.hasData}');
        print('Tab - Raw data length: ${snapshot.data?.length ?? 0}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('Tab - Error: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          print('Tab - No data or empty');
          return _buildEmptyState();
        }

        // Filter exchanges by status
        final exchanges = snapshot.data!
            .where((exchange) => statuses.contains(exchange.status))
            .toList();

        print('Tab - Filtered to ${exchanges.length} exchanges with statuses: ${statuses.map((s) => s.displayName).join(", ")}');

        // Debug: Print each exchange status
        for (var exchange in snapshot.data!) {
          print('Exchange ${exchange.id}: status=${exchange.status.displayName} (${exchange.status.index})');
        }

        if (exchanges.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: REdgeInsets.all(16),
          itemCount: exchanges.length,
          itemBuilder: (context, index) {
            return _buildExchangeCard(exchanges[index]);
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
          Icon(
            Icons.swap_horiz,
            size: 80.sp,
            color: Colors.grey,
          ),
          SizedBox(height: 16.h),
          Text(
            'No Exchanges Yet',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Your exchanges will appear here',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeCard(ExchangeModel exchange) {
    final isProposer = exchange.proposedBy == userId;

    return Card(
      margin: REdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewExchangeDetails(exchange),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: REdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: REdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: exchange.status.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          exchange.status.icon,
                          size: 14.sp,
                          color: exchange.status.color,
                        ),
                        SizedBox(width: 4.w),
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
                  const Spacer(),
                  Text(
                    _formatDate(exchange.proposedAt),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  _buildItemThumbnail(
                    isProposer
                        ? exchange.itemOffered
                        : exchange.itemRequested,
                    'You offer',
                  ),
                  Padding(
                    padding: REdgeInsets.symmetric(horizontal: 16),
                    child: Icon(
                      Icons.swap_horiz,
                      color: ColorsManager.purple,
                      size: 28.sp,
                    ),
                  ),
                  _buildItemThumbnail(
                    isProposer
                        ? exchange.itemRequested
                        : exchange.itemOffered,
                    'You receive',
                  ),
                ],
              ),
              if (exchange.notes != null && exchange.notes!.isNotEmpty) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: REdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    exchange.notes!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemThumbnail(ExchangeItem item, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.network(
                  item.imageUrl,
                  width: 50.w,
                  height: 50.h,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 50.w,
                    height: 50.h,
                    color: Colors.grey[200],
                    child: Icon(Icons.image, color: Colors.grey),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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