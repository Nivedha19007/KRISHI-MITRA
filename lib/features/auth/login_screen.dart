import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../home/main_navigation_screen.dart';
import 'register_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  UserRole _selectedRole = UserRole.farmer;
  final _emailController = TextEditingController(text: 'arun.farmer@krishimitra.org');
  final _passwordController = TextEditingController(text: 'password123');

  void _handleLogin() async {
    await ref.read(currentUserProvider.notifier).login(
          _emailController.text,
          _passwordController.text,
          _selectedRole,
        );

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  void _quickLogin(UserRole role) async {
    setState(() {
      _selectedRole = role;
    });
    final email = role == UserRole.farmer ? 'arun.farmer@krishimitra.org' : 'customer.priya@krishimitra.org';
    await ref.read(currentUserProvider.notifier).login(email, 'password123', role);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
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
            colors: [AppColors.primaryGreen, AppColors.leafGreen, Color(0xFF1B5E20)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.eco,
                    size: 72,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 14),
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
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),

                  // Choose Your Language Card on Login Page
                  Card(
                    color: Colors.white.withValues(alpha: 0.95),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.language, color: AppColors.primaryGreen, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                'Choose your language',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildLangChip('English', 'en', currentLocale),
                                _buildLangChip('हिन्दी', 'hi', currentLocale),
                                _buildLangChip('தமிழ்', 'ta', currentLocale),
                                _buildLangChip('తెలుగు', 'te', currentLocale),
                                _buildLangChip('ಕನ್ನಡ', 'kn', currentLocale),
                                _buildLangChip('മലയാളം', 'ml', currentLocale),
                                _buildLangChip('मराठी', 'mr', currentLocale),
                                _buildLangChip('ગુજરાતી', 'gu', currentLocale),
                                _buildLangChip('ਪੰਜਾਬੀ', 'pa', currentLocale),
                                _buildLangChip('বাংলা', 'bn', currentLocale),
                                _buildLangChip('ଓଡ଼ିଆ', 'or', currentLocale),
                                _buildLangChip('অসমীয়া', 'as', currentLocale),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Login Form Card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.selectRole,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 12),
                          SegmentedButton<UserRole>(
                            segments: [
                              ButtonSegment(
                                value: UserRole.farmer,
                                label: Text('${l10n.farmer} 🌾'),
                              ),
                              ButtonSegment(
                                value: UserRole.customer,
                                label: Text('${l10n.customer} 🛒'),
                              ),
                            ],
                            selected: {_selectedRole},
                            onSelectionChanged: (Set<UserRole> selection) {
                              setState(() {
                                _selectedRole = selection.first;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: '${l10n.email} / ${l10n.phone}',
                              prefixIcon: const Icon(Icons.person_outline, color: AppColors.primaryGreen),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: l10n.password,
                              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryGreen),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text('${l10n.login.toUpperCase()} TO ${l10n.appTitle}', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Don't have an account? ", style: GoogleFonts.inter(fontSize: 13)),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                  );
                                },
                                child: Text(l10n.register, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick Demo Role Shortcut Card
                  Card(
                    color: Colors.white.withValues(alpha: 0.95),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            '⚡ Quick Demo Module Selector',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ActionChip(
                                avatar: const Icon(Icons.agriculture, size: 16, color: AppColors.primaryGreen),
                                label: Text('${l10n.farmer} View'),
                                backgroundColor: AppColors.mintBg,
                                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                                onPressed: () => _quickLogin(UserRole.farmer),
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.shopping_bag, size: 16, color: Colors.blue),
                                label: Text('${l10n.customer} View'),
                                backgroundColor: Colors.blue.shade50,
                                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                                onPressed: () => _quickLogin(UserRole.customer),
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildLangChip(String label, String code, Locale currentLocale) {
    final isSelected = currentLocale.languageCode == code;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primaryGreen,
        backgroundColor: AppColors.mintBg,
        labelStyle: GoogleFonts.inter(
          color: isSelected ? Colors.white : AppColors.primaryGreen,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onSelected: (_) {
          ref.read(localeProvider.notifier).setLocale(code);
        },
      ),
    );
  }
}
