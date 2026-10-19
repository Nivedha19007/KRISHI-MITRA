import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/config/app_config.dart';
import '../../data/models/batch_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../core/widgets/responsive_center.dart';

class ProductTimelineScreen extends ConsumerWidget {
  final String? batchId;
  final BatchModel? batch;

  const ProductTimelineScreen({super.key, this.batchId, this.batch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (batch != null) {
      return _buildTimelineContent(context, batch!);
    }

    final cleanId = AppConfig.sanitizeBatchId(batchId ?? '');
    if (cleanId.isEmpty) {
      return _buildNotFoundScreen(context, cleanId);
    }

    return FutureBuilder<BatchModel?>(
      future: ref.watch(productRepositoryProvider).getBatchById(cleanId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Crop Timeline',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final batchData = snapshot.data;
        if (batchData == null) {
          return _buildNotFoundScreen(context, cleanId);
        }

        return _buildTimelineContent(context, batchData);
      },
    );
  }

  Widget _buildNotFoundScreen(BuildContext context, String cleanBatchId) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Crop Traceability',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: ResponsiveCenter(
        maxWidth: 600,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 64,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Crop Not Found',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'No valid crop traceability record was found for Batch ID:\n"$cleanBatchId"',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacementNamed(context, '/');
                    }
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: Text(
                    'Back / Home',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
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

  Widget _buildTimelineContent(BuildContext context, BatchModel batchData) {
    final rawTimeline = batchData.timeline;
    final completedEvents = rawTimeline.where((m) => m.isCompleted).toList();
    completedEvents.sort((a, b) {
      if (a.timestamp == null && b.timestamp == null) return 0;
      if (a.timestamp == null) return 1;
      if (b.timestamp == null) return -1;
      return a.timestamp!.compareTo(b.timestamp!);
    });

    final pendingEvents = rawTimeline.where((m) => !m.isCompleted).toList();
    final orderedTimeline = [...completedEvents, ...pendingEvents];

    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final headerSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Batch Header Card with QR Code
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: AppColors.mintBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primaryGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () => AppConfig.launchTimelineUrl(batchData.batchId),
                child: QrImageView(
                  data: AppConfig.getTimelineUrl(batchData.batchId),
                  version: QrVersions.auto,
                  size: 90.0,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.verifiedBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '✓ Traceability Verified',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.verifiedGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      batchData.productName,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Variety: ${batchData.variety} • Qty: ${batchData.quantity} kg',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    Text(
                      'Farmer: ${batchData.farmerName}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Location: ${batchData.farmLocation}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
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
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.workspace_premium,
                color: AppColors.accentGold,
                size: 34,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batchData.qualityStatus,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      batchData.certificateInfo,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final timelineSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🌱 ${batchData.productName} Unique Journey Timeline',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          'Generated specifically from information entered by ${batchData.farmerName}',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 16),

        // Timeline Milestones List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orderedTimeline.length,
          itemBuilder: (context, index) {
            final milestone = orderedTimeline[index];
            final isLast = index == orderedTimeline.length - 1;
            final isCompleted = milestone.isCompleted;

            String timeBadgeText;
            if (isCompleted && milestone.timestamp != null) {
              final dateStr = DateFormat('dd MMM yyyy').format(milestone.timestamp!);
              final timeStr = DateFormat('hh:mm a').format(milestone.timestamp!);
              timeBadgeText = '$dateStr at $timeStr';
            } else {
              timeBadgeText = 'Awaiting update';
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline Node Column
                Column(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isCompleted
                          ? AppColors.primaryGreen
                          : Colors.grey.shade300,
                      child: Icon(
                        isCompleted
                            ? Icons.check
                            : Icons.hourglass_empty_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 3,
                        height: 70,
                        color: isCompleted
                            ? AppColors.primaryGreen
                            : Colors.grey.shade300,
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
                      color: isCompleted
                          ? Colors.white
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCompleted
                            ? AppColors.primaryGreen.withValues(alpha: 0.3)
                            : AppColors.borderLight,
                        width: isCompleted ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                milestone.title,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: isCompleted
                                      ? AppColors.primaryGreen
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? AppColors.mintBg
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                timeBadgeText,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted
                                      ? AppColors.primaryGreen
                                      : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          milestone.description.isNotEmpty
                              ? milestone.description
                              : (isCompleted
                                  ? 'Stage completed by farmer'
                                  : 'Pending stage update from farmer'),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                milestone.location.isNotEmpty
                                    ? milestone.location
                                    : batchData.farmLocation,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              flex: 2,
                              child: Text(
                                'Farmer: ${batchData.farmerName}',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
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
    );

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
      body: ResponsiveCenter(
        maxWidth: isDesktop ? 1200 : 900,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: headerSection),
                    const SizedBox(width: 24),
                    Expanded(flex: 3, child: timelineSection),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headerSection,
                    const SizedBox(height: 22),
                    timelineSection,
                  ],
                ),
        ),
      ),
    );
  }
}
