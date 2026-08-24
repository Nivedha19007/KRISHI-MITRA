import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/responsive_center.dart';
import '../../data/models/batch_model.dart';
import '../../data/repositories/product_repository.dart';

class FarmerTimelineEditScreen extends ConsumerStatefulWidget {
  final String batchId;
  final String productName;

  const FarmerTimelineEditScreen({
    super.key,
    required this.batchId,
    required this.productName,
  });

  @override
  ConsumerState<FarmerTimelineEditScreen> createState() =>
      _FarmerTimelineEditScreenState();
}

class _FarmerTimelineEditScreenState
    extends ConsumerState<FarmerTimelineEditScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  List<_EditableMilestone> _milestones = [];
  late TextEditingController _qualityStatusController;
  late TextEditingController _certificateController;

  @override
  void initState() {
    super.initState();
    _qualityStatusController = TextEditingController();
    _certificateController = TextEditingController();
    _loadBatch();
  }

  @override
  void dispose() {
    _qualityStatusController.dispose();
    _certificateController.dispose();
    for (final m in _milestones) {
      m.dispose();
    }
    super.dispose();
  }

  Future<void> _loadBatch() async {
    try {
      final repo = ref.read(productRepositoryProvider);
      final batch = await repo.getBatchById(widget.batchId);

      if (batch != null) {
        _qualityStatusController.text = batch.qualityStatus;
        _certificateController.text = batch.certificateInfo;

        final existingMap = {
          for (final m in batch.timeline) m.stage: m
        };

        final stages = [
          TimelineStage.seeded,
          TimelineStage.cropGrowing,
          TimelineStage.harvested,
          TimelineStage.qualityVerified,
          TimelineStage.packed,
          TimelineStage.shipped,
          TimelineStage.delivered,
        ];

        _milestones = stages.map((stage) {
          final existing = existingMap[stage];
          return _EditableMilestone(
            stage: stage,
            title: existing?.title ?? stage.displayName,
            description: existing?.description ?? '',
            timestamp: existing?.timestamp,
            status: existing?.status ?? (existing?.isCompleted == true ? 'completed' : 'pending'),
            location: existing?.location ?? batch.farmLocation,
            actorName: existing?.actorName ?? batch.farmerName,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('[TIMELINE_EDIT_WARN] Error loading batch: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveTimeline() async {
    setState(() => _isSaving = true);
    try {
      final updatedList = _milestones.map((m) {
        return TimelineMilestone(
          id: m.stage.name,
          stage: m.stage,
          title: m.title,
          description: m.descriptionController.text.trim(),
          timestamp: m.isCompleted ? m.timestamp : null, // No timestamp for pending
          status: m.status,
          location: m.locationController.text.trim(),
          actorName: m.actorController.text.trim(),
        );
      }).toList();

      await ref.read(productRepositoryProvider).saveBatchTimeline(
            widget.batchId,
            updatedList,
            qualityStatus: _qualityStatusController.text.trim(),
            certificateInfo: _certificateController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Product timeline saved to Firestore! Public QR updated.'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save timeline: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Product Timeline',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 800,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.mintBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryGreen.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.timeline,
                                  color: AppColors.primaryGreen,
                                  size: 26,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Farmer Journey Editor • ${widget.productName}',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Enter exact dates and descriptions for each lifecycle stage. Unfilled stages remain pending without fabricated dates.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Batch ID: ${widget.batchId}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Quality & Certification Metadata Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quality Grade & Certification',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _qualityStatusController,
                                decoration: const InputDecoration(
                                  labelText: 'Quality Status / Grade',
                                  hintText: 'e.g. Grade A+ (Quality Verified)',
                                  prefixIcon: Icon(Icons.verified_outlined),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _certificateController,
                                decoration: const InputDecoration(
                                  labelText: 'Certification Info',
                                  hintText: 'e.g. Organic India Certificate #IND-ORG-8821',
                                  prefixIcon: Icon(Icons.card_membership_outlined),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Lifecycle Stages (${_milestones.where((m) => m.isCompleted).length} / 7 Completed)',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Milestones List
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _milestones.length,
                        itemBuilder: (context, index) {
                          final m = _milestones[index];
                          return _buildMilestoneEditorCard(m, index);
                        },
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _isSaving ? null : _saveTimeline,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(
                            _isSaving
                                ? 'SAVING TO FIRESTORE...'
                                : 'SAVE PRODUCT TIMELINE TO FIRESTORE',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildMilestoneEditorCard(_EditableMilestone m, int index) {
    final isCompleted = m.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCompleted
              ? AppColors.primaryGreen.withValues(alpha: 0.5)
              : Colors.grey.shade300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isCompleted
                      ? AppColors.primaryGreen
                      : Colors.grey.shade300,
                  child: Icon(
                    isCompleted ? Icons.check : Icons.circle_outlined,
                    size: 18,
                    color: isCompleted ? Colors.white : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${index + 1}. ${m.title}',
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isCompleted
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                ChoiceChip(
                  label: Text(m.status.toUpperCase()),
                  selected: m.isCompleted,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        m.status = 'completed';
                        m.timestamp ??= DateTime.now();
                      } else {
                        m.status = 'pending';
                        m.timestamp = null;
                      }
                    });
                  },
                  selectedColor: AppColors.primaryGreen,
                  labelStyle: TextStyle(
                    color: isCompleted ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  backgroundColor: Colors.grey.shade100,
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (isCompleted) ...[
              // Date & Time Picker Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: m.timestamp ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setState(() {
                            final current = m.timestamp ?? DateTime.now();
                            m.timestamp = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              current.hour,
                              current.minute,
                            );
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        m.timestamp != null
                            ? DateFormat('dd MMM yyyy').format(m.timestamp!)
                            : 'Select Date',
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                            m.timestamp ?? DateTime.now(),
                          ),
                        );
                        if (time != null) {
                          setState(() {
                            final current = m.timestamp ?? DateTime.now();
                            m.timestamp = DateTime(
                              current.year,
                              current.month,
                              current.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      },
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text(
                        m.timestamp != null
                            ? DateFormat('hh:mm a').format(m.timestamp!)
                            : 'Select Time',
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: m.descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Event Description',
                  hintText: 'e.g. Sown high-grade seeds in organic soil',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: m.locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g. Gobichettipalayam, Erode',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                ),
              ),
            ] else ...[
              Text(
                'Status: Pending (Awaiting farmer update — no timestamp assigned)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EditableMilestone {
  final TimelineStage stage;
  final String title;
  late TextEditingController descriptionController;
  late TextEditingController locationController;
  late TextEditingController actorController;
  DateTime? timestamp;
  String status;

  _EditableMilestone({
    required this.stage,
    required this.title,
    required String description,
    required this.timestamp,
    required this.status,
    required String location,
    required String actorName,
  }) {
    descriptionController = TextEditingController(text: description);
    locationController = TextEditingController(text: location);
    actorController = TextEditingController(text: actorName);
  }

  bool get isCompleted => status == 'completed' || status == 'current';

  void dispose() {
    descriptionController.dispose();
    locationController.dispose();
    actorController.dispose();
  }
}
