import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/india_locations.dart';
import '../../core/localization/localized_helpers.dart';
import '../../core/utils/distance_calculator.dart';
import '../../data/models/product_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../core/widgets/responsive_center.dart';
import '../../core/widgets/smart_image.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final ProductModel? productToEdit;

  const AddProductScreen({super.key, this.productToEdit});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _farmerNameController;
  late TextEditingController _mobileController;
  late TextEditingController _villageController;
  late TextEditingController _farmLocationController;
  late TextEditingController _cropNameController;
  late TextEditingController _varietyController;
  late TextEditingController _quantityController;
  late TextEditingController _stockController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _certificateController;
  late TextEditingController _certificateUrlController;
  late TextEditingController _imageUrlController;
  late TextEditingController _bulkMinQtyController;
  late TextEditingController _bulkPriceController;

  String _state = 'Tamil Nadu';
  String _district = 'Coimbatore';
  String _category = 'Vegetables';
  String _unit = 'kg';
  DateTime _harvestDate = DateTime.now();
  DateTime _expectedDeliveryDate = DateTime.now().add(const Duration(days: 2));

  bool _qualityChecked = true;
  bool _packed = true;
  bool _dispatched = false;
  bool _isOrganic = false;
  bool _isVerifiedFarmer = true;
  bool _isPublished = true;
  bool _hasPhotoUploaded = false;
  bool _isSaving = false;

  static final List<Map<String, String>> _samplePhotos = [
    {
      'name': 'Tomato',
      'url':
          'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=600',
    },
    {
      'name': 'Turmeric',
      'url':
          'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=600',
    },
    {
      'name': 'Paddy Rice',
      'url':
          'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=600',
    },
    {
      'name': 'Cotton',
      'url':
          'https://images.unsplash.com/photo-1605000797499-95a51c5269ae?w=600',
    },
    {
      'name': 'Banana',
      'url':
          'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=600',
    },
  ];

  @override
  void initState() {
    super.initState();

    final user = ref.read(currentUserProvider);
    final p = widget.productToEdit;

    _farmerNameController = TextEditingController(
      text: p?.farmerName ?? user.name.trim(),
    );

    _mobileController = TextEditingController(
      text: p?.farmerMobile.isNotEmpty == true
          ? p!.farmerMobile
          : user.phone.trim(),
    );

    _state = (p?.state.isNotEmpty == true)
        ? p!.state
        : (user.state.trim().isNotEmpty ? user.state : 'Tamil Nadu');

    final districts = IndiaLocations.getDistricts(_state);

    _district = (p?.district.isNotEmpty == true && districts.contains(p!.district))
        ? p.district
        : (user.district.trim().isNotEmpty && districts.contains(user.district)
            ? user.district
            : districts.first);

    _villageController = TextEditingController(
      text: p?.village ?? user.village.trim(),
    );

    _farmLocationController = TextEditingController(text: p?.location ?? '');
    _cropNameController = TextEditingController(text: p?.name ?? '');
    _varietyController = TextEditingController(text: p?.variety ?? '');
    _quantityController = TextEditingController(
      text: p != null ? p.quantity.toString() : '',
    );
    _stockController = TextEditingController(
      text: p != null ? p.availableStock.toString() : '',
    );
    _priceController = TextEditingController(
      text: p != null ? p.pricePerUnit.toString() : '',
    );
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _certificateController = TextEditingController(text: p?.certificateName ?? '');
    _certificateUrlController = TextEditingController(text: p?.certificateUrl ?? '');
    _imageUrlController = TextEditingController(
      text: (p?.imageUrls.isNotEmpty == true) ? p!.imageUrls.first : '',
    );
    _bulkMinQtyController = TextEditingController(
      text: p?.bulkDiscountMinQty != null ? p!.bulkDiscountMinQty.toString() : '',
    );
    _bulkPriceController = TextEditingController(
      text: p?.bulkDiscountPricePerUnit != null ? p!.bulkDiscountPricePerUnit.toString() : '',
    );

    if (p != null) {
      _category = p.category;
      _unit = p.unit;
      _harvestDate = p.harvestDate;
      _expectedDeliveryDate = p.expectedDeliveryDate;
      _qualityChecked = p.qualityChecked;
      _packed = p.packed;
      _dispatched = p.dispatched;
      _isOrganic = p.isOrganic;
      _isVerifiedFarmer = p.isVerifiedFarmer;
      _isPublished = p.isPublished;
      _hasPhotoUploaded = p.imageUrls.isNotEmpty;
    }
  }

  @override
  void dispose() {
    _farmerNameController.dispose();
    _mobileController.dispose();
    _villageController.dispose();
    _farmLocationController.dispose();
    _cropNameController.dispose();
    _varietyController.dispose();
    _quantityController.dispose();
    _stockController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _certificateController.dispose();
    _certificateUrlController.dispose();
    _imageUrlController.dispose();
    _bulkMinQtyController.dispose();
    _bulkPriceController.dispose();
    super.dispose();
  }

  void _submitCropProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider);
    final l10n = context.l10n;
    final isFarmerVerified = currentUser.verificationStatus == VerificationStatus.verified;

    if (currentUser.role == UserRole.farmer && !isFarmerVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.accountVerificationPendingDesc),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final qty = double.tryParse(_quantityController.text.trim());
    final stock = double.tryParse(_stockController.text.trim());
    final price = double.tryParse(_priceController.text.trim());

    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid positive harvest quantity (> 0).'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (stock == null || stock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid available stock (>= 0).'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid price per unit (>= 0).'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_imageUrlController.text.trim().isEmpty) {
      _imageUrlController.text =
          'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=600';
    }

    setState(() {
      _isSaving = true;
    });

    final String generatedBatchId = widget.productToEdit?.batchId ??
        '${_cropNameController.text.substring(0, _cropNameController.text.length >= 3 ? 3 : _cropNameController.text.length).toUpperCase()}-${_district.substring(0, _district.length >= 3 ? 3 : _district.length).toUpperCase()}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final coords = DistanceCalculator.getCoordinatesForDistrict(
      _district,
      _state,
    );

    final isEditing = widget.productToEdit != null;

    final productModel = ProductModel(
      id: isEditing
          ? widget.productToEdit!.id
          : 'prod_${DateTime.now().millisecondsSinceEpoch}',
      farmerId: currentUser.uid,
      farmerName: currentUser.name.trim().isNotEmpty
          ? currentUser.name.trim()
          : _farmerNameController.text.trim(),
      farmerMobile: currentUser.phone.trim().isNotEmpty
          ? currentUser.phone.trim()
          : _mobileController.text.trim(),
      state: _state,
      district: _district,
      village: _villageController.text.trim(),
      location: _farmLocationController.text.trim().isNotEmpty
          ? _farmLocationController.text.trim()
          : '$_district Farm',
      latitude: coords[0],
      longitude: coords[1],
      name: _cropNameController.text.trim(),
      category: _category,
      variety: _varietyController.text.trim(),
      quantity: qty,
      availableStock: stock,
      unit: _unit,
      pricePerUnit: price,
      harvestDate: _harvestDate,
      qualityChecked: _qualityChecked,
      packed: _packed,
      dispatched: _dispatched,
      expectedDeliveryDate: _expectedDeliveryDate,
      description: _descriptionController.text.trim(),
      imageUrls: [_imageUrlController.text.trim()],
      certificateName: _certificateController.text.trim(),
      certificateUrl: _certificateUrlController.text.trim().isNotEmpty
          ? _certificateUrlController.text.trim()
          : (widget.productToEdit?.certificateUrl ??
              'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=400'),
      isOrganic: _isOrganic,
      isVerifiedFarmer: isFarmerVerified,
      certificationStatus: isFarmerVerified
          ? VerificationStatus.verified
          : VerificationStatus.pending,
      farmingType: _isOrganic ? 'Organic' : 'Conventional',
      batchId: generatedBatchId,
      isPublished: _isPublished,
      rating: widget.productToEdit?.rating ?? 4.8,
      reviewCount: widget.productToEdit?.reviewCount ?? 1,
      bulkDiscountMinQty: double.tryParse(_bulkMinQtyController.text.trim()),
      bulkDiscountPricePerUnit: double.tryParse(_bulkPriceController.text.trim()),
    );

    try {
      if (isEditing) {
        await ref.read(productsProvider.notifier).updateProduct(productModel);
      } else {
        await ref.read(productsProvider.notifier).addProduct(productModel);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Crop "${productModel.name}" updated successfully!'
                  : 'Crop "${productModel.name}" listed successfully!',
            ),
            backgroundColor: AppColors.primaryGreen,
            duration: const Duration(seconds: 3),
          ),
        );

        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save product: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _imageUrlController.text = pickedFile.path;
          _hasPhotoUploaded = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Photo captured/selected successfully via ${source == ImageSource.camera ? 'Camera' : 'Gallery'}!',
              ),
              backgroundColor: AppColors.primaryGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access image picker: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _pickCertificate() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _certificateUrlController.text = pickedFile.path;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verified certificate selected successfully!'),
              backgroundColor: AppColors.primaryGreen,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access image picker: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final districts = IndiaLocations.getDistricts(_state);
    final l10n = context.l10n;
    final isEditing = widget.productToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? '${l10n.edit} ${l10n.crop}' : '${l10n.addProduct} (${l10n.farmer})',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: context.isDesktop ? 1350 : 800,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Builder(
                builder: (context) {
                  if (context.isDesktop) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderBanner(isEditing),
                        const SizedBox(height: 20),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle('1. ${l10n.farmerLocationInfo}'),
                                  const SizedBox(height: 12),
                                  _buildFarmerLocationFields(districts),
                                  const SizedBox(height: 24),

                                  _buildSectionTitle('2. ${l10n.cropDetailsPricing}'),
                                  const SizedBox(height: 12),
                                  _buildCropPricingFields(),
                                  const SizedBox(height: 24),

                                  _buildSectionTitle('3. ${l10n.supplyChainTraceabilityStatus}'),
                                  const SizedBox(height: 12),
                                  _buildTraceabilityFields(),
                                  const SizedBox(height: 24),

                                  _buildSectionTitle('4. ${l10n.organicCertified} & ${l10n.verifiedFarmer}'),
                                  const SizedBox(height: 12),
                                  _buildBadgesFields(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),

                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle('5. ${l10n.uploadCropPhoto}'),
                                  const SizedBox(height: 12),
                                  _buildPhotoUploadCard(),
                                  const SizedBox(height: 20),
                                  _buildLivePreviewCard(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        _buildSectionTitle('6. ${l10n.productTimeline} & ${l10n.submit}'),
                        const SizedBox(height: 12),
                        _buildDescriptionAndPublishSection(isEditing),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderBanner(isEditing),
                      const SizedBox(height: 20),

                      _buildSectionTitle('1. ${l10n.farmerLocationInfo}'),
                      const SizedBox(height: 12),
                      _buildFarmerLocationFields(districts),
                      const SizedBox(height: 24),

                      _buildSectionTitle('2. ${l10n.cropDetailsPricing}'),
                      const SizedBox(height: 12),
                      _buildCropPricingFields(),
                      const SizedBox(height: 12),
                      _buildBulkDiscountFields(),
                      const SizedBox(height: 24),

                      _buildSectionTitle('3. ${l10n.supplyChainTraceabilityStatus}'),
                      const SizedBox(height: 12),
                      _buildTraceabilityFields(),
                      const SizedBox(height: 24),

                      _buildSectionTitle('4. ${l10n.uploadCropPhoto} & ${l10n.verifiedFarmer}'),
                      const SizedBox(height: 12),
                      _buildPhotoUploadCard(),
                      const SizedBox(height: 12),
                      _buildBadgesFields(),
                      const SizedBox(height: 24),

                      _buildSectionTitle('5. ${l10n.submit}'),
                      const SizedBox(height: 12),
                      _buildDescriptionAndPublishSection(isEditing),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(bool isEditing) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mintBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.storefront,
            color: AppColors.primaryGreen,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? '${l10n.edit} ${l10n.crop}' : l10n.sellDirectlyToCustomers,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primaryGreen,
                  ),
                ),
                Text(
                  isEditing
                      ? '${l10n.edit} ${l10n.myProducts}'
                      : l10n.sellDirectlySubtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFieldWrapper({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildFarmerLocationFields(List<String> districts) {
    final l10n = context.l10n;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFormFieldWrapper(
                label: '${l10n.farmerNameLabel} (✓)',
                child: TextFormField(
                  controller: _farmerNameController,
                  readOnly: true,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person, color: AppColors.primaryGreen),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFormFieldWrapper(
                label: '${l10n.mobileNumberLabel} (✓)',
                child: TextFormField(
                  controller: _mobileController,
                  readOnly: true,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.phone, color: AppColors.primaryGreen),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildFormFieldWrapper(
                label: '${l10n.state} *',
                child: DropdownButtonFormField<String>(
                  initialValue: _state,
                  isExpanded: true,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  items: IndiaLocations.statesAndUTs
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _state = v;
                        final dList = IndiaLocations.getDistricts(v);
                        _district = dList.first;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFormFieldWrapper(
                label: '${l10n.district} *',
                child: DropdownButtonFormField<String>(
                  initialValue: districts.contains(_district)
                      ? _district
                      : districts.first,
                  isExpanded: true,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  items: districts
                      .map(
                        (d) => DropdownMenuItem(
                          value: d,
                          child: Text(d, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _district = v);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildFormFieldWrapper(
                label: l10n.village,
                child: TextFormField(
                  controller: _villageController,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. ${l10n.village}',
                    hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFormFieldWrapper(
                label: l10n.farmLocation,
                child: TextFormField(
                  controller: _farmLocationController,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. ${l10n.farmLocation}',
                    hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCropPricingFields() {
    final l10n = context.l10n;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFormFieldWrapper(
                label: '${l10n.cropName} *',
                child: TextFormField(
                  controller: _cropNameController,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. ${l10n.cropName}',
                    hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? l10n.error : null,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFormFieldWrapper(
                label: '${l10n.category} *',
                child: DropdownButtonFormField<String>(
                  initialValue: _category,
                  isExpanded: true,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  items: ['Vegetables', 'Fruits', 'Grains', 'Pulses', 'Spices', 'Organic']
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(LocalizedHelpers.getCategoryName(context, c)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildFormFieldWrapper(
                label: '${l10n.cropVariety} *',
                child: TextFormField(
                  controller: _varietyController,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. ${l10n.cropVariety}',
                    hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? l10n.error : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFormFieldWrapper(
                label: '${l10n.quantity} *',
                child: DropdownButtonFormField<String>(
                  initialValue: _unit,
                  isExpanded: true,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  items: ['kg', 'Ton', 'Quintal', 'Dozen', 'Item']
                      .map((u) => DropdownMenuItem(
                            value: u,
                            child: Text(LocalizedHelpers.getUnitName(context, u)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _unit = v!),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 550) {
              return Row(
                children: [
                  Expanded(child: _buildTotalHarvestField()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStockField()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildPriceField()),
                ],
              );
            } else {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildTotalHarvestField()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStockField()),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildPriceField(),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildBulkDiscountFields() {
    final l10n = context.l10n;
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_offer_outlined, color: AppColors.primaryGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.bulkDiscountTitle,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 6),
                        child: Text(
                          'Min Bulk Qty ($_unit)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _bulkMinQtyController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 50',
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 6),
                        child: Text(
                          'Bulk Price / Unit (₹)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _bulkPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 25',
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTraceabilityFields() {
    final l10n = context.l10n;
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.calendar_today,
            color: Colors.white,
          ),
          title: Text(
            '${l10n.harvestDate}: ${_harvestDate.toString().split(' ').first}',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: TextButton(
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _harvestDate,
                firstDate: DateTime.now().subtract(const Duration(days: 60)),
                lastDate: DateTime.now(),
              );
              if (d != null) setState(() => _harvestDate = d);
            },
            child: Text(
              l10n.change,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              ),
            ),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.local_shipping_outlined,
            color: Colors.white,
          ),
          title: Text(
            '${l10n.expectedDeliveryTime}: ${_expectedDeliveryDate.toString().split(' ').first}',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: TextButton(
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _expectedDeliveryDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 60)),
              );
              if (d != null) setState(() => _expectedDeliveryDate = d);
            },
            child: Text(
              l10n.change,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.leafGreen,
          title: Text(
            l10n.qualityChecked,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            l10n.certificateVerified,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          value: _qualityChecked,
          onChanged: (v) => setState(() => _qualityChecked = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.leafGreen,
          title: Text(
            l10n.productTimeline,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            l10n.verifiedFarmer,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          value: _packed,
          onChanged: (v) => setState(() => _packed = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.leafGreen,
          title: Text(
            l10n.pendingDeliveries,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            l10n.orders,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          value: _dispatched,
          onChanged: (v) => setState(() => _dispatched = v),
        ),
      ],
    );
  }

  Widget _buildBadgesFields() {
    final l10n = context.l10n;
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.leafGreen,
          title: Text(
            l10n.organicCropTag,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            l10n.organicCropTagSubtitle,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          value: _isOrganic,
          onChanged: (v) => setState(() => _isOrganic = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.leafGreen,
          title: Text(
            l10n.verifiedFarmerBadge,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            l10n.verifiedFarmerBadgeSubtitle,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          value: _isVerifiedFarmer,
          onChanged: (v) => setState(() => _isVerifiedFarmer = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.leafGreen,
          title: Text(
            l10n.publishInMarketplace,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            l10n.publishInMarketplaceSubtitle,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          value: _isPublished,
          onChanged: (v) => setState(() => _isPublished = v),
        ),
        const SizedBox(height: 14),
        _buildFormFieldWrapper(
          label: l10n.optionalCertificateInfo,
          child: TextFormField(
            controller: _certificateController,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'e.g. Organic India Certificate #IND-ORG-8821',
              prefixIcon: Icon(Icons.verified_user_outlined, color: AppColors.primaryGreen),
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildFormFieldWrapper(
          label: 'Upload Verified Certificate',
          child: TextFormField(
            controller: _certificateUrlController,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. Certificate URL or upload document',
              prefixIcon: const Icon(Icons.verified_outlined, color: AppColors.primaryGreen),
              suffixIcon: IconButton(
                icon: const Icon(Icons.upload_file, color: AppColors.primaryGreen),
                tooltip: 'Upload Verified Certificate',
                onPressed: _pickCertificate,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoUploadCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.add_a_photo, color: AppColors.primaryGreen, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Upload Crop Photo',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Upload real photos of your harvested crop to build trust with buyers.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: Text(
                      'Take Photo',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      side: const BorderSide(color: AppColors.primaryGreen),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: Text(
                      'Upload Photo',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_hasPhotoUploaded && _imageUrlController.text.isNotEmpty) ...[
              Text(
                'Photo Preview:',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    SmartImage(
                      pathOrUrl: _imageUrlController.text,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.85),
                        child: IconButton(
                          icon: const Icon(
                            Icons.delete_forever,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _imageUrlController.clear();
                              _hasPhotoUploaded = false;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Or Select Sample Photo:',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _samplePhotos.map((photo) {
                  final isSelected = _imageUrlController.text == photo['url'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      avatar: Icon(
                        Icons.check_circle,
                        size: 16,
                        color: isSelected ? Colors.white : AppColors.primaryGreen,
                      ),
                      label: Text(photo['name']!),
                      backgroundColor: isSelected
                          ? AppColors.primaryGreen
                          : AppColors.mintBg,
                      labelStyle: GoogleFonts.inter(
                        color: isSelected ? Colors.white : AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      onPressed: () {
                        setState(() {
                          _imageUrlController.text = photo['url']!;
                          _hasPhotoUploaded = true;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivePreviewCard() {
    final l10n = context.l10n;
    final cropName = _cropNameController.text.trim().isNotEmpty
        ? _cropNameController.text.trim()
        : l10n.crop;
    final price = _priceController.text.trim().isNotEmpty
        ? _priceController.text.trim()
        : '0';
    final farmerName = _farmerNameController.text.trim().isNotEmpty
        ? _farmerNameController.text.trim()
        : l10n.farmer;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.remove_red_eye, color: AppColors.primaryGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${l10n.marketplace} ${l10n.viewDetails}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          if (_imageUrlController.text.isNotEmpty)
            ClipRRect(
              child: SmartImage(
                pathOrUrl: _imageUrlController.text,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cropName,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      '₹$price/${LocalizedHelpers.getUnitName(context, _unit)}',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.farmer}: $farmerName • $_district, $_state',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (_isOrganic)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: AppColors.organicBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '🌱 ${l10n.organicCertified}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.organicTag,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.mintBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${l10n.availableStock}: ${_stockController.text.isNotEmpty ? _stockController.text : "0"} ${LocalizedHelpers.getUnitName(context, _unit)}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionAndPublishSection(bool isEditing) {
    final l10n = context.l10n;
    return Column(
      children: [
        _buildFormFieldWrapper(
          label: 'Crop Image URL',
          child: TextFormField(
            controller: _imageUrlController,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'https://images.unsplash.com/...',
              prefixIcon: Icon(Icons.image_outlined, color: AppColors.primaryGreen),
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 14),
        _buildFormFieldWrapper(
          label: '${l10n.crop} ${l10n.viewDetails} *',
          child: TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. Fresh organic harvest direct from farm...',
              hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? l10n.error : null,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Icon(isEditing ? Icons.save_rounded : Icons.publish_rounded, size: 22),
            label: Text(
              _isSaving
                  ? l10n.loading.toUpperCase()
                  : (isEditing
                      ? '${l10n.edit} ${l10n.marketplace}'.toUpperCase()
                      : l10n.listCropForSale.toUpperCase()),
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _isSaving ? null : _submitCropProduct,
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildTotalHarvestField() {
    final l10n = context.l10n;
    return _buildFormFieldWrapper(
      label: '${l10n.harvestQty} *',
      child: TextFormField(
        controller: _quantityController,
        keyboardType: TextInputType.number,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'e.g. 100',
          hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return l10n.error;
          final n = double.tryParse(v.trim());
          if (n == null || n <= 0) return l10n.error;
          return null;
        },
      ),
    );
  }

  Widget _buildStockField() {
    final l10n = context.l10n;
    return _buildFormFieldWrapper(
      label: '${l10n.availableStock} *',
      child: TextFormField(
        controller: _stockController,
        keyboardType: TextInputType.number,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'e.g. 50',
          hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return l10n.error;
          final n = double.tryParse(v.trim());
          if (n == null || n < 0) return l10n.error;
          return null;
        },
      ),
    );
  }

  Widget _buildPriceField() {
    final l10n = context.l10n;
    return _buildFormFieldWrapper(
      label: '${l10n.pricePerUnitLabel} (₹) *',
      child: TextFormField(
        controller: _priceController,
        keyboardType: TextInputType.number,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'e.g. 40',
          hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        onChanged: (_) => setState(() {}),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return l10n.error;
          final n = double.tryParse(v.trim());
          if (n == null || n < 0) return l10n.error;
          return null;
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontWeight: FontWeight.bold,
        fontSize: 17,
        color: Colors.white,
      ),
    );
  }
}
