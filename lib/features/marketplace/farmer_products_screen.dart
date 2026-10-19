import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/localized_helpers.dart';
import '../../core/widgets/responsive_center.dart';
import '../../core/widgets/smart_image.dart';
import '../../data/models/product_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/product_repository.dart';
import 'add_product_screen.dart';
import '../traceability/product_qr_screen.dart';

class FarmerProductsScreen extends ConsumerWidget {
  const FarmerProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final allProducts = ref.watch(productsProvider);
    final l10n = context.l10n;

    // Filter products belonging ONLY to the authenticated farmer
    final myProducts = allProducts
        .where((p) => p.farmerId == user.uid || p.farmerName == user.name)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.myProducts,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 26),
            tooltip: l10n.sellCrop,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddProductScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 1200,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user.verificationStatus != VerificationStatus.verified) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade400),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.pending_actions_rounded,
                            color: Colors.amber.shade900, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.accountVerificationPendingDesc,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Top Header Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.mintBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.inventory_2_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l10n.myProducts} (${myProducts.length})',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.primaryDarkGreen,
                              ),
                            ),
                            Text(
                              l10n.manageListings,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddProductScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(
                          l10n.sellCrop,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Product List View / Grid View
                Expanded(
                  child: myProducts.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: myProducts.length,
                          itemBuilder: (context, index) {
                            final product = myProducts[index];
                            return _buildProductCard(context, ref, product);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.mintBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.agriculture_rounded,
              size: 64,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noActiveCrops,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tagline,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddProductScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add_circle, color: Colors.white),
            label: Text(
              l10n.listCropForSale.toUpperCase(),
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    WidgetRef ref,
    ProductModel product,
  ) {
    final l10n = context.l10n;
    final imageUrl = product.imageUrls.isNotEmpty
        ? product.imageUrls.first
        : 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=600';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Crop Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SmartImage(
                    pathOrUrl: imageUrl,
                    width: 95,
                    height: 95,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),

                // Crop Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          // Publish Status Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: product.isPublished
                                  ? Colors.green.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: product.isPublished
                                    ? Colors.green.shade400
                                    : Colors.grey.shade400,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 4,
                                  backgroundColor: product.isPublished
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  product.isPublished ? 'LIVE' : 'DRAFT',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: product.isPublished
                                        ? Colors.green.shade800
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      Text(
                        '${l10n.varietyStock}: ${product.variety} • ${l10n.category}: ${LocalizedHelpers.getCategoryName(context, product.category)}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Text(
                            '₹${product.pricePerUnit}/${LocalizedHelpers.getUnitName(context, product.unit)}',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.mintBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${l10n.availableStock}: ${product.availableStock} ${LocalizedHelpers.getUnitName(context, product.unit)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (product.batchId != null && product.batchId!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${l10n.batchId}: ${product.batchId}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (product.bulkDiscountMinQty != null &&
                          product.bulkDiscountPricePerUnit != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Bulk Offer: ≥${product.bulkDiscountMinQty!.toInt()} ${product.unit} @ ₹${product.bulkDiscountPricePerUnit!.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDarkGreen,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Action Buttons Bar (Edit, Publish Toggle, Delete)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  // Edit Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      side: const BorderSide(color: AppColors.primaryGreen),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddProductScreen(
                            productToEdit: product,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: Text(
                      l10n.edit.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // QR & Timeline Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductQrScreen(product: product),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                    label: Text(
                      l10n.productTimeline.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Publish / Unpublish Toggle Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: product.isPublished
                          ? Colors.orange.shade800
                          : AppColors.primaryGreen,
                      side: BorderSide(
                        color: product.isPublished
                            ? Colors.orange.shade300
                            : AppColors.primaryGreen,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                    onPressed: () async {
                      try {
                        await ref
                            .read(productsProvider.notifier)
                            .togglePublishStatus(product);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                product.isPublished
                                    ? 'Product unpublished.'
                                    : 'Product published live!',
                              ),
                              backgroundColor: product.isPublished
                                  ? Colors.orange.shade800
                                  : AppColors.primaryGreen,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update status: $e'),
                              backgroundColor: Colors.red.shade700,
                            ),
                          );
                        }
                      }
                    },
                    icon: Icon(
                      product.isPublished
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 16,
                    ),
                    label: Text(
                      product.isPublished ? l10n.cancel.toUpperCase() : l10n.confirm.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Delete Button
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: l10n.delete,
                    onPressed: () => _confirmDelete(context, ref, product),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ProductModel product,
  ) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '${l10n.delete} ${l10n.crop}?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '${l10n.confirmLogout} (${product.name})',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel.toUpperCase()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(productsProvider.notifier)
                    .deleteProduct(product.id);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${product.name}" ${l10n.delete}.'),
                      backgroundColor: Colors.red.shade700,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.error}: $e'),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                }
              }
            },
            child: Text(
              l10n.delete.toUpperCase(),
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
