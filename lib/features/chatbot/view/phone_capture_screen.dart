import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agriguard_project/core/core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../view_model/chatbot_view_model.dart';
import 'chatbot_main_screen.dart';

class PhoneCaptureScreen extends StatefulWidget {
  const PhoneCaptureScreen({super.key});

  @override
  State<PhoneCaptureScreen> createState() => _PhoneCaptureScreenState();
}

class _PhoneCaptureScreenState extends State<PhoneCaptureScreen>
    with SingleTickerProviderStateMixin {
  File? _selectedImage;
  String _selectedCrop = 'Tomato';
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool _takingLongerThanUsual = false;
  Timer? _loadingWarningTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ChatbotViewModel>().initHistoryListener(user.uid);
      });
    }
  }

  @override
  void dispose() {
    _loadingWarningTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _captureImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;
      if (!mounted) return;

      setState(() {
        _selectedImage = File(pickedFile.path);
      });

      context.read<ChatbotViewModel>().clearResult();
      _animController.reset();
      _runClassification();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Future<void> _runClassification() async {
    if (_selectedImage == null) return;

    setState(() => _takingLongerThanUsual = false);

    _loadingWarningTimer?.cancel();
    _loadingWarningTimer = Timer(const Duration(seconds: 12), () {
      if (mounted) setState(() => _takingLongerThanUsual = true);
    });

    final success = await context.read<ChatbotViewModel>().classifyImage(
          imageFile: _selectedImage!,
          cropType: _selectedCrop,
        );

    _loadingWarningTimer?.cancel();
    if (success && mounted) _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final chatbotVm = context.watch<ChatbotViewModel>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Plant Diagnosis',
          style: TextStyle(
            color: primaryColor,
            fontFamily: 'AbhayaLibre',
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_edu_rounded, color: primaryColor, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatbotMainScreen(initialIndex: 1)),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCropSelector(colorScheme),
                const SizedBox(height: 24),
                _buildImageSection(chatbotVm, colorScheme, theme),
                const SizedBox(height: 24),
                _buildResultsSection(chatbotVm, colorScheme, theme),
                const SizedBox(height: 100),
              ],
            ),
          ),
          if (chatbotVm.isClassifying) _buildLoadingOverlay(colorScheme, theme),
        ],
      ),
    );
  }

  Widget _buildCropSelector(ColorScheme colorScheme) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: primaryColor.withAlpha(20),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: ['Tomato', 'Wheat'].map((crop) {
          final isSelected = _selectedCrop == crop;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedCrop = crop);
                if (_selectedImage != null) _runClassification();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                alignment: Alignment.center,
                child: Text(
                  crop,
                  style: TextStyle(
                    color: isSelected ? colorScheme.onPrimary : primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildImageSection(ChatbotViewModel chatbotVm, ColorScheme colorScheme, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    if (_selectedImage != null) {
      return Container(
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withAlpha(isDark ? 40 : 30),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(_selectedImage!, fit: BoxFit.cover),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withAlpha(120)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: FloatingActionButton.small(
                  backgroundColor: colorScheme.surface,
                  onPressed: _showCaptureOptionsBottomSheet,
                  child: const Icon(Icons.flip_camera_ios_rounded, color: primaryColor),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        GestureDetector(
          onTap: () => _captureImage(ImageSource.camera),
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withAlpha(200)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withAlpha(isDark ? 50 : 80),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(width: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan Plant Leaf',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'AbhayaLibre',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Point camera at diseased leaf',
                      style: TextStyle(color: colorScheme.onPrimary.withAlpha(178), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _captureImage(ImageSource.gallery),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: primaryColor.withAlpha(isDark ? 80 : 40), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 40 : 10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.photo_library_rounded, color: primaryColor, size: 28),
                const SizedBox(width: 14),
                const Text(
                  'Upload from Gallery',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'AbhayaLibre',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCaptureOptionsBottomSheet() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose Photo Option',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'AbhayaLibre',
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded, color: primaryColor),
                  title: Text(
                    'Capture with Camera',
                    style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _captureImage(ImageSource.camera);
                  },
                ),
                Divider(color: theme.dividerColor),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: primaryColor),
                  title: Text(
                    'Select from Gallery',
                    style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _captureImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultsSection(ChatbotViewModel chatbotVm, ColorScheme colorScheme, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    if (chatbotVm.classificationError != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: redColor.withAlpha(isDark ? 35 : 20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: redColor.withAlpha(isDark ? 100 : 80)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: redColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Diagnosis Failed',
                    style: TextStyle(color: redColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chatbotVm.classificationError!,
                    style: TextStyle(
                      color: isDark ? Colors.red.shade300 : Colors.red.shade900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final result = chatbotVm.latestResult;
    if (result == null) return const SizedBox.shrink();

    final bool isPlantInvalid = result.confidence < 0.35 || result.prediction.isEmpty;

    if (isPlantInvalid) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2E2010) : const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.orange.withAlpha(80) : const Color(0xFFFED7AA),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 48),
            const SizedBox(height: 12),
            Text(
              'Plant could not be detected',
              style: TextStyle(
                color: isDark ? Colors.orange.shade300 : Colors.orange.shade900,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'AbhayaLibre',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please upload a clear plant image. Ensure the leaf is well-lit, centered, and belongs to a Tomato or Wheat crop.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withAlpha(160),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    final cleanDisease = result.prediction.replaceAll('___', ' ').replaceAll('_', ' ').trim();
    final bool isHealthy = cleanDisease.toLowerCase().contains('healthy');

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 40 : 5),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isHealthy
                        ? Colors.green.withAlpha(isDark ? 40 : 30)
                        : redColor.withAlpha(isDark ? 40 : 30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isHealthy ? Icons.check_circle_rounded : Icons.coronavirus_rounded,
                    color: isHealthy
                        ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
                        : (isDark ? Colors.red.shade300 : Colors.red.shade700),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DIAGNOSIS COMPLETE',
                        style: TextStyle(
                          color: colorScheme.onSurface.withAlpha(130),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        _selectedCrop,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(isDark ? 40 : 30),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    '${(result.confidence * 100).toStringAsFixed(1)}% Conf.',
                    style: const TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: 32, color: theme.dividerColor),
            Text(
              'Result:',
              style: TextStyle(
                color: colorScheme.onSurface.withAlpha(130),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              cleanDisease,
              style: TextStyle(
                color: isHealthy
                    ? (isDark ? Colors.green.shade300 : Colors.green.shade800)
                    : (isDark ? Colors.red.shade300 : Colors.red.shade900),
                fontSize: 24,
                fontWeight: FontWeight.w900,
                fontFamily: 'AbhayaLibre',
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => _navigateToChat(chatbotVm),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withAlpha(210)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withAlpha(isDark ? 50 : 80),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: colorScheme.onPrimary.withAlpha(220), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Ask about it more',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, color: colorScheme.onPrimary.withAlpha(178), size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToChat(ChatbotViewModel chatbotVm) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to chat with AgriGuard AI.')),
      );
      return;
    }

    await chatbotVm.startChatSession(
      userId: user.uid,
      cropType: _selectedCrop,
      imageUrl: '',
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChatbotMainScreen(initialIndex: 0)),
      );
    }
  }

  Widget _buildLoadingOverlay(ColorScheme colorScheme, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      color: Colors.black.withAlpha(isDark ? 160 : 120),
      child: Center(
        child: Container(
          width: 240,
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 2),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: primaryColor, strokeWidth: 3),
              const SizedBox(height: 24),
              Text(
                'Analyzing plant leaf...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Running neural model',
                style: TextStyle(color: grayColor, fontSize: 11),
              ),
              if (_takingLongerThanUsual) ...[
                const SizedBox(height: 16),
                Divider(color: theme.dividerColor),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(Icons.wifi_off_rounded, color: orangeColor, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Slow network connection detected. Please wait...',
                        style: TextStyle(
                          color: orangeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
