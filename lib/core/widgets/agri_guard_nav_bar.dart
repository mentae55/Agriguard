// lib/presentation/widgets/common/agri_guard_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/core.dart';
import '../../features/home/presentation/view_model/home_viewmodel.dart';
import '../../features/home/presentation/widgets/common/scale_on_tap.dart';

class AgriGuardNavBar extends StatelessWidget {
  const AgriGuardNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: pd16h, vertical: pd8v),
        height: height72,
        decoration: BoxDecoration(
          color: theme.primaryColor,
          borderRadius: BorderRadius.circular(radius28),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withAlpha(isDark ? 50 : 90),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: pd12h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _NavItem(
                index: 0,
                outlined: Icons.location_on_outlined,
                solid: Icons.location_on_rounded,
              ),
              _NavItem(
                index: 1,
                outlined: Icons.notifications_none,
                solid: Icons.notifications,
                badge: vm.criticalCount > 0 ? '${vm.criticalCount}' : null,
              ),
              _FloatingHomeItem(index: 2),
              _NavItem(
                index: 3,
                outlined: Icons.smart_toy_outlined,
                solid: Icons.smart_toy_rounded,
              ),
              _NavItem(
                index: 4,
                outlined: Icons.person_outline_rounded,
                solid: Icons.person_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final IconData outlined;
  final IconData solid;
  final String? badge;

  const _NavItem({
    required this.index,
    required this.outlined,
    required this.solid,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.read<HomeViewModel>();
    final isSelected = vm.selectedNavIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return ScaleOnTap(
      onTap: () => vm.setNavIndex(index),
      child: SizedBox(
        height: height56,
        width: width50,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                isSelected ? solid : outlined,
                key: ValueKey(isSelected),
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onPrimary.withAlpha(130),
                size: isSelected ? 28 : 24,
              ),
            ),
            if (badge != null)
              Positioned(
                top: 10,
                right: 5,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: redColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).primaryColor, width: 1.5),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FloatingHomeItem extends StatelessWidget {
  final int index;

  const _FloatingHomeItem({required this.index});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<HomeViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = vm.selectedNavIndex == index;

    return ScaleOnTap(
      onTap: () => vm.setNavIndex(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: width50,
        height: width50,
        decoration: BoxDecoration(
          color: colorScheme.onPrimary,
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 40 : 25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: Center(
          child: Icon(
            isSelected ? Icons.home_rounded : Icons.home_outlined,
            color: theme.primaryColor,
            size: 28,
          ),
        ),
      ),
    );
  }
}