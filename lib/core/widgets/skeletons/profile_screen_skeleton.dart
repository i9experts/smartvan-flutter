import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'shimmer_skeleton.dart';

/// Mirrors ProfileScreen's header, stats row, info card and settings card.
class ProfileScreenSkeleton extends StatelessWidget {
  const ProfileScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF1B2B6B),
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
                child: Shimmer.fromColors(
                  baseColor: Colors.white.withOpacity(0.18),
                  highlightColor: Colors.white.withOpacity(0.35),
                  period: const Duration(milliseconds: 1400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      const SkeletonCircle(size: 90),
                      const SizedBox(height: 12),
                      const SkeletonLine(widthFactor: 0.3, height: 14),
                      const SizedBox(height: 8),
                      const SkeletonLine(widthFactor: 0.4, height: 10),
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
                  Row(
                    children: List.generate(
                      3,
                      (i) => Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: i < 2 ? 12 : 0),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Column(
                            children: [
                              SkeletonCircle(size: 24),
                              SizedBox(height: 8),
                              SkeletonLine(widthFactor: 0.4, height: 16),
                              SizedBox(height: 4),
                              SkeletonLine(widthFactor: 0.5, height: 9),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SkeletonLine(widthFactor: 0.45, height: 16),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: List.generate(
                        4,
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              const SkeletonCircle(size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: const [
                                    SkeletonLine(widthFactor: 0.3, height: 9),
                                    SizedBox(height: 6),
                                    SkeletonLine(widthFactor: 0.5, height: 12),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SkeletonLine(widthFactor: 0.25, height: 16),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: List.generate(
                        5,
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              const SkeletonBox(
                                  width: 36, height: 36, radius: 10),
                              const SizedBox(width: 12),
                              const Expanded(
                                child:
                                    SkeletonLine(widthFactor: 0.5, height: 11),
                              ),
                            ],
                          ),
                        ),
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
