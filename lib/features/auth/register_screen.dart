import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/widgets/responsive_center.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'login_screen.dart';
import 'otp_verification_screen.dart';
import 'registration_confirmation_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  UserRole _selectedRole = UserRole.farmer;
  CustomerAuthMode _customerMode = CustomerAuthMode.email;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedState = 'Tamil Nadu';

  String _selectedDistrict = 'Coimbatore';
  final _villageController = TextEditingController();
  String _selectedFarmerType = 'Organic Farmer';

  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _indianStates = [
    'Tamil Nadu',
    'Kerala',
    'Karnataka',
    'Andhra Pradesh',
    'Telangana',
    'Maharashtra',
    'Punjab',
    'Uttar Pradesh',
    'Gujarat',
  ];

  final Map<String, List<String>> _districtsByState = {
    'Tamil Nadu': ['Coimbatore', 'Erode', 'Tiruppur', 'Salem', 'Madurai'],
    'Kerala': ['Palakkad', 'Wayanad', 'Idukki', 'Thrissur'],
    'Karnataka': ['Mandya', 'Hassan', 'Mysuru', 'Belagavi'],
    'Andhra Pradesh': ['Guntur', 'Krishna', 'Kurnool'],
    'Telangana': ['Warangal', 'Nizamabad', 'Karimnagar'],
    'Maharashtra': ['Nashik', 'Pune', 'Nagpur', 'Satara'],
    'Punjab': ['Ludhiana', 'Amritsar', 'Jalandhar'],
    'Uttar Pradesh': ['Varanasi', 'Agra', 'Kanpur'],
    'Gujarat': ['Anand', 'Rajkot', 'Surat'],
  };

  final List<String> _farmerTypes = [
    'Organic Farmer',
    'Grain & Paddy Producer',
    'Horticulture & Fruits',
    'Vegetable Cultivator',
    'Spices & Plantation',
    'Dairy & Mixed Farming',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _villageController.dispose();
    _addressController.dispose();
    super.dispose();
  }


  void _handleRegistrationSubmit() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final deliveryAddress = _addressController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your full name.';
      });
      return;
    }

    if (_selectedRole == UserRole.customer && deliveryAddress.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your complete delivery address.';
      });
      return;
    }

    if (_selectedRole == UserRole.farmer || _customerMode == CustomerAuthMode.phone) {
      if (phone.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter your 10-digit mobile number.';
        });
        return;
      }
    }

    if (_selectedRole == UserRole.customer && _customerMode == CustomerAuthMode.email) {
      if (email.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter your email address.';
        });
        return;
      }
      if (password.length < 6) {
        setState(() {
          _errorMessage = 'Password must be at least 6 characters.';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_selectedRole == UserRole.farmer || _customerMode == CustomerAuthMode.phone) {
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
                    farmerName: name,
                    isRegistration: true,
                    registrationData: {
                      'name': name,
                      'phone': phone,
                      'email': email,
                      'password': password,
                      'state': _selectedState,
                      'district': _selectedDistrict,
                      'village': _villageController.text.trim(),
                      'deliveryAddress': deliveryAddress,
                      'farmerType': _selectedFarmerType,
                    },
                  ),
                ),
              );
            }
          },
          onVerificationFailed: (error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = error.message ?? 'Failed to send OTP.';
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
    } else {
      try {
        // Check if email already exists
        final isDup = await ref.read(authRepositoryProvider).isDuplicateAccount(
          phone: phone.isNotEmpty ? phone : null,
          email: email.isNotEmpty ? email : null,
        );

        if (isDup) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  'Account Already Exists',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
                content: Text(
                  'An account with email "$email" already exists. Would you like to log in via Email OTP?',
                  style: GoogleFonts.inter(fontSize: 14),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LoginScreen(
                            loginHint: LoginHint(
                              role: UserRole.customer,
                              email: email,
                            ),
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Log In via Email OTP',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }
          return;
        }

        // New customer email registration: send Email OTP first BEFORE creating account
        await ref.read(currentUserProvider.notifier).sendCustomerEmailOtp(
              email: email,
              phoneNumber: phone.isNotEmpty ? phone : '9876543210',
              onCodeSent: (verificationId) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OtpVerificationScreen(
                        phoneNumber: phone.isNotEmpty ? phone : email,
                        email: email,
                        isEmailOtp: true,
                        verificationId: verificationId,
                        role: UserRole.customer,
                        isRegistration: true,
                        registrationData: {
                          'name': name,
                          'email': email,
                          'phone': phone.isNotEmpty ? phone : '9876543210',
                          'password': password,
                          'state': _selectedState,
                          'district': _selectedDistrict,
                          'village': _villageController.text.trim(),
                          'deliveryAddress': deliveryAddress,
                          'farmerType': _selectedFarmerType,
                        },
                      ),
                    ),
                  );
                }
              },
              onVerificationFailed: (error) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _errorMessage = error.message ?? 'Failed to send OTP to email.';
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

  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final districts = _districtsByState[_selectedState] ?? ['Coimbatore'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.createAccountTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: ResponsiveCenter(
            maxWidth: 600,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.selectRole,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

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
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.primaryGreen;
                      }
                      return Colors.white;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
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

                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _selectedRole == UserRole.farmer
                              ? '${l10n.farmer} ${l10n.register}'
                              : '${l10n.customer} ${l10n.register}',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDarkGreen,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // CUSTOMER AUTH MODE CHIPS
                        if (_selectedRole == UserRole.customer) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ChoiceChip(
                                label: Text(l10n.emailAndPasswordTab),
                                selected:
                                    _customerMode == CustomerAuthMode.email,
                                selectedColor: AppColors.primaryGreen,
                                backgroundColor: AppColors.mintBg,
                                labelStyle: GoogleFonts.inter(
                                  color:
                                      _customerMode == CustomerAuthMode.email
                                          ? Colors.white
                                          : AppColors.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                                onSelected: (_) {
                                  setState(() {
                                    _customerMode = CustomerAuthMode.email;
                                    _errorMessage = null;
                                  });
                                },
                              ),
                              const SizedBox(width: 10),
                              ChoiceChip(
                                label: Text(l10n.mobileOtpTab),
                                selected:
                                    _customerMode == CustomerAuthMode.phone,
                                selectedColor: AppColors.primaryGreen,
                                backgroundColor: AppColors.mintBg,
                                labelStyle: GoogleFonts.inter(
                                  color:
                                      _customerMode == CustomerAuthMode.phone
                                          ? Colors.white
                                          : AppColors.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                                onSelected: (_) {
                                  setState(() {
                                    _customerMode = CustomerAuthMode.phone;
                                    _errorMessage = null;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // COMMON FIELDS: Full Name
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: '${l10n.name} *',
                            hintText: l10n.farmerNameHint,
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // PHONE NUMBER (Farmer or Customer Phone Mode)
                        if (_selectedRole == UserRole.farmer ||
                            _customerMode == CustomerAuthMode.phone) ...[
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: '${l10n.mobileNumberLabel} *',
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
                          const SizedBox(height: 14),
                        ],

                        // EMAIL FIELD (Customer Email Mode)
                        if (_selectedRole == UserRole.customer &&
                            _customerMode == CustomerAuthMode.email) ...[
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: '${l10n.email} *',
                              hintText: 'customer@gmail.com',
                              prefixIcon: const Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: '${l10n.password} *',
                              prefixIcon: const Icon(Icons.lock_outline),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // CUSTOMER DELIVERY ADDRESS FIELD
                        if (_selectedRole == UserRole.customer) ...[
                          TextField(
                            controller: _addressController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: '${l10n.address} *',
                              hintText: 'Enter complete delivery address (Door No, Street, Landmark)',
                              prefixIcon: const Icon(Icons.home_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],


                        // STATE DROPDOWN
                        DropdownButtonFormField<String>(
                          initialValue: _selectedState,
                          decoration: InputDecoration(
                            labelText: '${l10n.state} *',
                            prefixIcon: const Icon(Icons.map_outlined),
                          ),
                          items: _indianStates.map((st) {
                            return DropdownMenuItem(
                              value: st,
                              child: Text(st),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedState = val;
                                _selectedDistrict =
                                    (_districtsByState[val] ?? ['Coimbatore'])
                                        .first;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 14),

                        // DISTRICT DROPDOWN
                        DropdownButtonFormField<String>(
                          initialValue: districts.contains(_selectedDistrict)
                              ? _selectedDistrict
                              : districts.first,
                          decoration: InputDecoration(
                            labelText: '${l10n.district} *',
                            prefixIcon: const Icon(Icons.location_city_outlined),
                          ),
                          items: districts.map((dist) {
                            return DropdownMenuItem(
                              value: dist,
                              child: Text(dist),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedDistrict = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 14),

                        // FARMER SPECIFIC FIELDS
                        if (_selectedRole == UserRole.farmer) ...[
                          TextField(
                            controller: _villageController,
                            decoration: InputDecoration(
                              labelText: l10n.village,
                              hintText: 'e.g. Gobichettipalayam',
                              prefixIcon: const Icon(Icons.home_work_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),

                          DropdownButtonFormField<String>(
                            initialValue: _selectedFarmerType,
                            decoration: InputDecoration(
                              labelText: '${l10n.farmerType} *',
                              prefixIcon: const Icon(Icons.eco_outlined),
                            ),
                            items: _farmerTypes.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedFarmerType = val;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                        ],

                        // SUBMIT BUTTON
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _isLoading ? null : _handleRegistrationSubmit,
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
                                    l10n.createAccount.toUpperCase(),
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                          ),
                        ),
                      ],
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
