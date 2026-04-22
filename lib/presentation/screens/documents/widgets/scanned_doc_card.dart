import '../../../../core/theme/theme_colors.dart';
import 'package:flutter/material.dart';

class ScannedDocCard extends StatelessWidget {
  final String name;
  final String type;
  final String date;
  final String status;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ScannedDocCard({
    super.key,
    required this.name,
    required this.type,
    required this.date,
    required this.status,
    required this.icon,
    required this.onTap,
    required this.onDelete,
  });

  Color _getStatusColor(BuildContext context) {
    switch (status) {
      case 'Verified':
        return context.colors.eligible;
      case 'Processing':
        return context.colors.urgencyMedium;
      case 'Needs Review':
        return context.colors.urgencyHigh;
      default:
        return context.colors.textHint;
    }
  }

  IconData get _statusIcon {
    switch (status) {
      case 'Verified':
        return Icons.check_circle_rounded;
      case 'Processing':
        return Icons.hourglass_top_rounded;
      case 'Needs Review':
        return Icons.error_outline_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colors.glassBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: context.colors.primaryLight, size: 26),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Type badge
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.colors.bgCardLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: context.colors.textHint,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                       const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          date,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.colors.textHint,
                            fontSize: 11,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Status
            SizedBox(
              width: 80,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(_statusIcon, color: _getStatusColor(context), size: 20),
                   const SizedBox(height: 4),
                  Text(
                    status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _getStatusColor(context),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
