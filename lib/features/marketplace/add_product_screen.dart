import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/india_locations.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/utils/distance_calculator.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/product_repository.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

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
  bool _isOrganic = true;
  bool _isVerifiedFarmer = true;
  bool _hasPhotoUploaded = true;

  final List<Map<String, String>> _samplePhotos = [
    {'name': 'Country Tomato', 'url': 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=600'},
    {'name': 'Fresh Potato', 'url': 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=600'},
    {'name': 'Red Onion', 'url': 'https://images.unsplash.com/photo-1618512496248-a07fe83aa8cb?w=600'},
    {'name': 'Alphonso Mango', 'url': 'https://images.unsplash.com/photo-1553279768-865429fa0078?w=600'},
    {'name': 'Golden Wheat', 'url': 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=600'},
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _farmerNameController = TextEditingController(text: user.name.isNotEmpty ? user.name : 'Arun Kumar');
    _mobileController = TextEditingController(text: user.phone.isNotEmpty ? user.phone : '+91 98765 43210');
    _state = user.state.isNotEmpty ? user.state : 'Tamil Nadu';
    final districts = IndiaLocations.getDistricts(_state);
    _district = user.district.isNotEmpty && districts.contains(user.district) ? user.district : districts.first;
    _villageController = TextEditingController(text: user.village.isNotEmpty ? user.village : 'Pollachi North');
    _farmLocationController = TextEditingController(text: '${_villageController.text}, $_district Farm');
    _cropNameController = TextEditingController(text: 'Country Tomato');
    _varietyController = TextEditingController(text: 'Country Red');
    _quantityController = TextEditingController(text: '200');
    _stockController = TextEditingController(text: '200');
    _priceController = TextEditingController(text: '24');
    _descriptionController = TextEditingController(text: 'Freshly harvested organic country tomatoes grown naturally without synthetic pesticides.');
    _certificateController = TextEditingController(text: 'Organic India Certified #IND-ORG-8821');
    _imageUrlController = TextEditingController(text: 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=600');
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

  void _submitCropProduct() {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider);

    final String generatedBatchId =
        '${_cropNameController.text.substring(0, 3).toUpperCase()}-${_district.substring(0, 3).toUpperCase()}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final coords = DistanceCalculator.getCoordinatesForDistrict(_district, _state);

    final newProduct = ProductModel(
      id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
      farmerId: currentUser.uid,
      farmerName: _farmerNameController.text.trim(),
      farmerMobile: _mobileController.text.trim(),
      state: _state,
      district: _district,
      village: _villageController.text.trim(),
      location: _farmLocationController.text.trim(),
      latitude: coords[0],
      longitude: coords[1],
      name: _cropNameController.text.trim(),
      category: _category,
      variety: _varietyController.text.trim(),
      quantity: double.tryParse(_quantityController.text.trim()) ?? 100.0,
      availableStock: double.tryParse(_stockController.text.trim()) ?? 100.0,
      unit: _unit,
      pricePerUnit: double.tryParse(_priceController.text.trim()) ?? 24.0,
      harvestDate: _harvestDate,
      qualityChecked: _qualityChecked,
      packed: _packed,
      dispatched: _dispatched,
      expectedDeliveryDate: _expectedDeliveryDate,
      description: _descriptionController.text.trim(),
      imageUrls: [_imageUrlController.text.trim()],
      certificateName: _certificateController.text.trim(),
      certificateUrl: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=400',
      isOrganic: _isOrganic,
      isVerifiedFarmer: _isVerifiedFarmer,
      farmingType: _isOrganic ? 'Organic' : 'Conventional',
      batchId: generatedBatchId,
      isPublished: true,
      rating: 4.9,
      reviewCount: 1,
    );

    ref.read(productsProvider.notifier).addProduct(newProduct);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Crop "${newProduct.name}" listed successfully! Now live in Customer Marketplace.'),
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 3),
      ),
    );

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _simulateUploadPhoto(String sourceName, String presetUrl) {
    setState(() {
      _imageUrlController.text = presetUrl;
      _hasPhotoUploaded = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Photo uploaded via $sourceName successfully!'),
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final districts = IndiaLocations.getDistricts(_state);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${l10n.addProduct} (${l10n.farmer})',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner: Sell Directly to Customers
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.mintBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront, color: AppColors.primaryGreen, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sell Directly to Customers',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen),
                            ),
                            Text(
                              'Upon submission, your crop will automatically appear in the Customer Marketplace.',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section 1: Farmer & Location Information
                _buildSectionTitle('1. Farmer & Location Information'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _farmerNameController,
                        decoration: const InputDecoration(labelText: 'Farmer Name *', prefixIcon: Icon(Icons.person)),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _mobileController,
                        decoration: const InputDecoration(labelText: 'Mobile Number *', prefixIcon: Icon(Icons.phone)),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
                        decoration: const InputDecoration(labelText: 'State *'),
                        items: IndiaLocations.statesAndUTs.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
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
                        initialValue: districts.contains(_district) ? _district : districts.first,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'District *'),
                        items: districts.map((d) => DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis))).toList(),
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
                        decoration: const InputDecoration(labelText: 'Village *'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _farmLocationController,
                        decoration: const InputDecoration(labelText: 'Farm Location *'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Section 2: Crop Details & Pricing
                _buildSectionTitle('2. Crop Details & Pricing'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cropNameController,
                        decoration: const InputDecoration(labelText: 'Crop Name *'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _category,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Category *'),
                        items: ['Vegetables', 'Fruits', 'Grains', 'Pulses', 'Spices']
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
                        decoration: const InputDecoration(labelText: 'Crop Variety *'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _unit,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Unit *'),
                        items: ['kg', 'Ton', 'Quintal', 'Box']
                            .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: (v) => setState(() => _unit = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Responsive Pricing Fields (Total Harvest, Available Stock, Price per Kg)
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
                const SizedBox(height: 24),

                // Section 3: Supply Chain & Traceability Status
                _buildSectionTitle('3. Supply Chain & Traceability Status'),
                const SizedBox(height: 12),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today, color: AppColors.primaryGreen),
                  title: Text('Harvest Date: ${_harvestDate.toString().split(' ').first}'),
                  trailing: TextButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _harvestDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) setState(() => _harvestDate = d);
                    },
                    child: const Text('Change'),
                  ),
                ),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.local_shipping_outlined, color: AppColors.primaryGreen),
                  title: Text('Expected Delivery Time: ${_expectedDeliveryDate.toString().split(' ').first}'),
                  trailing: TextButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _expectedDeliveryDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (d != null) setState(() => _expectedDeliveryDate = d);
                    },
                    child: const Text('Change'),
                  ),
                ),

                const SizedBox(height: 10),
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

                const SizedBox(height: 24),

                // Section 4: Photo Upload & Verification Badges
                _buildSectionTitle('4. Upload Crop Photo & Verification Badges'),
                const SizedBox(height: 12),

                // Upload Photo Card
                Card(
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
                                'Upload Crop Photo *',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Upload real photos of your harvested crop to build trust with buyers.',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 14),

                        // Camera & Gallery Upload Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () => _simulateUploadPhoto('Camera 📷', _imageUrlController.text),
                                icon: const Icon(Icons.camera_alt, size: 18),
                                label: Text('Take Photo', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryGreen,
                                  side: const BorderSide(color: AppColors.primaryGreen),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () => _simulateUploadPhoto('Gallery 🖼️', _imageUrlController.text),
                                icon: const Icon(Icons.photo_library, size: 18),
                                label: Text('Upload Photo', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Photo Preview Container
                        if (_hasPhotoUploaded && _imageUrlController.text.isNotEmpty) ...[
                          Text('Photo Preview:', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Image.network(
                                  _imageUrlController.text,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 140,
                                    color: AppColors.mintBg,
                                    child: const Center(child: Icon(Icons.eco, size: 48, color: AppColors.primaryGreen)),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: CircleAvatar(
                                    backgroundColor: Colors.white.withValues(alpha: 0.85),
                                    child: IconButton(
                                      icon: const Icon(Icons.refresh, color: AppColors.primaryGreen, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _imageUrlController.text = _samplePhotos[(DateTime.now().second) % _samplePhotos.length]['url']!;
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

                        // Sample Presets row
                        Text('Or Select Crop Sample Photo:', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _samplePhotos.map((photo) {
                              final isSelected = _imageUrlController.text == photo['url'];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ActionChip(
                                  avatar: Icon(Icons.check_circle, size: 16, color: isSelected ? Colors.white : AppColors.primaryGreen),
                                  label: Text(photo['name']!),
                                  backgroundColor: isSelected ? AppColors.primaryGreen : AppColors.mintBg,
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
                ),
                const SizedBox(height: 16),

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

                const SizedBox(height: 12),
                TextFormField(
                  controller: _certificateController,
                  decoration: const InputDecoration(
                    labelText: 'Optional Certificate (e.g. Organic India #ORG-8821 / GAP)',
                    prefixIcon: Icon(Icons.verified_user_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Crop Image URL *',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Product Description & Soil Quality Notes *',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.publish_rounded, size: 22),
                    label: Text(
                      'SUBMIT & PUBLISH TO MARKETPLACE',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _submitCropProduct,
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalHarvestField() {
    return TextFormField(
      controller: _quantityController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(labelText: 'Harvest Qty *'),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildStockField() {
    return TextFormField(
      controller: _stockController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(labelText: 'Available Stock *'),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(labelText: 'Price / Unit (₹) *'),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
    );
  }
}
