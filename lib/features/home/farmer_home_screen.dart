import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../marketplace/add_product_screen.dart';
import '../marketplace/farmer_orders_screen.dart';
import '../marketplace/product_list_screen.dart';
import '../market/mandi_prices_screen.dart';
import '../community/community_feed_screen.dart';
import '../profile/profile_screen.dart';

class FarmerHomeScreen extends ConsumerWidget {
  const FarmerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final l10n = context.l10n;
    final products = ref.watch(productsProvider);
    final farmerProducts = products.where((p) => p.farmerId == user.uid || p.farmerName == user.name).toList();
    final orders = ref.watch(orderRepositoryProvider).getOrdersForUser(user.uid, true);

    final totalRevenue = orders.fold<double>(0.0, (sum, o) => sum + o.totalAmount);
    final pendingDeliveries = orders.where((o) => o.orderStatus != 'Delivered').length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${l10n.farmer} ${l10n.home}',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
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
            // Welcome Farmer Card
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryGreen, AppColors.leafGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: AppColors.primaryGreen.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Welcome, ${user.name} 🌾',
                          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '✓ Verified Farmer',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${user.village.isNotEmpty ? "${user.village}, " : ""}${user.district}, ${user.state} • ${user.farmerType}',
                    style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Analytics Dashboard Grid
            Text(
              'Sales Analytics & Revenue',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _buildMetricCard('Total Revenue', '₹${totalRevenue.toStringAsFixed(0)}', Icons.payments_rounded, AppColors.accentGold),
                const SizedBox(width: 10),
                _buildMetricCard('Active Listings', '${farmerProducts.length}', Icons.eco_rounded, AppColors.primaryGreen),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildMetricCard('Orders Received', '${orders.length}', Icons.shopping_bag_rounded, Colors.blue),
                const SizedBox(width: 10),
                _buildMetricCard('Active Dispatch', '$pendingDeliveries', Icons.local_shipping_rounded, Colors.orange),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Actions Header
            Text(
              'Farmer Responsibilities & Actions',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _buildActionButton(context, 'Sell Crop', 'List new harvest', Icons.add_circle, AppColors.primaryGreen, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()));
                }),
                _buildActionButton(context, 'Orders Received', 'Manage buyers', Icons.receipt_long, Colors.blue, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmerOrdersScreen()));
                }),
                _buildActionButton(context, 'Live Mandi Prices', 'Check APMC rates', Icons.storefront, AppColors.accentGold, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MandiPricesScreen()));
                }),
                _buildActionButton(context, 'Farmer Community', 'Q&A & Machinery', Icons.forum, Colors.orange, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityFeedScreen()));
                }),
                _buildActionButton(context, 'Farmer Profile', 'Details & Badges', Icons.person, Colors.teal, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                }),
              ],
            ),
            const SizedBox(height: 20),

            // Listed Crops Preview Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Active Crops (${farmerProducts.length})',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ProductListScreen()),
                            );
                          },
                          child: Text('View Marketplace', style: GoogleFonts.inter(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    if (farmerProducts.isEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'No crops listed yet. Click "Sell Crop" to list your produce.',
                            style: GoogleFonts.inter(color: AppColors.textMuted),
                          ),
                        ),
                      ),
                    ] else ...[
                      Column(
                        children: farmerProducts.take(3).map((p) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(color: AppColors.mintBg, borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.eco, color: AppColors.primaryGreen),
                            ),
                            title: Text(p.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                            subtitle: Text('${p.variety} • Qty: ${p.availableStock} ${p.unit}', style: GoogleFonts.inter(fontSize: 12)),
                            trailing: Text(
                              '₹${p.pricePerUnit}/${p.unit}',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.primaryGreen, fontSize: 16),
                            ),
                          );
                        }).toList(),
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
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                  Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
