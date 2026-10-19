import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/india_locations.dart';
import '../../core/localization/localized_helpers.dart';
import '../../core/widgets/responsive_center.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditPhoneDialog(BuildContext context, WidgetRef ref, UserModel user) {
    final l10n = context.l10n;
    final controller = TextEditingController(text: user.phone);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            user.phone.isNotEmpty ? 'Edit Phone Number' : 'Add Phone Number',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.phone,
                    hintText: '+91 98765 43210',
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primaryGreen),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final clean = (value ?? '').replaceAll(RegExp(r'\D'), '');
                    if (clean.length < 10) {
                      return 'Please enter a valid 10-digit phone number';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                var newPhone = controller.text.trim();
                if (!newPhone.startsWith('+')) {
                  final digits = newPhone.replaceAll(RegExp(r'\D'), '');
                  if (digits.length == 10) {
                    newPhone = '+91 $digits';
                  }
                }
                final updatedUser = user.copyWith(phone: newPhone);
                await ref.read(currentUserProvider.notifier).updateProfile(updatedUser);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Phone number updated successfully!'),
                      backgroundColor: AppColors.primaryGreen,
                    ),
                  );
                }
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }

  void _showEditLocationDialog(BuildContext context, WidgetRef ref, UserModel user) {
    final l10n = context.l10n;
    String selectedState = user.state.trim().isNotEmpty ? user.state.trim() : 'Tamil Nadu';
    if (!IndiaLocations.statesAndUTs.contains(selectedState)) {
      selectedState = 'Tamil Nadu';
    }

    List<String> availableDistricts = IndiaLocations.districtsByState[selectedState] ?? ['Coimbatore'];
    String selectedDistrict = user.district.trim().isNotEmpty ? user.district.trim() : availableDistricts.first;
    if (!availableDistricts.contains(selectedDistrict)) {
      availableDistricts = [selectedDistrict, ...availableDistricts];
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Edit State & District',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.state,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      key: ValueKey('state_$selectedState'),
                      initialValue: selectedState,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        prefixIcon: Icon(Icons.map_outlined, color: AppColors.primaryGreen),
                      ),
                      items: IndiaLocations.statesAndUTs.map((st) {
                        return DropdownMenuItem<String>(
                          value: st,
                          child: Text(st, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (newSt) {
                        if (newSt != null) {
                          setDialogState(() {
                            selectedState = newSt;
                            availableDistricts = IndiaLocations.districtsByState[newSt] ?? ['Main District'];
                            selectedDistrict = availableDistricts.first;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.district,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      key: ValueKey('dist_${selectedState}_$selectedDistrict'),
                      initialValue: availableDistricts.contains(selectedDistrict)
                          ? selectedDistrict
                          : availableDistricts.first,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        prefixIcon: Icon(Icons.location_city_outlined, color: AppColors.primaryGreen),
                      ),
                      items: availableDistricts.map((dist) {
                        return DropdownMenuItem<String>(
                          value: dist,
                          child: Text(dist, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (newDist) {
                        if (newDist != null) {
                          setDialogState(() {
                            selectedDistrict = newDist;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final updatedUser = user.copyWith(
                      state: selectedState,
                      district: selectedDistrict,
                    );
                    await ref.read(currentUserProvider.notifier).updateProfile(updatedUser);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Location updated successfully!'),
                          backgroundColor: AppColors.primaryGreen,
                        ),
                      );
                    }
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditAddressDialog(BuildContext context, WidgetRef ref, UserModel user) {
    final l10n = context.l10n;
    final controller = TextEditingController(
      text: user.deliveryAddress.isNotEmpty ? user.deliveryAddress : user.fullAddress,
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            user.fullAddress.isNotEmpty ? l10n.editAddress : l10n.addAddress,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.address,
                  hintText: 'Enter complete delivery address (Door No, Street, City)',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newAddr = controller.text.trim();
                final updatedUser = user.copyWith(deliveryAddress: newAddr);
                await ref.read(currentUserProvider.notifier).updateProfile(updatedUser);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final currentLocale = ref.watch(localeProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${l10n.profile} & ${l10n.settings}',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ResponsiveCenter(
        maxWidth: context.isDesktop ? 1150 : 800,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Builder(
            builder: (context) {
              final headerCard = Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primaryGreen,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0] : 'U',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.name,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${user.role.name.toUpperCase()} MODULE • ${user.district}, ${user.state}',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF334155),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.verifiedBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.verifiedGreen),
                      ),
                      child: Text(
                        '✓ ${l10n.verifiedFarmer} (${user.role.name == "farmer" ? l10n.farmer : l10n.customer})',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.verifiedGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              final detailsCard = Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.phone_outlined,
                        color: AppColors.primaryGreen,
                      ),
                      title: Text(
                        l10n.phone,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      subtitle: Text(
                        user.phone.isNotEmpty ? user.phone : l10n.noDataFound,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      trailing: TextButton.icon(
                        onPressed: () => _showEditPhoneDialog(context, ref, user),
                        icon: Icon(
                          user.phone.isNotEmpty ? Icons.edit_outlined : Icons.add_circle_outline,
                          size: 18,
                          color: AppColors.primaryGreen,
                        ),
                        label: Text(
                          user.phone.isNotEmpty ? 'Edit Phone' : 'Add Phone',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    if (user.email.isNotEmpty && !user.email.endsWith('@agriconnect.org')) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.email_outlined,
                          color: AppColors.primaryGreen,
                        ),
                        title: Text(
                          l10n.email,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        subtitle: Text(
                          user.email,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],

                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.home_outlined,
                        color: AppColors.primaryGreen,
                      ),
                      title: Text(
                        l10n.address,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      subtitle: Text(
                        user.fullAddress.isNotEmpty ? user.fullAddress : l10n.noDataFound,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      trailing: TextButton.icon(
                        onPressed: () => _showEditAddressDialog(context, ref, user),
                        icon: Icon(
                          user.fullAddress.isNotEmpty ? Icons.edit_outlined : Icons.add_circle_outline,
                          size: 18,
                          color: AppColors.primaryGreen,
                        ),
                        label: Text(
                          user.fullAddress.isNotEmpty ? l10n.editAddress : l10n.addAddress,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.location_city_outlined,
                        color: AppColors.primaryGreen,
                      ),
                      title: Text(
                        '${l10n.state} & ${l10n.district}',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      subtitle: Text(
                        '${user.district}, ${user.state}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      trailing: TextButton.icon(
                        onPressed: () => _showEditLocationDialog(context, ref, user),
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: AppColors.primaryGreen,
                        ),
                        label: Text(
                          'Edit Location',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    if (user.role == UserRole.farmer) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.eco_outlined,
                          color: AppColors.primaryGreen,
                        ),
                        title: Text(
                          l10n.farmerType,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        subtitle: Text(
                          LocalizedHelpers.getFarmerTypeName(context, user.farmerType),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );

              final languageCard = Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.language,
                            color: AppColors.primaryGreen,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.selectAppLanguage,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildLangChip(ref, 'English', 'en', currentLocale),
                          _buildLangChip(ref, 'हिन्दी (Hindi)', 'hi', currentLocale),
                          _buildLangChip(ref, 'தமிழ் (Tamil)', 'ta', currentLocale),
                          _buildLangChip(ref, 'తెలుగు (Telugu)', 'te', currentLocale),
                          _buildLangChip(ref, 'ಕನ್ನಡ (Kannada)', 'kn', currentLocale),
                          _buildLangChip(ref, 'മലയാളം (Malayalam)', 'ml', currentLocale),
                          _buildLangChip(ref, 'मराठी (Marathi)', 'mr', currentLocale),
                        ],
                      ),
                    ],
                  ),
                ),
              );

              final roleSwitcherCard = Card(
                color: AppColors.mintBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.swap_horizontal_circle,
                    color: AppColors.primaryGreen,
                    size: 28,
                  ),
                  title: Text(
                    'Switch User Role (Demo)',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  subtitle: Text(
                    'Switch between Farmer and Customer modules',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: DropdownButton<UserRole>(
                    value: user.role,
                    items: [UserRole.farmer, UserRole.customer]
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(
                              r.name.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (newRole) {
                      if (newRole != null) {
                        ref
                            .read(currentUserProvider.notifier)
                            .switchRole(newRole);
                      }
                    },
                  ),
                ),
              );

              final logoutButton = SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    await ref.read(currentUserProvider.notifier).signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, size: 20),
                  label: Text(
                    'LOG OUT',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              );

              if (context.isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          headerCard,
                          const SizedBox(height: 18),
                          detailsCard,
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          languageCard,
                          const SizedBox(height: 18),
                          roleSwitcherCard,
                          const SizedBox(height: 24),
                          logoutButton,
                        ],
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  headerCard,
                  const SizedBox(height: 18),
                  languageCard,
                  const SizedBox(height: 18),
                  detailsCard,
                  const SizedBox(height: 18),
                  roleSwitcherCard,
                  const SizedBox(height: 24),
                  logoutButton,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLangChip(
    WidgetRef ref,
    String label,
    String code,
    Locale currentLocale,
  ) {
    final isSelected = currentLocale.languageCode == code;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primaryGreen,
      backgroundColor: AppColors.mintBg,
      labelStyle: GoogleFonts.inter(
        color: isSelected ? Colors.white : AppColors.primaryGreen,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (_) {
        ref.read(localeProvider.notifier).setLocale(code);
      },
    );
  }
}
