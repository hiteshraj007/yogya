import '../../../../core/theme/theme_colors.dart';
import 'package:flutter/material.dart';

class CriteriaBreakdown extends StatelessWidget {
  final Map<String, bool> criteria;

  CriteriaBreakdown({
    super.key,
    required this.criteria,
  });

  IconData _getIcon(String key) {
    switch (key) {
      case 'Age':
        return Icons.cake_rounded;
      case 'Qualification':
        return Icons.school_rounded;
      case 'Attempts':
        return Icons.refresh_rounded;
      case 'Nationality':
        return Icons.flag_rounded;
      case 'Category':
        return Icons.groups_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.bgCardLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: criteria.entries.map((entry) {
          final isOk = entry.value;
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  _getIcon(entry.key),
                  color: isOk ? context.colors.eligible : context.colors.ineligible,
                  size: 18,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isOk
                        ? context.colors.eligible.withOpacity(0.12)
                        : context.colors.ineligible.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOk
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: isOk
                            ? context.colors.eligible
                            : context.colors.ineligible,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        isOk ? 'Pass' : 'Fail',
                        style: TextStyle(
                          color: isOk
                              ? context.colors.eligible
                              : context.colors.ineligible,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
