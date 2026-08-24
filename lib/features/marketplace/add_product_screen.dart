import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/india_locations.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/utils/distance_calculator.dart';
import '../../data/models/product_model.dart';
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
  late TextEditingController _imageUrlController;

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
    _imageUrlController = TextEditingController(
      text: (p?.imageUrls.isNotEmpty == true) ? p!.imageUrls.first : '',
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
    _imageUrlController.dispose();
    super.dispose();
  }

  void _submitCropProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider);

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
      certificateUrl: widget.productToEdit?.certificateUrl ??
          'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=400',
      isOrganic: _isOrganic,
      isVerifiedFarmer: _isVerifiedFarmer,
      farmingType: _isOrganic ? 'Organic' : 'Conventional',
      batchId: generatedBatchId,
      isPublished: _isPublished,
      rating: widget.productToEdit?.rating ?? 4.8,
      reviewCount: widget.productToEdit?.reviewCount ?? 1,
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

  @override
  Widget build(BuildContext context) {
    final districts = IndiaLocations.getDistricts(_state);
    final l10n = context.l10n;
    final isEditing = widget.productToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Crop Product' : '${l10n.addProduct} (${l10n.farmer})',
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
                                  _buildSectionTitle('1. Farmer & Location Information'),
                                  const SizedBox(height: 12),
                                  _buildFarmerLocationFields(districts),
                                  const SizedBox(height: 24),

                                  _buildSectionTitle('2. Crop Details & Pricing'),
                                  const SizedBox(height: 12),
                                  _buildCropPricingFields(),
                                  const SizedBox(height: 24),

                                  _buildSectionTitle('3. Supply Chain & Traceability Status'),
                                  const SizedBox(height: 12),
                                  _buildTraceabilityFields(),
                                  const SizedBox(height: 24),

                                  _buildSectionTitle('4. Organic & Verification Badges'),
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
                                  _buildSectionTitle('5. Crop Photo & Marketplace Preview'),
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

                        _buildSectionTitle('6. Description & Publish Status'),
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

                      _buildSectionTitle('1. Farmer & Location Information'),
                      const SizedBox(height: 12),
                      _buildFarmerLocationFields(districts),
                      const SizedBox(height: 24),

                      _buildSectionTitle('2. Crop Details & Pricing'),
                      const SizedBox(height: 12),
                      _buildCropPricingFields(),
                      const SizedBox(height: 24),

                      _buildSectionTitle('3. Supply Chain & Traceability Status'),
                      const SizedBox(height: 12),
                      _buildTraceabilityFields(),
                      const SizedBox(height: 24),

                      _buildSectionTitle('4. Upload Crop Photo & Verification Badges'),
                      const SizedBox(height: 12),
                      _buildPhotoUploadCard(),
                      const SizedBox(height: 12),
                      _buildBadgesFields(),
                      const SizedBox(height: 24),

                      _buildSectionTitle('5. Description & Publish Status'),
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
                  isEditing ? 'Edit Crop Details' : 'Sell Directly to Customers',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primaryGreen,
                  ),
                ),
                Text(
                  isEditing
                      ? 'Update crop inventory, pricing, or publish status for your product.'
                      : 'Upon submission, your crop will automatically appear in the Customer Marketplace.',
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

  Widget _buildFarmerLocationFields(List<String> districts) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _farmerNameController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Farmer Name (Authenticated)',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _mobileController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number (Authenticated)',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _state,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'State *',
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
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: districts.contains(_district)
                    ? _district
                    : districts.first,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'District *',
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
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _villageController,
                decoration: const InputDecoration(
                  labelText: 'Village / Taluk',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _farmLocationController,
                decoration: const InputDecoration(
                  labelText: 'Farm Location',
                  hintText: 'e.g. Green Acres Farm',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCropPricingFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cropNameController,
                decoration: const InputDecoration(
                  labelText: 'Crop Name *',
                  hintText: 'e.g. Organic Tomato',
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Crop name is required' : null,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                ),
                items: ['Vegetables', 'Fruits', 'Grains', 'Pulses', 'Spices', 'Organic']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _varietyController,
                decoration: const InputDecoration(
                  labelText: 'Crop Variety *',
                  hintText: 'e.g. Country / Hybrid',
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Variety is required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _unit,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Unit *',
                ),
                items: ['kg', 'Ton', 'Quintal', 'Box']
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (v) => setState(() => _unit = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
                  const SizedBox(height: 12),
                  _buildPriceField(),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildTraceabilityFields() {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.calendar_today,
            color: AppColors.primaryGreen,
          ),
          title: Text(
            'Harvest Date: ${_harvestDate.toString().split(' ').first}',
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
            child: const Text('Change'),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.local_shipping_outlined,
            color: AppColors.primaryGreen,
          ),
          title: Text(
            'Expected Delivery Time: ${_expectedDeliveryDate.toString().split(' ').first}',
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
            child: const Text('Change'),
          ),
        ),
        const SizedBox(height: 6),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: AppColors.primaryGreen,
          title: const Text('Quality Checked Status'),
          subtitle: const Text('Certified quality inspection passed'),
          value: _qualityChecked,
          onChanged: (v) => setState(() => _qualityChecked = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: AppColors.primaryGreen,
          title: const Text('Packed Status'),
          subtitle: const Text('Crop packed in ventilated crates'),
          value: _packed,
          onChanged: (v) => setState(() => _packed = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: AppColors.primaryGreen,
          title: const Text('Dispatched Status'),
          subtitle: const Text('Loaded for transit to market hub'),
          value: _dispatched,
          onChanged: (v) => setState(() => _dispatched = v),
        ),
      ],
    );
  }

  Widget _buildBadgesFields() {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: AppColors.verifiedGreen,
          title: const Text('Organic Crop Tag'),
          subtitle: const Text('Grown 100% naturally without synthetic chemicals'),
          value: _isOrganic,
          onChanged: (v) => setState(() => _isOrganic = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: AppColors.verifiedGreen,
          title: const Text('Verified Farmer Badge'),
          subtitle: const Text('Government / FPO farmer verification active'),
          value: _isVerifiedFarmer,
          onChanged: (v) => setState(() => _isVerifiedFarmer = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: AppColors.primaryGreen,
          title: const Text('Publish in Marketplace'),
          subtitle: const Text('Visible to customers in the marketplace'),
          value: _isPublished,
          onChanged: (v) => setState(() => _isPublished = v),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _certificateController,
          decoration: const InputDecoration(
            labelText: 'Optional Certificate Info',
            hintText: 'e.g. Organic India Certificate #IND-ORG-8821',
            prefixIcon: Icon(Icons.verified_user_outlined),
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
    final cropName = _cropNameController.text.trim().isNotEmpty
        ? _cropNameController.text.trim()
        : 'Crop Name';
    final price = _priceController.text.trim().isNotEmpty
        ? _priceController.text.trim()
        : '0';
    final farmerName = _farmerNameController.text.trim().isNotEmpty
        ? _farmerNameController.text.trim()
        : 'Farmer Name';

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
                  'Live Buyer Marketplace Preview',
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
                      '₹$price/$_unit',
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
                  'Farmer: $farmerName • $_district, $_state',
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
                          '🌱 Organic',
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
                        'Stock: ${_stockController.text.isNotEmpty ? _stockController.text : "0"} $_unit',
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
    return Column(
      children: [
        TextFormField(
          controller: _imageUrlController,
          decoration: const InputDecoration(
            labelText: 'Crop Image URL',
            hintText: 'https://images.unsplash.com/...',
            prefixIcon: Icon(Icons.image_outlined),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Product Description & Soil Quality Notes *',
            hintText: 'Describe crop freshness, organic soil preparation, packaging details...',
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Description is required' : null,
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
                  ? 'SAVING PRODUCT...'
                  : (isEditing
                      ? 'UPDATE PRODUCT IN MARKETPLACE'
                      : 'SUBMIT & PUBLISH TO MARKETPLACE'),
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
    return TextFormField(
      controller: _quantityController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Harvest Qty *',
        hintText: 'e.g. 100',
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Required';
        final n = double.tryParse(v.trim());
        if (n == null || n <= 0) return 'Must be > 0';
        return null;
      },
    );
  }

  Widget _buildStockField() {
    return TextFormField(
      controller: _stockController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Available Stock *',
        hintText: 'e.g. 100',
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Required';
        final n = double.tryParse(v.trim());
        if (n == null || n < 0) return 'Must be >= 0';
        return null;
      },
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Price / Unit (₹) *',
        hintText: 'e.g. 35',
      ),
      onChanged: (_) => setState(() {}),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Required';
        final n = double.tryParse(v.trim());
        if (n == null || n < 0) return 'Must be >= 0';
        return null;
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontWeight: FontWeight.bold,
        fontSize: 17,
        color: AppColors.textPrimary,
      ),
    );
  }
}
