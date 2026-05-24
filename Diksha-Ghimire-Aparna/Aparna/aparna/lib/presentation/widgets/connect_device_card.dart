import 'package:flutter/material.dart';
import '../../main.dart';
import '../bloc/health_dashboard/health_dashboard_bloc.dart';
import '../bloc/health_dashboard/health_dashboard_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aparna/l10n/app_localizations.dart';

class ConnectDeviceCard extends StatelessWidget {
  final String deviceName;
  final String deviceType;
  final bool showRemoveButton;
  final DateTime? lastUpdated;

  const ConnectDeviceCard({
    Key? key,
    required this.deviceName,
    required this.deviceType,
    this.showRemoveButton = true,
    this.lastUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.watch, color: AppTheme.primaryColor, size: 28),
        ),
        title: Text(
          deviceName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deviceType,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              if (lastUpdated != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.sync,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${l10n.lastSynced}: ${_formatLastUpdated(lastUpdated!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        trailing: showRemoveButton
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 24),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _showRemoveDialog(context, l10n),
                    tooltip: 'Remove device',
                  ),
                ],
              )
            : const Icon(Icons.check_circle, color: Colors.green, size: 28),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.removeDevice),
          content: Text(
            l10n.removeDeviceConfirmation(deviceName),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<HealthDashboardBloc>().add(RemoveDevice());
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.remove),
            ),
          ],
        );
      },
    );
  }

  String _formatLastUpdated(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
