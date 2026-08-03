import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/product_repository.dart';
import 'product_timeline_screen.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final _batchIdController = TextEditingController(text: 'TOM-ERD-101');
  bool _isCameraActive = false;

  void _searchBatch(String batchId) {
    final cleanCode = batchId.trim().replaceAll('KRISHI_MITRA_BATCH_', '').replaceAll('KRISHIMITRA_BATCH:', '');
    final batch = ref.read(productRepositoryProvider).getBatchById(cleanCode);
    if (batch != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductTimelineScreen(batch: batch)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No traceability record found for Batch ID: $batchId')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Crop QR Scanner',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Icon(Icons.qr_code_scanner, size: 64, color: AppColors.primaryGreen),
                    const SizedBox(height: 12),
                    Text(
                      'Scan Produce QR Code',
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Scan the unique QR code on your purchased crop crate or order receipt to launch the full farm-to-doorstep timeline.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        setState(() {
                          _isCameraActive = !_isCameraActive;
                        });
                      },
                      icon: Icon(_isCameraActive ? Icons.camera_alt_outlined : Icons.camera_alt),
                      label: Text(
                        _isCameraActive ? 'Close Camera Scanner' : 'Launch Camera Scanner',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isCameraActive) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 250,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: MobileScanner(
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        final String? code = barcode.rawValue;
                        if (code != null) {
                          _searchBatch(code);
                          break;
                        }
                      }
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR ENTER BATCH ID MANUALLY',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _batchIdController,
              decoration: InputDecoration(
                labelText: 'Enter Batch ID (e.g. TOM-ERD-101)',
                prefixIcon: const Icon(Icons.numbers, color: AppColors.primaryGreen),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward, color: AppColors.primaryGreen),
                  onPressed: () => _searchBatch(_batchIdController.text),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _searchBatch(_batchIdController.text),
                child: Text('VERIFY & VIEW CROP JOURNEY', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
