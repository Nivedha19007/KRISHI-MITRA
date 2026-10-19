import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/localized_helpers.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/order_repository.dart';

import '../../core/widgets/responsive_center.dart';

class FarmerOrdersScreen extends ConsumerStatefulWidget {
  const FarmerOrdersScreen({super.key});

  @override
  ConsumerState<FarmerOrdersScreen> createState() => _FarmerOrdersScreenState();
}

class _FarmerOrdersScreenState extends ConsumerState<FarmerOrdersScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final ordersAsync = ref.watch(farmerOrdersStreamProvider(currentUser.uid));
    final orders = ordersAsync.value ?? [];
    final l10n = context.l10n;

    final filteredOrders = orders.where((o) {
      final status = o.orderStatus.toLowerCase();
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Pending') return status == 'pending' || status == 'placed';
      if (_selectedFilter == 'Confirmed') return status == 'confirmed';
      if (_selectedFilter == 'Packed') return status == 'packed';
      if (_selectedFilter == 'Dispatched') return status.contains('dispatch') || status == 'shipped';
      if (_selectedFilter == 'Delivered') return status == 'delivered';
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.ordersReceived,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ResponsiveCenter(
        maxWidth: 1200,
        child: Column(
          children: [
            // Filter Tabs
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', '${l10n.orders} (${orders.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pending', l10n.pendingOrders),
                    const SizedBox(width: 8),
                    _buildFilterChip('Confirmed', l10n.confirm),
                    const SizedBox(width: 8),
                    _buildFilterChip('Packed', l10n.productTimeline),
                    const SizedBox(width: 8),
                    _buildFilterChip('Dispatched', l10n.pendingDeliveries),
                    const SizedBox(width: 8),
                    _buildFilterChip('Delivered', l10n.completedOrders),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(farmerOrdersStreamProvider(currentUser.uid));
                },
                child: ordersAsync.isLoading && !ordersAsync.hasValue
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryGreen,
                        ),
                      )
                    : filteredOrders.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 100),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inbox_outlined,
                                      size: 70,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      l10n.noCustomerOrders,
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final isDesktop = constraints.maxWidth >= 800;
                              if (isDesktop) {
                                return GridView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(16),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 1.35,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: filteredOrders.length,
                                  itemBuilder: (context, index) {
                                    return _buildOrderCard(
                                        context, filteredOrders[index]);
                                  },
                                );
                              }
                              return ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredOrders.length,
                                itemBuilder: (context, index) {
                                  return _buildOrderCard(
                                      context, filteredOrders[index]);
                                },
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = value),
      selectedColor: AppColors.primaryGreen,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.primaryGreen,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      backgroundColor: AppColors.mintBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    final l10n = context.l10n;
    final statusColor = order.orderStatus == 'Delivered'
        ? AppColors.verifiedGreen
        : order.orderStatus.contains('Dispatched')
        ? AppColors.primaryGreen
        : AppColors.pendingAmber;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID & Status Badge
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
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    order.orderStatus,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),

            // Product Details
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
                        '${l10n.varietyStock}: ${order.variety} • ${l10n.quantity}: ${order.quantity} ${LocalizedHelpers.getUnitName(context, order.unit)}',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${order.totalAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Customer Info
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${l10n.buyerStatus}: ${order.customerName}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.deliveryAddress,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.qr_code,
                        size: 18,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${l10n.batchId}: ${order.batchId}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (order.rating != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${l10n.averageRating}: ${order.rating}/5.0',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                    if (order.reviewText != null &&
                        order.reviewText!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '"${order.reviewText}"',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Action Buttons to Update Order Status
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showStatusUpdateDialog(context, order),
                    child: Text(l10n.verificationStatus),
                  ),
                ),
                const SizedBox(width: 10),
                if (order.orderStatus != 'Dispatched' &&
                    order.orderStatus != 'Delivered')
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.local_shipping, size: 18),
                      label: Text(l10n.pendingDeliveries),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                      ),
                      onPressed: () {
                        ref
                            .read(orderRepositoryProvider)
                            .updateOrderStatus(order.id, 'Dispatched');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.success),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusUpdateDialog(BuildContext context, OrderModel order) {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.verificationStatus,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.primaryGreen,
                ),
                title: Text(l10n.confirm),
                onTap: () {
                  ref
                      .read(orderRepositoryProvider)
                      .updateOrderStatus(order.id, 'Confirmed');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primaryGreen,
                ),
                title: Text(l10n.productTimeline),
                onTap: () {
                  ref
                      .read(orderRepositoryProvider)
                      .updateOrderStatus(order.id, 'Packed');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.primaryGreen,
                ),
                title: Text(l10n.pendingDeliveries),
                onTap: () {
                  ref
                      .read(orderRepositoryProvider)
                      .updateOrderStatus(order.id, 'Dispatched');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.home_outlined,
                  color: AppColors.verifiedGreen,
                ),
                title: Text(l10n.completedOrders),
                onTap: () {
                  ref
                      .read(orderRepositoryProvider)
                      .updateOrderStatus(order.id, 'Delivered');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
