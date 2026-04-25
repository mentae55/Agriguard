import 'package:flutter/material.dart';
import 'package:agriguard_project/core/core.dart'; // To use primaryColor

class MapWidgets {
  static Widget buildFloatingButton({
    required BuildContext context,
    required VoidCallback onTap,
    required IconData icon,
    String? tooltip,
  }) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 14,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: 26,
          ),
        ),
      ),
    );
  }

  static Widget buildRouteLoadingIndicator(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Finding route...',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildSearchLoadingIndicator(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      ),
    );
  }

  static Widget buildSearchResults(
      BuildContext context, {
        required List<Map<String, dynamic>> searchResults,
        required Function(Map<String, dynamic>) onLocationSelected,
      }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: searchResults.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          indent: 14,
          endIndent: 14,
        ),
        itemBuilder: (context, index) {
          final result = searchResults[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            leading: Icon(
              Icons.location_on,
              color: primaryColor,
              size: 25,
            ),
            title: Text(
              result['name'] ?? '',
              style: Theme.of(context).textTheme.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: result['address'] != null ? Text(
              result['address'],
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ) : null,
            onTap: () => onLocationSelected(result),
          );
        },
      ),
    );
  }

  static Widget buildRouteInfoCard(
      BuildContext context, {
        required double distance,
        required double duration,
        VoidCallback? onClose,
      }) {
    final theme = Theme.of(context);
    final distanceInKm = distance / 1000;
    final durationInMinutes = (duration / 60).ceil();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withAlpha(240),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
        border: Border.all(color: primaryColor.withAlpha(80), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(context, icon: Icons.route, value: '${distanceInKm.toStringAsFixed(1)} km'),
              _buildInfoItem(context, icon: Icons.access_time, value: '$durationInMinutes min'),
              _buildInfoItem(context, icon: Icons.directions_car, value: '${_calculateAverageSpeed(distanceInKm, durationInMinutes)} km/h'),
            ],
          ),
          if (onClose != null) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: onClose,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text('Close Route', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  static Widget _buildInfoItem(
      BuildContext context, {
        required IconData icon,
        required String value,
      }) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: primaryColor, size: 40),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  static String _calculateAverageSpeed(double distanceInKm, int durationInMinutes) {
    if (durationInMinutes == 0) return '0';
    final hours = durationInMinutes / 60;
    final averageSpeed = distanceInKm / hours;
    return averageSpeed.toStringAsFixed(1);
  }
}
