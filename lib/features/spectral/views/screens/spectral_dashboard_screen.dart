// ============================================================
// spectral_dashboard_screen.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/spectral_view_model.dart';
import '../../data/models/spectral_prediction.dart';
import '../widgets/risk_status_card.dart';
import '../widgets/plant_info_card.dart';
import '../widgets/actions_card.dart';
import '../widgets/group_probability_chart.dart';
import '../widgets/disease_probability_section.dart';
import '../widgets/spectral_shimmer.dart';

class SpectralDashboardScreen extends StatefulWidget {
  const SpectralDashboardScreen({super.key});

  @override
  State<SpectralDashboardScreen> createState() =>
      _SpectralDashboardScreenState();
}

class _SpectralDashboardScreenState extends State<SpectralDashboardScreen> {
  late SpectralViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = context.read<SpectralViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vm.initialize();
    });
  }

  @override
  void dispose() {
    _vm.tearDown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<SpectralViewModel>(
        builder: (context, vm, _) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverHeader(theme, isDark, vm),
              if (vm.isLoading && !vm.hasData)
                const SliverFillRemaining(
                  child: SpectralShimmer(),
                )
              else if (vm.state == SpectralState.error && !vm.hasData)
                SliverFillRemaining(
                  child: SpectralErrorView(
                    message: vm.errorMessage,
                    onRetry: vm.refresh,
                  ),
                )
              else if (vm.hasData)
                _buildContent(vm.prediction!, theme, isDark, vm)
              else
                const SliverFillRemaining(
                  child: _SpectralEmptyState(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverHeader(ThemeData theme, bool isDark, SpectralViewModel vm) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1A2F1A), const Color(0xFF121212)]
                : [const Color(0xFF66785F), const Color(0xFF8BA07E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                const Spacer(),
                if (vm.isLoading && vm.hasData)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: vm.refresh,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.refresh_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.biotech_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spectral Disease Prediction',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'AbhayaLibre',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Early disease detection before symptoms appear',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(SpectralPrediction p, ThemeData theme, bool isDark,
      SpectralViewModel vm) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          RiskStatusCard(prediction: p),
          const SizedBox(height: 16),
          PlantInfoCard(prediction: p),
          const SizedBox(height: 16),
          PredictedGroupCard(prediction: p),
          const SizedBox(height: 16),
          LikelyDiseaseCard(prediction: p),
          const SizedBox(height: 16),
          ActionsCard(prediction: p),
          const SizedBox(height: 16),
          GroupProbabilityChart(prediction: p),
          const SizedBox(height: 16),
          DiseaseProbabilitySection(prediction: p),
        ]),
      ),
    );
  }
}

class _SpectralEmptyState extends StatelessWidget {
  const _SpectralEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.biotech_outlined,
              size: 72, color: Colors.grey.withAlpha(120)),
          const SizedBox(height: 16),
          const Text('No spectral data yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'AbhayaLibre')),
          const SizedBox(height: 8),
          Text('Starting the analysis stream...',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ],
      ),
    );
  }
}
