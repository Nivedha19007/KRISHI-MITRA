import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_model.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../core/constants/app_colors.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final ProductModel product;

  const CheckoutScreen({super.key, required this.product});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  double _orderQuantity = 5.0;
  String _paymentMethod = 'Cash / Offline on Delivery';
  final _addressController = TextEditingController(text: 'Flat 402, Green Avenue, Anna Nagar, Chennai');

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final totalAmount = _orderQuantity * widget.product.pricePerUnit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Place Order'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text('Variety: ${widget.product.variety}', style: const TextStyle(color: AppColors.primaryDarkGreen)),
                    Text('Farmer: ${widget.product.farmerName} (${widget.product.district})'),
                    const Divider(),
                    Text('Price: ₹${widget.product.pricePerUnit.toStringAsFixed(0)} / ${widget.product.unit}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Order Quantity', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            if (_orderQuantity > 1) {
                              setState(() => _orderQuantity -= 1);
                            }
                          },
                        ),
                        Text(
                          '${_orderQuantity.toStringAsFixed(0)} ${widget.product.unit}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            if (_orderQuantity < widget.product.quantity) {
                              setState(() => _orderQuantity += 1);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Delivery Address',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Mode',
                prefixIcon: Icon(Icons.payment),
              ),
              items: const [
                DropdownMenuItem(value: 'Cash / Offline on Delivery', child: Text('Cash / Offline on Delivery')),
                DropdownMenuItem(value: 'UPI / NetBanking (Mock Demo)', child: Text('UPI / NetBanking (Mock Demo)')),
                DropdownMenuItem(value: 'Direct Farmer Wallet Transfer', child: Text('Direct Farmer Wallet Transfer')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _paymentMethod = val);
              },
            ),
            const SizedBox(height: 24),
            Card(
              color: AppColors.primaryLightGreen.withOpacity(0.2),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount Payable:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      '₹${totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: () {
                final order = OrderModel(
                  id: 'ord_${DateTime.now().millisecondsSinceEpoch}',
                  customerId: currentUser.uid,
                  customerName: currentUser.name,
                  farmerId: widget.product.farmerId,
                  farmerName: widget.product.farmerName,
                  productId: widget.product.id,
                  productName: widget.product.name,
                  variety: widget.product.variety,
                  quantity: _orderQuantity,
                  unit: widget.product.unit,
                  pricePerUnit: widget.product.pricePerUnit,
                  totalAmount: totalAmount,
                  paymentStatus: 'Payment Successful ($_paymentMethod)',
                  orderStatus: 'Confirmed',
                  deliveryAddress: _addressController.text,
                  batchId: widget.product.batchId ?? 'TOM-CBE-001',
                );

                ref.read(orderRepositoryProvider).placeOrder(order);

                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('🎉 Order Confirmed!'),
                    content: Text(
                      'Your order for ${_orderQuantity.toStringAsFixed(0)} ${widget.product.unit} of ${widget.product.name} has been placed directly with Farmer ${widget.product.farmerName}.\n\nBatch ID: ${widget.product.batchId}',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: const Text('BACK TO MARKETPLACE'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('CONFIRM ORDER', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
