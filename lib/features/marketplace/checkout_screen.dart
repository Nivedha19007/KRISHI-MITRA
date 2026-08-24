import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/responsive_center.dart';
import '../../data/models/order_model.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/cart_repository.dart';
import '../../data/repositories/order_repository.dart';
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
    final initialAddr = [
      if (user.village.trim().isNotEmpty) user.village.trim(),
      if (user.district.trim().isNotEmpty) user.district.trim(),
      if (user.state.trim().isNotEmpty) user.state.trim(),
    ].join(', ');

    _addressController = TextEditingController(
      text: initialAddr.isNotEmpty
          ? initialAddr
          : 'Anna Nagar, Chennai, Tamil Nadu',
    );

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

  void _placeCustomerOrder() async {
    final currentUser = ref.read(currentUserProvider);

    if (currentUser.uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to place an order.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid delivery address.'),
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
        const SnackBar(
          content: Text('No product selected for order.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_orderQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quantity must be greater than zero.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    final totalAmount = _orderQuantity * targetProduct.pricePerUnit;
    final effectiveBatchId = (targetProduct.batchId != null &&
            targetProduct.batchId!.isNotEmpty)
        ? targetProduct.batchId!
        : 'BATCH-${targetProduct.id}';

    final order = OrderModel(
      id: 'ord_${DateTime.now().millisecondsSinceEpoch}',
      customerId: currentUser.uid,
      customerName: currentUser.name.trim().isNotEmpty
          ? currentUser.name.trim()
          : 'Customer',
      farmerId: targetProduct.farmerId,
      farmerName: targetProduct.farmerName,
      productId: targetProduct.id,
      productName: targetProduct.name,
      productImage: targetProduct.imageUrls.isNotEmpty
          ? targetProduct.imageUrls.first
          : '',
      variety: targetProduct.variety,
      quantity: _orderQuantity,
      unit: targetProduct.unit,
      pricePerUnit: targetProduct.pricePerUnit,
      totalAmount: totalAmount,
      paymentStatus: _paymentMethod,
      orderStatus: 'Placed',
      deliveryAddress: _addressController.text.trim(),
      batchId: effectiveBatchId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await ref.read(orderRepositoryProvider).placeOrder(order);

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
              'Order Failed',
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
                child: const Text('OK'),
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

    ProductModel? product;
    if (widget.product != null) {
      product = widget.product;
    } else if (widget.cartItems != null && widget.cartItems!.isNotEmpty) {
      product = widget.cartItems!.first.product;
    }

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(child: Text('No item to checkout.')),
      );
    }

    final totalAmount = _orderQuantity * product.pricePerUnit;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Checkout & Confirm Order',
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
                          'Variety: ${product.variety} • Category: ${product.category}',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Farmer: ${product.farmerName} (${product.district}, ${product.state})',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Price per Unit:',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '₹${product.pricePerUnit.toStringAsFixed(0)} / ${product.unit}',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ],
                        ),
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
                              'Select Order Quantity',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Stock: ${product.availableStock} ${product.unit}',
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
                                '${_orderQuantity.toStringAsFixed(0)} ${product.unit}',
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
                                          'Maximum stock available is ${product.availableStock} ${product.unit}',
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
                          Text(
                            'Buyer: ${currentUser.name} (${currentUser.phone})',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.primaryDarkGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Address *',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _paymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                        prefixIcon: Icon(Icons.payment),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Cash on Delivery',
                          child: Text('Cash on Delivery (Pay on Receipt)'),
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount Payable:',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₹${totalAmount.toStringAsFixed(0)}',
                              style: GoogleFonts.outfit(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
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
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isPlacingOrder ? null : _placeCustomerOrder,
                        icon: _isPlacingOrder
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.shopping_bag_rounded),
                        label: Text(
                          _isPlacingOrder
                              ? 'PLACING ORDER...'
                              : 'CONFIRM & PLACE ORDER',
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
