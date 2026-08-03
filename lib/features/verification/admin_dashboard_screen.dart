import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/status_badge.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  List<UserModel> _pendingFarmers = [
    UserModel(
      uid: 'pending_farmer_1',
      name: 'Ramanathan S.',
      email: 'raman.farmer@krishimitra.org',
      phone: '+91 94433 22110',
      role: UserRole.farmer,
      state: 'Tamil Nadu',
      district: 'Erode',
      village: 'Gobichettipalayam',
      farmerType: 'Turmeric & Grain Producer',
      verificationStatus: VerificationStatus.pending,
    ),
    UserModel(
      uid: 'pending_farmer_2',
      name: 'Sunita Deshmukh',
      email: 'sunita.d@krishimitra.org',
      phone: '+91 98220 11992',
      role: UserRole.farmer,
      state: 'Maharashtra',
      district: 'Pune',
      village: 'Baramati',
      farmerType: 'Organic Cotton & Sugarcane',
      verificationStatus: VerificationStatus.pending,
    ),
  ];

  void _verifyFarmer(int index, bool approve) {
    setState(() {
      final farmer = _pendingFarmers.removeAt(index);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? '✅ Approved Farmer Verification for ${farmer.name}'
                : '❌ Rejected Verification for ${farmer.name}',
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Verification Dashboard 🛡️'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Summary Banner
            Card(
              color: Colors.purple.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings, size: 40, color: Colors.purple),
                    SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Government / Admin Verification Queue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Review farmer registration details & organic certificates', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pending Farmer Verifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Chip(label: Text('${_pendingFarmers.length} Pending'), backgroundColor: AppColors.pendingAmber.withOpacity(0.2)),
              ],
            ),
            const SizedBox(height: 12),

            if (_pendingFarmers.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: Text('🎉 All pending farmer verification requests have been processed!'),
                  ),
                ),
              )
            else
              ..._pendingFarmers.asMap().entries.map((entry) {
                final idx = entry.key;
                final farmer = entry.value;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(farmer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            StatusBadge.pending(),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Location: ${farmer.village}, ${farmer.district}, ${farmer.state}'),
                        Text('Farmer Type: ${farmer.farmerType}'),
                        Text('Phone: ${farmer.phone}'),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              onPressed: () => _verifyFarmer(idx, false),
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text('Reject'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                              onPressed: () => _verifyFarmer(idx, true),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Approve & Verify'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
