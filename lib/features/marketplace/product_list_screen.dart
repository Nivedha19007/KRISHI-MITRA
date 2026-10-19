import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/india_locations.dart';
import '../../core/localization/localized_helpers.dart';
import '../../data/models/product_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/cart_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../core/widgets/responsive_center.dart';
import '../../core/widgets/smart_image.dart';
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

  final List<String> _categories = [
    'All',
    'Vegetables',
    'Fruits',
    'Grains',
    'Pulses',
    'Spices',
  ];

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final l10n = context.l10n;

    final filteredProducts = products.where((p) {
      if (!p.isPublished) return false;
      if (p.certificationStatus != VerificationStatus.verified) return false;
      if (_selectedCategory != 'All' && p.category != _selectedCategory) {
        return false;
      }
      if (_selectedState != 'All' && p.state != _selectedState) {
        return false;
      }
      if (_selectedDistrict != 'All' && p.district != _selectedDistrict) {
        return false;
      }
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.trim().toLowerCase();
        final matchName = p.name.toLowerCase().contains(query);
        final matchVariety = p.variety.toLowerCase().contains(query);
        final matchFarmer = p.farmerName.toLowerCase().contains(query);
        final matchDistrict = p.district.toLowerCase().contains(query);
        final matchState = p.state.toLowerCase().contains(query);
        if (!matchName &&
            !matchVariety &&
            !matchFarmer &&
            !matchDistrict &&
            !matchState) {
          return false;
        }
      }
      return true;
    }).toList();

    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 1200
        ? 4
        : (width >= 900 ? 3 : (width >= 600 ? 2 : 1));

    final gridWidth = (width > 1400 ? 1400 : width) - 24;
    final cardWidth =
        (gridWidth - (12 * (crossAxisCount - 1))) / crossAxisCount;
    final expectedHeight = (cardWidth * 9 / 16) + 210;
    final aspectRatio = cardWidth / expectedHeight;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${l10n.crop} ${l10n.marketplace}',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ResponsiveCenter(
        maxWidth: 1400,
        child: Column(
          children: [
            // Filter & Search Header Card (Frosted Half-White)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Nearby Farmers Banner
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NearbyFarmersScreen(
                            initialCropSearch: _searchController.text,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
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
                            Icons.near_me,
                            color: AppColors.primaryGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.nearbyFarmersBannerTitle,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: AppColors.primaryGreen,
                          ),
                        ],
                      ),
                    ),
                  ),

                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: l10n.searchPlaceholder,
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.primaryGreen,
                      ),
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
                          label: l10n.category,
                          value: _selectedCategory,
                          items: _categories,
                          isCategory: true,
                          onChanged: (val) =>
                              setState(() => _selectedCategory = val!),
                        ),
                        const SizedBox(width: 8),

                        // State Filter
                        _buildDropdownFilter(
                          label: l10n.state,
                          value: _selectedState,
                          items: [
                            'All',
                            ...IndiaLocations.statesAndUTs,
                          ],
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
                            label: l10n.district,
                            value: _selectedDistrict,
                            items: [
                              'All',
                              ...IndiaLocations.getDistricts(_selectedState),
                            ],
                            onChanged: (val) =>
                                setState(() => _selectedDistrict = val!),
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
                          Icon(
                            Icons.search_off,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.noDataFound,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: aspectRatio,
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
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    bool isCategory = false,
    required ValueChanged<String?> onChanged,
  }) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.mintBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isDense: true,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
          items: items
              .map((i) => DropdownMenuItem(
                    value: i,
                    child: Text(
                      '$label: ${i == 'All' ? l10n.allCommodities : (isCategory ? LocalizedHelpers.getCategoryName(context, i) : i)}',
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildMarketplaceProductCard(
    BuildContext context,
    ProductModel product,
  ) {
    final l10n = context.l10n;
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image with Badges
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: SmartImage(
                      pathOrUrl: product.imageUrls.isNotEmpty
                          ? product.imageUrls.first
                          : '',
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (product.isOrganic)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.organicBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.organicTag.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        '🌱 ${l10n.organicCertified}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.organicTag,
                        ),
                      ),
                    ),
                  ),
                if (product.isVerifiedFarmer)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.verifiedBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '✓ ${l10n.verifiedFarmer}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.verifiedGreen,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Content Details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Crop Name & Variety
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${l10n.varietyStock}: ${product.variety}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Farmer Name & Location
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          product.farmerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${product.village.isNotEmpty ? "${product.village}, " : ""}${product.district}, ${product.state}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Rating & Stock
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${product.rating}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          product.availableStock <= 0
                              ? 'OUT OF STOCK'
                              : '${l10n.availableStock}: ${product.availableStock.toInt()} ${LocalizedHelpers.getUnitName(context, product.unit)}',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: product.availableStock <= 0 ? FontWeight.bold : FontWeight.normal,
                            color: product.availableStock <= 0
                                ? Colors.red.shade700
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Price & Quick Add Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '₹${product.pricePerUnit.toStringAsFixed(0)}/${LocalizedHelpers.getUnitName(context, product.unit)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: product.availableStock <= 0
                            ? null
                            : () {
                                ref
                                    .read(cartProvider.notifier)
                                    .addToCart(product, 1);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.addedToCartSnackbar,
                                    ),
                                    backgroundColor: AppColors.primaryGreen,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: product.availableStock <= 0
                                ? Colors.grey
                                : AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.availableStock <= 0 ? 'Out of Stock' : '+ ${l10n.addToCart}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
