// lib/presentation/views/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/agri_guard_nav_bar.dart';
import '../../../map/view/map_screen.dart';
import '../view_model/home_viewmodel.dart';
import '../widgets/home/hero_header.dart';
import '../widgets/home/live_stats_row.dart';
import '../widgets/home/alert_banner.dart';
import '../widgets/home/features_grid.dart';
import '../widgets/home/device_status_card.dart';
import '../../../alerts/view/alerts_screen.dart';
import '../../../profile/view/profile_screen.dart';
import '../../../device_settings/views/device_settings_screen.dart';

class HomeScreen extends StatelessWidget {
  final String serial;
  const HomeScreen({super.key, required this.serial});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(
        serial: serial,
      )..initialize(),
      child: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatelessWidget {
  const _HomeScreenContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final theme = Theme.of(context);

    // Nav indices:
    // 0 → Map  |  1 → Alerts  |  2 → Dashboard (Home)
    // 3 → Chatbot  |  4 → Profile
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // ── Floating NavBar overlaid at the bottom ──────────────────────────
      bottomNavigationBar: const AgriGuardNavBar(),
      body: IndexedStack(
        index: vm.selectedNavIndex,
        children: [
          const MapScreen(),
          const AlertsScreen(),
          _buildDashboard(context, vm),
          const DeviceSettingsScreen(serial: '',),
          const ProfileScreen(),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, HomeViewModel vm) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: HeroHeader(vm: vm)),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(pd20h, 0, pd20h, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                SizedBox(height: height20),
                LiveStatsRow(vm: vm),
                SizedBox(height: height20),
                AlertBanner(vm: vm),
                SizedBox(height: height24),
                _SectionLabel('Quick Actions'),
                SizedBox(height: height15),
                const FeaturesGrid(),
                SizedBox(height: height24),
                _SectionLabel('Device Status'),
                SizedBox(height: height15),
                DeviceStatusCard(vm: vm),
                // Extra bottom padding so content clears the floating nav bar
                SizedBox(height: height110),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.displayMedium?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            fontFamily: 'AbhayaLibre',
            letterSpacing: -0.3,
          ) ??
          TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            fontFamily: 'AbhayaLibre',
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.3,
          ),
    );
  }
}