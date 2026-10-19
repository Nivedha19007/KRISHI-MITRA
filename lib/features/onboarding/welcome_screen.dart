import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/widgets/responsive_center.dart';
import '../auth/login_screen.dart';

/// Vector Custom Painter for the signature Krishi Mitra dual-leaf emblem
class KrishiMitraLogoPainter extends CustomPainter {
  const KrishiMitraLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Left Leaf (Fresh Bright Lime / Spring Green)
    final leftPaint = Paint()
      ..color = const Color(0xFF86EFAC) // Glowing spring green
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final leftPath = Path();
    leftPath.moveTo(w * 0.46, h * 0.88);
    leftPath.cubicTo(w * 0.15, h * 0.72, w * 0.06, h * 0.36, w * 0.30, h * 0.14);
    leftPath.cubicTo(w * 0.48, h * 0.28, w * 0.52, h * 0.58, w * 0.46, h * 0.88);
    leftPath.close();
    canvas.drawPath(leftPath, leftPaint);

    // Right Leaf (Rich Forest Emerald Green)
    final rightPaint = Paint()
      ..color = const Color(0xFF22C55E) // Bright vibrant leaf green
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final rightPath = Path();
    rightPath.moveTo(w * 0.48, h * 0.90);
    rightPath.cubicTo(w * 0.68, h * 0.66, w * 0.96, h * 0.45, w * 0.84, h * 0.10);
    rightPath.cubicTo(w * 0.56, h * 0.18, w * 0.40, h * 0.48, w * 0.48, h * 0.90);
    rightPath.close();
    canvas.drawPath(rightPath, rightPaint);

    // Subtle Leaf Spine highlight on right leaf
    final veinPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = w * 0.035
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final veinPath = Path();
    veinPath.moveTo(w * 0.52, h * 0.82);
    veinPath.quadraticBezierTo(w * 0.62, h * 0.48, w * 0.78, h * 0.22);
    canvas.drawPath(veinPath, veinPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class KrishiMitraLogo extends StatelessWidget {
  final double size;
  const KrishiMitraLogo({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withValues(alpha: 0.35),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(size, size * 0.9),
        painter: const KrishiMitraLogoPainter(),
      ),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // -------------------------------------------------------------
          // 1. FULL-SCREEN BACKGROUND IMAGE (Edge-to-edge 100% cover)
          // -------------------------------------------------------------
          Image.asset(
            'assets/images/welcome_fullscreen_bg.jpg',
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.15),
            errorBuilder: (context, error, stackTrace) {
              return _buildBackgroundFallback();
            },
          ),

          // -------------------------------------------------------------
          // 2. CINEMATIC GRADIENT OVERLAY (Enhanced readability & contrast)
          // -------------------------------------------------------------
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xF005180A), // Rich dark emerald at top (readability)
                  const Color(0xC0072210), // Gentle gradient into sky
                  const Color(0x3005180A), // Light over farmer, customer & sunrise
                  const Color(0x7505180A), // Subtle shading towards the bottom
                  const Color(0xF505180A), // Solid dark base for CTA button
                ],
                stops: const [0.0, 0.24, 0.50, 0.76, 1.0],
              ),
            ),
          ),

          // -------------------------------------------------------------
          // 3. FOREGROUND INTERACTIVE CONTENT
          // -------------------------------------------------------------
          SafeArea(
            child: ResponsiveCenter(
              maxWidth: 480,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isShort = constraints.maxHeight < 680;

                      // For short screens, enable scroll protection
                      if (isShort) {
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 12.0,
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 12),
                              _buildBranding(),
                              const SizedBox(height: 20),
                              _buildFeatureHighlights(),
                              const SizedBox(height: 90), // farmer & customer view
                              _buildBottomSection(),
                            ],
                          ),
                        );
                      }

                      // Standard mobile viewport: Edge-to-edge balanced layout
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 12.0,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            _buildBranding(),
                            const SizedBox(height: 20),
                            _buildFeatureHighlights(),
                            const Spacer(), // Leaves the farmer, woman & landscape completely visible
                            _buildBottomSection(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Centre-aligned Branding: Leaf Logo + KRISHI MITRA + Tagline
  Widget _buildBranding() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const KrishiMitraLogo(size: 58),
        const SizedBox(height: 12),

        // KRISHI (White) MITRA (Vibrant Green)
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'KRISHI ',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.70),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              TextSpan(
                text: 'MITRA',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                  color: const Color(0xFF4ADE80), // Vibrant fresh green
                  shadows: [
                    Shadow(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.65),
                      blurRadius: 14,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // Tagline
        Text(
          'Connecting Farmers Directly\nwith Consumers',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.92),
            height: 1.3,
            letterSpacing: 0.2,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.75),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Four compact circular feature highlights in a horizontal row
  Widget _buildFeatureHighlights() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: _buildFeatureItem(
            icon: Icons.eco_rounded,
            title: 'Better Prices\nfor Farmers',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFeatureItem(
            icon: Icons.shopping_basket_rounded,
            title: 'Fresh Produce\nfor Consumers',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFeatureItem(
            icon: Icons.handshake_rounded,
            title: 'Direct\nConnection',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFeatureItem(
            icon: Icons.verified_user_rounded,
            title: 'Transparency\n& Traceability',
          ),
        ),
      ],
    );
  }

  /// Circular Frosted Glass Feature Item
  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF166534).withValues(alpha: 0.50),
            border: Border.all(
              color: const Color(0xFF4ADE80).withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 22,
            color: const Color(0xFF86EFAC), // Bright luminous green
          ),
        ),
        const SizedBox(height: 7),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.2,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.90),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Bottom Section: Rounded Glowing "Get Started →" Button + Mission Statement
  Widget _buildBottomSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Rounded Green "Get Started →" Button with luminous border & glow
        Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF16A34A).withValues(alpha: 0.45),
                blurRadius: 20,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _navigateToLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: const BorderSide(
                  color: Color(0xFF4ADE80), // Radiant green border
                  width: 1.4,
                ),
              ),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0F5128), // Deep Forest Green
                    Color(0xFF15803D), // Emerald Green
                    Color(0xFF16A34A), // Vibrant Green
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Container(
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Get Started',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Subtext: Empowering Communities for a Greener Tomorrow
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.eco_rounded,
              size: 15,
              color: Color(0xFF86EFAC),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Empowering Communities for a Greener Tomorrow',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.92),
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  /// Graceful vector fallback if image is not yet rendered
  Widget _buildBackgroundFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F5128),
            Color(0xFF166534),
            Color(0xFF14532D),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}
