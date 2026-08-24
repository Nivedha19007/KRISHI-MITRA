import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/responsive_center.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/product_repository.dart';
import 'farmer_timeline_edit_screen.dart';
import 'public_product_timeline_screen.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final _batchIdController = TextEditingController(text: 'TOM-ERD-101');
  bool _isCameraActive = false;
  bool _isProcessingScan = false;
  MobileScannerController? _cameraController;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _batchIdController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _searchBatch(String rawBatchId) async {
    if (_isProcessingScan) return;
    setState(() {
      _isProcessingScan = true;
    });

    final cleanCode = AppConfig.sanitizeBatchId(rawBatchId);
    if (cleanCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid QR code scanned.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isProcessingScan = false);
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final userModel = ref.read(currentUserProvider);

    // EXPERIENCE A: If an authenticated farmer scans inside the Flutter app:
    if (currentUser != null && userModel.role == UserRole.farmer) {
      try {
        final repo = ref.read(productRepositoryProvider);
        final batch = await repo.getBatchById(cleanCode);

        if (!mounted) return;

        if (batch == null) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Product Batch Not Found',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              content: Text(
                'No product batch was found matching ID: "$cleanCode".',
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
        } else if (batch.farmerId == currentUser.uid ||
            batch.farmerName == userModel.name) {
          // Ownership Verified! Open Farmer Timeline Editor inside Flutter App (NO Chrome, NO browser)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✓ Verified Owner! Opening Timeline Editor for ${batch.productName}...',
              ),
              backgroundColor: AppColors.primaryGreen,
              duration: const Duration(seconds: 1),
            ),
          );

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FarmerTimelineEditScreen(
                batchId: cleanCode,
                productName: batch.productName,
              ),
            ),
          );
        } else {
          // Ownership Check Failed: Batch belongs to another farmer
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.gpp_bad_rounded,
                    color: Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Access Denied',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
              content: Text(
                'This product belongs to another farmer (${batch.farmerName}). You do not have permission to edit this crop timeline.',
                style: GoogleFonts.inter(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('CLOSE'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        debugPrint('[QR_SCAN_ERROR] $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading batch: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessingScan = false);
        }
      }
      return;
    }

    // EXPERIENCE B: Customer or unauthenticated in-app scan: view Public Timeline
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicProductTimelineScreen(batchId: cleanCode),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _isProcessingScan = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sampleBatches = [
      {
        'id': 'TOM-ERD-101',
        'crop': 'Country Tomato (Arun)',
        'farmer': 'Arun Kumar',
        'icon': '🍅',
        'status': 'Quality Checked 🧪',
      },
      {
        'id': 'TOM-ERD-102',
        'crop': 'Country Tomato (Karthik)',
        'farmer': 'Karthik Raja',
        'icon': '🍅',
        'status': 'Packed 📦',
      },
      {
        'id': 'TOM-ERD-103',
        'crop': 'Country Tomato (Venkatesh)',
        'farmer': 'Venkatesh M.',
        'icon': '🍅',
        'status': 'Packed 📦',
      },
      {
        'id': 'RIC-CBE-004',
        'crop': 'Sona Masoori Rice',
        'farmer': 'Arun Kumar',
        'icon': '🌾',
        'status': 'Dispatched 🚚',
      },
      {
        'id': 'ONI-NSK-001',
        'crop': 'Nashik Red Onion',
        'farmer': 'Meena Patil',
        'icon': '🧅',
        'status': 'Dispatched 🚚',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Crop QR Scanner',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ResponsiveCenter(
        maxWidth: 600,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Camera Scanner Control Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.qr_code_scanner,
                        size: 64,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Scan Produce QR Code',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Farmers scanning their own produce open the In-App Timeline Editor. Customers viewing scanned QR codes see the Public Read-Only Timeline.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isCameraActive
                                ? Colors.red.shade700
                                : AppColors.primaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _isCameraActive = !_isCameraActive;
                            });
                          },
                          icon: Icon(
                            _isCameraActive
                                ? Icons.camera_alt_outlined
                                : Icons.camera_alt,
                            color: Colors.white,
                          ),
                          label: Text(
                            _isCameraActive
                                ? 'Close Camera Scanner'
                                : 'Launch Camera Scanner',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Live Mobile Camera Viewfinder
              if (_isCameraActive) ...[
                const SizedBox(height: 18),
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.primaryGreen, width: 3),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: MobileScanner(
                          controller: _cameraController,
                          onDetect: (capture) {
                            final List<Barcode> barcodes = capture.barcodes;
                            for (final barcode in barcodes) {
                              final String? code = barcode.rawValue;
                              if (code != null && code.isNotEmpty) {
                                _searchBatch(code);
                                break;
                              }
                            }
                          },
                        ),
                      ),
                      // Viewfinder Overlay Bracket Center
                      Center(
                        child: Container(
                          width: 190,
                          height: 190,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Container(
                                  height: 2,
                                  color: AppColors.accentGold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Camera Controls Row
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.flash_on,
                                color: Colors.white,
                              ),
                              onPressed: () => _cameraController?.toggleTorch(),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.cameraswitch,
                                color: Colors.white,
                              ),
                              onPressed: () =>
                                  _cameraController?.switchCamera(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Quick Scan Demo Batches Section
              Text(
                '⚡ Tap Batch ID to Scan In-App',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap any crop batch below to simulate scanning a physical QR code:',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sampleBatches.length,
                itemBuilder: (context, index) {
                  final b = sampleBatches[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.mintBg,
                        child: Text(
                          b['icon']!,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      title: Text(
                        '${b['crop']} (${b['id']})',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Farmer: ${b['farmer']} • Status: ${b['status']}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _searchBatch(
                          'https://krishi-mitra-38a5f.web.app/trace/${b['id']}',
                        ),
                        child: Text(
                          'Scan Batch',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR ENTER BATCH ID MANUALLY',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 18),

              // Manual Input Box
              TextField(
                controller: _batchIdController,
                decoration: InputDecoration(
                  labelText: 'Enter Batch ID (e.g. TOM-ERD-101)',
                  prefixIcon: const Icon(
                    Icons.numbers,
                    color: AppColors.primaryGreen,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.arrow_forward,
                      color: AppColors.primaryGreen,
                    ),
                    onPressed: () => _searchBatch(_batchIdController.text),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
