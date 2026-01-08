import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:barter/model/review_model.dart';
import 'package:barter/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReviewsScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final double averageRating;
  final int reviewCount;

  const ReviewsScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.averageRating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews for $userName'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Rating Summary Header
          Container(
            width: double.infinity,
            padding: REdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.withOpacity(0.15),
                  Colors.orange.withOpacity(0.1),
                ],
              ),
            ),
            child: Column(
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 48.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade700,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Icon(
                      index < averageRating.round()
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: Colors.amber.shade600,
                      size: 24.sp,
                    );
                  }),
                ),
                SizedBox(height: 8.h),
                Text(
                  '$reviewCount ${reviewCount == 1 ? "Review" : "Reviews"}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: ColorsManager.textSecondaryFor(context),
                  ),
                ),
              ],
            ),
          ),
          // Reviews List
          Expanded(
            child: StreamBuilder<List<ReviewModel>>(
              stream: FirebaseService.getUserReviews(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: REdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                          SizedBox(height: 16.h),
                          Text(
                            'Error loading reviews',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final reviews = snapshot.data ?? [];
                if (reviews.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 64.sp,
                          color: ColorsManager.textSecondaryFor(context).withOpacity(0.3),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No reviews yet',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: ColorsManager.textSecondaryFor(context),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: REdgeInsets.all(16),
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => SizedBox(height: 16.h),
                  itemBuilder: (context, index) {
                    return _buildReviewItem(context, reviews[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(BuildContext context, ReviewModel review) {
    return FutureBuilder<UserModel?>(
      future: FirebaseService.getUserById(review.reviewerId),
      builder: (context, snapshot) {
        final reviewer = snapshot.data;
        return Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          child: Padding(
            padding: REdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ColorsManager.purple.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 20.r,
                        backgroundColor: ColorsManager.purple.withOpacity(0.1),
                        backgroundImage: reviewer?.photoUrl != null && reviewer!.photoUrl!.isNotEmpty
                            ? NetworkImage(reviewer!.photoUrl!)
                            : null,
                        child: reviewer?.photoUrl == null || reviewer!.photoUrl!.isEmpty
                            ? Text(
                                reviewer != null && reviewer.name.isNotEmpty
                                    ? reviewer.name[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  color: ColorsManager.purple,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                ),
                              )
                            : null,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reviewer?.name ?? 'Unknown User',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15.sp,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            _formatDate(review.createdAt),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: REdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade400, Colors.amber.shade600],
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, color: Colors.white, size: 14.sp),
                          SizedBox(width: 4.w),
                          Text(
                            review.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (review.comment.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Container(
                    padding: REdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColorsManager.backgroundFor(context),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      review.comment,
                      style: TextStyle(
                        fontSize: 14.sp,
                        height: 1.5,
                        color: ColorsManager.textFor(context),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }
}
