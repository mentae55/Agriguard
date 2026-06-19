// lib/features/home/presentation/view/soil_analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agriguard_project/core/constants/app_colors.dart';
import '../view_model/soil_analysis_viewmodel.dart';
import '../widgets/soil/status_bar.dart';
import '../widgets/soil/gauge_card.dart';
import '../widgets/soil/recommendation_card.dart';
import '../widgets/soil/alerts_sections.dart';
import '../widgets/soil/trend_chart.dart';

class SoilAnalysisScreen extends StatelessWidget {
  const SoilAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SoilAnalysisViewModel()..initialize(),
      child: const _SoilAnalysisContent(),
    );
  }
}

class _SoilAnalysisContent extends StatelessWidget {
  const _SoilAnalysisContent();

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
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor),
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
      ),
      body: _buildBody(context, vm),
    );
  }

  Widget _buildBody(BuildContext context, SoilAnalysisViewModel vm) {
    if (vm.state == SoilState.initial || vm.state == SoilState.loading) {
      if (vm.latest == null) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryColor),
              SizedBox(height: 16),
              Text('Connecting to sensors...', style: TextStyle(color: grayColor)),
            ],
          ),
        );
      }
    }

    if (vm.state == SoilState.error && vm.latest == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(vm.errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: vm.refreshNow,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SoilStatusBar(vm: vm),
          const SizedBox(height: 24),
          const Text(
            'Parameters',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'AbhayaLibre'),
          ),
          const SizedBox(height: 12),
          GaugesGrid(vm: vm),
          const SizedBox(height: 24),
          RecommendationCard(vm: vm),
          const SizedBox(height: 24),
          AlertsSection(vm: vm),
          const SizedBox(height: 24),
          TrendsSection(vm: vm),
        ],
      ),
    );
  }
}