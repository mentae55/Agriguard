import 'package:agriguard_project/features/connection_to_device/view_model/connection_view_model.dart';
import 'package:agriguard_project/features/connection_to_device/widgets/connect_button_widget.dart';
import 'package:agriguard_project/features/connection_to_device/widgets/dashboard_button.dart';
import 'package:agriguard_project/features/connection_to_device/widgets/empty_network_widget.dart';
import 'package:agriguard_project/features/connection_to_device/widgets/header_widget.dart';
import 'package:agriguard_project/features/connection_to_device/widgets/network_list_widget.dart';
import 'package:agriguard_project/features/connection_to_device/widgets/password_field_widgets.dart';
import 'package:agriguard_project/features/connection_to_device/widgets/status_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:agriguard_project/core/core.dart';
import '../../home/view/home_screen.dart';
import '../services/device_provider.dart';
import '../widgets/loading_card_widget.dart';

class PasswordWifeScreen extends StatefulWidget {
  const PasswordWifeScreen({super.key});

  @override
  State<PasswordWifeScreen> createState() => _PasswordWifeScreenState();
}

class _PasswordWifeScreenState extends State<PasswordWifeScreen>
    with SingleTickerProviderStateMixin {
  final formKey = GlobalKey<FormState>();
  final passwordController = TextEditingController();
  final TextEditingController _hiddenSSIDController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // علشان ما نحفظش الجهاز أكتر من مرة لو الـ listener اتنادى مرتين
  bool _deviceSaved = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // تحميل شبكات الـ WiFi
      context.read<ConnectionViewModel>().loadWifiNetworks();

      // ✅ الـ FIX الأساسي:
      // بدل ما نشيك على isSuccess مباشرةً بعد connectToWifi() (اللي بترجع قبل ما Firebase يرد)،
      // بنضيف listener على الـ ViewModel نفسه بيشتغل لما isSuccess يتغير لـ true.
      context.read<ConnectionViewModel>().addListener(_onViewModelChanged);
    });
  }

  // ده بيتنادى أتوماتيكلي لما أي حاجة في الـ ViewModel تتغير
  void _onViewModelChanged() {
    if (!mounted) return;
    final viewModel = context.read<ConnectionViewModel>();
    // لو النجاح اتأكد وما حفظناش الجهاز قبل كده
    if (viewModel.isSuccess && !_deviceSaved) {
      _deviceSaved = true;
      _saveDeviceAfterSuccess(viewModel);
    }
  }

  // حفظ الجهاز في Firebase بعد ما الـ ESP يأكد الاتصال
  Future<void> _saveDeviceAfterSuccess(ConnectionViewModel viewModel) async {
    // الـ MAC محفوظ في الـ ViewModel قبل ما BLE ينقطع
    final mac = viewModel.lastConnectedMac ?? '';
    debugPrint('DEBUG [Screen]: isSuccess=true. Saving device MAC: $mac');

    if (mac.isEmpty) {
      debugPrint('DEBUG [Screen]: MAC is empty! Cannot save device.');
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null && mounted) {
      await context.read<DeviceProvider>().saveDevice(userId, mac);
      debugPrint('DEBUG [Screen]: Device saved to Firebase under user $userId');
    }
  }

  @override
  void dispose() {
    // مهم: إزالة الـ listener عشان نمنع memory leak
    context.read<ConnectionViewModel>().removeListener(_onViewModelChanged);
    _animController.dispose();
    passwordController.dispose();
    _hiddenSSIDController.dispose();
    super.dispose();
  }

  Future<void> _handleConnect(ConnectionViewModel viewModel) async {
    if (!formKey.currentState!.validate()) return;

    if (viewModel.isHiddenNetwork && _hiddenSSIDController.text.trim().isEmpty) {
      _showSnackBar('Please enter the hidden network name', isError: true);
      return;
    }

    if (!viewModel.isHiddenNetwork && viewModel.selectedSSID == null) {
      _showSnackBar('Please select a WiFi network', isError: true);
      return;
    }

    // إرسال الـ credentials، الـ ViewModel سيبدأ ينتظر تأكيد Firebase
    // لما الـ ESP يتصل وisonline يبقى true، الـ _onViewModelChanged هينادي _saveDeviceAfterSuccess
    await viewModel.connectToWifi(
      password: passwordController.text,
      hiddenSSID: _hiddenSSIDController.text,
    );
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
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
        backgroundColor: isError ? redColor : primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final viewModel = context.watch<ConnectionViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F3),
      body: Stack(
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
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  HeaderWidget(),
                  Expanded(
                    child: Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            _buildSectionHeader(
                              icon: Icons.wifi_rounded,
                              title: 'Select WiFi Network',
                              trailing: viewModel.isLoadingNetworks
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: primaryColor,
                                      ),
                                    )
                                  : GestureDetector(
                                      onTap: viewModel.loadWifiNetworks,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.refresh_rounded,
                                          color: primaryColor,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 12),
                            if (viewModel.isLoadingNetworks)
                              LoadingCardWidget()
                            else if (viewModel.wifiNetworks.isEmpty)
                              const EmptyNetworkWidget()
                            else
                              NetworkListWidget(
                                hiddenSSIDController: _hiddenSSIDController,
                              ),
                            const SizedBox(height: 16),
                            if (viewModel.selectedSSID != null || viewModel.isHiddenNetwork) ...[
                              _buildSectionHeader(
                                icon: Icons.lock_outline_rounded,
                                title: viewModel.isHiddenNetwork
                                    ? 'Password for hidden network'
                                    : 'Password for "${viewModel.selectedSSID}"',
                              ),
                              const SizedBox(height: 12),
                              PasswordFieldWidgets(
                                controller: passwordController,
                              ),
                              const SizedBox(height: 20),
                            ],
                            if (viewModel.statusMessage.isNotEmpty) ...[
                              StatusCardWidget(
                                viewModel.statusMessage,
                                viewModel.isSuccess,
                                viewModel.isSending,
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (viewModel.selectedSSID != null || viewModel.isHiddenNetwork) ...[
                              ConnectButtonWidget(
                                isSending: viewModel.isSending,
                                onPressed: () => _handleConnect(viewModel),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (viewModel.isSuccess) ...[
                              DashboardButton(
                                onTap: () {
                                  final serial = context.read<DeviceProvider>().savedSerial ?? '';
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HomeScreen(serial: serial),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
                            SizedBox(height: size.height * 0.05),
                          ],
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
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryColor, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              fontFamily: 'AbhayaLibre',
              color: blackColor,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}
