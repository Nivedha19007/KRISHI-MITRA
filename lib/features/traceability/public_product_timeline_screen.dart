import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/responsive_center.dart';
import '../../data/models/batch_model.dart';
import '../../data/repositories/product_repository.dart';

class PublicProductTimelineScreen extends ConsumerWidget {
  final String batchId;

  const PublicProductTimelineScreen({super.key, required this.batchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cleanBatchId = AppConfig.sanitizeBatchId(batchId);
    final repo = ref.watch(productRepositoryProvider);

    return FutureBuilder<BatchModel?>(
      future: repo.getBatchById(cleanBatchId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text(
                'KRISHI MITRA | Crop Traceability',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final batch = snapshot.data;

        // Requirement #9: Invalid Batch ID Error Page (No App Navigation)
        if (batch == null || cleanBatchId.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text(
                'KRISHI MITRA | Crop Traceability',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
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
                      'Product Traceability Not Found',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Sorry, this QR code does not correspond to a valid product batch.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Batch ID: "$cleanBatchId"',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final productName = batch.productName;
        final variety = batch.variety;
        final farmerName = batch.farmerName;
        final location = batch.farmLocation;
        final currentStatus = batch.currentStatus;
        final rawTimeline = batch.timeline;

        // Separate & Sort Completed Events Chronologically
        final completedEvents = rawTimeline.where((m) => m.isCompleted).toList();
        completedEvents.sort((a, b) {
          if (a.timestamp == null && b.timestamp == null) return 0;
          if (a.timestamp == null) return 1;
          if (b.timestamp == null) return -1;
          return a.timestamp!.compareTo(b.timestamp!);
        });

        final pendingEvents = rawTimeline.where((m) => !m.isCompleted).toList();
        final orderedEvents = [...completedEvents, ...pendingEvents];

        final isOrganic = productName.toLowerCase().contains('organic') ||
            batch.certificateInfo.toLowerCase().contains('organic');

        final dynamicTitle = isOrganic
            ? 'Organic $productName Unique Journey Timeline'
            : '$productName Unique Journey Timeline';

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false, // Pure standalone page, no back button to main app
            title: Text(
              'KRISHI MITRA | Crop Traceability 🌾',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          body: ResponsiveCenter(
            maxWidth: 700,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Public Verification Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryGreen, AppColors.leafGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Traceability Verified',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentGold,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Batch: $cleanBatchId',
                                style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          productName,
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (variety.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Variety: $variety • Quantity: ${batch.quantity} kg',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          'Farmer: $farmerName',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white70,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                location.isNotEmpty ? location : 'Farm Location Verified',
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.workspace_premium,
                              color: AppColors.accentGold,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Quality Status: ',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              batch.qualityStatus.isNotEmpty
                                  ? batch.qualityStatus
                                  : 'Grade A+ (Verified)',
                              style: GoogleFonts.inter(
                                color: AppColors.accentGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        if (batch.certificateInfo.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.card_membership,
                                color: Colors.white70,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  batch.certificateInfo,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Live Status Bar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mintBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.sensors,
                          color: AppColors.primaryGreen,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Current Lifecycle Stage: ',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            currentStatus,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Dynamic Timeline Title
                  Text(
                    dynamicTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Farmer-verified chronological journey from seed sowing to customer delivery:',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Customer-Facing Timeline List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orderedEvents.length,
                    itemBuilder: (context, index) {
                      final milestone = orderedEvents[index];
                      final isLast = index == orderedEvents.length - 1;
                      final isCompleted = milestone.isCompleted;

                      IconData nodeIcon;
                      Color nodeColor;

                      switch (milestone.stage) {
                        case TimelineStage.cultivated:
                        case TimelineStage.seeded:
                          nodeIcon = Icons.spa;
                          nodeColor = AppColors.primaryGreen;
                          break;
                        case TimelineStage.cropGrowing:
                          nodeIcon = Icons.grass;
                          nodeColor = Colors.green.shade600;
                          break;
                        case TimelineStage.harvested:
                          nodeIcon = Icons.agriculture;
                          nodeColor = AppColors.accentGold;
                          break;
                        case TimelineStage.qualityVerified:
                          nodeIcon = Icons.verified;
                          nodeColor = AppColors.verifiedGreen;
                          break;
                        case TimelineStage.packed:
                          nodeIcon = Icons.inventory_2;
                          nodeColor = Colors.brown.shade600;
                          break;
                        case TimelineStage.dispatched:
                        case TimelineStage.shipped:
                          nodeIcon = Icons.local_shipping;
                          nodeColor = Colors.blue.shade700;
                          break;
                        case TimelineStage.delivered:
                          nodeIcon = Icons.task_alt;
                          nodeColor = AppColors.primaryGreen;
                          break;
                      }

                      String timeBadgeText;
                      if (isCompleted && milestone.timestamp != null) {
                        final dateStr = DateFormat('dd MMM yyyy').format(milestone.timestamp!);
                        final timeStr = DateFormat('hh:mm a').format(milestone.timestamp!);
                        timeBadgeText = '$dateStr at $timeStr';
                      } else {
                        timeBadgeText = 'Awaiting update';
                      }

                      return ClipRect(
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Node & Connector Line
                              Column(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: isCompleted
                                        ? nodeColor
                                        : Colors.grey.shade300,
                                    child: Icon(
                                      isCompleted ? nodeIcon : Icons.hourglass_empty_rounded,
                                      color: isCompleted ? Colors.white : Colors.grey.shade600,
                                      size: 20,
                                    ),
                                  ),
                                  if (!isLast)
                                    Expanded(
                                      child: Container(
                                        width: 3,
                                        color: isCompleted
                                            ? nodeColor.withValues(alpha: 0.4)
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 14),

                              // Details Card
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isCompleted
                                          ? AppColors.borderLight
                                          : Colors.grey.shade200,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.03,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              milestone.title,
                                              style: GoogleFonts.outfit(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                color: isCompleted
                                                    ? AppColors.textPrimary
                                                    : AppColors.textMuted,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isCompleted
                                                  ? AppColors.mintBg
                                                  : Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              timeBadgeText,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isCompleted
                                                    ? AppColors.primaryGreen
                                                    : AppColors.textMuted,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        milestone.description.isNotEmpty
                                            ? milestone.description
                                            : (isCompleted
                                                ? 'Stage completed by farmer'
                                                : 'Pending stage update from farmer'),
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          height: 1.4,
                                          color: isCompleted
                                              ? AppColors.textSecondary
                                              : AppColors.textMuted,
                                        ),
                                      ),
                                      if (milestone.location.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              size: 14,
                                              color: AppColors.primaryGreen,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                'Location: ${milestone.location}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primaryGreen,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (milestone.actorName.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.person_outline,
                                              size: 14,
                                              color: AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                'Verified by: ${milestone.actorName}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Bottom Public Footer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: AppColors.primaryGreen,
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'KRISHI MITRA Open Traceability Standard',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Public customer page dynamically synchronized with farmer Firestore updates.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
