import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/widgets/responsive_center.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'admin_login_screen.dart';

import 'otp_verification_screen.dart';
import 'register_screen.dart';
import 'registration_confirmation_screen.dart' show LoginHint;
import '../home/main_navigation_screen.dart';
import '../onboarding/welcome_screen.dart';

enum CustomerAuthMode { email, phone }

class LoginScreen extends ConsumerStatefulWidget {
  final LoginHint? loginHint;
  const LoginScreen({super.key, this.loginHint});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  UserRole _selectedRole = UserRole.farmer;
  CustomerAuthMode _customerAuthMode = CustomerAuthMode.phone;

  final _farmerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.loginHint != null) {
      _selectedRole = widget.loginHint!.role;
      _phoneController.text = widget.loginHint!.phone;
    }
  }

  @override
  void dispose() {
    _farmerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // EMAIL LOGIN (Customers)
  // ============================================================

  void _handleSendEmailOtpLogin() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your registered email address.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final querySnap = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      Map<String, dynamic>? userData;
      if (querySnap.docs.isNotEmpty) {
        userData = querySnap.docs.first.data();
      } else {
        final lowerSnap = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email.toLowerCase())
            .get();
        if (lowerSnap.docs.isNotEmpty) {
          userData = lowerSnap.docs.first.data();
        }
      }

      if (userData == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Customer account not found. Please register first.';
          });
        }
        return;
      }

      final phone = (userData['phone'] as String?) ?? email;

      await ref.read(currentUserProvider.notifier).sendCustomerEmailOtp(
            email: email,
            phoneNumber: phone,
            onCodeSent: (verificationId) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OtpVerificationScreen(
                      phoneNumber: phone,
                      email: email,
                      isEmailOtp: true,
                      verificationId: verificationId,
                      role: UserRole.customer,
                      isRegistration: false,
                    ),
                  ),
                );
              }
            },
            onVerificationFailed: (error) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = error.message ?? 'Failed to generate OTP. Please try again.';
                });
              }
            },
          );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  // ============================================================
  // LOGIN VIA PHONE OTP (Farmers & Customers)
  // ============================================================

  void _handleSendPhoneOtpLogin() async {
    final farmerName = _farmerNameController.text.trim();
    final phone = _phoneController.text.trim();

    if (_selectedRole == UserRole.farmer && farmerName.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your registered Farmer Name.';
      });
      return;
    }

    if (phone.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your 10-digit mobile number.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });


    try {
      await ref.read(currentUserProvider.notifier).sendPhoneOtp(
            phoneNumber: phone,
            onCodeSent: (verificationId) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OtpVerificationScreen(
                      phoneNumber: phone,
                      verificationId: verificationId,
                      role: _selectedRole,
                      farmerName: _selectedRole == UserRole.farmer ? farmerName : null,
                      isRegistration: false,
                    ),
                  ),
                );
              }
            },
            onVerificationFailed: (error) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = error.message ??
                      'Failed to send OTP to mobile number. Please check the number and try again.';
                });
              }
            },
          );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  // ============================================================
  // 1-CLICK QUICK DEMO LOGIN (Farmer, Consumer, Admin)
  // Instant bypass of SMS/OTP for effortless demonstration & evaluation
  // ============================================================

  void _handleQuickDemoLogin(UserRole role) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await ref.read(currentUserProvider.notifier).loginAsDemoUser(role);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Signed in as Demo ${user.role.name.toUpperCase()}: ${user.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primaryGreen,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Demo Login error: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 4.0),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 24,
            ),
            tooltip: 'Back to Welcome',
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.25),
              shape: const CircleBorder(),
            ),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                );
              }
            },
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: ResponsiveCenter(
                maxWidth: 550,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.eco, size: 72, color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      l10n.appTitle,
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      l10n.tagline,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Language Selector Card
                    Card(
                      color: Colors.white.withValues(alpha: 0.95),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.language,
                                  color: AppColors.primaryGreen,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.selectAppLanguage,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _buildLangChip(ref, 'English', 'en', currentLocale),
                                _buildLangChip(ref, 'हिन्दी', 'hi', currentLocale),
                                _buildLangChip(ref, 'தமிழ்', 'ta', currentLocale),
                                _buildLangChip(ref, 'తెలుగు', 'te', currentLocale),
                                _buildLangChip(ref, 'ಕನ್ನಡ', 'kn', currentLocale),
                                _buildLangChip(ref, 'മലയാളം', 'ml', currentLocale),
                                _buildLangChip(ref, 'मराठी', 'mr', currentLocale),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // MAIN LOGIN CARD
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.selectModule,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Role Selection Segmented Buttons
                            SegmentedButton<UserRole>(
                              segments: [
                                ButtonSegment(
                                  value: UserRole.farmer,
                                  label: Text(
                                    l10n.farmerRoleChip,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ButtonSegment(
                                  value: UserRole.customer,
                                  label: Text(
                                    l10n.customerRoleChip,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              selected: {_selectedRole},
                              onSelectionChanged: (set) {
                                setState(() {
                                  _selectedRole = set.first;
                                  _errorMessage = null;
                                });
                              },
                              style: ButtonStyle(
                                backgroundColor:
                                    WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return AppColors.primaryGreen;
                                  }
                                  return Colors.transparent;
                                }),
                                foregroundColor:
                                    WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Colors.white;
                                  }
                                  return AppColors.textPrimary;
                                }),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ERROR BANNER
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline,
                                        color: Colors.red.shade700, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: GoogleFonts.inter(
                                          color: Colors.red.shade800,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // FARMER FORM (Name + Mobile OTP Only, Button: LOGIN)
                            if (_selectedRole == UserRole.farmer) ...[
                              Text(
                                l10n.farmerLoginTitle,
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDarkGreen,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.farmerLoginSubtitle,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),

                              TextField(
                                controller: _farmerNameController,
                                decoration: InputDecoration(
                                  labelText: l10n.farmerNameLabel,
                                  hintText: l10n.farmerNameHint,
                                  prefixIcon: const Icon(Icons.person_outline),
                                ),
                              ),
                              const SizedBox(height: 14),

                              TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: l10n.mobileNumberLabel,
                                  hintText: '98765 43210',
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                    child: Text(
                                      '+91',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryGreen,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed:
                                      _isLoading ? null : _handleSendPhoneOtpLogin,
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text(
                                          l10n.login.toUpperCase(),
                                          style: GoogleFonts.outfit(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                ),
                              ),
                            ]

                            // CUSTOMER FORM (Email OTP OR Mobile OTP)
                            else ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ChoiceChip(
                                    label: Text(l10n.emailOtpTab),
                                    selected: _customerAuthMode ==
                                        CustomerAuthMode.email,
                                    selectedColor: AppColors.primaryGreen,
                                    backgroundColor: AppColors.mintBg,
                                    labelStyle: GoogleFonts.inter(
                                      color: _customerAuthMode ==
                                              CustomerAuthMode.email
                                          ? Colors.white
                                          : AppColors.primaryGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    onSelected: (_) {
                                      setState(() {
                                        _customerAuthMode =
                                            CustomerAuthMode.email;
                                        _errorMessage = null;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                  ChoiceChip(
                                    label: Text(l10n.mobileOtpTab),
                                    selected: _customerAuthMode ==
                                        CustomerAuthMode.phone,
                                    selectedColor: AppColors.primaryGreen,
                                    backgroundColor: AppColors.mintBg,
                                    labelStyle: GoogleFonts.inter(
                                      color: _customerAuthMode ==
                                              CustomerAuthMode.phone
                                          ? Colors.white
                                          : AppColors.primaryGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    onSelected: (_) {
                                      setState(() {
                                        _customerAuthMode =
                                            CustomerAuthMode.phone;
                                        _errorMessage = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),

                              if (_customerAuthMode ==
                                  CustomerAuthMode.email) ...[
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: l10n.email,
                                    hintText: 'customer@gmail.com',
                                    prefixIcon: const Icon(Icons.email_outlined),
                                  ),
                                ),
                                const SizedBox(height: 24),


                                SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryGreen,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed:
                                        _isLoading ? null : _handleSendEmailOtpLogin,
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Text(
                                            'SEND EMAIL OTP',
                                            style: GoogleFonts.outfit(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                  ),
                                ),
                              ]
 else ...[
                                TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    labelText: l10n.mobileNumberLabel,
                                    hintText: '98765 43210',
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 14,
                                      ),
                                      child: Text(
                                        '+91',
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryGreen,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryGreen,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed:
                                        _isLoading ? null : _handleSendPhoneOtpLogin,
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Text(
                                            l10n.login.toUpperCase(),
                                            style: GoogleFonts.outfit(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ],

                            const SizedBox(height: 18),
                            const Divider(),
                            const SizedBox(height: 8),

                            // REGISTER LINK
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  _selectedRole == UserRole.farmer
                                      ? l10n.newFarmerPrompt
                                      : l10n.dontHaveAccountPrompt,
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    l10n.createAccount,
                                    style: GoogleFonts.outfit(
                                      color: AppColors.primaryGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 1-CLICK QUICK DEMO ACCESS CARD
                    _buildQuickDemoCard(context),

                    const SizedBox(height: 14),

                    // DISCREET ADMIN PORTAL LINK
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminLoginScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.admin_panel_settings_outlined,
                        color: Colors.white70,
                        size: 16,
                      ),
                      label: Text(
                        l10n.adminPortalLogin,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildQuickDemoCard(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: Color(0xFF4ADE80),
          width: 1.4,
        ),
      ),
      color: Colors.white.withValues(alpha: 0.96),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Quick Demo Access',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '1-CLICK',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Tap any persona below to explore instantly (No OTP needed):',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDemoPersonaButton(
                    icon: Icons.agriculture_rounded,
                    roleName: 'Farmer',
                    personaName: 'Arun Kumar',
                    color: AppColors.primaryGreen,
                    bgColor: const Color(0xFFF0FDF4),
                    borderColor: const Color(0xFF86EFAC),
                    onTap: () => _handleQuickDemoLogin(UserRole.farmer),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDemoPersonaButton(
                    icon: Icons.shopping_basket_rounded,
                    roleName: 'Consumer',
                    personaName: 'Priya Sharma',
                    color: const Color(0xFF0284C7),
                    bgColor: const Color(0xFFF0F9FF),
                    borderColor: const Color(0xFF7DD3FC),
                    onTap: () => _handleQuickDemoLogin(UserRole.customer),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDemoPersonaButton(
                    icon: Icons.admin_panel_settings_rounded,
                    roleName: 'Admin',
                    personaName: 'Govt. Officer',
                    color: Colors.purple.shade700,
                    bgColor: Colors.purple.shade50,
                    borderColor: Colors.purple.shade200,
                    onTap: () => _handleQuickDemoLogin(UserRole.admin),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoPersonaButton({
    required IconData icon,
    required String roleName,
    required String personaName,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                roleName,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                personaName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
        fontSize: 12,
      ),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (_) {
        ref.read(localeProvider.notifier).setLocale(code);
      },
    );
  }
}
