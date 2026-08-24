import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/india_locations.dart';
import '../../core/utils/distance_calculator.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/cart_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../core/widgets/responsive_center.dart';
import 'product_detail_screen.dart';
import 'checkout_screen.dart';

class NearbyFarmersScreen extends ConsumerStatefulWidget {
  final String? initialCropSearch;

  const NearbyFarmersScreen({super.key, this.initialCropSearch});

  @override
  ConsumerState<NearbyFarmersScreen> createState() =>
      _NearbyFarmersScreenState();
}

class _NearbyFarmersScreenState extends ConsumerState<NearbyFarmersScreen> {
  late TextEditingController _cropSearchController;
  String _customerState = 'Tamil Nadu';
  String _customerDistrict = 'Erode';
  double _selectedRadiusKm = 20.0;
  String _selectedSortBy =
      'Nearest'; // Nearest, Lowest Price, Highest Quantity, Recently Harvested
  bool _isMapView = false;

  final List<double> _radiusOptions = [5.0, 10.0, 20.0, 50.0, 100.0];
  final List<String> _sortOptions = [
    'Nearest',
    'Lowest Price',
    'Highest Quantity',
    'Recently Harvested',
  ];

  @override
  void initState() {
    super.initState();
    _cropSearchController = TextEditingController(
      text: widget.initialCropSearch ?? 'Tomato',
    );
  }

  @override
  void dispose() {
    _cropSearchController.dispose();
    super.dispose();
  }

  void _showLocationPickerModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String tempState = _customerState;
        String tempDistrict = _customerDistrict;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final districts = IndiaLocations.getDistricts(tempState);
            if (!districts.contains(tempDistrict)) {
              tempDistrict = districts.first;
            }

            return Container(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📍 Set Your Delivery Location',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: tempState,
                    decoration: const InputDecoration(labelText: 'State'),
                    items: IndiaLocations.statesAndUTs
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          tempState = val;
                          tempDistrict = IndiaLocations.getDistricts(val).first;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: tempDistrict,
                    decoration: const InputDecoration(labelText: 'District'),
                    items: districts
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => tempDistrict = val);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _customerState = tempState;
                          _customerDistrict = tempDistrict;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        'CONFIRM LOCATION',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = ref.watch(productsProvider);
    final customerCoords = DistanceCalculator.getCoordinatesForDistrict(
      _customerDistrict,
      _customerState,
    );
    final custLat = customerCoords[0];
    final custLon = customerCoords[1];

    final String query = _cropSearchController.text.trim().toLowerCase();

    // 1. Identify crop match & compute distances
    final List<Map<String, dynamic>> nearbyResults = [];

    for (var product in allProducts) {
      if (query.isNotEmpty) {
        final nameMatch = product.name.toLowerCase().contains(query);
        final catMatch = product.category.toLowerCase().contains(query);
        final varMatch = product.variety.toLowerCase().contains(query);
        if (!nameMatch && !catMatch && !varMatch) continue;
      }

      final distance = DistanceCalculator.calculateDistance(
        custLat,
        custLon,
        product.latitude,
        product.longitude,
      );

      // Radius filter: include only if within selected radius
      if (distance <= _selectedRadiusKm) {
        nearbyResults.add({'product': product, 'distance': distance});
      }
    }

