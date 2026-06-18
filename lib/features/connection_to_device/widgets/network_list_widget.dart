import 'package:agriguard_project/features/connection_to_device/view_model/connection_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/core.dart';

class NetworkListWidget extends StatelessWidget {
  final TextEditingController hiddenSSIDController;

  const NetworkListWidget({
    super.key,
    required this.hiddenSSIDController,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ConnectionViewModel>();
    final wifiNetworks = viewModel.wifiNetworks;
    final selectedSSID = viewModel.selectedSSID;
    final isHiddenNetwork = viewModel.isHiddenNetwork;
    final showHiddenNetworkSection = viewModel.showHiddenNetworkSection;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
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
          ...List.generate(wifiNetworks.length, (index) {
            final network = wifiNetworks[index];
            final isSelected = !isHiddenNetwork && selectedSSID == network;
            final isLast = index == wifiNetworks.length - 1;

            return Column(
              children: [
                GestureDetector(
                  onTap: () {
                    hiddenSSIDController.clear();
                    viewModel.setSelectedSSID(network, false, false);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withAlpha(20)
                          : Colors.transparent,
                      borderRadius: BorderRadius.only(
                        topLeft: index == 0 ? const Radius.circular(20) : Radius.zero,
                        topRight: index == 0 ? const Radius.circular(20) : Radius.zero,
                        bottomLeft: isLast && !showHiddenNetworkSection
                            ? const Radius.circular(20)
                            : Radius.zero,
                        bottomRight: isLast && !showHiddenNetworkSection
                            ? const Radius.circular(20)
                            : Radius.zero,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor.withAlpha(35)
                                : (isDark ? theme.colorScheme.tertiary : const Color(0xFFF5F8F3)),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            Icons.wifi_rounded,
                            color: isSelected ? primaryColor : grayColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            network,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                              fontFamily: 'AbhayaLibre',
                              fontSize: 15,
                              color: isSelected ? primaryColor : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              color: theme.colorScheme.onPrimary,
                              size: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: theme.dividerColor,
                  ),
              ],
            );
          }),

          Divider(height: 1, color: theme.dividerColor),

          // Hidden Network Toggle
          GestureDetector(
            onTap: () {
              final newShowSection = !showHiddenNetworkSection;
              if (newShowSection) {
                viewModel.setSelectedSSID(null, true, true);
              } else {
                hiddenSSIDController.clear();
                viewModel.setSelectedSSID(null, false, false);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: showHiddenNetworkSection
                    ? primaryColor.withAlpha(20)
                    : Colors.transparent,
                borderRadius: showHiddenNetworkSection
                    ? BorderRadius.zero
                    : const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: showHiddenNetworkSection
                          ? primaryColor.withAlpha(35)
                          : (isDark ? theme.colorScheme.tertiary : const Color(0xFFF5F8F3)),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.wifi_lock_rounded,
                      color: showHiddenNetworkSection ? primaryColor : grayColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add Hidden Network',
                      style: TextStyle(
                        color: showHiddenNetworkSection ? primaryColor : grayColor,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'AbhayaLibre',
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    showHiddenNetworkSection
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: showHiddenNetworkSection ? primaryColor : grayColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (showHiddenNetworkSection)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.tertiary : const Color(0xFFF5F8F3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  if (isHiddenNetwork) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: hiddenSSIDController,
                      style: TextStyle(
                        fontFamily: 'AbhayaLibre',
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter your hidden WiFi name',
                        hintStyle: TextStyle(
                          color: grayColor.withValues(alpha: 0.6),
                          fontFamily: 'AbhayaLibre',
                        ),
                        prefixIcon: Icon(
                          Icons.wifi_lock_rounded,
                          color: primaryColor,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? theme.colorScheme.onSurface.withAlpha(30) : const Color(0xFFE2E8E4),
                            width: 1.2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? theme.colorScheme.onSurface.withAlpha(30) : const Color(0xFFE2E8E4),
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      validator: (value) {
                        if (isHiddenNetwork && (value == null || value.isEmpty)) {
                          return 'Please enter the network name';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
