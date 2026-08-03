import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/batch_model.dart';
import '../../data/repositories/product_repository.dart';

class ProductTimelineScreen extends ConsumerWidget {
  final String? batchId;
  final BatchModel? batch;

  const ProductTimelineScreen({super.key, this.batchId, this.batch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveBatchId = batchId ?? batch?.batchId ?? 'TOM-ERD-101';
    final batchData = batch ?? ref.watch(productRepositoryProvider).getBatchById(effectiveBatchId);

    if (batchData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Crop Timeline')),
        body: const Center(child: Text('Batch timeline details not found.')),
      );
    }

    final timeline = batchData.timeline;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Crop Timeline: ${batchData.productName}',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Batch Header Card with QR Code
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.mintBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  QrImageView(
                    data: 'KRISHI_MITRA_BATCH_${batchData.batchId}',
                    version: QrVersions.auto,
                    size: 80.0,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.verifiedBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '✓ Traceability Verified',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.verifiedGreen),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          batchData.productName,
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          'Variety: ${batchData.variety} • Qty: ${batchData.quantity} kg',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                        ),
                        Text(
                          'Farmer: ${batchData.farmerName}',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Text(
                          'Location: ${batchData.farmLocation}',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Certificate Info Badge
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium, color: AppColors.accentGold, size: 34),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          batchData.qualityStatus,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                        ),
                        Text(
                          batchData.certificateInfo,
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            Text(
              '🌱 ${batchData.productName} Unique Journey Timeline',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
            ),
            Text(
              'Generated specifically from information entered by ${batchData.farmerName}',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // Timeline Milestones List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: timeline.length,
              itemBuilder: (context, index) {
                final milestone = timeline[index];
                final isLast = index == timeline.length - 1;
                final dateStr = milestone.timestamp.toString().split(' ').first;
                final timeStr = '${milestone.timestamp.hour.toString().padLeft(2, '0')}:${milestone.timestamp.minute.toString().padLeft(2, '0')}';

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline Node Column
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: milestone.isCompleted ? AppColors.primaryGreen : Colors.grey.shade300,
                          child: Icon(
                            milestone.isCompleted ? Icons.check : Icons.hourglass_empty,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 3,
                            height: 70,
                            color: milestone.isCompleted ? AppColors.primaryGreen : Colors.grey.shade300,
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // Milestone Card Content
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: milestone.isCompleted ? Colors.white : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: milestone.isCompleted ? AppColors.primaryGreen.withOpacity(0.3) : AppColors.borderLight,
                            width: milestone.isCompleted ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  milestone.title,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: milestone.isCompleted ? AppColors.primaryGreen : AppColors.textSecondary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.mintBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$dateStr at $timeStr',
                                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              milestone.description,
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  milestone.location,
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                                ),
                                const Spacer(),
                                Text(
                                  'Farmer: ${batchData.farmerName}',
                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
