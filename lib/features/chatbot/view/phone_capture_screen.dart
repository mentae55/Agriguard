import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agriguard_project/core/core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../view_model/chatbot_view_model.dart';
import 'chat_screen.dart';
import 'chatbot_main_screen.dart';

class PhoneCaptureScreen extends StatefulWidget {
  const PhoneCaptureScreen({super.key});

  @override
  State<PhoneCaptureScreen> createState() => _PhoneCaptureScreenState();
}

class _PhoneCaptureScreenState extends State<PhoneCaptureScreen>
    with SingleTickerProviderStateMixin {
  File? _selectedImage;
  String _selectedCrop = 'Tomato'; // Default
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);

    // Fetch previous chats list in the background
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ChatbotViewModel>().initHistoryListener(user.uid);
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Camera image capture
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

      // Clear any previous results
      context.read<ChatbotViewModel>().clearResult();
      _animController.reset();

      // Trigger automatic classification
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

    final success = await context.read<ChatbotViewModel>().classifyImage(
          imageFile: _selectedImage!,
          cropType: _selectedCrop,
        );

    if (success && mounted) {
      _animController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatbotVm = context.watch<ChatbotViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF5), // Ultra light, organic greenish-white
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
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
          // Navigates to Chat History Screen
          IconButton(
            icon: Icon(Icons.history_edu_rounded, color: primaryColor, size: 28),
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
                // 1. Crop Selector
                _buildCropSelector(),
                const SizedBox(height: 24),

                // 2. Image Display or Picker Options
                _buildImageSection(chatbotVm),
                const SizedBox(height: 24),

                // 3. Status/Results Section
                _buildResultsSection(chatbotVm),

                const SizedBox(height: 100), // Bottom spacer
              ],
            ),
          ),

          // Loading overlay during classification
          if (chatbotVm.isClassifying) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // Sliding crop selector
  Widget _buildCropSelector() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: primaryColor.withAlpha(20),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedCrop = 'Tomato');
                if (_selectedImage != null) _runClassification();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedCrop == 'Tomato' ? primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Tomato',
                  style: TextStyle(
                    color: _selectedCrop == 'Tomato' ? Colors.white : primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedCrop = 'Wheat');
                if (_selectedImage != null) _runClassification();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedCrop == 'Wheat' ? primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Wheat',
                  style: TextStyle(
                    color: _selectedCrop == 'Wheat' ? Colors.white : primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Image section holding current image or showing glassmorphic capture buttons
  Widget _buildImageSection(ChatbotViewModel chatbotVm) {
    if (_selectedImage != null) {
      return Container(
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withAlpha(30),
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
              // Gradient Overlay
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
              // Change Image Floating Action Button
              Positioned(
                top: 16,
                right: 16,
                child: FloatingActionButton.small(
                  backgroundColor: Colors.white,
                  onPressed: () => _showCaptureOptionsBottomSheet(),
                  child: Icon(Icons.flip_camera_ios_rounded, color: primaryColor),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Capture Trigger Buttons (when no image is picked)
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
                  color: primaryColor.withAlpha(80),
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
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan Plant Leaf',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'AbhayaLibre',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Point camera at diseased leaf',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: primaryColor.withAlpha(40), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library_rounded, color: primaryColor, size: 28),
                const SizedBox(width: 14),
                Text(
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

  // Options bottom sheet for picking
  void _showCaptureOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                Text(
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
                  leading: Icon(Icons.camera_alt_rounded, color: primaryColor),
                  title: const Text('Capture with Camera', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _captureImage(ImageSource.camera);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.photo_library_rounded, color: primaryColor),
                  title: const Text('Select from Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
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

  // Results Section (Diagnosis Card)
  Widget _buildResultsSection(ChatbotViewModel chatbotVm) {
    if (chatbotVm.classificationError != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withAlpha(80)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Diagnosis Failed',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chatbotVm.classificationError!,
                    style: TextStyle(color: Colors.red.shade900, fontSize: 13),
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

    // IMAGE VALIDATION RULE:
    // If the confidence level is extremely low (e.g., < 0.35) or result contains no meaningful agricultural class
    final bool isPlantInvalid = result.confidence < 0.35 || result.prediction.isEmpty;

    if (isPlantInvalid) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED), // Warm light orange
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFED7AA), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 48),
            const SizedBox(height: 12),
            Text(
              'Plant could not be detected',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'AbhayaLibre',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please upload a clear plant image. Ensure the leaf is well-lit, centered, and belongs to a Tomato or Wheat crop.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.5),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
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
                    color: isHealthy ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isHealthy ? Icons.check_circle_rounded : Icons.coronavirus_rounded,
                    color: isHealthy ? Colors.green.shade700 : Colors.red.shade700,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DIAGNOSIS COMPLETE',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        _selectedCrop,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    '${(result.confidence * 100).toStringAsFixed(1)}% Conf.',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            const Text(
              'Result:',
              style: TextStyle(color: Colors.black38, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              cleanDisease,
              style: TextStyle(
                color: isHealthy ? Colors.green.shade800 : Colors.red.shade900,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                fontFamily: 'AbhayaLibre',
              ),
            ),
            const SizedBox(height: 24),

            // VERY IMPORTANT:
            // "Ask AgriGuard AI" Button appears ONLY after successful classification!
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
                      color: primaryColor.withAlpha(80),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Colors.white.withAlpha(220), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Ask about it more',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Navigate to Chat screen safely
  Future<void> _navigateToChat(ChatbotViewModel chatbotVm) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to chat with AgriGuard AI.')),
      );
      return;
    }

    // Initialize session in Firebase
    await chatbotVm.startChatSession(
      userId: user.uid,
      cropType: _selectedCrop,
      imageUrl: '', // optional url of image if stored in cloud storage
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChatbotMainScreen(initialIndex: 0)),
      );
    }
  }

  // Scanner Loading Overlay
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withAlpha(120),
      child: Center(
        child: Container(
          width: 220,
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 2),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: primaryColor, strokeWidth: 3),
              const SizedBox(height: 24),
              const Text(
                'Analyzing plant leaf...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Running neural model',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
