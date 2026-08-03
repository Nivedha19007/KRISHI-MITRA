import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // User Profile Header Card
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primaryGreen,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0] : 'U',
                      style: GoogleFonts.outfit(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${user.role.name.toUpperCase()} MODULE • ${user.district}, ${user.state}',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.verifiedBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.verifiedGreen),
                    ),
                    child: Text(
                      '✓ ${l10n.verifiedFarmer} (${user.role.name == "farmer" ? l10n.farmer : l10n.customer})',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.verifiedGreen),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Choose Your Language Card
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
                        const Icon(Icons.language, color: AppColors.primaryGreen),
                        const SizedBox(width: 8),
                        Text(
                          'Choose your language',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    Text(
                      'Select your preferred language anytime',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
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
                        _buildLangChip(ref, 'ગુજરાતી (Gujarati)', 'gu', currentLocale),
                        _buildLangChip(ref, 'ਪੰਜਾਬੀ (Punjabi)', 'pa', currentLocale),
                        _buildLangChip(ref, 'বাংলা (Bengali)', 'bn', currentLocale),
                        _buildLangChip(ref, 'ଓଡ଼ିଆ (Odia)', 'or', currentLocale),
                        _buildLangChip(ref, 'অসমীয়া (Assamese)', 'as', currentLocale),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // User Info Details
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.phone_outlined, color: AppColors.primaryGreen),
                    title: Text(l10n.phone, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                    subtitle: Text(user.phone, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.email_outlined, color: AppColors.primaryGreen),
                    title: Text(l10n.email, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                    subtitle: Text(user.email, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.location_city_outlined, color: AppColors.primaryGreen),
                    title: Text('${l10n.state} & ${l10n.district}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                    subtitle: Text('${user.district}, ${user.state}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                  ),
                  if (user.role == UserRole.farmer) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.eco_outlined, color: AppColors.primaryGreen),
                      title: Text(l10n.farmerType, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                      subtitle: Text(user.farmerType, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Demo Role Switcher
            Card(
              color: AppColors.mintBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.swap_horizontal_circle, color: AppColors.primaryGreen, size: 28),
                title: Text('Switch User Role (Demo)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: Text('Switch between Farmer and Customer modules', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                trailing: DropdownButton<UserRole>(
                  value: user.role,
                  items: [UserRole.farmer, UserRole.customer]
                      .map((r) => DropdownMenuItem(value: r, child: Text(r.name.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12))))
                      .toList(),
                  onChanged: (newRole) {
                    if (newRole != null) {
                      ref.read(currentUserProvider.notifier).switchRole(newRole);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                icon: const Icon(Icons.logout, size: 20),
                label: Text('LOG OUT', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLangChip(WidgetRef ref, String label, String code, Locale currentLocale) {
    final isSelected = currentLocale.languageCode == code;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primaryGreen,
      backgroundColor: AppColors.mintBg,
      labelStyle: GoogleFonts.inter(
        color: isSelected ? Colors.white : AppColors.primaryGreen,
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (_) {
        ref.read(localeProvider.notifier).setLocale(code);
      },
    );
  }
}
