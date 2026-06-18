import 'package:agriguard_project/features/connection_to_device/view_model/connection_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/core.dart';

class EmptyNetworkWidget extends StatelessWidget {
  const EmptyNetworkWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        SizedBox(height: size * 0.2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Container(
            width: double.infinity,
            height: size * 0.25,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.onSurface.withAlpha(isDark ? 12 : 8),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  color: grayColor.withValues(alpha: 0.4),
                  size: 42,
                ),
                const SizedBox(height: 10),
                Text(
                  'No networks found',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withAlpha(180),
                    fontSize: 15,
                    fontFamily: 'AbhayaLibre',
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => context.read<ConnectionViewModel>().loadWifiNetworks(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          color: primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Try Again',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'AbhayaLibre',
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
