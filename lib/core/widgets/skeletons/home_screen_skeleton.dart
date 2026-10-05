import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'shimmer_skeleton.dart';

/// Mirrors the layout of HomeScreen's `_buildHome` body: header, active
/// trip banner, quick actions, kids strip and alerts list.
class HomeScreenSkeleton extends StatelessWidget {
  const HomeScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 90,
          floating: false,
          pinned: true,
          backgroundColor: const Color(0xFF1B2B6B),
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1B2B6B), Color(0xFF2D4099)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.white.withOpacity(0.18),
                        highlightColor: Colors.white.withOpacity(0.35),
                        period: const Duration(milliseconds: 1400),
                        child: SkeletonCircle(
                          size: 48,
                          margin: const EdgeInsets.only(right: 12),
                        ),
                      ),
                      Expanded(
                        child: Shimmer.fromColors(
                          baseColor: Colors.white.withOpacity(0.18),
                          highlightColor: Colors.white.withOpacity(0.35),
                          period: const Duration(milliseconds: 1400),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonLine(widthFactor: 0.6, height: 14),
                              const SizedBox(height: 8),
                              SkeletonLine(widthFactor: 0.4, height: 10),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: AppShimmer(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 76, radius: 16, width: double.infinity),
                  const SizedBox(height: 24),
                  SkeletonBox(height: 110, radius: 16, width: double.infinity),
                  const SizedBox(height: 24),
                  const SkeletonLine(widthFactor: 0.35, height: 16),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      4,
                      (_) => Column(
                        children: [
                          const SkeletonCircle(size: 60),
                          const SizedBox(height: 8),
                          const SizedBox(
                            width: 60,
                            child: SkeletonLine(widthFactor: 0.6, height: 9),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SkeletonLine(widthFactor: 0.25, height: 16),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      itemBuilder: (context, index) => Container(
                        width: 90,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SkeletonCircle(size: 48),
                            SizedBox(height: 8),
                            SkeletonLine(widthFactor: 0.6, height: 9),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SkeletonLine(widthFactor: 0.3, height: 16),
                  const SizedBox(height: 12),
                  ...List.generate(
                    2,
                    (_) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const SkeletonBox(width: 40, height: 40, radius: 10),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                SkeletonLine(widthFactor: 0.5, height: 11),
                                SizedBox(height: 6),
                                SkeletonLine(widthFactor: 0.8, height: 9),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
