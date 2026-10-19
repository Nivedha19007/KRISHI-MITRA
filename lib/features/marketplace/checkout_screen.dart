import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/localized_helpers.dart';
import '../../core/utils/delivery_calculator.dart';
import '../../core/widgets/responsive_center.dart';
import '../../data/models/delivery_model.dart';
import '../../data/models/order_model.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/cart_repository.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/product_repository.dart';
import 'order_success_screen.dart';


class CheckoutScreen extends ConsumerStatefulWidget {
  final ProductModel? product;
  final List<CartItem>? cartItems;

  const CheckoutScreen({
    super.key,
    this.product,
    this.cartItems,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  late double _orderQuantity;
  String _paymentMethod = 'Cash on Delivery';
  late TextEditingController _addressController;
  late TextEditingController _notesController;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();

    final user = ref.read(currentUserProvider);
    final initialAddr = user.fullAddress;

    _addressController = TextEditingController(
      text: initialAddr.isNotEmpty
          ? initialAddr
          : 'Anna Nagar, Chennai, Tamil Nadu',
    );


    _addressController.addListener(() {
      if (mounted) setState(() {});
    });

    _notesController = TextEditingController();

    if (widget.product != null) {
      _orderQuantity = 5.0;
    } else if (widget.cartItems != null && widget.cartItems!.isNotEmpty) {
      _orderQuantity = widget.cartItems!.first.quantity;
    } else {
      _orderQuantity = 1.0;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  DeliveryResult _computeDeliveryDetails(ProductModel product) {
    final pickupAddress = [
      if (product.village.isNotEmpty) product.village,
      product.district,
      product.state,
    ].join(', ');

    return DeliveryCalculator.calculateFromAddresses(
      pickupAddress: pickupAddress,
      deliveryAddress: _addressController.text,
      pickupCoords: [product.latitude, product.longitude],
    );
  }

  void _placeCustomerOrder() async {
    final currentUser = ref.read(currentUserProvider);
    final l10n = context.l10n;

    if (currentUser.uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.enterMobilePrompt),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.state),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ProductModel? targetProduct;
    if (widget.product != null) {
      targetProduct = widget.product;
    } else if (widget.cartItems != null && widget.cartItems!.isNotEmpty) {
      targetProduct = widget.cartItems!.first.product;
    }

    if (targetProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noDataFound),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_orderQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.quantity),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    double unitPrice = targetProduct.pricePerUnit;
    double discountSavings = 0.0;
    if (targetProduct.bulkDiscountMinQty != null &&
        targetProduct.bulkDiscountPricePerUnit != null &&
        targetProduct.bulkDiscountMinQty! > 0 &&
        _orderQuantity >= targetProduct.bulkDiscountMinQty!) {
      unitPrice = targetProduct.bulkDiscountPricePerUnit!;
      discountSavings = (_orderQuantity * targetProduct.pricePerUnit) - (_orderQuantity * unitPrice);
    }

    // Dynamic distance and delivery fee calculation
    final deliveryRes = _computeDeliveryDetails(targetProduct);
    final double distanceKm = deliveryRes.distanceKm;
    final double deliveryCharge = deliveryRes.deliveryCharge;
    final double productSubtotal = _orderQuantity * targetProduct.pricePerUnit;
    final double finalTotal = (productSubtotal - discountSavings) + deliveryCharge;
    final effectiveBatchId = (targetProduct.batchId != null &&
            targetProduct.batchId!.isNotEmpty)
        ? targetProduct.batchId!
        : 'BATCH-${targetProduct.id}';

    final orderId = 'ord_${DateTime.now().millisecondsSinceEpoch}';

    final pickupAddressStr = [
      if (targetProduct.village.isNotEmpty) targetProduct.village,
      targetProduct.district,
      targetProduct.state,
    ].join(', ');

    final order = OrderModel(
      id: orderId,
      customerId: currentUser.uid,
      customerName: currentUser.name.trim().isNotEmpty
          ? currentUser.name.trim()
          : 'Customer',
      customerPhone: currentUser.phone,
      farmerId: targetProduct.farmerId,
      farmerName: targetProduct.farmerName,
      farmerPhone: targetProduct.farmerMobile,
      productId: targetProduct.id,
      productName: targetProduct.name,
      productImage: targetProduct.imageUrls.isNotEmpty
          ? targetProduct.imageUrls.first
          : '',
      variety: targetProduct.variety,
      quantity: _orderQuantity,
      unit: targetProduct.unit,
      pricePerUnit: unitPrice,
      totalAmount: finalTotal,
      deliveryCharge: deliveryCharge,
      paymentStatus: _paymentMethod,
      orderStatus: 'Placed',
      deliveryAddress: _addressController.text.trim(),
      pickupAddress: pickupAddressStr,
      distanceKm: distanceKm,
      batchId: effectiveBatchId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      // 1. Store order securely in Firestore with stock deduction transaction
      await ref.read(orderRepositoryProvider).placeOrder(order);

      // 2. Create Delivery Request in Firebase for Delivery Partner tracking
      final pCoords = [targetProduct.latitude, targetProduct.longitude];
      final dCoords = DeliveryCalculator.getCoordinatesFromAddress(
        _addressController.text,
        fallbackCoords: pCoords,
      );

      final deliveryRequest = DeliveryModel(
        id: 'del_$orderId',
        orderId: orderId,
        customerId: currentUser.uid,
        customerName: currentUser.name.trim().isNotEmpty
            ? currentUser.name.trim()
            : 'Customer',
        customerPhone: currentUser.phone,
        farmerId: targetProduct.farmerId,
        farmerName: targetProduct.farmerName,
        farmerPhone: targetProduct.farmerMobile,
        pickupLocation: pickupAddressStr,
        pickupLatitude: pCoords[0],
        pickupLongitude: pCoords[1],
        deliveryAddress: _addressController.text.trim(),
        deliveryLatitude: dCoords[0],
        deliveryLongitude: dCoords[1],
        distanceKm: distanceKm,
        deliveryCharge: deliveryCharge,
        productSubtotal: productSubtotal - discountSavings,
        finalTotal: finalTotal,
        deliveryStatus: 'Placed',
        createdAt: DateTime.now(),
      );

      await ref.read(deliveryRepositoryProvider).createDeliveryRequest(deliveryRequest);

      // Deduct stock in Riverpod state immediately for live UI updates across all screens
      ref.read(productsProvider.notifier).deductStock(targetProduct.id, _orderQuantity);

      // Clear customer cart only after order succeeds
      ref.read(cartProvider.notifier).clearCart();


      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderSuccessScreen(order: order),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              l10n.error,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: GoogleFonts.inter(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final l10n = context.l10n;

    ProductModel? product;
    if (widget.product != null) {
      product = widget.product;
    } else if (widget.cartItems != null && widget.cartItems!.isNotEmpty) {
      product = widget.cartItems!.first.product;
    }

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.buyProducts)),
        body: Center(child: Text(l10n.noDataFound)),
      );
    }

