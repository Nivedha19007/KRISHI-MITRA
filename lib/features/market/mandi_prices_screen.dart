import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/india_locations.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/widgets/responsive_center.dart';
import '../../data/models/mandi_price_model.dart';
import '../../data/repositories/market_repository.dart';

class MandiPricesScreen extends ConsumerStatefulWidget {
  const MandiPricesScreen({super.key});

  @override
  ConsumerState<MandiPricesScreen> createState() => _MandiPricesScreenState();
}

class _MandiPricesScreenState extends ConsumerState<MandiPricesScreen> {
  final String _selectedCountry = 'India';
  String _selectedState = 'Tamil Nadu';
  String _selectedDistrict = 'Erode';
  String _selectedCommodity = 'Tomato';

  final List<String> _commonCommodities = [
    'All',
    'Tomato',
    'Potato',
    'Onion',
    'Carrot',
    'Coconut',
    'Rice',
    'Wheat',
    'Cotton',
    'Groundnut',
    'Mango',
    'Grape',
    'Chilli',
    'Turmeric',
    'Garlic',
    'Ginger',
    'Banana - Ripe',
    'Banana - Green',
    'Tapioca',
    'Apple',
    'Brinjal',
    'Cabbage',
    'Cauliflower',
    'Maize',
  ];

