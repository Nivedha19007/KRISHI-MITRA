import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/cart_repository.dart';
import 'checkout_screen.dart';
import '../traceability/product_timeline_screen.dart';

class ProductDetailScreen extends ConsumerWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchId = product.batchId ?? 'BATCH-${product.id}';

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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large Product Image
            Stack(
              children: [
                Image.network(
                  product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
                  height: 260,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 260,
                    color: AppColors.mintBg,
                    child: const Icon(Icons.eco, size: 80, color: AppColors.primaryGreen),
                  ),
                ),

                // Badge overlay
                Positioned(
                  bottom: 12,
                  left: 16,
                  child: Row(
                    children: [
                      if (product.isOrganic)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.organicBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.organicTag),
                          ),
                          child: Text(
                            '🌱 Organic Certified',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.organicTag),
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (product.isVerifiedFarmer)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.verifiedBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.verifiedGreen),
                          ),
                          child: Text(
                            '✓ Verified Farmer',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.verifiedGreen),
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
                          style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '${product.rating}',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            ' (${product.reviewCount})',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    'Variety: ${product.variety} • Category: ${product.category}',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                  ),
                  const SizedBox(height: 16),

                  // Price & Available Stock Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.mintBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Direct Farmer Price', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                            Text(
                              '₹${product.pricePerUnit.toStringAsFixed(0)} / ${product.unit}',
                              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Available Stock', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                            Text(
                              '${product.availableStock.toInt()} ${product.unit}',
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Farmer Information & Location Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: AppColors.primaryGreen,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Farmer: ${product.farmerName}',
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17),
                                    ),
                                    Text(
                                      'Phone: ${product.farmerMobile}',
                                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),

                          Row(
                            children: [
                              const Icon(Icons.location_on, color: AppColors.primaryGreen, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Farm Location:',
                                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                    Text(
                                      '${product.location}, ${product.village.isNotEmpty ? "${product.village}, " : ""}${product.district}, ${product.state}',
                                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              const Icon(Icons.calendar_today, color: AppColors.primaryGreen, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Harvest Date: ${product.harvestDate.toString().split(' ').first}',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Verified Certificates Badge Row (Requirement #15)
                  Text(
                    'Verified Badges & Certificates',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildCertificateBadge(context, '✓ Verified Farmer', AppColors.verifiedBg, AppColors.verifiedGreen),
                      _buildCertificateBadge(context, '🌱 Organic Certified', AppColors.organicBg, AppColors.organicTag),
                      _buildCertificateBadge(context, '🏛️ FPO Direct Produce', AppColors.fpoBg, AppColors.fpoBlue),
                      _buildCertificateBadge(context, '🧪 Quality Checked', Colors.purple.shade50, Colors.purple.shade700),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // QR Code & Product Timeline Launcher (Requirement #12)
                  Card(
                    color: AppColors.mintBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          QrImageView(
                            data: 'KRISHI_MITRA_BATCH_$batchId',
                            version: QrVersions.auto,
                            size: 70.0,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Unique Crop QR Code',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                                ),
                                Text(
                                  'Scan or click to view farm timeline entered by farmer',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 6),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.timeline, size: 16),
                                  label: const Text('Scan QR Timeline'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    side: const BorderSide(color: AppColors.primaryGreen),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductTimelineScreen(batchId: batchId),
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

                  // Crop Description
                  Text('Description', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 6),
                  Text(
                    product.description,
                    style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom Bar with Buy Now & Add to Cart
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -3))],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: const Text('Add to Cart'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
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
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  ref.read(cartProvider.notifier).addToCart(product, 1);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckoutScreen(product: product),
                    ),
                  );
                },
                child: Text('Buy Now', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateBadge(BuildContext context, String label, Color bg, Color text) {
    return GestureDetector(
      onTap: () => _showCertificateModal(context, label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: text.withOpacity(0.4)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: text),
        ),
      ),
    );
  }

  void _showCertificateModal(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            title,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified, size: 60, color: AppColors.primaryGreen),
              const SizedBox(height: 12),
              Text(
                'Verification Certificate Info:',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                product.certificateName,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Issued to Farmer: ${product.farmerName}\nLocation: ${product.district}, ${product.state}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
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
}