    // Compute effective price respecting bulk discount
    final bool bulkApplied = product.bulkDiscountMinQty != null &&
        product.bulkDiscountPricePerUnit != null &&
        product.bulkDiscountMinQty! > 0 &&
        _orderQuantity >= product.bulkDiscountMinQty!;
    final double effectiveUnitPrice =
        bulkApplied ? product.bulkDiscountPricePerUnit! : product.pricePerUnit;
    final double productSubtotal = _orderQuantity * product.pricePerUnit;
    final double discountSavings = bulkApplied
        ? (_orderQuantity * (product.pricePerUnit - product.bulkDiscountPricePerUnit!))
        : 0.0;

    // Automatically calculated Distance & Delivery Fee using customer & farmer locations
    final deliveryRes = _computeDeliveryDetails(product);
    final double deliveryCharge = deliveryRes.deliveryCharge;
    final double finalTotal = (productSubtotal - discountSavings) + deliveryCharge;
    final bool isOutOfStock = product.availableStock <= 0;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.buyProducts,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: isDesktop ? 1100 : 700,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Builder(
              builder: (context) {
                final productCard = Card(
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
                            const Icon(
                              Icons.eco,
                              color: AppColors.primaryGreen,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                product!.name,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${l10n.varietyStock}: ${product.variety} • ${l10n.category}: ${LocalizedHelpers.getCategoryName(context, product.category)}',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${l10n.farmer}: ${product.farmerName} (${product.district}, ${product.state})',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const Divider(height: 24),
                        // Out-of-stock banner
                        if (isOutOfStock)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.inventory_2_outlined, color: Colors.red.shade700, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.outOfStock,
                                  style: GoogleFonts.inter(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.unitPrice,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (bulkApplied)
                                  Text(
                                    '₹${product.pricePerUnit.toStringAsFixed(0)} / ${LocalizedHelpers.getUnitName(context, product.unit)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.grey.shade500,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                Text(
                                  '₹${effectiveUnitPrice.toStringAsFixed(0)} / ${LocalizedHelpers.getUnitName(context, product.unit)}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: bulkApplied ? Colors.orange.shade700 : AppColors.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Bulk discount info row
                        if (product.bulkDiscountMinQty != null &&
                            product.bulkDiscountPricePerUnit != null &&
                            product.bulkDiscountMinQty! > 0) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.local_offer_outlined, color: Colors.orange.shade700, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${l10n.bulkDiscountTitle}: ${product.bulkDiscountMinQty!.toStringAsFixed(0)}+ ${LocalizedHelpers.getUnitName(context, product.unit)} @ ₹${product.bulkDiscountPricePerUnit!.toStringAsFixed(0)}/${LocalizedHelpers.getUnitName(context, product.unit)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.orange.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );

                final quantityCard = Card(
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.quantity,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${l10n.availableStock}: ${product.availableStock} ${LocalizedHelpers.getUnitName(context, product.unit)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.mintBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: AppColors.primaryGreen,
                                  size: 28,
                                ),
                                onPressed: () {
                                  if (_orderQuantity > 1) {
                                    setState(() => _orderQuantity -= 1);
                                  }
                                },
                              ),
                              Text(
                                '${_orderQuantity.toStringAsFixed(0)} ${LocalizedHelpers.getUnitName(context, product.unit)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  color: AppColors.primaryGreen,
                                  size: 28,
                                ),
                                onPressed: () {
                                  if (_orderQuantity < product!.availableStock) {
                                    setState(() => _orderQuantity += 1);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${l10n.availableStock}: ${product.availableStock} ${LocalizedHelpers.getUnitName(context, product.unit)}',
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );

                final addressAndPaymentSection = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Buyer details header
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.mintBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person,
                            color: AppColors.primaryGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${l10n.customer}: ${currentUser.name} (${currentUser.phone})',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.primaryDarkGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: '${l10n.address} *',
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _paymentMethod,
                      decoration: InputDecoration(

                        labelText: l10n.paymentMethod,
                        prefixIcon: const Icon(Icons.payment),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'UPI',
                          child: Text(l10n.paymentUpi),
                        ),
                        DropdownMenuItem(
                          value: 'Credit Card/Debit Card',
                          child: Text(l10n.paymentCard),
                        ),
                        DropdownMenuItem(
                          value: 'Cash on Delivery',
                          child: Text(l10n.paymentCod),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _paymentMethod = val);
                      },
                    ),

                    const SizedBox(height: 20),

                    Card(
                      color: AppColors.mintBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: AppColors.primaryGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    l10n.productSubtotal,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '₹${productSubtotal.toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            if (bulkApplied) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      l10n.discountSavings,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.orange.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '- ₹${discountSavings.toStringAsFixed(0)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    l10n.deliveryFeeLabelForKm(
                                      deliveryRes.distanceKm.toStringAsFixed(1),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '₹${deliveryCharge.toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ],
                            ),

                            const Divider(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${l10n.finalTotal}:',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '₹${finalTotal.toStringAsFixed(0)}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ],
                            ),

                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isOutOfStock
                              ? Colors.grey.shade400
                              : AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: (_isPlacingOrder || isOutOfStock) ? null : _placeCustomerOrder,
                        icon: _isPlacingOrder
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(isOutOfStock ? Icons.block : Icons.shopping_bag_rounded),
                        label: Text(
                          isOutOfStock
                              ? l10n.outOfStock.toUpperCase()
                              : (_isPlacingOrder
                                  ? l10n.loading.toUpperCase()
                                  : l10n.confirm.toUpperCase()),
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );

                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            productCard,
                            const SizedBox(height: 16),
                            quantityCard,
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(child: addressAndPaymentSection),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    productCard,
                    const SizedBox(height: 16),
                    quantityCard,
                    const SizedBox(height: 16),
                    addressAndPaymentSection,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
