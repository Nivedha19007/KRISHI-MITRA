import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/localized_helpers.dart';
import '../../core/widgets/responsive_center.dart';
import '../../data/models/product_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/product_repository.dart';
import 'farmer_timeline_edit_screen.dart';
import 'product_qr_screen.dart';
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

    try {
      final repo = ref.read(productRepositoryProvider);
      final batch = await repo.getBatchById(cleanCode);

      if (!mounted) return;

      // If owner farmer, open timeline editor
      if (currentUser != null &&
          userModel.role == UserRole.farmer &&
          batch != null &&
          (batch.farmerId == currentUser.uid || batch.farmerName == userModel.name)) {
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
        // Customer or visitor scan: view public timeline
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PublicProductTimelineScreen(batchId: cleanCode),
          ),
        );
      }
    } catch (e) {
      debugPrint('[QR_SCAN_ERROR] $e');
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PublicProductTimelineScreen(batchId: cleanCode),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingScan = false);
      }
    }
  }

  void _showBatchQrModal(BuildContext context, Map<String, dynamic> b) {
    final batchId = b['id'] as String;
    final cropName = b['crop'] as String;
    final farmerName = b['farmer'] as String;
    final status = b['status'] as String;
    final ProductModel? product = b['product'] as ProductModel?;
    final traceUrl = 'https://krishi-mitra-38a5f.web.app/trace/$batchId';
    final l10n = context.l10n;
    final currentUser = FirebaseAuth.instance.currentUser;
    final userModel = ref.read(currentUserProvider);
    final isOwner = product != null &&
        currentUser != null &&
        (product.farmerId == currentUser.uid || product.farmerName == userModel.name);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.qr_code_2_rounded, color: AppColors.primaryGreen, size: 26),
                          const SizedBox(width: 8),
                          Text(
                            'Crop QR & Traceability',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Crop & Farmer Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.mintBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          cropName,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDarkGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.farmerLabel}: $farmerName • $status',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // QR Code Display
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: traceUrl,
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppColors.primaryDarkGreen,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.primaryDarkGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Batch ID Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Batch ID: $batchId',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: traceUrl));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Traceability link copied to clipboard!'),
                                backgroundColor: AppColors.primaryGreen,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primaryGreen),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons:
                  // 1. View Timeline Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PublicProductTimelineScreen(batchId: batchId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.timeline_rounded, size: 20),
                      label: Text(
                        'View Crop Timeline',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 2. Scan / Verify with Camera
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryGreen,
                        side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _searchBatch(traceUrl);
                      },
                      icon: const Icon(Icons.qr_code_scanner, size: 20),
                      label: Text(
                        'Scan & Verify Batch',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),

                  // 3. Edit Timeline (for owners/farmers)
                  if (isOwner) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryDarkGreen,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FarmerTimelineEditScreen(
                                batchId: batchId,
                                productName: cropName,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                        label: Text(
                          'Edit Timeline Stages',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (product != null) ...[
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductQrScreen(product: product),
                          ),
                        );
                      },
                      child: Text(
                        'Open Full QR Certificate Page →',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final allProducts = ref.watch(productsProvider);
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

    // Combine farmer uploaded products with sample demo batches
    final List<Map<String, dynamic>> displayedBatches = [];

    for (final p in allProducts) {
      final batchId = (p.batchId != null && p.batchId!.isNotEmpty)
          ? p.batchId!
          : 'BATCH-${p.id}';

      String status = 'Harvested 🌾';
      if (p.dispatched) {
        status = 'Dispatched 🚚';
      } else if (p.packed) {
        status = 'Packed 📦';
      } else if (p.qualityChecked) {
        status = 'Quality Checked 🧪';
      }

      String icon = '🥬';
      final n = p.name.toLowerCase();
      if (n.contains('tomato')) {
        icon = '🍅';
      } else if (n.contains('rice') || n.contains('paddy')) {
        icon = '🌾';
      } else if (n.contains('onion')) {
        icon = '🧅';
      } else if (n.contains('carrot')) {
        icon = '🥕';
      } else if (n.contains('potato')) {
        icon = '🥔';
      } else if (n.contains('banana')) {
        icon = '🍌';
      } else if (n.contains('apple')) {
        icon = '🍎';
      } else if (n.contains('cotton')) {
        icon = '🌱';
      }

      displayedBatches.add({
        'id': batchId,
        'crop': '${p.name}${p.variety.isNotEmpty ? " (${p.variety})" : ""}',
        'farmer': p.farmerName.isNotEmpty ? p.farmerName : 'Verified Farmer',
        'icon': icon,
        'status': status,
        'product': p,
      });
    }

    for (final s in sampleBatches) {
      if (!displayedBatches.any((b) => b['id'] == s['id'])) {
        displayedBatches.add(s);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.scanQrCodeTitle,
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
                        l10n.scanQrCodeTitle,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.alignCameraNotice,
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
                                ? l10n.closeScanner
                                : l10n.launchScanner,
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
                '⚡ ${l10n.batchId}',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.alignCameraNotice,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayedBatches.length,
                itemBuilder: (context, index) {
                  final b = displayedBatches[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      onTap: () => _showBatchQrModal(context, b),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.mintBg,
                        child: Text(
                          b['icon'] ?? '🌿',
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
                        '${l10n.farmerLabel}: ${b['farmer']} • ${l10n.statusLabel}: ${b['status']}',
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
                        onPressed: () => _showBatchQrModal(context, b),
                        child: Text(
                          l10n.scanBatchBtn,
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
                  const Expanded(child: Divider(color: Colors.white38)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      l10n.manualBatchHint.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Colors.white38)),
                ],
              ),
              const SizedBox(height: 18),

              // Manual Input Box
              TextField(
                controller: _batchIdController,
                style: GoogleFonts.outfit(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. TOM-ERD-101',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: const Icon(
                    Icons.numbers,
                    color: Colors.black87,
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
