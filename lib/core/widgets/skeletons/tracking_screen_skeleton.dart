import 'package:flutter/material.dart';
import 'shimmer_skeleton.dart';

/// Mirrors TrackingScreen's map area and bottom info card while trip data
/// and the map are still loading.
class TrackingScreenSkeleton extends StatelessWidget {
  const TrackingScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: const Color(0xFFE8EAF0)),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: AppShimmer(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const SkeletonBox(width: 48, height: 48, radius: 12),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            SkeletonLine(widthFactor: 0.4, height: 13),
                            SizedBox(height: 6),
                            SkeletonLine(widthFactor: 0.6, height: 10),
                          ],
                        ),
                      ),
                      const SkeletonBox(width: 60, height: 22, radius: 20),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFEAECF0), height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(
                      3,
                      (_) => const SizedBox(
                        width: 56,
                        child: Column(
                          children: [
                            SkeletonCircle(size: 20),
                            SizedBox(height: 6),
                            SkeletonLine(widthFactor: 0.9, height: 12),
                            SizedBox(height: 4),
                            SkeletonLine(widthFactor: 0.7, height: 9),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SkeletonBox(height: 48, radius: 12, width: double.infinity),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
