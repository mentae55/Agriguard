// lib/presentation/widgets/home/features_grid.dart
import 'package:agriguard_project/features/chatbot/view/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../chatbot/view/chatbot_main_screen.dart';
import '../../../../chatbot/view/phone_capture_screen.dart';
import '../../view/soil_analysis_screen.dart';
import '../../view_model/home_viewmodel.dart';
import '../../view_model/weather_details_screen.dart';
import '../../../../spectral/views/screens/spectral_dashboard_screen.dart';
import '../common/scale_on_tap.dart';

class _GridItem {
  final String networkImage;
  final String localImage;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _GridItem({
    required this.networkImage,
    required this.localImage,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

class FeaturesGrid extends StatelessWidget {
  const FeaturesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      _GridItem(
      networkImage:
      'https://encrypted-tbn3.gstatic.com/images?q=tbn:ANd9GcTGqElC61PCCs9EHURsb4TQSUsaCDPq6XGwrhkw7mx1V-iWYHNB',
      localImage: 'assets/app_images/images/logo.png',
      title: 'Chat with Ai  ',
      subtitle: 'Chat about your crops',
      icon: Icons.smart_toy_rounded,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChatbotMainScreen()),
      ),
    ),
      _GridItem(
        networkImage:
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRi3heGGlGC_n_bzu2bb85TEwuYzX7lsOvmWA&s',
        localImage: 'assets/app_images/images/camera.png',
        title: 'Photo Capture',
        subtitle: 'AI crop analysis',
        icon: Icons.camera_alt_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PhoneCaptureScreen()),
        ),
      ),

      _GridItem(
        networkImage:
        'https://agriconnutritech.com/wp-content/uploads/2024/08/hand-holding.webp',
        localImage: 'assets/app_images/images/soil.png',
        title: 'Soil Analysis',
        subtitle: 'Monitor nutrients',
        icon: Icons.grass_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SoilAnalysisScreen()),
        ),
      ), _GridItem(
        networkImage:
        'https://cdn8.futura-sciences.com/a1920/images/photosynthese.jpeg',
        localImage: 'assets/app_images/images/camera.png',
        title: 'Spectral Analysis',
        subtitle: 'Early disease prediction',
        icon: Icons.biotech_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SpectralDashboardScreen()),
        ),
      ),
      _GridItem(
        networkImage:
        'https://www.yarbo.com/cdn/shop/files/Yarbo_Robot_1_200kb.jpg?v=1781161297&width=1280',
        localImage: 'assets/app_images/images/location.png',
        title: 'Live Location',
        subtitle: 'Track robot GPS',
        icon: Icons.location_on_rounded,
        onTap: () => context.read<HomeViewModel>().setNavIndex(0),
      ),
      _GridItem(
        networkImage:
        'https://i.postimg.cc/YCX2M0m7/weather.png',
        localImage: 'assets/app_images/images/weather.png',
        title: 'Weather',
        subtitle: 'Wind, humidity & rain',
        icon: Icons.cloud_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WeatherDetailsScreen()),
        ),
      ),


    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.88,
      ),
      itemBuilder: (ctx, i) => _GridCard(item: items[i], theme: theme),
    );
  }
}

class _GridCard extends StatelessWidget {
  final _GridItem item;
  final ThemeData theme;

  const _GridCard({required this.item, required this.theme});

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return ScaleOnTap(
      onTap: item.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 40 : 8),
              blurRadius: isDark ? 8 : 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      item.networkImage,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => Image.asset(
                        item.localImage,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx2, err2, st2) => Container(
                          color: primaryColor.withAlpha(20),
                          child: Center(
                            child: Icon(item.icon,
                                color: primaryColor, size: 36),
                          ),
                        ),
                      ),
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFF0F4F0),
                          child: Center(
                            child: Icon(item.icon,
                                color: primaryColor.withAlpha(120), size: 36),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 50,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Color(0x3C000000),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withAlpha(220),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon,
                            color: primaryColor, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'AbhayaLibre',
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: grayColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}