import 'package:flutter/material.dart';
import 'shimmer_skeleton.dart';

/// Mirrors AlertsScreen's alert-card list layout.
class AlertsScreenSkeleton extends StatelessWidget {
  const AlertsScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(width: 44, height: 44, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonLine(widthFactor: 0.5, height: 13),
                    SizedBox(height: 6),
                    SkeletonLine(widthFactor: 0.9, height: 10),
                    SizedBox(height: 4),
                    SkeletonLine(widthFactor: 0.7, height: 10),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SkeletonBox(width: 60, height: 16, radius: 8),
                        SkeletonLine(widthFactor: 0.15, height: 9),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