    // 2. Sort results based on selected criteria
    if (_selectedSortBy == 'Nearest') {
      nearbyResults.sort(
        (a, b) => (a['distance'] as double).compareTo(b['distance'] as double),
      );
    } else if (_selectedSortBy == 'Lowest Price') {
      nearbyResults.sort(
        (a, b) => (a['product'] as ProductModel).pricePerUnit.compareTo(
          (b['product'] as ProductModel).pricePerUnit,
        ),
      );
    } else if (_selectedSortBy == 'Highest Quantity') {
      nearbyResults.sort(
        (a, b) => (b['product'] as ProductModel).availableStock.compareTo(
          (a['product'] as ProductModel).availableStock,
        ),
      );
    } else if (_selectedSortBy == 'Recently Harvested') {
      nearbyResults.sort(
        (a, b) => (b['product'] as ProductModel).harvestDate.compareTo(
          (a['product'] as ProductModel).harvestDate,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nearby Farmers & Local Crops',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.list_alt : Icons.map_outlined),
            tooltip: _isMapView ? 'List View' : 'Map View',
            onPressed: () => setState(() => _isMapView = !_isMapView),
          ),
        ],
      ),
      body: ResponsiveCenter(
        maxWidth: 1200,
        child: Column(
          children: [
            // Top Control Panel
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location Selector Bar
                  InkWell(
                    onTap: _showLocationPickerModal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mintBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: AppColors.primaryGreen,
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Your Location: ',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '📍 $_customerDistrict, $_customerState',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.edit_location_alt_outlined,
                            size: 20,
                            color: AppColors.primaryGreen,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Crop Search Input
                  TextField(
                    controller: _cropSearchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search crop (e.g. Tomato, Rice, Potato)...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.primaryGreen,
                      ),
                      suffixIcon: _cropSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _cropSearchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Distance Radius Selection Chips
                  Row(
                    children: [
                      Text(
                        'Radius: ',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _radiusOptions.map((r) {
                              final isSelected = _selectedRadiusKm == r;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6.0),
                                child: ChoiceChip(
                                  label: Text('${r.toInt()} km'),
                                  selected: isSelected,
                                  selectedColor: AppColors.primaryGreen,
                                  backgroundColor: AppColors.mintBg,
                                  labelStyle: GoogleFonts.inter(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  onSelected: (_) =>
                                      setState(() => _selectedRadiusKm = r),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Sorting Row & View Mode Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Sort: ',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedSortBy,
                                isDense: true,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                items: _sortOptions
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedSortBy = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      Text(
                        '${nearbyResults.length} Farmers Found',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Main View: List or Map Mode
            Expanded(
              child: _isMapView
                  ? _buildMapView(nearbyResults, customerCoords)
                  : _buildListView(nearbyResults),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> results) {
    if (results.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        final ProductModel product = item['product'];
        final double distance = item['distance'];
        final daysAgo = DateTime.now().difference(product.harvestDate).inDays;

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Farmer Name & Distance Pill
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primaryGreen,
                      child: Text(
                        product.farmerName.isNotEmpty
                            ? product.farmerName[0]
                            : 'F',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.farmerName,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '📍 ${product.village.isNotEmpty ? "${product.village}, " : ""}${product.district}, ${product.state}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Distance Badge Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mintBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryGreen),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.near_me,
                            size: 14,
                            color: AppColors.primaryGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${distance.toStringAsFixed(1)} km away',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Crop Specs Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        product.imageUrls.isNotEmpty
                            ? product.imageUrls.first
                            : '',
                        height: 85,
                        width: 85,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 85,
                          width: 85,
                          color: AppColors.mintBg,
                          child: const Icon(
                            Icons.eco,
                            size: 36,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                product.name,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '(${product.variety})',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          Text(
                            'Available Stock: ${product.availableStock.toInt()} ${product.unit}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Harvested ${daysAgo == 0 ? "Today" : "$daysAgo days ago"}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),

                          Row(
                            children: [
                              Text(
                                '₹${product.pricePerUnit.toStringAsFixed(0)}/${product.unit}',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (product.isOrganic)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.organicBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '🌱 Organic',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.organicTag,
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
                const SizedBox(height: 10),

                // Badges Row
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (product.qualityChecked)
                      _buildMiniBadge(
                        '✓ Quality Checked',
                        AppColors.verifiedGreen,
                        AppColors.verifiedBg,
                      ),
                    if (product.isVerifiedFarmer)
                      _buildMiniBadge(
                        '✓ Verified Farmer',
                        AppColors.primaryGreen,
                        AppColors.mintBg,
                      ),
                    _buildMiniBadge(
                      'Est. Delivery: 1-2 Days',
                      Colors.blue.shade800,
                      Colors.blue.shade50,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Comparison Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryGreen,
                          side: const BorderSide(color: AppColors.primaryGreen),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailScreen(product: product),
                            ),
                          );
                        },
                        child: Text(
                          'View Product',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue.shade800,
                          side: BorderSide(color: Colors.blue.shade800),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          ref.read(cartProvider.notifier).addToCart(product, 1);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Added "${product.name}" from Farmer ${product.farmerName} to cart!',
                              ),
                              backgroundColor: AppColors.primaryGreen,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Text(
                          'Add to Cart',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckoutScreen(product: product),
                            ),
                          );
                        },
                        child: Text(
                          'Buy Now',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
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

  Widget _buildMapView(
    List<Map<String, dynamic>> results,
    List<double> customerCoords,
  ) {
    return Container(
      color: Colors.grey.shade200,
      width: double.infinity,
      child: Stack(
        children: [
          // Simulated Map Background Grid Representation
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1524661135-423995f22d0b?w=800',
                  ),
                  fit: BoxFit.cover,
                  opacity: 0.25,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Customer Pin Center
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '📍 YOU HERE ($_customerDistrict)',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Map Control Info Banner
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.map, color: AppColors.primaryGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Interactive Map View — Displaying ${results.length} farmers within ${_selectedRadiusKm.toInt()} km radius.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Farmers Pins Overlay Sheet at Bottom
          if (results.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final item = results[index];
                    final ProductModel p = item['product'];
                    final double dist = item['distance'];

                    return Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 8),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  p.farmerName,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.mintBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${dist.toStringAsFixed(1)} km',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${p.name} (${p.variety})',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Price: ₹${p.pricePerUnit.toStringAsFixed(0)}/${p.unit} • Stock: ${p.availableStock.toInt()} ${p.unit}',
                            style: GoogleFonts.inter(fontSize: 11),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            height: 34,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetailScreen(product: p),
                                  ),
                                );
                              },
                              child: Text(
                                'View Product Details',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.nature_people_outlined,
              size: 72,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No nearby farmers found for "${_cropSearchController.text}"',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No farmers with available ${_cropSearchController.text} were found within ${_selectedRadiusKm.toInt()} km of $_customerDistrict.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                setState(() {
                  if (_selectedRadiusKm < 100) {
                    _selectedRadiusKm = _selectedRadiusKm == 5
                        ? 10
                        : (_selectedRadiusKm == 10
                              ? 20
                              : (_selectedRadiusKm == 20 ? 50 : 100));
                  }
                });
              },
              icon: const Icon(Icons.zoom_out_map),
              label: Text(
                'Increase Search Radius (Try ${_selectedRadiusKm < 50 ? "${(_selectedRadiusKm * 2).toInt()} km" : "100 km"})',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
