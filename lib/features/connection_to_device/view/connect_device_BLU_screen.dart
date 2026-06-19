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
        _showToast(context, 'Connected to ${device.platformName}', isSuccess: true);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PasswordWifeScreen(),
          ),
        );
      } else {
        _showToast(context, 'Connection Failed. Try again.', isSuccess: false);
      }
    }
  }

  void _showToast(BuildContext context, String message, {required bool isSuccess}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: theme.colorScheme.onPrimary,
              size: 20,
            ),
            SizedBox(width: 10),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.primaryColor),
          onPressed: () => Navigator.pop(context),
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
                _buildHeroSection(viewModel, theme),
                const SizedBox(height: 28),
                _buildStepsCard(theme, isDark),
                const SizedBox(height: 24),
                _buildScanButton(viewModel, theme),
                const SizedBox(height: 20),
                _buildScanResults(viewModel, theme, isDark),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(ConnectionViewModel viewModel, ThemeData theme) {
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
                  color: primaryColor.withAlpha(20),
                  boxShadow: viewModel.isScanning
                      ? [
                          BoxShadow(
                            color: primaryColor.withAlpha(40),
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
        Text(
          'Connect Your AgriGuard',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            fontFamily: 'AbhayaLibre',
            color: theme.colorScheme.onSurface,
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

  Widget _buildStepsCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withAlpha(isDark ? 15 : 10),
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
                  color: primaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.info_outline, color: primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Before you start',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'AbhayaLibre',
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStep(1, 'Power on your AgriGuard device', Icons.power_settings_new, theme),
          const SizedBox(height: 12),
          _buildStep(2, 'Enable Bluetooth on your phone', Icons.bluetooth, theme),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String text, IconData icon, ThemeData theme) {
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
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
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
              color: theme.colorScheme.onSurface.withAlpha(190),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanButton(ConnectionViewModel viewModel, ThemeData theme) {
    return GestureDetector(
      onTap: viewModel.isScanning ? null : viewModel.startScan,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: viewModel.isScanning ? theme.colorScheme.onSurface.withAlpha(30) : primaryColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: viewModel.isScanning
              ? []
              : [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.35),
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
              Icon(Icons.bluetooth_searching, color: theme.colorScheme.onPrimary, size: 22),
            const SizedBox(width: 10),
            Text(
              viewModel.isScanning ? 'Scanning...' : 'Scan for Devices',
              style: TextStyle(
                color: viewModel.isScanning ? primaryColor : theme.colorScheme.onPrimary,
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

  Widget _buildScanResults(ConnectionViewModel viewModel, ThemeData theme, bool isDark) {
    if (!viewModel.isScanning && viewModel.scanResults.isEmpty) {
      return Column(
        children: [
          Icon(Icons.bluetooth_disabled, color: Colors.grey.withValues(alpha: 0.4), size: 48),
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
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final result = viewModel.scanResults[index];
            final device = result.device;
            final isThisConnecting =
                viewModel.connectingDeviceId == device.remoteId.toString();

            return _buildDeviceCard(context, device, isThisConnecting, viewModel.isConnecting, theme, isDark);
          },
        ),
      ],
    );
  }

  Widget _buildDeviceCard(
    BuildContext context,
    BluetoothDevice device,
    bool isThisConnecting,
    bool isAnyConnecting,
    ThemeData theme,
    bool isDark,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isThisConnecting
            ? primaryColor.withAlpha(20)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isThisConnecting
              ? primaryColor.withAlpha(60)
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withAlpha(isDark ? 15 : 10),
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
                  ? primaryColor.withAlpha(35)
                  : primaryColor.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.bluetooth,
              color: primaryColor,
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
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontFamily: 'AbhayaLibre',
                    fontSize: 16,
                    color: theme.colorScheme.onSurface,
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
                      ? theme.colorScheme.onSurface.withAlpha(30)
                      : primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Connect',
                  style: TextStyle(
                    color: isAnyConnecting ? Colors.grey : theme.colorScheme.onPrimary,
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