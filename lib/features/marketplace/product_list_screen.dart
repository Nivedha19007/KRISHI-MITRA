import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/india_locations.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/cart_repository.dart';
import '../../data/repositories/product_repository.dart';
import 'nearby_farmers_screen.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  String _selectedCategory = 'All';
  String _selectedState = 'All';
  String _selectedDistrict = 'All';
  final _searchController = TextEditingController();

  final List<String> _categories = ['All', 'Vegetables', 'Fruits', 'Grains', 'Pulses', 'Spices'];

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);

    final filteredProducts = products.where((p) {
      if (_selectedCategory != 'All' && p.category != _selectedCategory) return false;
      if (_selectedState != 'All' && p.state != _selectedState) return false;
      if (_selectedDistrict != 'All' && p.district != _selectedDistrict) return false;
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.trim().toLowerCase();
        final matchName = p.name.toLowerCase().contains(query);
        final matchVariety = p.variety.toLowerCase().contains(query);
        final matchFarmer = p.farmerName.toLowerCase().contains(query);
        final matchDistrict = p.district.toLowerCase().contains(query);
        final matchState = p.state.toLowerCase().contains(query);
        if (!matchName && !matchVariety && !matchFarmer && !matchDistrict && !matchState) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Crop Marketplace',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter & Search Header Card
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Nearby Farmers Banner
                InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => NearbyFarmersScreen(initialCropSearch: _searchController.text)));
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.mintBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.near_me, color: AppColors.primaryGreen, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '📍 Search Farmers by Distance Radius (5, 10, 20 km)',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right, size: 18, color: AppColors.primaryGreen),
                      ],
                    ),
                  ),
                ),

                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by crop, farmer, district, state...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Category Filter
                      _buildDropdownFilter(
                        label: 'Category',
                        value: _selectedCategory,
                        items: _categories,
                        onChanged: (val) => setState(() => _selectedCategory = val!),
                      ),
                      const SizedBox(width: 8),

                      // State Filter
                      _buildDropdownFilter(
                        label: 'State',
                        value: _selectedState,
                        items: ['All', ...IndiaLocations.statesAndUTs.take(12)],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedState = val;
                              _selectedDistrict = 'All';
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),

                      // District Filter
                      if (_selectedState != 'All')
                        _buildDropdownFilter(
                          label: 'District',
                          value: _selectedDistrict,
                          items: ['All', ...IndiaLocations.getDistricts(_selectedState)],
                          onChanged: (val) => setState(() => _selectedDistrict = val!),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Marketplace Products Grid View
          Expanded(
            child: filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No crops match your filter',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.62,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return _buildMarketplaceProductCard(context, product);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.mintBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isDense: true,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text('$label: $i'))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildMarketplaceProductCard(BuildContext context, ProductModel product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 110,
                      color: AppColors.mintBg,
                      child: const Icon(Icons.eco, size: 44, color: AppColors.primaryGreen),
                    ),
                  ),
                ),
                if (product.isOrganic)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.organicBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.organicTag.withOpacity(0.5)),
                      ),
                      child: Text(
                        '🌱 Organic',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.organicTag),
                      ),
                    ),
                  ),
                if (product.isVerifiedFarmer)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.verifiedBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '✓ Verified',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.verifiedGreen),
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Crop Name & Variety
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                  ),
                  Text(
                    'Variety: ${product.variety}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                  ),
                  const SizedBox(height: 4),

                  // Farmer Name & Location (State, District, Village)
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          product.farmerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          '${product.village.isNotEmpty ? "${product.village}, " : ""}${product.district}, ${product.state}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Rating & Stock
                  Row(
                    children: [
                      const Icon(Icons.star, size: 13, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        '${product.rating}',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        'Stock: ${product.availableStock.toInt()} ${product.unit}',
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Price & Quick Add Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${product.pricePerUnit.toStringAsFixed(0)}/${product.unit}',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen),
                      ),
                      InkWell(
                        onTap: () {
                          ref.read(cartProvider.notifier).addToCart(product, 1);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added "${product.name}" to cart!'),
                              backgroundColor: AppColors.primaryGreen,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+ Add',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
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
      ),
    );
  }
}
