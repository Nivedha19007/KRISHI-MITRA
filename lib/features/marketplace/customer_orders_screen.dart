import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/config/app_config.dart';
import '../../core/localization/localized_helpers.dart';
import '../../data/models/order_model.dart';
import '../../data/models/quality_complaint_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/quality_complaint_repository.dart';
import '../traceability/product_timeline_screen.dart';
import '../traceability/public_product_timeline_screen.dart';

import '../../core/widgets/responsive_center.dart';

class CustomerOrdersScreen extends ConsumerStatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  ConsumerState<CustomerOrdersScreen> createState() =>
      _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends ConsumerState<CustomerOrdersScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final ordersAsync = ref.watch(customerOrdersStreamProvider(currentUser.uid));
    final orders = ordersAsync.value ?? [];
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.myOrdersAndTraceability,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ResponsiveCenter(
        maxWidth: 1200,
        child: orders.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 70,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.noOrdersPlaced,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 800;
                  if (isDesktop) {
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.35,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        return _buildCustomerOrderCard(context, orders[index]);
                      },
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      return _buildCustomerOrderCard(context, orders[index]);
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildCustomerOrderCard(BuildContext context, OrderModel order) {
    final l10n = context.l10n;
    final isDelivered = order.orderStatus == 'Delivered';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${l10n.orders} #${order.id}',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDelivered
                        ? AppColors.verifiedBg
                        : AppColors.mintBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDelivered
                          ? AppColors.verifiedGreen
                          : AppColors.primaryGreen,
                    ),
                  ),
                  child: Text(
                    order.orderStatus,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDelivered
                          ? AppColors.verifiedGreen
                          : AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),

            // Product Item Info
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.mintBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.eco,
                    color: AppColors.primaryGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.productName,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '${l10n.farmer}: ${order.farmerName}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${order.quantity} ${LocalizedHelpers.getUnitName(context, order.unit)} • ₹${order.totalAmount.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),

                // Mini Unique QR Code
                InkWell(
                  onTap: () => _showQrModal(context, order),
                  child: QrImageView(
                    data: AppConfig.getTimelineUrl(order.batchId),
                    version: QrVersions.auto,
                    size: 50.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Rating & Review section or Action Buttons
            if (isDelivered) ...[
              if (order.rating != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${l10n.averageRating}: ${order.rating}/5.0 — "${order.reviewText ?? ""}"',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.report_problem_outlined, size: 16, color: Colors.red),
                      label: Text(
                        l10n.reportQualityIssue,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _showQualityComplaintModal(context, order),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.star_outline, size: 16),
                      label: Text(l10n.submitReview, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12)),
                      onPressed: () => _showRatingModal(context, order),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.qr_code_scanner, size: 16),
                      label: Text(l10n.productTimeline, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductTimelineScreen(batchId: order.batchId),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.report_problem_outlined, size: 16, color: Colors.red),
                      label: Text(
                        l10n.reportQualityIssue,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _showQualityComplaintModal(context, order),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.timeline, size: 16),
                      label: Text(l10n.productTimeline, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductTimelineScreen(batchId: order.batchId),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showQrModal(BuildContext context, OrderModel order) {
    final timelineUrl = AppConfig.getTimelineUrl(order.batchId);
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.scanQr,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Text(
                    order.productName,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  Text(
                    '${l10n.farmer}: ${order.farmerName}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${l10n.batchId}: ${order.batchId}',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.accentGold,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // QR Code Encoding Timeline Web URL
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryGreen,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: timelineUrl,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // "View Timeline" Button
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
                        Navigator.pop(context);
                        AppConfig.launchTimelineUrl(order.batchId);
                      },
                      icon: const Icon(
                        Icons.open_in_browser,
                        color: Colors.white,
                      ),
                      label: Text(
                        l10n.productTimeline,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PublicProductTimelineScreen(
                            batchId: order.batchId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.timeline, size: 18),
                    label: Text(l10n.productTimeline),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRatingModal(BuildContext context, OrderModel order) {
    final l10n = context.l10n;
    double currentRating = order.rating ?? 5.0;
    final reviewController = TextEditingController(
      text: order.reviewText ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.submitReview,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    '${l10n.farmer}: ${order.farmerName} • ${l10n.crop}: ${order.productName}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Rating Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        icon: Icon(
                          starValue <= currentRating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 36,
                        ),
                        onPressed: () {
                          setModalState(
                            () => currentRating = starValue.toDouble(),
                          );
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: l10n.tagline,
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        ref
                            .read(orderRepositoryProvider)
                            .addOrderFeedback(
                              order.id,
                              currentRating,
                              reviewController.text,
                            );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.success,
                            ),
                          ),
                        );
                      },
                      child: Text(l10n.submitReview),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showQualityComplaintModal(BuildContext context, OrderModel order) {
    final l10n = context.l10n;
    final currentUser = ref.read(currentUserProvider);
    String selectedIssue = 'spoiledProduce';
    final descController = TextEditingController();
    final photoController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.reportQualityIssue,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.red.shade700,
                    ),
                  ),
                  Text(
                    'Order #${order.id} • ${order.productName}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.issueType,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedIssue,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'spoiledProduce',
                        child: Text(l10n.spoiledProduce),
                      ),
                      DropdownMenuItem(
                        value: 'poorQuality',
                        child: Text(l10n.poorQuality),
                      ),
                      DropdownMenuItem(
                        value: 'incorrectQuality',
                        child: Text(l10n.incorrectQuality),
                      ),
                      DropdownMenuItem(
                        value: 'other',
                        child: Text(l10n.otherQualityIssue),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedIssue = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: l10n.complaintDescription,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: photoController,
                    decoration: InputDecoration(
                      labelText: l10n.photoEvidence,
                      hintText: 'https://...',
                      prefixIcon: const Icon(Icons.photo_camera_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        final complaint = QualityComplaintModel(
                          complaintId: 'cmp_${DateTime.now().millisecondsSinceEpoch}',
                          customerId: currentUser.uid,
                          customerName: currentUser.name.isNotEmpty ? currentUser.name : 'Customer',
                          orderId: order.id,
                          productId: order.productId,
                          productName: order.productName,
                          batchId: order.batchId,
                          issueType: selectedIssue,
                          description: descController.text.trim(),
                          photoUrl: photoController.text.trim(),
                        );
                        await ref.read(qualityComplaintRepositoryProvider).submitComplaint(complaint);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.complaintSubmitted),
                              backgroundColor: AppColors.primaryGreen,
                            ),
                          );
                        }
                      },
                      child: Text(
                        l10n.reportQualityIssue.toUpperCase(),
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
