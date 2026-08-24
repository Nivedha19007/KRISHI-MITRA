import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';
import '../models/batch_model.dart';
import 'sample_data.dart';

class FirestoreSeeder {
  static Future<void> seedIfEmpty(FirebaseFirestore firestore) async {
    try {
      final productsSnapshot = await firestore
          .collection('products')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 4));

      if (productsSnapshot.docs.isEmpty) {
        final batch = firestore.batch();

        // 1. Seed Products (Public Marketplace Content)
        for (final product in SampleData.sampleProducts) {
          final docRef = firestore.collection('products').doc(product.id);
          batch.set(docRef, product.toMap(), SetOptions(merge: true));

          // 2. Create & Seed corresponding Batch for QR Traceability
          final cleanBatchId = AppConfig.sanitizeBatchId(
            product.batchId ?? 'BATCH-${product.id}',
          );
          final batchModel = BatchModel(
            batchId: cleanBatchId,
            productId: product.id,
            farmerId: product.farmerId,
            farmerName: product.farmerName,
            farmLocation: product.location,
            productName: product.name,
            variety: product.variety,
            quantity: product.quantity,
            qualityStatus: product.isOrganic
                ? 'Grade A+ (Organic Certified)'
                : 'Grade A (Quality Checked)',
            certificateInfo: product.certificateName.isNotEmpty
                ? product.certificateName
                : 'Verified Farm Batch #$cleanBatchId',
            currentStatus: product.dispatched ? 'Dispatched 🚚' : 'Packed 📦',
            timeline: [
              TimelineMilestone(
                stage: TimelineStage.cultivated,
                title: 'Seeded 🌱',
                description:
                    'Sown organic seeds at ${product.location} by ${product.farmerName}',
                timestamp: product.harvestDate.subtract(
                  const Duration(days: 90),
                ),
                location: product.location,
                isCompleted: true,
              ),
              TimelineMilestone(
                stage: TimelineStage.cultivated,
                title: 'Crop Growing 🌿',
                description:
                    'Monitored natural growth and organic bio-fertilizer application',
                timestamp: product.harvestDate.subtract(
                  const Duration(days: 45),
                ),
                location: product.location,
                isCompleted: true,
              ),
              TimelineMilestone(
                stage: TimelineStage.harvested,
                title: 'Harvested 🌾',
                description:
                    'Freshly harvested at peak ripeness on ${product.harvestDate.day}/${product.harvestDate.month}/${product.harvestDate.year}',
                timestamp: product.harvestDate,
                location: product.location,
                isCompleted: true,
              ),
              TimelineMilestone(
                stage: TimelineStage.qualityVerified,
                title: 'Quality Verified 🧪',
                description:
                    'Inspected and verified: ${product.certificateName.isNotEmpty ? product.certificateName : "Standard Quality Pass"}',
                timestamp: product.harvestDate.add(const Duration(hours: 4)),
                location: product.location,
                isCompleted: product.qualityChecked,
              ),
              TimelineMilestone(
                stage: TimelineStage.packed,
                title: 'Packed 📦',
                description:
                    'Safely packed in sustainable farm crates under batch ID: $cleanBatchId',
                timestamp: product.harvestDate.add(const Duration(hours: 8)),
                location: product.location,
                isCompleted: product.packed,
              ),
              TimelineMilestone(
                stage: TimelineStage.dispatched,
                title: 'Shipped 🚚',
                description:
                    'Dispatched from farm for direct delivery. Expected: ${product.expectedDeliveryDate.day}/${product.expectedDeliveryDate.month}/${product.expectedDeliveryDate.year}',
                timestamp: product.harvestDate.add(const Duration(hours: 14)),
                location: '${product.district}, ${product.state}',
                isCompleted: product.dispatched,
              ),
            ],
          );

          final batchDocRef = firestore.collection('batches').doc(cleanBatchId);
          batch.set(batchDocRef, batchModel.toMap(), SetOptions(merge: true));
        }

        await batch.commit();
        debugPrint('[SEEDER] Sample products & batches seeded to Firestore');
      }
    } catch (e) {
      debugPrint('[SEEDER_NOTICE] Optional background seeding skipped: $e');
    }
  }
}