  @override
  Widget build(BuildContext context) {
    final stateOptions = ['All', ...IndiaLocations.statesAndUTs];
    final currentState = stateOptions.contains(_selectedState) ? _selectedState : 'All';

    final districts = currentState == 'All'
        ? <String>[]
        : IndiaLocations.getDistricts(currentState);
    final districtOptions = ['All', ...districts];
    final currentDistrict = districtOptions.contains(_selectedDistrict)
        ? _selectedDistrict
        : districtOptions.first;
    final l10n = context.l10n;

    final liveMandiAsync = ref.watch(
      liveMandiPricesProvider(
        MandiFilterQuery(
          state: currentState,
          district: currentDistrict,
          commodity: _selectedCommodity,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.mandiPrices,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Mandi Prices',
            onPressed: () {
              ref.invalidate(
                liveMandiPricesProvider(
                  MandiFilterQuery(
                    state: currentState,
                    district: currentDistrict,
                    commodity: _selectedCommodity,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 1400,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter Card (Dynamic State, District & Commodity Selectors)
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: AppColors.primaryGreen,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Official Mandi Price Search',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Country Selector (Display Only)
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCountry,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Country',
                            prefixIcon: Icon(Icons.public),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'India',
                              child: Text('🇮🇳 India'),
                            ),
                          ],
                          onChanged: (val) {},
                        ),
                        const SizedBox(height: 12),

                        // State & District Dynamic Selectors
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: currentState,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'State',
                                ),
                                items: stateOptions
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(
                                          s,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null && val != currentState) {
                                    setState(() {
                                      _selectedState = val;
                                      _selectedDistrict = 'All';
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: currentDistrict,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'District',
                                ),
                                items: districtOptions
                                    .map(
                                      (d) => DropdownMenuItem(
                                        value: d,
                                        child: Text(
                                          d,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedDistrict = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Commodity Dynamic Autocomplete & Selector
                        Autocomplete<String>(
                          initialValue: TextEditingValue(text: _selectedCommodity),
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return _commonCommodities;
                            }
                            return _commonCommodities.where((String option) {
                              return option
                                  .toLowerCase()
                                  .contains(textEditingValue.text.toLowerCase());
                            });
                          },
                          onSelected: (String selection) {
                            setState(() {
                              _selectedCommodity = selection;
                            });
                          },
                          fieldViewBuilder:
                              (context, textEditingController, focusNode, onFieldSubmitted) {
                            return TextFormField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: 'Crop / Commodity',
                                prefixIcon: Icon(Icons.eco),
                                hintText: 'Select or type crop name (e.g. Tomato, Wheat, All)',
                              ),
                              onChanged: (val) {
                                final clean = val.trim();
                                if (clean.isNotEmpty && clean != _selectedCommodity) {
                                  setState(() {
                                    _selectedCommodity = clean;
                                  });
                                }
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Active Query Pathway Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primaryGreen.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_tree_outlined,
                        size: 20,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            '$currentState  ↓  $currentDistrict  ↓  $_selectedCommodity',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Async Content Handling (Loading, Error, Empty, Success)
                liveMandiAsync.when(
                  loading: () => _buildLoadingWidget(),
                  error: (err, stack) => _buildErrorWidget(err, currentState, currentDistrict),
                  data: (prices) {
                    if (prices.isEmpty) {
                      return _buildEmptyStateWidget(currentState, currentDistrict);
                    }
                    return _buildSuccessResultsWidget(prices, currentState, currentDistrict);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primaryGreen),
              const SizedBox(height: 16),
              Text(
                'Fetching live Mandi prices from Government data.gov.in...',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(Object error, String currentState, String currentDistrict) {
    final message = error.toString().replaceAll('Exception: ', '');

    return Card(
      elevation: 2,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: Colors.redAccent,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Backend Mandi Service Error',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to fetch live Mandi records from backend server:\n$message\n\n'
              'Ensure .NET backend is running at ${AppConfig.backendBaseUrl}.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                ref.invalidate(
                  liveMandiPricesProvider(
                    MandiFilterQuery(
                      state: currentState,
                      district: currentDistrict,
                      commodity: _selectedCommodity,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Fetch'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget(String currentState, String currentDistrict) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 56,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'No Mandi Price Data Available',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No official government market arrival records were returned for:\n'
                '$currentState → $currentDistrict → $_selectedCommodity\n\n'
                'Try selecting "All" or a different state, district, or crop.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessResultsWidget(
    List<MandiPriceModel> prices,
    String currentState,
    String currentDistrict,
  ) {
    final primary = prices.first;
    final avgPrice = prices.fold<double>(
          0.0,
          (sum, item) => sum + item.currentPricePerKg,
        ) /
        prices.length;

    final dateStr = DateFormat('dd/MM/yyyy').format(primary.date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Highlight Card
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.mintBg, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primaryGreen.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedCommodity,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${prices.length} Reporting Mandi Yard${prices.length > 1 ? "s" : ""}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.verifiedBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.verifiedGreen.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified,
                          size: 16,
                          color: AppColors.verifiedGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Official AGMARKNET ($dateStr)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.verifiedGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Average Rate Across Mandis',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹${avgPrice.toStringAsFixed(1)}',
                            style: GoogleFonts.outfit(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          Text(
                            '/kg',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Equivalent Per Quintal',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '₹${(avgPrice * 100).toStringAsFixed(0)}/q',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Reporting APMC Mandi Yards List
        Text(
          'Mandi Price Reports (${prices.length})',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: prices.length,
          itemBuilder: (context, index) {
            final mandi = prices[index];
            final modalQuintal = mandi.currentPricePerKg * 100;
            final minQuintal = mandi.minPrice * 100;
            final maxQuintal = mandi.maxPrice * 100;

            final cropName = mandi.product.isNotEmpty ? mandi.product : _selectedCommodity;
            final tagText = cropName != 'All' ? '$cropName • ${mandi.variety}' : mandi.variety;

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.mintBg,
                                child: Icon(
                                  Icons.storefront,
                                  color: AppColors.primaryGreen,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      mandi.mandiName,
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${mandi.district}, ${mandi.state}',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            tagText,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Modal Price',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '₹${mandi.currentPricePerKg.toStringAsFixed(1)}/kg',
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            Text(
                              '₹${modalQuintal.toStringAsFixed(0)} / quintal',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Min - Max Range',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '₹${mandi.minPrice.toStringAsFixed(1)} - ₹${mandi.maxPrice.toStringAsFixed(1)}/kg',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '₹${minQuintal.toStringAsFixed(0)} - ₹${maxQuintal.toStringAsFixed(0)} / quintal',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
