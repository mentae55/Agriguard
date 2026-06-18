// lib/presentation/views/soil_analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../view_model/soil_analysis_viewmodel.dart';
import '../widgets/common/section_header.dart';
import '../widgets/soil/status_bar.dart';
import '../widgets/soil/recommendation_card.dart';
import '../widgets/soil/gauge_card.dart';
import '../widgets/soil/alerts_sections.dart';
import '../widgets/soil/trend_chart.dart';

class SoilAnalysisScreen extends StatelessWidget {
  const SoilAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SoilAnalysisViewModel(fetchSoilData: context.read())..initialize(),
      child: const _SoilAnalysisContent(),
    );
  }
}

class _SoilAnalysisContent extends StatefulWidget {
  const _SoilAnalysisContent();

  @override
  State<_SoilAnalysisContent> createState() => _SoilAnalysisContentState();
}

class _SoilAnalysisContentState extends State<_SoilAnalysisContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SoilAnalysisViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.secondary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.keyboard_return_rounded, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Soil Analysis',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontFamily: 'AbhayaLibre',
            fontSize: 24,
          ),
        ),
        actions: [
          if (!vm.isLoading && !vm.hasError)
            Padding(
              padding: EdgeInsets.only(right: pd8h),
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => Container(
                    width: width8,
                    height: height8,
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(
                          (0.4 + 0.6 * _pulseController.value * 255).toInt()),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(right: pd16h),
            child: SvgPicture.asset(
              'assets/app_images/icons/logo.svg',
              width: width50,
              height: height48,
            ),
          ),
        ],
      ),
      body: vm.isLoading
          ? _buildLoading()
          : vm.hasError
          ? _buildError(vm)
          : _buildContent(vm),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: primaryColor, strokeWidth: 3),
          SizedBox(height: height20),
          const Text(
            'Connecting to sensors...',
            style: TextStyle(
              color: grayColor,
              fontSize: 15,
              fontFamily: 'AbhayaLibre',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(SoilAnalysisViewModel vm) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(pd32a),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(pd24a),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3A1A1A) : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(radius20),
                border: Border.all(color: redColor.withAlpha(60)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.sensors_off_rounded, color: redColor, size: 48),
                  SizedBox(height: height12),
                  Text(
                    'Could not connect to sensors',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontFamily: 'AbhayaLibre',
                      fontSize: 18,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: height8),
                  Text(
                    vm.errorMessage,
                    style: const TextStyle(color: grayColor, fontSize: 12),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(height: height24),
            GestureDetector(
              onTap: vm.initialize,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: pd32h, vertical: pd15h),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(radius16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withAlpha(80),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: colorScheme.onPrimary, size: 20),
                    SizedBox(width: width8),
                    Text(
                      'Retry',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'AbhayaLibre',
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(SoilAnalysisViewModel vm) {
    final snap = vm.latest!;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(pd20h, pd16v, pd20h, height100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SoilStatusBar(vm: vm, snap: snap),
          SizedBox(height: height24),
          const SectionHeader(title: 'Live Sensor Gauges', icon: Icons.sensors_rounded),
          SizedBox(height: height12),
          GaugesGrid(vm: vm, snap: snap),
          SizedBox(height: height28),
          const SectionHeader(title: 'AI Recommendation', icon: Icons.lightbulb_outline_rounded),
          SizedBox(height: height12),
          RecommendationCard(vm: vm, snap: snap),
          SizedBox(height: height28),
          const SectionHeader(title: 'Active Alerts', icon: Icons.warning_amber_rounded),
          SizedBox(height: height12),
          AlertsSection(vm: vm, snap: snap),
          SizedBox(height: height28),
          const SectionHeader(title: 'Historical Trends', icon: Icons.show_chart_rounded),
          SizedBox(height: height12),
          TrendsSection(vm: vm),
        ],
      ),
    );
  }
}