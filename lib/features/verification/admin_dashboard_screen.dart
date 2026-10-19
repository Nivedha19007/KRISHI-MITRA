import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/localized_helpers.dart';
import '../../core/widgets/responsive_center.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/datasources/sample_data.dart';
import '../../data/models/delivery_model.dart';
import '../../data/models/harvest_batch_model.dart';
import '../../data/models/order_model.dart';
import '../../data/models/organic_certificate_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/quality_complaint_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../data/repositories/harvest_batch_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/organic_certificate_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/quality_complaint_repository.dart';
import '../auth/login_screen.dart';
import '../marketplace/delivery_management_screen.dart';

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
    _tabController = TabController(length: 8, vsync: this);
    _ensureAuthSession();
  }

  void _ensureAuthSession() async {
    if (fb.FirebaseAuth.instance.currentUser == null) {
      try {
        await fb.FirebaseAuth.instance.signInAnonymously();
      } catch (e) {
        debugPrint('[ADMIN_DASHBOARD_WARN] Anonymous sign-in exception: $e');
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<String?> _showRejectionReasonDialog(BuildContext context, String title) async {
    final controller = TextEditingController();
    final l10n = context.l10n;
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: l10n.rejectionReasonHint,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(l10n.confirmRejection),
            ),
          ],
        );
      },
    );
  }

  void _verifyFarmer(UserModel farmer, VerificationStatus newStatus) async {
    final currentAdmin = ref.read(currentUserProvider);
    final l10n = context.l10n;
    String? rejectionReason;
    if (newStatus == VerificationStatus.rejected) {
      rejectionReason = await _showRejectionReasonDialog(
          context, '${l10n.rejectApplication}: ${farmer.name}');
      if (rejectionReason == null) return;
    }

    try {
      await ref
          .read(authRepositoryProvider)
          .updateVerificationStatus(
            farmer.uid,
            newStatus,
            adminUid: currentAdmin.uid,
            rejectionReason: rejectionReason,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == VerificationStatus.verified
                  ? '✅ ${l10n.verifyFarmer}: ${farmer.name}'
                  : '❌ ${l10n.rejectApplication}: ${farmer.name}',
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
            content: Text('${l10n.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _verifyProduct(ProductModel product, VerificationStatus newStatus) async {
    final l10n = context.l10n;
    String? rejectionReason;
    if (newStatus == VerificationStatus.rejected) {
      rejectionReason = await _showRejectionReasonDialog(
          context, '${l10n.rejectApplication}: ${product.name}');
      if (rejectionReason == null) return;
    }

    try {
      await ref
          .read(productRepositoryProvider)
          .updateProductVerification(
            product.id,
            status: newStatus,
            isVerifiedFarmer: newStatus == VerificationStatus.verified,
            rejectionReason: rejectionReason,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == VerificationStatus.verified
                  ? '✅ ${l10n.productApprovals}: ${product.name}'
                  : '❌ ${l10n.rejectApplication}: ${product.name}',
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
            content: Text('${l10n.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final l10n = context.l10n;

    // SECURITY ROUTE PROTECTION (Requirement #9, #10, #11)
    if (currentUser.role != UserRole.admin) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.accessDenied,
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
                l10n.adminPrivilegesRequired,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${currentUser.phone} ${l10n.accessDenied}',
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
    final certsAsync = ref.watch(adminCertificatesStreamProvider);
    final batchesAsync = ref.watch(adminBatchesStreamProvider);
    final complaintsAsync = ref.watch(adminComplaintsStreamProvider);
    final deliveriesAsync = ref.watch(allDeliveriesStreamProvider);

    final allUsers = usersAsync.when(
      data: (data) => data.isNotEmpty ? data : SampleData.sampleUsers,
      error: (err, stack) => SampleData.sampleUsers,
      loading: () => SampleData.sampleUsers,
    );

    final allProducts = productsAsync.when(
      data: (data) => data.isNotEmpty ? data : SampleData.sampleProducts,
      error: (err, stack) => SampleData.sampleProducts,
      loading: () => SampleData.sampleProducts,
    );

    final allOrders = ordersAsync.when(
      data: (data) => data.isNotEmpty ? data : SampleData.sampleOrders,
      error: (err, stack) => SampleData.sampleOrders,
      loading: () => SampleData.sampleOrders,
    );

    final certs = certsAsync.when(
      data: (data) => data,
      error: (err, stack) => <OrganicCertificateModel>[],
      loading: () => <OrganicCertificateModel>[],
    );

    final batches = batchesAsync.when(
      data: (data) => data,
      error: (err, stack) => <HarvestBatchModel>[],
      loading: () => <HarvestBatchModel>[],
    );

    final complaints = complaintsAsync.when(
      data: (data) => data,
      error: (err, stack) => <QualityComplaintModel>[],
      loading: () => <QualityComplaintModel>[],
    );

    final deliveries = deliveriesAsync.when(
      data: (data) => data,
      error: (err, stack) => <DeliveryModel>[],
      loading: () => <DeliveryModel>[],
    );

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
          '${l10n.admin} Dashboard 🛡️',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.admin,
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
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelPadding: const EdgeInsets.symmetric(horizontal: 16),
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: '${l10n.farmer} (${pendingFarmers.length})'),
            Tab(text: '${l10n.organicCertificates} (${certs.length})'),
            Tab(text: '${l10n.harvestBatches} (${batches.length})'),
            Tab(text: '${l10n.qualityComplaints} (${complaints.length})'),
            Tab(text: '${l10n.pendingDeliveries} (${deliveries.length})'),
            Tab(text: '${l10n.productApprovals} (${allProducts.length})'),
            Tab(text: '${l10n.orders} (${allOrders.length})'),
            Tab(text: '${l10n.customer} (${allUsers.length})'),
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
                          l10n.farmer,
                          '${farmers.length}',
                          Icons.agriculture,
                          AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        _buildMetricTile(
                          l10n.pendingVerifications,
                          '${pendingFarmers.length}',
                          Icons.pending_actions,
                          Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        _buildMetricTile(
                          l10n.verifiedFarmer,
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
                          l10n.customer,
                          '${customers.length}',
                          Icons.shopping_bag,
                          Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        _buildMetricTile(
                          l10n.orders,
                          '${allOrders.length}',
                          Icons.receipt_long,
                          Colors.purple,
                        ),
                        const SizedBox(width: 8),
                        _buildMetricTile(
                          l10n.totalRevenue,
                          '₹${totalPlatformRevenue.toStringAsFixed(0)}',
                          Icons.account_balance_wallet,
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

                    // TAB 2: ORGANIC CERTIFICATES QUEUE
                    _buildOrganicCertsTab(certs),

                    // TAB 3: HARVEST BATCHES QUEUE
                    _buildHarvestBatchesTab(batches),

                    // TAB 4: QUALITY COMPLAINTS QUEUE
                    _buildQualityComplaintsTab(complaints),

                    // TAB 5: DELIVERIES MANAGEMENT QUEUE
                    const DeliveryManagementScreen(),

                    // TAB 6: PRODUCT APPROVALS QUEUE
                    _buildProductApprovalsTab(allProducts),

                    // TAB 7: PLATFORM ORDERS MONITORING
                    _buildOrdersMonitoringTab(allOrders),

                    // TAB 8: USERS DIRECTORY
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
    final l10n = context.l10n;
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
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip('Pending', '${l10n.pendingFilter} (${pendingFarmers.length})', isFarmer: true),
                const SizedBox(width: 8),
                _buildFilterChip('Verified', '${l10n.verifiedStatus} (${verifiedFarmers.length})', isFarmer: true),
                const SizedBox(width: 8),
                _buildFilterChip('Rejected', '${l10n.rejectedFilter} (${rejectedFarmers.length})', isFarmer: true),
                const SizedBox(width: 8),
                _buildFilterChip('All', '${l10n.allFilter} (${allFarmers.length})', isFarmer: true),
              ],
            ),
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
                              '${l10n.locationLabel}: ${farmer.village.isNotEmpty ? "${farmer.village}, " : ""}${farmer.district}, ${farmer.state}',
                              style: GoogleFonts.inter(fontSize: 14),
                            ),
                            Text(
                              '${l10n.farmerTypeLabel}: ${LocalizedHelpers.getFarmerTypeName(context, farmer.farmerType)}',
                              style: GoogleFonts.inter(fontSize: 14),
                            ),
                            Text(
                              '${l10n.phoneLabel}: ${farmer.phone}',
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
                                    label: Text(l10n.reject.toUpperCase()),
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
                                    label: Text(l10n.approveAndVerify.toUpperCase()),
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
    final l10n = context.l10n;
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
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip('All', '${l10n.allFilter} (${products.length})', isFarmer: false),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', l10n.pendingFilter, isFarmer: false),
                const SizedBox(width: 8),
                _buildFilterChip('Approved', l10n.approvedFilter, isFarmer: false),
                const SizedBox(width: 8),
                _buildFilterChip('Rejected', l10n.rejectedFilter, isFarmer: false),
              ],
            ),
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
                                if (p.certificationStatus != VerificationStatus.rejected)
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    onPressed: () => _verifyProduct(
                                      p,
                                      VerificationStatus.rejected,
                                    ),
                                    child: Text(l10n.rejectProduct),
                                  ),
                                const SizedBox(width: 12),
                                if (p.certificationStatus != VerificationStatus.verified)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryGreen,
                                    ),
                                    onPressed: () => _verifyProduct(
                                      p,
                                      VerificationStatus.verified,
                                    ),
                                    icon: const Icon(Icons.check_circle_outline, size: 18),
                                    label: Text(l10n.approveAndPublish),
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
    final l10n = context.l10n;
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
              l10n.noOrdersRecordedYet,
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
                              '${l10n.orderIdLabel} #${o.id}',
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
                      label: l10n.buyerLabel,
                      value: o.customerName,
                      icon: Icons.person_outline,
                    ),
                    _buildOrderDetailItem(
                      label: l10n.farmerLabel,
                      value: o.farmerName,
                      icon: Icons.agriculture_outlined,
                    ),
                    _buildOrderDetailItem(
                      label: l10n.productLabel,
                      value: o.productName,
                      icon: Icons.grass,
                    ),
                    _buildOrderDetailItem(
                      label: l10n.quantityLabel,
                      value: '${o.quantity} ${LocalizedHelpers.getUnitName(context, o.unit)}',
                      icon: Icons.scale_outlined,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Status Badges Row (wrapped to prevent overflow)
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
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
                        '${l10n.statusLabel}: ${o.orderStatus}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
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
                        '${l10n.paymentLabel}: ${o.paymentStatus}',
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
    final l10n = context.l10n;
    if (users.isEmpty) {
      return Center(
        child: Text(
          l10n.noUsersRegisteredYet,
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
              '${l10n.roleLabel}: ${u.role.name.toUpperCase()} • ${l10n.phoneLabel}: ${u.phone}\n${l10n.locationLabel}: ${u.district}, ${u.state}',
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

  Widget _buildOrganicCertsTab(List<OrganicCertificateModel> certs) {
    final l10n = context.l10n;
    final admin = ref.read(currentUserProvider);
    if (certs.isEmpty) {
      return Center(
        child: Text(
          'No organic certificates submitted yet.',
          style: GoogleFonts.outfit(fontSize: 16, color: AppColors.textMuted),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: certs.length,
      itemBuilder: (context, index) {
        final c = certs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      c.certificateType,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    _buildTextBadge(c.verificationStatus),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Farmer: ${c.farmerName} (ID: ${c.farmerId})', style: GoogleFonts.inter(fontSize: 14)),
                Text('Cert #: ${c.certificateNumber} • Body: ${c.certificationBody}', style: GoogleFonts.inter(fontSize: 14)),
                Text('Expiry: ${c.expiryDate.toString().split(' ').first}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (c.verificationStatus != 'rejected')
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        onPressed: () async {
                          final reason = await _showRejectionReasonDialog(context, 'Reject Certificate');
                          if (reason != null) {
                            await ref.read(organicCertificateRepositoryProvider).updateCertificateVerificationStatus(
                              certificateId: c.certificateId,
                              status: 'rejected',
                              adminId: admin.uid,
                              rejectionReason: reason,
                            );
                          }
                        },
                        child: Text(l10n.reject),
                      ),
                    const SizedBox(width: 8),
                    if (c.verificationStatus != 'approved')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                        onPressed: () async {
                          await ref.read(organicCertificateRepositoryProvider).updateCertificateVerificationStatus(
                            certificateId: c.certificateId,
                            status: 'approved',
                            adminId: admin.uid,
                          );
                        },
                        child: Text(l10n.approve),
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

  Widget _buildHarvestBatchesTab(List<HarvestBatchModel> batches) {
    final l10n = context.l10n;
    final admin = ref.read(currentUserProvider);
    if (batches.isEmpty) {
      return Center(
        child: Text(
          'No harvest batches submitted yet.',
          style: GoogleFonts.outfit(fontSize: 16, color: AppColors.textMuted),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: batches.length,
      itemBuilder: (context, index) {
        final b = batches[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${b.productName} (${b.batchId})',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    _buildTextBadge(b.verificationStatus),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Farmer: ${b.farmerName} • Grade: ${b.qualityGrade}', style: GoogleFonts.inter(fontSize: 14)),
                Text('Harvest Date: ${b.harvestDate.toString().split(' ').first} • Quantity: ${b.quantity}', style: GoogleFonts.inter(fontSize: 14)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (b.verificationStatus != 'rejected')
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        onPressed: () async {
                          final reason = await _showRejectionReasonDialog(context, 'Reject Batch');
                          if (reason != null) {
                            await ref.read(harvestBatchRepositoryProvider).updateBatchVerificationStatus(
                              batchId: b.batchId,
                              status: 'rejected',
                              adminId: admin.uid,
                              rejectionReason: reason,
                            );
                          }
                        },
                        child: Text(l10n.reject),
                      ),
                    const SizedBox(width: 8),
                    if (b.verificationStatus != 'approved')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                        onPressed: () async {
                          await ref.read(harvestBatchRepositoryProvider).updateBatchVerificationStatus(
                            batchId: b.batchId,
                            status: 'approved',
                            adminId: admin.uid,
                          );
                        },
                        child: Text(l10n.approve),
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

  Widget _buildQualityComplaintsTab(List<QualityComplaintModel> complaints) {
    if (complaints.isEmpty) {
      return Center(
        child: Text(
          'No customer quality complaints reported.',
          style: GoogleFonts.outfit(fontSize: 16, color: AppColors.textMuted),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: complaints.length,
      itemBuilder: (context, index) {
        final cmp = complaints[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Issue: ${cmp.issueType.toUpperCase()}',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red.shade700),
                    ),
                    _buildTextBadge(cmp.status),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Customer: ${cmp.customerName} • Product: ${cmp.productName}', style: GoogleFonts.inter(fontSize: 14)),
                Text('Order ID: ${cmp.orderId} • Batch ID: ${cmp.batchId}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                Text('Description: "${cmp.description}"', style: GoogleFonts.inter(fontSize: 14)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (cmp.status != 'resolved')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                        onPressed: () async {
                          await ref.read(qualityComplaintRepositoryProvider).updateComplaintStatus(
                            complaintId: cmp.complaintId,
                            status: 'resolved',
                            adminRemarks: 'Reviewed and resolved by Admin',
                          );
                        },
                        child: const Text('Mark Resolved'),
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

  Widget _buildTextBadge(String status) {
    Color color = Colors.orange;
    if (status == 'approved' || status == 'resolved' || status == 'verified') {
      color = AppColors.primaryGreen;
    } else if (status == 'rejected') {
      color = Colors.red;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
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
