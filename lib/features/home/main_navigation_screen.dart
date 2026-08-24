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
import '../marketplace/farmer_products_screen.dart';
import '../marketplace/farmer_orders_screen.dart';
import '../marketplace/customer_orders_screen.dart';
import '../marketplace/cart_screen.dart';
import '../market/mandi_prices_screen.dart';
import '../verification/admin_dashboard_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
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
        const FarmerProductsScreen(), // My Products Management
        const FarmerOrdersScreen(), // Orders Received
        const MandiPricesScreen(), // Live Mandi Prices
        const CommunityFeedScreen(), // Farmer Community
        const ProfileScreen(), // Profile
      ];
      navItems = [
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard_rounded),
          label: l10n.home,
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_rounded),
          label: 'My Products',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.receipt_long_rounded),
          label: l10n.orders,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.storefront_rounded),
          label: l10n.mandi,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.forum_rounded),
          label: l10n.community,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_rounded),
          label: l10n.profile,
        ),
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
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_rounded),
          label: l10n.home,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.shopping_bag_rounded),
          label: l10n.marketplace,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.shopping_cart_rounded),
          label: l10n.buyProducts,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.local_shipping_rounded),
          label: l10n.orders,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.bar_chart_rounded),
          label: l10n.mandiPrices,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_rounded),
          label: l10n.profile,
        ),
      ];
    } else {
      screens = [
        const AdminDashboardScreen(),
        const ProductListScreen(),
        const MandiPricesScreen(),
        const ProfileScreen(),
      ];
      navItems = [
        BottomNavigationBarItem(
          icon: const Icon(Icons.admin_panel_settings),
          label: l10n.admin,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.storefront),
          label: l10n.marketplace,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.analytics),
          label: l10n.mandi,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person),
          label: l10n.profile,
        ),
      ];
    }

    final safeIndex = _currentIndex < screens.length ? _currentIndex : 0;
    final width = MediaQuery.of(context).size.width;
    final isWideSidebar = width >= 1100;
    final isDesktop = width >= 900;

    if (isWideSidebar) {
      return Scaffold(
        body: Row(
          children: [
            Container(
              width: 260,
              color: Colors.white,
              child: Column(
                children: [
                  // App Branding Header
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.mintBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.eco,
                            size: 28,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KRISHI MITRA',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppColors.primaryGreen,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Direct Farm Connect',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // User Info Mini Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.mintBg.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primaryGreen,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                user.role == UserRole.farmer
                                    ? '👨‍🌾 Farmer Account'
                                    : (user.role == UserRole.admin ? '🛡️ Admin' : '🛒 Buyer'),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Sidebar Navigation Items
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: navItems.length,
                      itemBuilder: (context, index) {
                        final item = navItems[index];
                        final isSelected = index == safeIndex;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: Material(
                            color: isSelected
                                ? AppColors.primaryGreen.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: ListTile(
                              leading: IconTheme(
                                data: IconThemeData(
                                  color: isSelected
                                      ? AppColors.primaryGreen
                                      : Colors.grey.shade600,
                                  size: 22,
                                ),
                                child: item.icon,
                              ),
                              title: Text(
                                item.label ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primaryGreen
                                      : AppColors.textPrimary,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              onTap: () => setState(() => _currentIndex = index),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: IndexedStack(index: safeIndex, children: screens),
            ),
          ],
        ),
      );
    }

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: safeIndex,
              onDestinationSelected: (index) =>
                  setState(() => _currentIndex = index),
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: const IconThemeData(
                color: AppColors.primaryGreen,
              ),
              selectedLabelTextStyle: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.primaryGreen,
              ),
              unselectedLabelTextStyle: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.eco,
                      size: 36,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'KRISHI MITRA',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
              destinations: navItems.map((item) {
                return NavigationRailDestination(
                  icon: item.icon,
                  label: Text(item.label ?? ''),
                );
              }).toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: IndexedStack(index: safeIndex, children: screens),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: safeIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primaryGreen,
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 10),
          items: navItems,
        ),
      ),
    );
  }
}
