import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/localized_helpers.dart';
import '../../core/widgets/responsive_center.dart';
import '../../data/models/delivery_model.dart';
import '../../data/repositories/delivery_repository.dart';

class DeliveryManagementScreen extends ConsumerStatefulWidget {
  final bool showAppBar;
  const DeliveryManagementScreen({super.key, this.showAppBar = false});

  @override
  ConsumerState<DeliveryManagementScreen> createState() =>
      _DeliveryManagementScreenState();
}

class _DeliveryManagementScreenState
    extends ConsumerState<DeliveryManagementScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final deliveriesAsync = ref.watch(allDeliveriesStreamProvider);
    final deliveries = deliveriesAsync.value ?? [];
    final l10n = context.l10n;

    final filteredDeliveries = deliveries.where((d) {
      if (_selectedFilter == 'All') return true;
      return d.deliveryStatus.toLowerCase() == _selectedFilter.toLowerCase();
    }).toList();

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(
                '${l10n.pendingDeliveries} 🚚',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
            )
          : null,
      body: ResponsiveCenter(
        maxWidth: 1200,
        child: Column(
          children: [
            // Filter Chips
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', '${l10n.allFilter} (${deliveries.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Placed', 'Placed'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Assigned', 'Assigned'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pickup', 'Pickup'),
                    const SizedBox(width: 8),
                    _buildFilterChip('In Transit', 'In Transit'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Delivered', 'Delivered'),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: filteredDeliveries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.noOrdersRecordedYet,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredDeliveries.length,
                      itemBuilder: (context, index) {
                        return _buildDeliveryCard(context, filteredDeliveries[index]);
                      },
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
        fontSize: 13,
      ),
      backgroundColor: AppColors.mintBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildDeliveryCard(BuildContext context, DeliveryModel delivery) {
    final l10n = context.l10n;
    Color statusColor = AppColors.pendingAmber;
    if (delivery.deliveryStatus == 'Assigned') statusColor = Colors.blue;
    if (delivery.deliveryStatus == 'Pickup') statusColor = Colors.indigo;
    if (delivery.deliveryStatus == 'In Transit') statusColor = Colors.purple;
    if (delivery.deliveryStatus == 'Delivered') statusColor = AppColors.verifiedGreen;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Delivery ID & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${l10n.orders} #${delivery.orderId}',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    delivery.deliveryStatus,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Pickup & Delivery Locations
            Row(
              children: [
                const Icon(Icons.store_mall_directory_outlined, size: 20, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.farmer}: ${delivery.farmerName}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        delivery.pickupLocation,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 20, color: Colors.deepOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.customer}: ${delivery.customerName}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        delivery.deliveryAddress,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Delivery Fee Breakdown
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.mintBg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.deliveryCharge,
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      Text(
                        '₹${delivery.deliveryCharge.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.totalPrice,
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      Text(
                        '₹${delivery.finalTotal > 0 ? delivery.finalTotal.toStringAsFixed(0) : (delivery.productSubtotal + delivery.deliveryCharge).toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Partner',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      Text(
                        delivery.assignedPartnerName ?? 'Unassigned',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
                    label: Text(
                      delivery.assignedPartnerName != null ? 'Change Partner' : 'Assign Partner',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _showAssignPartnerDialog(context, delivery),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit_note, size: 18),
                    label: Text(
                      l10n.statusLabel,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                    ),
                    onPressed: () => _showUpdateStatusSheet(context, delivery),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignPartnerDialog(BuildContext context, DeliveryModel delivery) {
    final nameController = TextEditingController(text: delivery.assignedPartnerName ?? '');
    final phoneController = TextEditingController(text: delivery.assignedPartnerPhone ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Assign Delivery Partner',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Delivery Partner Name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Partner Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
              onPressed: () async {
                final partnerName = nameController.text.trim();
                final partnerPhone = phoneController.text.trim();
                if (partnerName.isEmpty) return;

                await ref.read(deliveryRepositoryProvider).assignDeliveryPartner(
                      deliveryId: delivery.id,
                      partnerId: 'partner_${DateTime.now().millisecondsSinceEpoch}',
                      partnerName: partnerName,
                      partnerPhone: partnerPhone,
                    );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Delivery partner assigned successfully!'),
                      backgroundColor: AppColors.primaryGreen,
                    ),
                  );
                }
              },
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateStatusSheet(BuildContext context, DeliveryModel delivery) {
    final l10n = context.l10n;
    final statuses = ['Placed', 'Assigned', 'Pickup', 'In Transit', 'Delivered'];

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
                l10n.updateDeliveryStatus,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 12),
              ...statuses.map((status) {
                final isCurrent = delivery.deliveryStatus == status;
                return ListTile(
                  leading: Icon(
                    isCurrent ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isCurrent ? AppColors.primaryGreen : Colors.grey,
                  ),
                  title: Text(
                    status,
                    style: GoogleFonts.inter(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  onTap: () async {
                    await ref.read(deliveryRepositoryProvider).updateDeliveryStatus(
                          delivery.id,
                          status,
                        );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Delivery status updated to $status!'),
                          backgroundColor: AppColors.primaryGreen,
                        ),
                      );
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
