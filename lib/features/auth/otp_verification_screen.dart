import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/widgets/responsive_center.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../home/main_navigation_screen.dart';
import 'login_screen.dart';
import 'registration_confirmation_screen.dart' show LoginHint;

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String? email;
  final bool isEmailOtp;
  final String verificationId;
  final UserRole role;
  final String? farmerName;
  final bool isRegistration;
  final Map<String, String>? registrationData;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.email,
    this.isEmailOtp = false,
    required this.verificationId,
    required this.role,
    this.farmerName,
    this.isRegistration = false,
    this.registrationData,
  });


  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  late String _currentVerificationId;
  bool _isLoading = false;
  String? _errorMessage;

  Timer? _resendTimer;
  int _secondsRemaining = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _secondsRemaining = 30;
      _canResend = false;
    });
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  String _getEnteredOtp() {
    return _otpControllers.map((c) => c.text).join();
  }

  void _handleVerifyOtp() async {
    final otp = _getEnteredOtp();
    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter all 6 digits of the OTP code.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.isEmailOtp) {
        // 1. Verify Email OTP via backend
        await ref.read(currentUserProvider.notifier).verifyEmailOtp(
              email: widget.email!,
              phoneNumber: widget.phoneNumber,
              otpCode: otp,
            );

        if (widget.isRegistration) {
          // 2. Create customer account in Firestore ONLY after successful OTP verification!
          final reg = widget.registrationData ?? {};
          await ref.read(currentUserProvider.notifier).registerDirect(
                name: reg['name'] ?? '',
                phone: reg['phone'] ?? widget.phoneNumber,
                role: widget.role,
                state: reg['state'] ?? 'Tamil Nadu',
                district: reg['district'] ?? 'Coimbatore',
                village: reg['village'] ?? '',
                deliveryAddress: reg['deliveryAddress'] ?? '',
                farmerType: reg['farmerType'] ?? 'Organic Farmer',
                email: reg['email'] ?? widget.email!,
                password: reg['password'] ?? '',
              );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Account created! Please continue to login.'),
                backgroundColor: AppColors.primaryGreen,
                duration: Duration(seconds: 4),
              ),
            );

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => LoginScreen(
                  loginHint: LoginHint(
                    role: widget.role,
                    email: widget.email!,
                  ),
                ),
              ),
              (route) => false,
            );
          }
          return;
        }

        // Email OTP Login (Non-registration)
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          );
        }
        return;
      }


      if (widget.isRegistration) {
        // REGISTRATION FLOW (Requirement 4)
        final reg = widget.registrationData ?? {};

        await ref.read(currentUserProvider.notifier).verifyPhoneOtp(
              verificationId: _currentVerificationId,
              smsCode: otp,
              role: widget.role,
              name: reg['name'],
              email: reg['email'],
              state: reg['state'],
              district: reg['district'],
              village: reg['village'],
              farmerType: reg['farmerType'],
            );

        if (mounted) {
          final l10n = context.l10n;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✓ ${l10n.registrationSuccessfulTitle} ${l10n.continueToLoginButton}',
              ),
              backgroundColor: AppColors.primaryGreen,
              duration: const Duration(seconds: 3),
            ),
          );

          // Return to Login Page with pre-filled registered phone number and role
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => LoginScreen(
                loginHint: LoginHint(
                  role: widget.role,
                  phone: widget.phoneNumber,
                ),
              ),
            ),
            (route) => false,
          );
        }
      } else if (widget.role == UserRole.farmer) {
        // FARMER LOGIN FLOW (Requirement 5)
        await ref.read(currentUserProvider.notifier).loginFarmerWithPhoneOtp(
              farmerName: widget.farmerName ?? '',
              verificationId: _currentVerificationId,
              smsCode: otp,
            );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          );
        }
      } else {
        // CUSTOMER PHONE LOGIN FLOW
        await ref.read(currentUserProvider.notifier).verifyPhoneOtp(
              verificationId: _currentVerificationId,
              smsCode: otp,
              role: widget.role,
            );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          );
        }
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

  void _handleResendOtp() async {
    if (!_canResend || _isLoading) return;

    final l10n = context.l10n;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (widget.isEmailOtp) {
      try {
        await ref.read(currentUserProvider.notifier).sendCustomerEmailOtp(
              email: widget.email!,
              phoneNumber: widget.phoneNumber,
              onCodeSent: (newVerificationId) {
                if (mounted) {
                  setState(() {
                    _currentVerificationId = newVerificationId;
                    _isLoading = false;
                  });
                  _startResendTimer();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✓ ${l10n.newCodeGeneratedInTerminal} ${widget.email}'),
                      backgroundColor: AppColors.primaryGreen,
                    ),
                  );
                }
              },
              onVerificationFailed: (error) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _errorMessage = error.message ?? 'Failed to generate new OTP.';
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
      return;
    }

    try {
      await ref.read(currentUserProvider.notifier).sendPhoneOtp(
            phoneNumber: widget.phoneNumber,
            onCodeSent: (newVerificationId) {
              if (mounted) {
                setState(() {
                  _currentVerificationId = newVerificationId;
                  _isLoading = false;
                });
                _startResendTimer();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✓ ${l10n.weSentOtpTo} ${widget.phoneNumber}'),
                    backgroundColor: AppColors.primaryGreen,
                  ),
                );
              }
            },
            onVerificationFailed: (error) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = error.message ?? 'Failed to resend OTP.';
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
    final l10n = context.l10n;
    final displayPhone = widget.phoneNumber.length >= 10
        ? '+91 ${widget.phoneNumber.substring(0, 2)}**** ${widget.phoneNumber.substring(widget.phoneNumber.length - 4)}'
        : widget.phoneNumber;

    final titleText = widget.isEmailOtp
        ? l10n.emailOtpVerificationTitle
        : l10n.enterOtpTitle;

    final subtitleText = widget.isEmailOtp
        ? '${l10n.enterTerminalOtpDesc}\n${widget.email}'
        : '${l10n.weSentOtpTo}\n$displayPhone';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEmailOtp ? l10n.emailOtpVerificationTitle : l10n.otpVerificationTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 500,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.mintBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    widget.isEmailOtp ? Icons.terminal_rounded : Icons.mark_email_read_outlined,
                    size: 56,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  titleText,
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitleText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

                // Error Message Banner
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 10),
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

                // 6 OTP Input Boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 45,
                      height: 55,
                      child: TextFormField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.borderLight,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primaryGreen,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            if (index < 5) {
                              FocusScope.of(context)
                                  .requestFocus(_focusNodes[index + 1]);
                            } else {
                              FocusScope.of(context).unfocus();
                              _handleVerifyOtp();
                            }
                          } else if (value.isEmpty && index > 0) {
                            FocusScope.of(context)
                                .requestFocus(_focusNodes[index - 1]);
                          }
                        },
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 30),

                // VERIFY OTP BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _isLoading ? null : _handleVerifyOtp,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            l10n.verifyAndProceed.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Resend / Generate New Code Countdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_canResend)
                      Text(
                        '${l10n.resendCodeIn} 00:${_secondsRemaining.toString().padLeft(2, '0')}',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      )
                    else
                      TextButton(
                        onPressed: _handleResendOtp,
                        child: Text(
                          widget.isEmailOtp
                              ? l10n.generateNewCode.toUpperCase()
                              : l10n.resendOtp.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0F172A)),
                  label: Text(
                    widget.isEmailOtp ? l10n.email : l10n.mobileNumberLabel,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0F172A),
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
}
