import 'package:flutter/material.dart';
import 'shimmer_skeleton.dart';

/// Mirrors PaymentHistoryScreen's summary cards, total-paid banner, filter
/// chips and payment card list.
class PaymentHistorySkeleton extends StatelessWidget {
  const PaymentHistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                3,
                (i) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonCircle(size: 20),
                        SizedBox(height: 8),
                        SkeletonLine(widthFactor: 0.4, height: 18),
                        SizedBox(height: 4),
                        SkeletonLine(widthFactor: 0.6, height: 9),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const SkeletonBox(height: 76, radius: 16, width: double.infinity),
            const SizedBox(height: 20),
            const SkeletonLine(widthFactor: 0.3, height: 16),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                4,
                (i) => Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: const SkeletonBox(width: 64, height: 32, radius: 20),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(
              3,
              (_) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const SkeletonBox(width: 42, height: 42, radius: 10),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            SkeletonLine(widthFactor: 0.5, height: 13),
                            SizedBox(height: 6),
                            SkeletonLine(widthFactor: 0.3, height: 9),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SkeletonLine(widthFactor: 0.7, height: 14),
                          SizedBox(height: 6),
                          SkeletonBox(width: 50, height: 16, radius: 8),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
