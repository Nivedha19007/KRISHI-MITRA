import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import 'home_screen.dart';
import 'farmer_home_screen.dart';
import '../community/community_feed_screen.dart';
import '../marketplace/product_list_screen.dart';
import '../marketplace/add_product_screen.dart';
import '../marketplace/farmer_orders_screen.dart';
import '../marketplace/customer_orders_screen.dart';
import '../marketplace/cart_screen.dart';
import '../market/mandi_prices_screen.dart';
import '../verification/admin_dashboard_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final l10n = context.l10n;

    List<Widget> screens;
    List<BottomNavigationBarItem> navItems;

    if (user.role == UserRole.farmer) {
      screens = [
        const FarmerHomeScreen(), // Farmer Dashboard
        const AddProductScreen(), // Sell Product
        const FarmerOrdersScreen(), // Orders Received
        const MandiPricesScreen(), // Live Mandi Prices
        const CommunityFeedScreen(), // Farmer Community
        const ProfileScreen(), // Profile
      ];
      navItems = [
        BottomNavigationBarItem(icon: const Icon(Icons.dashboard_rounded), label: l10n.home),
        BottomNavigationBarItem(icon: const Icon(Icons.add_circle), label: l10n.addProduct),
        BottomNavigationBarItem(icon: const Icon(Icons.receipt_long_rounded), label: l10n.orders),
        BottomNavigationBarItem(icon: const Icon(Icons.storefront_rounded), label: l10n.mandi),
        BottomNavigationBarItem(icon: const Icon(Icons.forum_rounded), label: l10n.community),
        BottomNavigationBarItem(icon: const Icon(Icons.person_rounded), label: l10n.profile),
      ];
    } else if (user.role == UserRole.customer) {
      screens = [
        const HomeScreen(), // Customer Home
        const ProductListScreen(), // Marketplace
        const CartScreen(), // Cart
        const CustomerOrdersScreen(), // My Orders & QR Track
        const MandiPricesScreen(), // Today's Live Prices (View Only)
        const ProfileScreen(), // Profile
      ];
      navItems = [
        BottomNavigationBarItem(icon: const Icon(Icons.home_rounded), label: l10n.home),
        BottomNavigationBarItem(icon: const Icon(Icons.shopping_bag_rounded), label: l10n.marketplace),
        BottomNavigationBarItem(icon: const Icon(Icons.shopping_cart_rounded), label: l10n.buyProducts),
        BottomNavigationBarItem(icon: const Icon(Icons.local_shipping_rounded), label: l10n.orders),
        BottomNavigationBarItem(icon: const Icon(Icons.bar_chart_rounded), label: l10n.mandiPrices),
        BottomNavigationBarItem(icon: const Icon(Icons.person_rounded), label: l10n.profile),
      ];
    } else {
      screens = [
        const AdminDashboardScreen(),
        const ProductListScreen(),
        const MandiPricesScreen(),
        const ProfileScreen(),
      ];
      navItems = [
        BottomNavigationBarItem(icon: const Icon(Icons.admin_panel_settings), label: l10n.admin),
        BottomNavigationBarItem(icon: const Icon(Icons.storefront), label: l10n.marketplace),
        BottomNavigationBarItem(icon: const Icon(Icons.analytics), label: l10n.mandi),
        BottomNavigationBarItem(icon: const Icon(Icons.person), label: l10n.profile),
      ];
    }

    final safeIndex = _currentIndex < screens.length ? _currentIndex : 0;

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -3)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: safeIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primaryGreen,
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 10),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 10),
          items: navItems,
        ),
      ),
    );
  }
}
