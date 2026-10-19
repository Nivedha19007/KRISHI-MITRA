import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/widgets/responsive_center.dart';
import '../../data/models/user_model.dart';
import 'login_screen.dart';

/// Simple data class to carry registration hints to the login screen.
class LoginHint {
  final UserRole role;
  final String phone;
  final String email;

  const LoginHint({
    required this.role,
    this.phone = '',
    this.email = '',
  });
}

class RegistrationConfirmationScreen extends ConsumerWidget {
  final UserModel registeredUser;

  const RegistrationConfirmationScreen({
    super.key,
    required this.registeredUser,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isFarmer = registeredUser.role == UserRole.farmer;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.registrationConfirmationTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ResponsiveCenter(
            maxWidth: 600,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primaryGreen,
                      size: 72,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.registrationSuccessfulTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isFarmer
                      ? l10n.farmerRegistrationSuccessDesc
                      : l10n.customerRegistrationSuccessDesc,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 28),

                // Registered Info Summary Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isFarmer ? Icons.agriculture_rounded : Icons.person_rounded,
                              color: AppColors.primaryGreen,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isFarmer ? l10n.farmerProfileSummary : l10n.customerProfileSummary,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(l10n.fullNameLabel, registeredUser.name),
                        if (registeredUser.phone.isNotEmpty)
                          _buildInfoRow(l10n.mobileNumberLabel, registeredUser.phone),
                        if (registeredUser.email.isNotEmpty)
                          _buildInfoRow(l10n.emailAddressLabel, registeredUser.email),
                        _buildInfoRow(
                          l10n.accountRoleLabel,
                          isFarmer ? l10n.farmerRoleChip : l10n.customerRoleChip,
                        ),
                        _buildInfoRow(l10n.stateLabel, registeredUser.state),
                        _buildInfoRow(l10n.districtLabel, registeredUser.district),
                        if (registeredUser.village.isNotEmpty)
                          _buildInfoRow(l10n.villageLabel, registeredUser.village),
                        if (isFarmer) ...[
                          _buildInfoRow(l10n.farmerTypeLabel, registeredUser.farmerType),
                          _buildInfoRow(
                            l10n.verificationStatusLabel,
                            registeredUser.verificationStatus == VerificationStatus.verified
                                ? l10n.verifiedStatus
                                : l10n.pendingVerificationStatus,
                            valueColor: registeredUser.verificationStatus == VerificationStatus.verified
                                ? AppColors.primaryGreen
                                : Colors.orange.shade800,
                          ),
                          if (registeredUser.certificateName != null &&
                              registeredUser.certificateName!.isNotEmpty)
                            _buildInfoRow(
                              l10n.uploadedCertificateLabel,
                              registeredUser.certificateName!,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Continue to Login Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LoginScreen(
                          loginHint: LoginHint(
                            role: registeredUser.role,
                            phone: registeredUser.phone,
                            email: registeredUser.email,
                          ),
                        ),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    l10n.continueToLoginButton,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
