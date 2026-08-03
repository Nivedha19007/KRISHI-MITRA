import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/india_locations.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../home/main_navigation_screen.dart';
import '../../core/constants/app_colors.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  UserRole _role = UserRole.farmer;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _villageController = TextEditingController();
  String _selectedState = 'Tamil Nadu';
  String _selectedDistrict = 'Coimbatore';
  String _farmerType = 'Organic Vegetable Producer';

  @override
  Widget build(BuildContext context) {
    final districts = IndiaLocations.getDistricts(_selectedState);
    if (!districts.contains(_selectedDistrict)) {
      _selectedDistrict = districts.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Krishi-Mitra Account', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Join India\'s Direct Farm Network',
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDarkGreen),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Register As', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SegmentedButton<UserRole>(
                      segments: const [
                        ButtonSegment(value: UserRole.farmer, label: Text('Farmer 🌾')),
                        ButtonSegment(value: UserRole.customer, label: Text('Customer 🛒')),
                      ],
                      selected: {_role},
                      onSelectionChanged: (set) => setState(() => _role = set.first),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person, color: AppColors.primaryGreen)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email, color: AppColors.primaryGreen)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number (+91)', prefixIcon: Icon(Icons.phone, color: AppColors.primaryGreen)),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _selectedState,
              decoration: const InputDecoration(labelText: 'Select State', prefixIcon: Icon(Icons.map, color: AppColors.primaryGreen)),
              items: IndiaLocations.statesAndUTs.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedState = val;
                    _selectedDistrict = IndiaLocations.getDistricts(val).first;
                  });
                }
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _selectedDistrict,
              decoration: const InputDecoration(labelText: 'Select District', prefixIcon: Icon(Icons.location_city, color: AppColors.primaryGreen)),
              items: districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedDistrict = val);
              },
            ),
            const SizedBox(height: 14),
            if (_role == UserRole.farmer) ...[
              TextField(
                controller: _villageController,
                decoration: const InputDecoration(labelText: 'Village Name', prefixIcon: Icon(Icons.home_work, color: AppColors.primaryGreen)),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _farmerType,
                decoration: const InputDecoration(labelText: 'Farming Type', prefixIcon: Icon(Icons.agriculture, color: AppColors.primaryGreen)),
                items: const [
                  DropdownMenuItem(value: 'Organic Vegetable Producer', child: Text('Organic Vegetable Producer')),
                  DropdownMenuItem(value: 'Fruit Cultivator', child: Text('Fruit Cultivator')),
                  DropdownMenuItem(value: 'Grains & Pulses Farmer', child: Text('Grains & Pulses Farmer')),
                  DropdownMenuItem(value: 'Horticulture & Spices', child: Text('Horticulture & Spices')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _farmerType = val);
                },
              ),
              const SizedBox(height: 14),
            ],
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                final newUser = UserModel(
                  uid: 'usr_${DateTime.now().millisecondsSinceEpoch}',
                  name: _nameController.text.isNotEmpty ? _nameController.text : 'New User',
                  email: _emailController.text.isNotEmpty ? _emailController.text : 'user@krishimitra.org',
                  phone: _phoneController.text.isNotEmpty ? _phoneController.text : '+91 99999 88888',
                  role: _role,
                  state: _selectedState,
                  district: _selectedDistrict,
                  village: _villageController.text,
                  farmerType: _farmerType,
                );

                ref.read(currentUserProvider.notifier).setUser(newUser);

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                );
              },
              child: Text('CREATE ACCOUNT', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
