import 'package:agriguard_project/features/home/view/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:agriguard_project/core/core.dart';
import '../services/device_provider.dart';
import 'connect_device_BLU_screen.dart';

class SelectDeviceScreen extends StatefulWidget {
  const SelectDeviceScreen({super.key});

  @override
  State<SelectDeviceScreen> createState() => _SelectDeviceScreenState();
}

class _SelectDeviceScreenState extends State<SelectDeviceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        context.read<DeviceProvider>().checkSavedDevice(userId);
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showRemoveDialog(BuildContext context, DeviceProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove Device?',
          style: TextStyle(
            fontFamily: 'AbhayaLibre',
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: blackColor,
          ),
        ),
        content: Text(
          'This will unlink your AgriGuard device. You can always add it back later.',
          style: TextStyle(
            fontFamily: 'AbhayaLibre',
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: grayColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: grayColor,
                fontFamily: 'AbhayaLibre',
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              Navigator.pop(context);
              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId != null) {
                await provider.removeDevice(userId);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.red.shade500,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Remove',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'AbhayaLibre',
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = FirebaseAuth.instance.currentUser?.displayName ?? '';
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F3),
      body: Consumer<DeviceProvider>(
        builder: (context, deviceProvider, _) {
          if (deviceProvider.status == DeviceStatus.loading) {
            return _buildLoadingState();
          }
          if (deviceProvider.status == DeviceStatus.error) {
            return _buildErrorState(context);
          }

          return Stack(
            children: [
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withOpacity(0.06),
                  ),
                ),
              ),
              Positioned(
                top: size.height * 0.35,
                left: -40,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withOpacity(0.04),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Image.asset(
                  'assets/app_images/images/plant.png',
                  fit: BoxFit.cover,
                  height: size.height * 0.5,
                ),
              ),
              Positioned.fill(
                child: SafeArea(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(name),
                          Expanded(
                            child: Center(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 30),
                                    if (deviceProvider.hasDevice)
                                      _buildDeviceFoundState(
                                        context,
                                        deviceProvider,
                                        size,
                                      )
                                    else
                                      _buildNoDeviceState(size),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeviceFoundState(
    BuildContext context,
    DeviceProvider deviceProvider,
    Size size,
  ) {
    final isOnline = deviceProvider.isDeviceOnline;

    return Column(
      children: [
        // Device Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Icon + status badge
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withOpacity(0.1),
                    ),
                    padding: const EdgeInsets.all(18),
                    child: SvgPicture.asset(
                      'assets/app_images/images/agri.svg',
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.green : Colors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      isOnline ? Icons.check_rounded : Icons.wifi_off_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Text(
                'AgriGuard',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'AbhayaLibre',
                  color: blackColor,
                ),
              ),

              const SizedBox(height: 4),

              // MAC Address chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F8F3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  deviceProvider.savedMac ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'AbhayaLibre',
                    fontWeight: FontWeight.w700,
                    color: grayColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Online / Offline status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isOnline
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline
                          ? 'Online — Ready'
                          : 'Offline — Needs connection',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'AbhayaLibre',
                        fontWeight: FontWeight.w800,
                        color: isOnline ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ===== Online → Go to Dashboard =====
        if (isOnline)
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    HomeScreen(serial: deviceProvider.savedSerial ?? ''),
              ),
            ),
            child: _buildPrimaryButton(
              icon: Icons.dashboard_rounded,
              label: 'Go to Dashboard',
              color: primaryColor,
            ),
          )
        // ===== Offline → Connect Device =====
        else ...[
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.orange.shade700,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your device is offline. Connect via Bluetooth to use it.',
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'AbhayaLibre',
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade800,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ConnectDeviceBLUScreen()),
            ),
            child: _buildPrimaryButton(
              icon: Icons.bluetooth_searching_rounded,
              label: 'Connect Device',
              color: primaryColor,
            ),
          ),

          const SizedBox(height: 10),

          // Refresh button
        ],

        // Remove Device
        GestureDetector(
          onTap: () => _showRemoveDialog(context, deviceProvider),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.link_off_rounded,
                  color: Colors.red.shade400,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Remove Device',
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'AbhayaLibre',
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: size.height * 0.22),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              fontFamily: 'AbhayaLibre',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDeviceState(Size size) {
    return Column(
      children: [
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primaryColor.withOpacity(0.08),
          ),
          padding: const EdgeInsets.all(28),
          child: SvgPicture.asset('assets/app_images/images/selectdevice.svg'),
        ),
        const SizedBox(height: 24),
        Text(
          'No Devices Yet',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            fontFamily: 'AbhayaLibre',
            color: blackColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add your AgriGuard device to start\nmonitoring your farm',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontFamily: 'AbhayaLibre',
            fontWeight: FontWeight.w600,
            color: grayColor,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            _buildFeatureChip(Icons.water_drop_outlined, 'Monitor'),
            const SizedBox(width: 10),
            _buildFeatureChip(Icons.thermostat_outlined, 'Control'),
            const SizedBox(width: 10),
            _buildFeatureChip(Icons.notifications_outlined, 'Alerts'),
          ],
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ConnectDeviceBLUScreen()),
          ),
          child: _buildPrimaryButton(
            icon: Icons.add_rounded,
            label: 'Add Device',
            color: primaryColor,
          ),
        ),
        SizedBox(height: size.height * 0.22),
      ],
    );
  }

  Widget _buildHeader(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${name.isNotEmpty ? name.split(' ').first : 'Farmer'}! 👋',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'AbhayaLibre',
                    color: blackColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your AgriGuard devices',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'AbhayaLibre',
                    fontWeight: FontWeight.w600,
                    color: grayColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(10),
            child: SvgPicture.asset('assets/app_images/icons/logo.svg'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: primaryColor, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'AbhayaLibre',
                fontWeight: FontWeight.w800,
                color: grayColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withOpacity(0.1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Checking for saved devices...',
            style: TextStyle(
              color: grayColor,
              fontSize: 15,
              fontFamily: 'AbhayaLibre',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: Colors.red,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontFamily: 'AbhayaLibre',
                color: blackColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Could not load your devices.\nPlease try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: grayColor,
                fontFamily: 'AbhayaLibre',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId != null) {
                  context.read<DeviceProvider>().checkSavedDevice(userId);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Try Again',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'AbhayaLibre',
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
