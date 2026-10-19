import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/localized_helpers.dart';
import '../../data/repositories/cart_repository.dart';
import 'checkout_screen.dart';

import '../../core/widgets/responsive_center.dart';
import '../../core/widgets/smart_image.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.buyProducts,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (cartItems.isNotEmpty)
            TextButton.icon(
              icon: const Icon(
                Icons.delete_sweep,
                color: Colors.white,
                size: 20,
              ),
              label: Text(
                l10n.delete,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => cartNotifier.clearCart(),
            ),
        ],
      ),
      body: ResponsiveCenter(
        maxWidth: 900,
        child: cartItems.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noOrdersPlaced,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        final product = item.product;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SmartImage(
                                    pathOrUrl: product.imageUrls.isNotEmpty
                                        ? product.imageUrls.first
                                        : '',
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${l10n.farmer}: ${product.farmerName}',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (item.isBulkDiscountApplied) ...[
                                        Row(
                                          children: [
                                            Text(
                                              '₹${item.effectiveUnitPrice.toStringAsFixed(0)}',
                                              style: GoogleFonts.outfit(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: AppColors.primaryGreen,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '₹${product.pricePerUnit.toStringAsFixed(0)}',
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                decoration: TextDecoration.lineThrough,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '🏷️ Bulk Discount Applied (Saved ₹${item.discountAmount.toStringAsFixed(0)})',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryGreen,
                                          ),
                                        ),
                                      ] else ...[
                                        Text(
                                          '₹${product.pricePerUnit}/${LocalizedHelpers.getUnitName(context, product.unit)}',
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: AppColors.primaryGreen,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // Quantity Controls
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: AppColors.primaryGreen,
                                      ),
                                      onPressed: () =>
                                          cartNotifier.updateQuantity(
                                            product.id,
                                            item.quantity - 1,
                                          ),
                                    ),
                                    Text(
                                      '${item.quantity.toInt()}',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.add_circle_outline,
                                        color: item.quantity >= product.availableStock
                                            ? Colors.grey
                                            : AppColors.primaryGreen,
                                      ),
                                      onPressed: item.quantity >= product.availableStock
                                          ? null
                                          : () => cartNotifier.updateQuantity(
                                                product.id,
                                                item.quantity + 1,
                                              ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom Checkout Container
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, -3),
                        ),
                      ],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${l10n.totalPrice} (${cartNotifier.itemCount})',
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '₹${cartNotifier.totalCartAmount.toStringAsFixed(0)}',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              if (cartItems.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CheckoutScreen(
                                      cartItems: cartItems,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              l10n.buyProducts,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
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
}
