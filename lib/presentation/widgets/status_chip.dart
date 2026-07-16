import 'package:flutter/material.dart';
import '../../domain/entities/link.dart';
import '../../domain/entities/sync_types.dart';

/// Small badge reflecting the server enrichment state of an item.
/// pending/parsing/enriching -> spinner; degraded/failed -> warning badge;
/// a queued offline op shows as "waiting to sync". Ready renders nothing.
class StatusChip extends StatelessWidget {
  final Link link;

  const StatusChip({super.key, required this.link});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (link.pendingOp != PendingOp.none) {
      return _chip(
        theme,
        icon: Icons.cloud_upload_outlined,
        label: 'Waiting to sync',
        color: theme.colorScheme.primary,
      );
    }

    switch (link.status) {
      case ItemStatus.pending:
      case ItemStatus.parsing:
      case ItemStatus.enriching:
        return _chip(
          theme,
          spinner: true,
          label: 'Processing…',
          color: theme.colorScheme.primary,
        );
      case ItemStatus.degraded:
        return _chip(
          theme,
          icon: Icons.info_outline,
          label: 'Limited preview',
          color: Colors.orange[700]!,
        );
      case ItemStatus.failed:
        return _chip(
          theme,
          icon: Icons.error_outline,
          label: 'Failed',
          color: theme.colorScheme.error,
        );
      case ItemStatus.ready:
        return const SizedBox.shrink();
    }
  }

  Widget _chip(
    ThemeData theme, {
    IconData? icon,
    bool spinner = false,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (spinner)
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: color),
            )
          else if (icon != null)
            Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
