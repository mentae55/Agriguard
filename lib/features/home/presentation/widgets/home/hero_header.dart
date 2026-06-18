// lib/presentation/widgets/home/hero_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../connection_to_device/view/select_device_screen.dart';
import '../../view_model/home_viewmodel.dart';
import '../common/scale_on_tap.dart';

class HeroHeader extends StatelessWidget {
  final HomeViewModel vm;
  const HeroHeader({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
        ? 'Good Afternoon'
        : 'Good Evening';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor,
            theme.primaryColor.withAlpha(200),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.onPrimary.withAlpha(15),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.onPrimary.withAlpha(10),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo + Switch button row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SvgPicture.asset(
                      'assets/app_images/icons/logo.svg',
                      height: 38,
                      colorFilter: ColorFilter.mode(
                          colorScheme.onPrimary, BlendMode.srcIn),
                      errorBuilder: (ctx, err, st) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.eco_rounded,
                              color: colorScheme.onPrimary, size: 26),
                          const SizedBox(width: 6),
                          Text(
                            'AGRIGUARD',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'AbhayaLibre',
                              fontSize: 18,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ScaleOnTap(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SelectDeviceScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.onPrimary.withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: colorScheme.onPrimary.withAlpha(60),
                              width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.swap_horiz_rounded,
                                color: colorScheme.onPrimary, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Switch',
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                fontFamily: 'AbhayaLibre',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  greeting,
                  style: TextStyle(
                    color: colorScheme.onPrimary.withAlpha(180),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Device #${vm.formattedSerial}',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'AbhayaLibre',
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Online & Transmitting',
                      style: TextStyle(
                        color: colorScheme.onPrimary.withAlpha(180),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}