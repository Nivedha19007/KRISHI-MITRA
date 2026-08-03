import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../traceability/product_timeline_screen.dart';

class CustomerOrdersScreen extends ConsumerStatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  ConsumerState<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends ConsumerState<CustomerOrdersScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final orders = ref.watch(ordersProvider({'uid': currentUser.uid, 'isFarmer': false}));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Orders & Traceability',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping_outlined, size: 70, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No orders placed yet',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Explore the marketplace to order fresh farm crops!',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return _buildCustomerOrderCard(context, order);
              },
            ),
    );
  }

  Widget _buildCustomerOrderCard(BuildContext context, OrderModel order) {
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
                Text(
                  'Order #${order.id}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDelivered ? AppColors.verifiedBg : AppColors.mintBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDelivered ? AppColors.verifiedGreen : AppColors.primaryGreen),
                  ),
                  child: Text(
                    order.orderStatus,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDelivered ? AppColors.verifiedGreen : AppColors.primaryGreen,
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
                  child: const Icon(Icons.eco, color: AppColors.primaryGreen, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.productName,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Farmer: ${order.farmerName}',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        '${order.quantity} ${order.unit} • ₹${order.totalAmount.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                      ),
                    ],
                  ),
                ),

                // Mini Unique QR Code
                InkWell(
                  onTap: () => _showQrModal(context, order),
                  child: Column(
                    children: [
                      QrImageView(
                        data: 'KRISHI_MITRA_BATCH_${order.batchId}',
                        version: QrVersions.auto,
                        size: 50.0,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap QR',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                      ),
                    ],
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
                          'Your Rating: ${order.rating}/5.0 — "${order.reviewText ?? "Great fresh produce!"}"',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
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
                      icon: const Icon(Icons.star_outline, size: 18),
                      label: Text(order.rating != null ? 'Edit Feedback' : 'Give Feedback'),
                      onPressed: () => _showRatingModal(context, order),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.qr_code_scanner, size: 18),
                      label: const Text('Crop Timeline'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductTimelineScreen(batchId: order.batchId),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.timeline, size: 18),
                  label: const Text('View Farm Timeline QR'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductTimelineScreen(batchId: order.batchId),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showQrModal(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Unique Crop QR Code',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Scan this QR code to view the complete farm-to-table timeline entered by ${order.farmerName}.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              QrImageView(
                data: 'KRISHI_MITRA_BATCH_${order.batchId}',
                version: QrVersions.auto,
                size: 200.0,
              ),
              const SizedBox(height: 12),
              Text(
                'Batch ID: ${order.batchId}',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryGreen),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductTimelineScreen(batchId: order.batchId),
                  ),
                );
              },
              child: const Text('Open Timeline'),
            ),
          ],
        );
      },
    );
  }

  void _showRatingModal(BuildContext context, OrderModel order) {
    double currentRating = order.rating ?? 5.0;
    final reviewController = TextEditingController(text: order.reviewText ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                    'Rate Your Produce Experience',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    'Farmer: ${order.farmerName} • Crop: ${order.productName}',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // Rating Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        icon: Icon(
                          starValue <= currentRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 36,
                        ),
                        onPressed: () {
                          setModalState(() => currentRating = starValue.toDouble());
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Share feedback about freshness, packaging, or delivery...',
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(ordersProvider({'uid': order.customerId, 'isFarmer': false}).notifier).submitFeedback(
                              order.id,
                              currentRating,
                              reviewController.text,
                            );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Thank you! Your feedback has been submitted.')),
                        );
                      },
                      child: const Text('Submit Rating & Review'),
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
