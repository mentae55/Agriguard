import 'password_Wife_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:agriguard_project/core/core.dart';
import 'package:provider/provider.dart';
import '../view_model/connection_view_model.dart';

class ConnectDeviceBLUScreen extends StatefulWidget {
  const ConnectDeviceBLUScreen({super.key});

  @override
  State<ConnectDeviceBLUScreen> createState() => _ConnectDeviceBLUScreenState();
}

class _ConnectDeviceBLUScreenState extends State<ConnectDeviceBLUScreen>
    with TickerProviderStateMixin {

  late AnimationController _pulseController;
  late AnimationController _fadeController;
  Animation<double>? _pulseAnimation;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConnectionViewModel>().checkPermissions();
    });
  }

  Future<void> _connectToDevice(BuildContext context, BluetoothDevice device) async {
    final viewModel = context.read<ConnectionViewModel>();
    final success = await viewModel.connectToDevice(device);

    if (mounted) {
      if (success) {
        _showToast(context, '✅ Connected to ${device.platformName}', isSuccess: true);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PasswordWifeScreen(),
          ),
        );
      } else {
        _showToast(context, '❌ Connection Failed. Try again.', isSuccess: false);
      }
    }
  }

  void _showToast(BuildContext context, String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'AbhayaLibre',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? primaryColor : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ConnectionViewModel>();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F3),
      appBar: AppBar(
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: Image.asset('assets/app_images/icons/back.png'),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildHeroSection(viewModel),
                const SizedBox(height: 28),
                _buildStepsCard(),
                const SizedBox(height: 24),
                _buildScanButton(viewModel),
                const SizedBox(height: 20),
                _buildScanResults(viewModel),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(ConnectionViewModel viewModel) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation ?? const AlwaysStoppedAnimation(1.0),
          builder: (context, child) {
            return Transform.scale(
              scale: viewModel.isScanning ? (_pulseAnimation?.value ?? 1.0) : 1.0,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.08),
                  boxShadow: viewModel.isScanning
                      ? [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ]
                      : [],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: SvgPicture.asset(
                    'assets/app_images/images/agri.svg',
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'Connect Your AgriGuard',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            fontFamily: 'AbhayaLibre',
            color: Colors.black,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          viewModel.isScanning
              ? 'Searching for nearby devices...'
              : 'Tap scan to find your device',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontFamily: 'AbhayaLibre',
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStepsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.info_outline, color: primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Before you start',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'AbhayaLibre',
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStep(1, 'Power on your AgriGuard device', Icons.power_settings_new),
          const SizedBox(height: 12),
          _buildStep(2, 'Enable Bluetooth on your phone', Icons.bluetooth),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String text, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                fontFamily: 'AbhayaLibre',
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.info_outline, color: Colors.grey, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'AbhayaLibre',
              fontWeight: FontWeight.w700,
              color: Colors.black.withOpacity(0.75),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanButton(ConnectionViewModel viewModel) {
    return GestureDetector(
      onTap: viewModel.isScanning ? null : viewModel.startScan,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: viewModel.isScanning ? Colors.grey.withOpacity(0.2) : primaryColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: viewModel.isScanning
              ? []
              : [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (viewModel.isScanning)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: primaryColor,
                ),
              )
            else
              const Icon(Icons.bluetooth_searching, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              viewModel.isScanning ? 'Scanning...' : 'Scan for Devices',
              style: TextStyle(
                color: viewModel.isScanning ? primaryColor : Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                fontFamily: 'AbhayaLibre',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanResults(ConnectionViewModel viewModel) {
    if (!viewModel.isScanning && viewModel.scanResults.isEmpty) {
      return Column(
        children: [
          Icon(Icons.bluetooth_disabled, color: Colors.grey.withOpacity(0.4), size: 48),
          const SizedBox(height: 10),
          const Text(
            'No devices found yet',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15,
              fontFamily: 'AbhayaLibre',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (viewModel.scanResults.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              '${viewModel.scanResults.length} device${viewModel.scanResults.length > 1 ? 's' : ''} found',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontFamily: 'AbhayaLibre',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: viewModel.scanResults.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final result = viewModel.scanResults[index];
            final device = result.device;
            final isThisConnecting =
                viewModel.connectingDeviceId == device.remoteId.toString();

            return _buildDeviceCard(context, device, isThisConnecting, viewModel.isConnecting);
          },
        ),
      ],
    );
  }

  Widget _buildDeviceCard(BuildContext context, BluetoothDevice device, bool isThisConnecting, bool isAnyConnecting) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isThisConnecting
            ? primaryColor.withOpacity(0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isThisConnecting
              ? primaryColor.withOpacity(0.3)
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isThisConnecting
                  ? primaryColor.withOpacity(0.15)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.bluetooth,
              color: isThisConnecting ? primaryColor : const Color(0xFF4CAF50),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.platformName.isEmpty
                      ? 'Unknown Device'
                      : device.platformName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontFamily: 'AbhayaLibre',
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  device.remoteId.toString(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontFamily: 'AbhayaLibre',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (isThisConnecting)
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: primaryColor,
              ),
            )
          else
            GestureDetector(
              onTap: isAnyConnecting ? null : () => _connectToDevice(context, device),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isAnyConnecting
                      ? Colors.grey.withOpacity(0.15)
                      : primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Connect',
                  style: TextStyle(
                    color: isAnyConnecting ? Colors.grey : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'AbhayaLibre',
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}