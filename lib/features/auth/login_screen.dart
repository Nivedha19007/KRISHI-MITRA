import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/widgets/responsive_center.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../home/main_navigation_screen.dart';
import 'admin_login_screen.dart';
import 'otp_verification_screen.dart';
import 'register_screen.dart';

enum CustomerAuthMode { email, phone }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  UserRole _selectedRole = UserRole.farmer;
  CustomerAuthMode _customerAuthMode = CustomerAuthMode.email;

  final _farmerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user =
          await ref.read(currentUserProvider.notifier).restoreSession();
      if (user != null && user.uid.isNotEmpty && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    });
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

  void _handleEmailLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both email and password.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(currentUserProvider.notifier).loginWithEmail(
            email: email,
            password: password,
            role: _selectedRole,
          );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final l10n = context.l10n;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryGreen,
              AppColors.leafGreen,
              Color(0xFF1B5E20),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
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
                                  'Select App Language',
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
                              'Select Module',
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
                                    'Farmer 🌾',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ButtonSegment(
                                  value: UserRole.customer,
                                  label: Text(
                                    'Customer 🛒',
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
                                'Farmer Login (Mobile OTP)',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDarkGreen,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Enter your registered name and mobile number.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),

                              TextField(
                                controller: _farmerNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Farmer Name',
                                  hintText: 'Enter your registered name',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                              ),
                              const SizedBox(height: 14),

                              TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: 'Mobile Number',
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
                                          'LOGIN',
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

                            // CUSTOMER FORM (Email & Password OR Mobile OTP, Button: LOGIN)
                            else ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ChoiceChip(
                                    label: const Text('Email & Password'),
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
                                    label: const Text('Mobile OTP'),
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
                                  decoration: const InputDecoration(
                                    labelText: 'Email Address',
                                    hintText: 'customer@gmail.com',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: Icon(Icons.lock_outline),
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
                                        _isLoading ? null : _handleEmailLogin,
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
                                            'LOGIN',
                                            style: GoogleFonts.outfit(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                  ),
                                ),
                              ] else ...[
                                TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    labelText: 'Mobile Number',
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
                                            'LOGIN',
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _selectedRole == UserRole.farmer
                                      ? "New farmer? "
                                      : "Don't have an account? ",
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
                                    'Create Account',
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
                        'Admin Portal Login',
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
