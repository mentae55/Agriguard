import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:agriguard_project/core/core.dart';
import 'package:agriguard_project/features/connection_to_device/view/select_device_screen.dart';

// Import new screens
import 'package:agriguard_project/features/alerts/view/alerts_screen.dart';
import 'package:agriguard_project/features/device_settings/view/device_settings_screen.dart';
import 'package:agriguard_project/features/profile/view/profile_screen.dart';
import 'soil_analysis_screen.dart';
import 'weather_details_screen.dart';
import 'package:agriguard_project/features/map/view/map_screen.dart'; // [Added] map screen

class HomeScreen extends StatefulWidget {
  final String serial;
  const HomeScreen({super.key, required this.serial});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  int _selectedNavIndex = 2; // Home selected by default

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8), // Ultra light, clean green-tinted white
      body: Stack(
        children: [
          // Subtle background texture/gradient
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withAlpha(10), // 0xFF66785F with low opacity
              ),
            ),
          ),
          
          // Main Content managed by IndexedStack
          IndexedStack(
            index: _selectedNavIndex,
            children: [
               // Tab 0: Map Screen
               const MapScreen(),
               // Tab 1: Alerts
               const AlertsScreen(),
               // Tab 2: Dashboard (Home)
               _buildDashboard(),
               // Tab 3: Device Settings
               DeviceSettingsScreen(serial: widget.serial),
               // Tab 4: Profile
               const ProfileScreen(),
            ],
          ),

          // 6. Custom Nav Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomNavigationBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SafeArea(
      bottom: false,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Branding Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/app_images/icons/logo.svg',
                    height: 65,
                    // Fallback if logo.svg is not perfectly designed
                    errorBuilder: (context, error, stackTrace) =>
                        _buildLogoFallback(),
                  ),
                ),
              ),
            ),

            // Content Body
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 2. Device Title & Switch
                  _buildDeviceTitleBar(),
                  const SizedBox(height: 32),

                  // 3. Priority Actions (Header + Card)
                  _buildSectionHeader(
                    title: 'Priority Actions',
                    trailing: _buildWeatherChip(),
                  ),
                  const SizedBox(height: 16),
                  _buildAlertCard(),
                  const SizedBox(height: 36),

                  // 4. Device Battery
                  _buildSectionHeader(title: 'Device Battery'),
                  const SizedBox(height: 16),
                  _buildModernBatteryCard(),
                  const SizedBox(height: 36),

                  // 5. Grid View Setup (We use column/row for custom sizing similar to the design)
                  _buildFeaturesGrid(),
                  
                  const SizedBox(height: 120), // Padding for the floating nav bar
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET BUILDERS
  // ==========================================

  Widget _buildLogoFallback() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.eco_rounded, color: primaryColor, size: 40),
        Text(
          'AGRIGUARD',
          style: TextStyle(
            color: primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            fontFamily: 'AbhayaLibre',
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceTitleBar() {
    String formattedSerial = widget.serial;
    if (formattedSerial.isEmpty) formattedSerial = '122';
    if (formattedSerial.length > 6) {
      formattedSerial = formattedSerial.substring(0, 6).toUpperCase();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Device #$formattedSerial',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              fontFamily: 'AbhayaLibre', // Elegant serif for the title
              letterSpacing: -0.5,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SelectDeviceScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: primaryColor.withAlpha(220), // Solid but slightly soft green
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withAlpha(60),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              'Switch',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({required String title, Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
            fontFamily: 'AbhayaLibre',
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildWeatherChip() {
    return Row(
      children: [
        Icon(Icons.wb_cloudy_rounded, color: Colors.yellow.shade600, size: 24),
        const SizedBox(width: 6),
        const Text(
          '24 °C',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
            fontFamily: 'AbhayaLibre',
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4), // Very soft, modern pale green
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.black87,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alert need your attention!',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'AbhayaLibre',
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Low Nitrogen detected',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'AbhayaLibre',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Click for more details',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBatteryCard() {
    // A much more polished version of the battery bar in the screenshot
    return Container(
      width: double.infinity,
      height: 65, // Thick bar look
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8E4), // extremely pale green/grey background
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Filled Portion
          FractionallySizedBox(
            widthFactor: 0.70, // 70% filled
            child: Container(
              decoration: BoxDecoration(
                color: primaryColor, // Dark green
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withAlpha(60),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          
          // Content inside the bar (Text)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    '70%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'AbhayaLibre',
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Can last about 12 h 23 min',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildGridItem(
                image: 'assets/app_images/images/location.png',
                title: 'Live location',
                subtitle: 'Click here to view!',
                fallbackIcon: Icons.location_on_rounded,
                onTap: () {
                   // Placeholder for Live Location
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGridItem(
                image: 'assets/app_images/images/soil.png',
                title: 'Soil Analysis',
                subtitle: 'Click here to monitor!',
                fallbackIcon: Icons.grass_rounded,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SoilAnalysisScreen()));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildGridItem(
                image: 'assets/app_images/images/camera.png',
                title: 'Phone Capture',
                subtitle: 'Get analysis of an image!',
                fallbackIcon: Icons.camera_alt_rounded,
                onTap: () {
                   // Placeholder for Phone Capture
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGridItem(
                image: 'assets/app_images/images/weather.png',
                title: 'Weather Details',
                subtitle: 'Wind, Humidity, Rainfall',
                fallbackIcon: Icons.cloud_rounded,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherDetailsScreen()));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGridItem({
    required String image,
    required String title,
    required String subtitle,
    required IconData fallbackIcon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withAlpha(20), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Section
          Padding(
            padding: const EdgeInsets.all(6.0), // Padding around the image to create the framing effect
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20), // inner border radius fits the outer padding nicely
              child: AspectRatio(
                aspectRatio: 1.5, // matches horizontal landscape photos
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFF0FDF4),
                    child: Center(
                      child: Icon(fallbackIcon, color: primaryColor, size: 40),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Texts Section
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    fontFamily: 'AbhayaLibre',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  // Exact matching bottom navigation bar with icons
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 80, // Substantial height for easy tapping
      decoration: BoxDecoration(
        color: primaryColor, // Same green as brand
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildNavItem(0, Icons.location_on_outlined, Icons.location_on_rounded),
              _buildNavItem(1, Icons.warning_amber_rounded, Icons.warning_rounded),
              _buildFloatingHomeItem(2),
              _buildNavItem(3, Icons.smart_toy_outlined, Icons.smart_toy_rounded),
              _buildNavItem(4, Icons.person_outline_rounded, Icons.person_rounded),
            ],
          ),
        ),
      ),
    );
  }

  // Standard Nav items
  Widget _buildNavItem(int index, IconData iconOutlined, IconData iconSolid) {
    final bool isSelected = _selectedNavIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedNavIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 60,
        width: 50, // ensures hit target is wide enough
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Icon(
            isSelected ? iconSolid : iconOutlined,
            key: ValueKey(isSelected),
            color: isSelected ? Colors.white : Colors.white60,
            size: isSelected ? 30 : 26,
          ),
        ),
      ),
    );
  }

  // Centered Home Item (The circular one in the design)
  Widget _buildFloatingHomeItem(int index) {
    final bool isSelected = _selectedNavIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedNavIndex = index;
        });
      },
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white, // The white circle inside the bar
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Icon(
            isSelected ? Icons.home_rounded : Icons.home_outlined,
            color: primaryColor,
            size: 30,
          ),
        ),
      ),
    );
  }
}