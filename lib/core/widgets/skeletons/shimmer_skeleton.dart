import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Wraps skeleton placeholders in the app's standard shimmer animation.
class AppShimmer extends StatelessWidget {
  final Widget child;
  const AppShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8EAF0),
      highlightColor: const Color(0xFFF5F6FA),
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

/// A rectangular skeleton block with rounded corners.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final EdgeInsetsGeometry? margin;

  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A circular skeleton block, e.g. for avatars.
class SkeletonCircle extends StatelessWidget {
  final double size;
  final EdgeInsetsGeometry? margin;

  const SkeletonCircle({super.key, required this.size, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: margin,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// A skeleton line of text, sized relative to [widthFactor] of its parent.
///
/// Uses [LayoutBuilder] rather than [FractionallySizedBox] so it degrades
/// gracefully to [fallbackWidth] when placed somewhere with unbounded width
/// (e.g. a `Column` inside a `Row` with no `Expanded`/`SizedBox`), instead of
/// throwing an infinite-width layout assertion.
class SkeletonLine extends StatelessWidget {
  final double widthFactor;
  final double height;
  final EdgeInsetsGeometry? margin;
  final double fallbackWidth;

  const SkeletonLine({
    super.key,
    this.widthFactor = 1,
    this.height = 12,
    this.margin,
    this.fallbackWidth = 60,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth * widthFactor
            : fallbackWidth;
        return Align(
          alignment: Alignment.centerLeft,
          child:
              SkeletonBox(width: width, height: height, radius: height / 2, margin: margin),
        );
      },
    );
  }
}

/// A white card container matching the app's standard card styling,
/// used as a backdrop for skeleton content outside a colored header.
class SkeletonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  const SkeletonCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
