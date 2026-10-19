import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/config/app_config.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/cart_repository.dart';
import '../../data/repositories/product_repository.dart';
import 'checkout_screen.dart';
import '../traceability/product_timeline_screen.dart';
import '../traceability/public_product_timeline_screen.dart';

import '../../core/localization/localized_helpers.dart';
import '../../core/widgets/responsive_center.dart';
import '../../core/widgets/smart_image.dart';

class ProductDetailScreen extends ConsumerWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final allProducts = ref.watch(productsProvider);
    final liveProduct = allProducts.firstWhere(
      (p) => p.id == product.id,
      orElse: () => product,
    );
    final batchId = liveProduct.batchId ?? 'BATCH-${liveProduct.id}';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          product.name,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ResponsiveCenter(
        maxWidth: 1000,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Large Product Image
              Stack(
                children: [
                  SmartImage(
                    pathOrUrl: product.imageUrls.isNotEmpty
                        ? product.imageUrls.first
                        : '',
                    height: 260,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),

                  // Badge overlay
                  Positioned(
                    bottom: 12,
                    left: 16,
                    child: Row(
                      children: [
                        if (product.isOrganic)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.organicBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.organicTag),
                            ),
                            child: Text(
                              '🌱 Organic Certified',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.organicTag,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (product.isVerifiedFarmer)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.verifiedBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.verifiedGreen,
                              ),
                            ),
                            child: Text(
                              '✓ Verified Farmer',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.verifiedGreen,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Rating Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: GoogleFonts.outfit(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 22,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${product.rating}',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              ' (${product.reviewCount})',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      '${l10n.variety}: ${product.variety} • ${l10n.categoryLabel}: ${LocalizedHelpers.getCategoryName(context, product.category)}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.90),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Price & Available Stock Banner
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Direct Farmer Price',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '₹${product.pricePerUnit.toStringAsFixed(0)} / ${product.unit}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Available Stock',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  product.availableStock <= 0
                                      ? 'OUT OF STOCK'
                                      : '${product.availableStock.toInt()} ${product.unit}',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: product.availableStock <= 0 ? 16 : 22,
                                    fontWeight: FontWeight.bold,
                                    color: product.availableStock <= 0
                                        ? Colors.red.shade700
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                    ),
                    if (product.bulkDiscountMinQty != null &&
                        product.bulkDiscountMinQty! > 0 &&
                        product.bulkDiscountPricePerUnit != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.mintBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primaryGreen),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_offer_rounded,
                              color: AppColors.primaryGreen,
                              size: 26,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bulk Discount Available!',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                  Text(
                                    'Buy ${product.bulkDiscountMinQty!.toInt()} ${product.unit} or more at ₹${product.bulkDiscountPricePerUnit!.toStringAsFixed(0)} / ${product.unit}',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
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
                    const SizedBox(height: 18),

                    // Farmer Information & Location Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: AppColors.primaryGreen,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Farmer: ${product.farmerName}',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 19,
                                        ),
                                      ),
                                      Text(
                                        'Phone: ${product.farmerMobile}',
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
                            const Divider(height: 20),

                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: AppColors.primaryGreen,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${l10n.locationLabel}:',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        '${product.location}, ${product.village.isNotEmpty ? "${product.village}, " : ""}${product.district}, ${product.state}',
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: AppColors.primaryGreen,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${l10n.harvestDate}: ${product.harvestDate.toString().split(' ').first}',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),


                    // Verified Certificates Badge Row
                    Text(
                      'Verified Badges & Certificates',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (product.isVerifiedFarmer)
                          _buildCertificateBadge(
                            context,
                            '✓ ${l10n.verifiedFarmer}',
                            AppColors.verifiedBg,
                            AppColors.verifiedGreen,
                          ),
                        if (product.isOrganicVerified)
                          _buildCertificateBadge(
                            context,
                            '🌱 ${l10n.organicCertified}',
                            AppColors.organicBg,
                            AppColors.organicTag,
                          ),
                        _buildCertificateBadge(
                          context,
                          '🏛️ FPO Direct Produce',
                          AppColors.fpoBg,
                          AppColors.fpoBlue,
                        ),
                        _buildCertificateBadge(
                          context,
                          '🧪 ${l10n.qualityVerified}',
                          Colors.purple.shade50,
                          Colors.purple.shade700,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // QR Code & Product Timeline Launcher (Requirement #12)
                    Card(
                      color: AppColors.mintBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () => _showLargeQrModal(context, batchId),
                              child: QrImageView(
                                data: AppConfig.getTimelineUrl(batchId),
                                version: QrVersions.auto,
                                size: 70.0,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Unique Crop QR Code',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Scan or click to view farm timeline entered by farmer',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.timeline, size: 18),
                                    label: const Text('Scan QR Timeline'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      side: const BorderSide(
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductTimelineScreen(
                                            batchId: batchId,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Crop Description (Half-white frosted container for high visibility)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.40),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            product.description,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              height: 1.5,
                              color: const Color(0xFF334155),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Bottom Bar with Buy Now & Add to Cart
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_shopping_cart, size: 20),
                label: Text(product.availableStock <= 0 ? 'Out of Stock' : 'Add to Cart'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: product.availableStock <= 0
                    ? null
                    : () {
                        ref.read(cartProvider.notifier).addToCart(product, 1);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added "${product.name}" to cart!'),
                            backgroundColor: AppColors.primaryGreen,
                          ),
                        );
                      },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: product.availableStock <= 0
                      ? Colors.grey
                      : AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: product.availableStock <= 0
                    ? null
                    : () {
                        ref.read(cartProvider.notifier).addToCart(product, 1);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckoutScreen(product: product),
                          ),
                        );
                      },
                child: Text(
                  product.availableStock <= 0 ? 'Out of Stock' : 'Buy Now',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateBadge(
    BuildContext context,
    String label,
    Color bg,
    Color text,
  ) {
    return GestureDetector(
      onTap: () => _showCertificateModal(context, label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: text.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: text,
          ),
        ),
      ),
    );
  }

  void _showCertificateModal(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified,
                size: 60,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(height: 12),
              Text(
                'Verification Certificate Info:',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.certificateName,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Issued to Farmer: ${product.farmerName}\nLocation: ${product.district}, ${product.state}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showLargeQrModal(BuildContext context, String batchId) {
    final timelineUrl = AppConfig.getTimelineUrl(batchId);

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
                        'Crop QR Code',
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
                    product.name,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  Text(
                    'Farmer: ${product.farmerName}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Batch ID: $batchId',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.accentGold,
                    ),
                  ),
                  const SizedBox(height: 14),

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
                  const SizedBox(height: 10),
                  Text(
                    '📱 Scan with phone camera to open public web timeline',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),

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
                        AppConfig.launchTimelineUrl(batchId);
                      },
                      icon: const Icon(
                        Icons.open_in_browser,
                        color: Colors.white,
                      ),
                      label: Text(
                        'View Timeline',
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
                          builder: (_) =>
                              PublicProductTimelineScreen(batchId: batchId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.timeline, size: 18),
                    label: const Text('Open App Timeline'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
