import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/order_repository.dart';

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
    final orders = ref.watch(ordersProvider({'uid': currentUser.uid, 'isFarmer': true}));

    final filteredOrders = orders.where((o) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Pending') return o.orderStatus != 'Delivered';
      if (_selectedFilter == 'Delivered') return o.orderStatus == 'Delivered';
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Orders Received',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip('All', 'All Orders (${orders.length})'),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', 'Active Dispatch'),
                const SizedBox(width: 8),
                _buildFilterChip('Delivered', 'Completed'),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: filteredOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 70, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No orders found',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'New customer orders for your crops will appear here.',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return _buildOrderCard(context, order);
                    },
                  ),
          ),
        ],
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
        fontSize: 12,
      ),
      backgroundColor: AppColors.mintBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
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
                Text(
                  'Order #${order.id}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    order.orderStatus,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
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
                        'Variety: ${order.variety} • Qty: ${order.quantity} ${order.unit}',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${order.totalAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryGreen),
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
                      const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Buyer: ${order.customerName}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.deliveryAddress,
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.qr_code, size: 16, color: AppColors.primaryGreen),
                      const SizedBox(width: 6),
                      Text(
                        'QR Batch ID: ${order.batchId}',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
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
                          'Buyer Rating: ${order.rating}/5.0',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber.shade900),
                        ),
                      ],
                    ),
                    if (order.reviewText != null && order.reviewText!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '"${order.reviewText}"',
                        style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textPrimary),
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
                    child: const Text('Update Status'),
                  ),
                ),
                const SizedBox(width: 10),
                if (order.orderStatus != 'Dispatched 🚚' && order.orderStatus != 'Delivered')
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.local_shipping, size: 18),
                      label: const Text('Dispatch Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                      ),
                      onPressed: () {
                        ref.read(ordersProvider({'uid': order.farmerId, 'isFarmer': true}).notifier).updateStatus(
                              order.id,
                              'Dispatched 🚚',
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Order marked as Dispatched!')),
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Order Status',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: AppColors.primaryGreen),
                title: const Text('Confirmed'),
                onTap: () {
                  ref.read(ordersProvider({'uid': order.farmerId, 'isFarmer': true}).notifier).updateStatus(order.id, 'Confirmed');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined, color: AppColors.primaryGreen),
                title: const Text('Packed'),
                onTap: () {
                  ref.read(ordersProvider({'uid': order.farmerId, 'isFarmer': true}).notifier).updateStatus(order.id, 'Packed');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.local_shipping_outlined, color: AppColors.primaryGreen),
                title: const Text('Dispatched 🚚'),
                onTap: () {
                  ref.read(ordersProvider({'uid': order.farmerId, 'isFarmer': true}).notifier).updateStatus(order.id, 'Dispatched 🚚');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.home_outlined, color: AppColors.verifiedGreen),
                title: const Text('Delivered'),
                onTap: () {
                  ref.read(ordersProvider({'uid': order.farmerId, 'isFarmer': true}).notifier).updateStatus(order.id, 'Delivered');
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
