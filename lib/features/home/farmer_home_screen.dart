import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../marketplace/add_product_screen.dart';
import '../marketplace/farmer_products_screen.dart';
import '../marketplace/farmer_orders_screen.dart';
import '../market/mandi_prices_screen.dart';
import '../community/community_feed_screen.dart';

import '../../core/widgets/responsive_center.dart';

class FarmerHomeScreen extends ConsumerWidget {
  const FarmerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final l10n = context.l10n;
    final products = ref.watch(productsProvider);
    final farmerProducts = products
        .where((p) => p.farmerId == user.uid || p.farmerName == user.name)
        .toList();

    final farmerStats = ref.watch(farmerStatisticsProvider(user.uid));
    final ordersAsync = ref.watch(farmerOrdersStreamProvider(user.uid));
    final orders = ordersAsync.value ?? [];
    final reviewsAsync = ref.watch(farmerReviewsStreamProvider(user.uid));
    final reviews = reviewsAsync.value ?? [];

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
      body: ResponsiveCenter(
        maxWidth: 1400,
        child: SingleChildScrollView(
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
                    BoxShadow(
                      color: AppColors.primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
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
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.verificationStatus == VerificationStatus.verified
                                ? '✓ Verified Farmer'
                                : (user.verificationStatus == VerificationStatus.pending
                                    ? '⏳ Verification Pending'
                                    : '❌ Verification Rejected'),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: user.verificationStatus == VerificationStatus.verified
                                  ? AppColors.primaryGreen
                                  : (user.verificationStatus == VerificationStatus.pending
                                      ? Colors.orange.shade800
                                      : Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${user.village.isNotEmpty ? "${user.village}, " : ""}${user.district}, ${user.state} • ${user.farmerType}',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              if (user.verificationStatus == VerificationStatus.pending) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.hourglass_top_rounded,
                        color: Colors.amber.shade900,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Verification Pending',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.amber.shade900,
                              ),
                            ),
                            Text(
                              'Your farmer profile is under review by government/admin officers. Market features remain active.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Sales Analytics & Revenue Overview
              Text(
                'Sales Analytics & Revenue Overview',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  _buildMetricCard(
                    'Total Revenue',
                    '₹${farmerStats.totalRevenue.toStringAsFixed(0)}',
                    Icons.payments_rounded,
                    AppColors.accentGold,
                  ),
                  const SizedBox(width: 10),
                  _buildMetricCard(
                    'Products Sold',
                    '${farmerStats.totalProductsSold.toStringAsFixed(0)} units',
                    Icons.inventory_rounded,
                    AppColors.primaryGreen,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildMetricCard(
                    'Total Orders',
                    '${farmerStats.totalOrders}',
                    Icons.shopping_bag_rounded,
                    Colors.blue,
                  ),
                  const SizedBox(width: 10),
                  _buildMetricCard(
                    'Pending Orders',
                    '${farmerStats.pendingOrders}',
                    Icons.pending_actions_rounded,
                    Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildMetricCard(
                    'Completed Orders',
                    '${farmerStats.completedOrders}',
                    Icons.check_circle_outline_rounded,
                    AppColors.verifiedGreen,
                  ),
                  const SizedBox(width: 10),
                  _buildMetricCard(
                    'Average Rating',
                    farmerStats.totalReviews > 0
                        ? '${farmerStats.averageRating} ★ (${farmerStats.totalReviews})'
                        : 'No reviews yet',
                    Icons.star_rounded,
                    Colors.amber.shade700,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions Header
              Text(
                'Farmer Responsibilities & Actions',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: context.isMobile
                    ? 2
                    : (context.isTablet ? 3 : 4),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  _buildActionButton(
                    context,
                    'Sell Crop',
                    'List new harvest',
                    Icons.add_circle,
                    AppColors.primaryGreen,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddProductScreen(),
                        ),
                      );
                    },
                  ),
                  _buildActionButton(
                    context,
                    'My Products',
                    'Manage listings',
                    Icons.inventory_2_rounded,
                    AppColors.primaryGreen,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FarmerProductsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildActionButton(
                    context,
                    'Orders Received',
                    'Manage buyers',
                    Icons.receipt_long,
                    Colors.blue,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FarmerOrdersScreen(),
                        ),
                      );
                    },
                  ),
                  _buildActionButton(
                    context,
                    'Live Mandi Prices',
                    'Check APMC rates',
                    Icons.storefront,
                    AppColors.accentGold,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MandiPricesScreen(),
                        ),
                      );
                    },
                  ),
                  _buildActionButton(
                    context,
                    'Farmer Community',
                    'Q&A & Machinery',
                    Icons.forum,
                    Colors.orange,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CommunityFeedScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Recent Orders Section
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Customer Orders',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const FarmerOrdersScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'View All Orders',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (orders.isEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No customer orders received yet.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Column(
                          children: orders.take(3).map((o) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.mintBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.shopping_basket,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                              title: Text(
                                '${o.productName} (${o.quantity} ${o.unit})',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                'Buyer: ${o.customerName} • Status: ${o.orderStatus}',
                                style: GoogleFonts.inter(fontSize: 13),
                              ),
                              trailing: Text(
                                '₹${o.totalAmount.toStringAsFixed(0)}',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                  fontSize: 17,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Product Performance Analytics
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product Performance Breakdown',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (farmerProducts.isEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'No active crops listed yet.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Column(
                          children: farmerProducts.map((p) {
                            final productOrders = orders
                                .where((o) => o.productId == p.id)
                                .toList();
                            final unitsSold = productOrders.fold<double>(
                              0.0,
                              (sum, o) => sum + o.quantity,
                            );
                            final revenue = productOrders.fold<double>(
                              0.0,
                              (sum, o) => sum + o.totalAmount,
                            );

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.borderLight,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          'Variety: ${p.variety} • Stock: ${p.availableStock} ${p.unit}',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          'Sold: ${unitsSold.toStringAsFixed(0)} ${p.unit} • Orders: ${productOrders.length}',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹${revenue.toStringAsFixed(0)}',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppColors.primaryGreen,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            p.reviewCount > 0
                                                ? '${p.rating} (${p.reviewCount})'
                                                : 'No ratings',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Customer Feedback & Reviews Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Feedback & Ratings (${reviews.length})',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (reviews.isEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'No customer feedback received yet.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Column(
                          children: reviews.take(5).map((r) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50.withValues(
                                  alpha: 0.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.amber.shade200,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${r.customerName} (${r.productName})',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${r.rating}/5.0',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (r.comment.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      '"${r.comment}"',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ],
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
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
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
                radius: 20,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
