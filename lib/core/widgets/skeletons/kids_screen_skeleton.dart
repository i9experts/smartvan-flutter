import 'package:flutter/material.dart';
import 'shimmer_skeleton.dart';

/// Mirrors KidsScreen's kid-card list layout.
class KidsScreenSkeleton extends StatelessWidget {
  const KidsScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 3,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const SkeletonCircle(size: 64),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          SkeletonLine(widthFactor: 0.5, height: 14),
                          SizedBox(height: 8),
                          SkeletonLine(widthFactor: 0.7, height: 10),
                          SizedBox(height: 6),
                          SkeletonLine(widthFactor: 0.4, height: 10),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const SkeletonBox(width: 56, height: 22, radius: 20),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Expanded(child: SkeletonLine(widthFactor: 0.7, height: 10)),
                    SizedBox(width: 12),
                    Expanded(child: SkeletonLine(widthFactor: 0.7, height: 10)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFEAECF0)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: List.generate(
                    4,
                    (_) => const Expanded(
                      child: Column(
                        children: [
                          SkeletonCircle(size: 20),
                          SizedBox(height: 6),
                          SkeletonLine(widthFactor: 0.5, height: 8),
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
    );
  }
}
