// ============================================================
// spectral_shimmer.dart — skeleton loading
// ============================================================
import 'package:flutter/material.dart';

class SpectralShimmer extends StatefulWidget {
  const SpectralShimmer({super.key});

  @override
  State<SpectralShimmer> createState() => _SpectralShimmerState();
}

class _SpectralShimmerState extends State<SpectralShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.9).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
            4,
            (i) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: i == 0 ? 120 : 80,
              decoration: BoxDecoration(
                color: base.withAlpha((_anim.value * 255).toInt()),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// spectral_error_view.dart
// ============================================================
class SpectralErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const SpectralErrorView(
      {super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 64, color: Colors.grey.withAlpha(140)),
            const SizedBox(height: 20),
            const Text('Unable to Load Data',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'AbhayaLibre')),
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    height: 1.5)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF66785F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
