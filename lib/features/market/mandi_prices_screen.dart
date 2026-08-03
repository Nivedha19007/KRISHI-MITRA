import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/india_locations.dart';
import '../../core/localization/locale_provider.dart';
import '../../data/repositories/market_repository.dart';

class MandiPricesScreen extends ConsumerStatefulWidget {
  const MandiPricesScreen({super.key});

  @override
  ConsumerState<MandiPricesScreen> createState() => _MandiPricesScreenState();
}

class _MandiPricesScreenState extends ConsumerState<MandiPricesScreen> {
  String _selectedCountry = 'India';
  String _selectedState = 'Tamil Nadu';
  String _selectedDistrict = 'Erode';
  String _selectedMandi = 'Gobichettipalayam Mandi';
  String _selectedCrop = 'Tomato';

  final List<String> _crops = ['Tomato', 'Onion', 'Rice', 'Potato', 'Mango', 'Grape', 'Wheat', 'Chilli', 'Turmeric'];

  @override
  Widget build(BuildContext context) {
    final districts = IndiaLocations.getDistricts(_selectedState);
    final currentDistrict = districts.contains(_selectedDistrict) ? _selectedDistrict : districts.first;
    final mandis = IndiaLocations.getMandis(currentDistrict);
    final currentMandi = mandis.contains(_selectedMandi) ? _selectedMandi : mandis.first;
    final l10n = context.l10n;

    final mandiPrices = ref.watch(mandiPricesProvider({
      'state': _selectedState,
      'product': _selectedCrop,
    }));

    final displayPrice = mandiPrices.isNotEmpty
        ? mandiPrices.first.currentPricePerKg
        : (_selectedCrop == 'Mango'
            ? 140.0
            : (_selectedCrop == 'Rice' ? 52.0 : (_selectedCrop == 'Onion' ? 22.0 : 24.0)));

    final minP = displayPrice * 0.85;
    final maxP = displayPrice * 1.15;
    final avgP = (minP + maxP) / 2;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.mandiPrices,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mandi Location Selection Hierarchy Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.primaryGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Mandi Selection Hierarchy',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Country Selection
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCountry,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Country', prefixIcon: Icon(Icons.public)),
                        items: const [DropdownMenuItem(value: 'India', child: Text('🇮🇳 India'))],
                        onChanged: (val) {},
                      ),
                      const SizedBox(height: 12),

                      // State & District Selectors
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedState,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'State'),
                              items: IndiaLocations.statesAndUTs.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedState = val;
                                    final dList = IndiaLocations.getDistricts(val);
                                    _selectedDistrict = dList.first;
                                    _selectedMandi = IndiaLocations.getMandis(_selectedDistrict).first;
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
                              decoration: const InputDecoration(labelText: 'District'),
                              items: districts.map((d) => DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedDistrict = val;
                                    _selectedMandi = IndiaLocations.getMandis(val).first;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Mandi Selector
                      DropdownButtonFormField<String>(
                        initialValue: currentMandi,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Mandi / APMC Yard', prefixIcon: Icon(Icons.storefront)),
                        items: mandis.map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedMandi = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      // Crop Selector
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCrop,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Crop / Produce', prefixIcon: Icon(Icons.eco)),
                        items: _crops.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCrop = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Live Price Display Hierarchy Result Card
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.mintBg, Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hierarchy Pathway Display Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_tree_outlined, size: 16, color: AppColors.primaryGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                '$_selectedState  ↓  $currentDistrict  ↓  $currentMandi  ↓  $_selectedCrop',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedCrop,
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                currentMandi,
                                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Timestamp Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.verifiedBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.verifiedGreen.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_filled, size: 14, color: AppColors.verifiedGreen),
                              const SizedBox(width: 4),
                              Text(
                                'Updated 10 mins ago',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.verifiedGreen),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Current Market Price', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 2),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '₹${displayPrice.toStringAsFixed(0)}',
                                    style: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                                  ),
                                  Text(
                                    '/kg',
                                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Average Rate', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                              Text(
                                '₹${avgP.toStringAsFixed(0)}/kg',
                                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                    // Min & Max Prices with Wrap for screen flexibility
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_downward, color: Colors.blue, size: 16),
                            const SizedBox(width: 4),
                            Text('Min Price: ₹${minP.toStringAsFixed(0)}/kg', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_upward, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text('Max Price: ₹${maxP.toStringAsFixed(0)}/kg', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber.shade900)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
