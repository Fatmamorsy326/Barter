import 'package:barter/core/resources/colors_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A shimmer loading effect widget for skeleton loading states
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Widget? child;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.child,
  });

  /// Creates a circular shimmer placeholder
  factory ShimmerLoading.circle({
    Key? key,
    required double size,
  }) {
    return ShimmerLoading(
      key: key,
      width: size,
      height: size,
      borderRadius: size / 2,
    );
  }

  /// Creates a text line shimmer placeholder
  factory ShimmerLoading.text({
    Key? key,
    double? width,
    double height = 14,
  }) {
    return ShimmerLoading(
      key: key,
      width: width ?? double.infinity,
      height: height,
      borderRadius: 4,
    );
  }

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                ColorsManager.shimmerBaseFor(context),
                ColorsManager.shimmerHighlightFor(context),
                ColorsManager.shimmerBaseFor(context),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// A card-shaped shimmer for item card loading states
class ShimmerItemCard extends StatelessWidget {
  const ShimmerItemCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorsManager.cardFor(context),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.shadowFor(context),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Expanded(
            flex: 3,
            child: ShimmerLoading(
              width: double.infinity,
              height: double.infinity,
              borderRadius: 16,
            ),
          ),
          // Content placeholder
          Expanded(
            flex: 2,
            child: Padding(
              padding: REdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLoading.text(width: 100.w, height: 14.h),
                  SizedBox(height: 8.h),
                  ShimmerLoading.text(width: 60.w, height: 12.h),
                  const Spacer(),
                  Row(
                    children: [
                      ShimmerLoading.circle(size: 14.w),
                      SizedBox(width: 6.w),
                      ShimmerLoading.text(width: 80.w, height: 10.h),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
