import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/responsive_center.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/order_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _farmerFilter = 'Pending';
  String _productFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _verifyFarmer(UserModel farmer, VerificationStatus newStatus) async {
    final currentAdmin = ref.read(currentUserProvider);
    try {
      await ref
          .read(authRepositoryProvider)
          .updateVerificationStatus(
            farmer.uid,
            newStatus,
            adminUid: currentAdmin.uid,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == VerificationStatus.verified
                  ? '✅ Verified Farmer ${farmer.name}'
                  : '❌ Rejected Farmer ${farmer.name}',
            ),
            backgroundColor: newStatus == VerificationStatus.verified
                ? AppColors.primaryGreen
                : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update verification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _verifyProduct(ProductModel product, VerificationStatus newStatus) async {
    try {
      await ref
          .read(productRepositoryProvider)
          .updateProductVerification(
            product.id,
            status: newStatus,
            isVerifiedFarmer: newStatus == VerificationStatus.verified,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == VerificationStatus.verified
                  ? '✅ Approved Product ${product.name}'
                  : '❌ Rejected Product ${product.name}',
            ),
            backgroundColor: newStatus == VerificationStatus.verified
                ? AppColors.primaryGreen
                : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update product approval: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    // SECURITY ROUTE PROTECTION (Requirement #9, #10, #11)
    if (currentUser.role != UserRole.admin) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Access Denied',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.gpp_maybe_rounded,
                size: 72,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Access Denied: Admin Privileges Required',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your authenticated account (${currentUser.phone}) is not authorized for Admin access.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final usersAsync = ref.watch(allUsersStreamProvider);
    final productsAsync = ref.watch(allPlatformProductsProvider);
    final ordersAsync = ref.watch(allPlatformOrdersProvider);

    final allUsers = usersAsync.value ?? [];
    final allProducts = productsAsync.value ?? [];
    final allOrders = ordersAsync.value ?? [];

    final farmers = allUsers.where((u) => u.role == UserRole.farmer).toList();
    final customers = allUsers.where((u) => u.role == UserRole.customer).toList();
    final verifiedFarmers = farmers
        .where((f) => f.verificationStatus == VerificationStatus.verified)
        .toList();
    final pendingFarmers = farmers
        .where((f) => f.verificationStatus == VerificationStatus.pending)
        .toList();
    final rejectedFarmers = farmers
        .where((f) => f.verificationStatus == VerificationStatus.rejected)
        .toList();

    final totalPlatformRevenue = allOrders.fold<double>(
      0.0,
      (sum, o) => sum + o.totalAmount,
    );

    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Government & Platform Admin Dashboard 🛡️',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Admin Logout',
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(text: 'Farmer Queue (${pendingFarmers.length})'),
            Tab(text: 'Product Approvals (${allProducts.length})'),
            Tab(text: 'Orders (${allOrders.length})'),
            Tab(text: 'Users (${allUsers.length})'),
          ],
        ),
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: isDesktop ? 1300 : 800,
          child: Column(
            children: [
              // Analytics Overview Grid Header
              Container(
                color: Colors.purple.shade50.withValues(alpha: 0.5),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildMetricTile(
                          'Total Farmers',
                          '${farmers.length}',
                          Icons.agriculture,
                          AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        _buildMetricTile(
                          'Pending Verif.',
                          '${pendingFarmers.length}',
                          Icons.pending_actions,
                          Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        _buildMetricTile(
                          'Verified Farmers',
                          '${verifiedFarmers.length}',
                          Icons.verified,
                          AppColors.verifiedGreen,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildMetricTile(
                          'Total Buyers',
                          '${customers.length}',
                          Icons.people,
                          Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        _buildMetricTile(
                          'Total Products',
                          '${allProducts.length}',
                          Icons.inventory_2,
                          Colors.purple,
                        ),
                        const SizedBox(width: 8),
                        _buildMetricTile(
                          'Platform Sales',
                          '₹${totalPlatformRevenue.toStringAsFixed(0)}',
                          Icons.payments,
                          AppColors.accentGold,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // TAB 1: FARMER VERIFICATION QUEUE
                    _buildFarmerQueueTab(
                      farmers,
                      pendingFarmers,
                      verifiedFarmers,
                      rejectedFarmers,
                    ),

                    // TAB 2: PRODUCT APPROVALS QUEUE
                    _buildProductApprovalsTab(allProducts),

                    // TAB 3: PLATFORM ORDERS MONITORING
                    _buildOrdersMonitoringTab(allOrders),

                    // TAB 4: USERS DIRECTORY
                    _buildUsersDirectoryTab(allUsers),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
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

  // TAB 1: FARMER VERIFICATION QUEUE
  Widget _buildFarmerQueueTab(
    List<UserModel> allFarmers,
    List<UserModel> pendingFarmers,
    List<UserModel> verifiedFarmers,
    List<UserModel> rejectedFarmers,
  ) {
    List<UserModel> displayList;
    if (_farmerFilter == 'Pending') {
      displayList = pendingFarmers;
    } else if (_farmerFilter == 'Verified') {
      displayList = verifiedFarmers;
    } else if (_farmerFilter == 'Rejected') {
      displayList = rejectedFarmers;
    } else {
      displayList = allFarmers;
    }

    return Column(
      children: [
        // Filter Row
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip('Pending', 'Pending (${pendingFarmers.length})', isFarmer: true),
              const SizedBox(width: 8),
              _buildFilterChip('Verified', 'Verified (${verifiedFarmers.length})', isFarmer: true),
              const SizedBox(width: 8),
              _buildFilterChip('Rejected', 'Rejected (${rejectedFarmers.length})', isFarmer: true),
              const SizedBox(width: 8),
              _buildFilterChip('All', 'All (${allFarmers.length})', isFarmer: true),
            ],
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: displayList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No farmer applications in this list.',
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
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    final farmer = displayList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
                                  farmer.name,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                _buildStatusBadge(farmer.verificationStatus),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Location: ${farmer.village.isNotEmpty ? "${farmer.village}, " : ""}${farmer.district}, ${farmer.state}',
                              style: GoogleFonts.inter(fontSize: 14),
                            ),
                            Text(
                              'Farmer Type: ${farmer.farmerType}',
                              style: GoogleFonts.inter(fontSize: 14),
                            ),
                            Text(
                              'Phone: ${farmer.phone}',
                              style: GoogleFonts.inter(fontSize: 14),
                            ),
                            Text(
                              'Firebase UID: ${farmer.uid}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (farmer.verificationStatus !=
                                    VerificationStatus.rejected)
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    onPressed: () => _verifyFarmer(
                                      farmer,
                                      VerificationStatus.rejected,
                                    ),
                                    icon: const Icon(Icons.close, size: 18),
                                    label: const Text('REJECT'),
                                  ),
                                const SizedBox(width: 12),
                                if (farmer.verificationStatus !=
                                    VerificationStatus.verified)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryGreen,
                                    ),
                                    onPressed: () => _verifyFarmer(
                                      farmer,
                                      VerificationStatus.verified,
                                    ),
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text('APPROVE & VERIFY'),
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
      ],
    );
  }

  // TAB 2: PRODUCT APPROVALS QUEUE
  Widget _buildProductApprovalsTab(List<ProductModel> products) {
    List<ProductModel> displayList = products;
    if (_productFilter == 'Approved') {
      displayList = products
          .where((p) => p.certificationStatus == VerificationStatus.verified)
          .toList();
    } else if (_productFilter == 'Pending') {
      displayList = products
          .where((p) => p.certificationStatus == VerificationStatus.pending)
          .toList();
    } else if (_productFilter == 'Rejected') {
      displayList = products
          .where((p) => p.certificationStatus == VerificationStatus.rejected)
          .toList();
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip('All', 'All (${products.length})', isFarmer: false),
              const SizedBox(width: 8),
              _buildFilterChip('Pending', 'Pending Review', isFarmer: false),
              const SizedBox(width: 8),
              _buildFilterChip('Approved', 'Approved', isFarmer: false),
              const SizedBox(width: 8),
              _buildFilterChip('Rejected', 'Rejected', isFarmer: false),
            ],
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: displayList.isEmpty
              ? Center(
                  child: Text(
                    'No products match filter.',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    final p = displayList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    p.name,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                _buildStatusBadge(p.certificationStatus),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Farmer: ${p.farmerName} • ID: ${p.farmerId}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              'Category: ${p.category} • Variety: ${p.variety} • Price: ₹${p.pricePerUnit}/${p.unit}',
                              style: GoogleFonts.inter(fontSize: 14),
                            ),
                            Text(
                              'Stock: ${p.availableStock} ${p.unit} • Farming: ${p.farmingType} • Certificate: ${p.certificateName}',
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  onPressed: () => _verifyProduct(
                                    p,
                                    VerificationStatus.rejected,
                                  ),
                                  child: const Text('Reject Product'),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryGreen,
                                  ),
                                  onPressed: () => _verifyProduct(
                                    p,
                                    VerificationStatus.verified,
                                  ),
                                  child: const Text('Approve & Publish'),
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
      ],
    );
  }

  // TAB 3: PLATFORM ORDERS MONITORING
  Widget _buildOrdersMonitoringTab(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No platform orders recorded yet.',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final o = orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row: Order ID & Total Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shopping_bag_outlined,
                            color: AppColors.primaryGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SelectableText(
                              'Order #${o.id}',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mintBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '₹${o.totalAmount.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Grid Details: Buyer, Farmer, Product, Quantity
                Wrap(
                  spacing: 16,
                  runSpacing: 10,
                  children: [
                    _buildOrderDetailItem(
                      label: 'Buyer',
                      value: o.customerName,
                      icon: Icons.person_outline,
                    ),
                    _buildOrderDetailItem(
                      label: 'Farmer',
                      value: o.farmerName,
                      icon: Icons.agriculture_outlined,
                    ),
                    _buildOrderDetailItem(
                      label: 'Product',
                      value: o.productName,
                      icon: Icons.grass,
                    ),
                    _buildOrderDetailItem(
                      label: 'Quantity',
                      value: '${o.quantity} ${o.unit}',
                      icon: Icons.scale_outlined,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Status Badges Row
                Row(
                  children: [
                    // Order Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        'Status: ${o.orderStatus}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Payment Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mintBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primaryGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'Payment: ${o.paymentStatus}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderDetailItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return SizedBox(
      width: 140,
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 4: USERS DIRECTORY
  Widget _buildUsersDirectoryTab(List<UserModel> users) {
    if (users.isEmpty) {
      return Center(
        child: Text(
          'No users registered yet.',
          style: GoogleFonts.outfit(fontSize: 16, color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final u = users[index];
        final roleColor = u.role == UserRole.admin
            ? Colors.purple
            : (u.role == UserRole.farmer
                ? AppColors.primaryGreen
                : Colors.blue);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: roleColor.withValues(alpha: 0.15),
              child: Icon(
                u.role == UserRole.farmer
                    ? Icons.agriculture
                    : (u.role == UserRole.admin
                        ? Icons.admin_panel_settings
                        : Icons.person),
                color: roleColor,
              ),
            ),
            title: Text(
              u.name,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Role: ${u.role.name.toUpperCase()} • Phone: ${u.phone}\nLocation: ${u.district}, ${u.state}',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            trailing: _buildStatusBadge(u.verificationStatus),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String value, String label, {required bool isFarmer}) {
    final isSelected = isFarmer
        ? _farmerFilter == value
        : _productFilter == value;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          if (isFarmer) {
            _farmerFilter = value;
          } else {
            _productFilter = value;
          }
        });
      },
      selectedColor: Colors.purple.shade700,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.purple.shade700,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
      backgroundColor: Colors.purple.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildStatusBadge(VerificationStatus status) {
    if (status == VerificationStatus.verified) {
      return StatusBadge.verified();
    } else if (status == VerificationStatus.rejected) {
      return StatusBadge.rejected();
    }
    return StatusBadge.pending();
  }
}
