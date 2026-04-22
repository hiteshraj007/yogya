import '../../../../core/theme/theme_colors.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_animations.dart';

class CategorySelector extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  CategorySelector({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  IconData _getIcon(String category) {
    switch (category) {
      case 'General':
        return Icons.person_rounded;
      case 'OBC':
        return Icons.groups_rounded;
      case 'SC':
        return Icons.diversity_3_rounded;
      case 'ST':
        return Icons.forest_rounded;
      case 'EWS':
        return Icons.account_balance_wallet_rounded;
      case 'PwD':
        return Icons.accessible_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  Color _getColor(BuildContext context, String category) {
    switch (category) {
      case 'General':
        return Color(0xFF6C5CE7);
      case 'OBC':
        return Color(0xFF00B894);
      case 'SC':
        return Color(0xFF0984E3);
      case 'ST':
        return Color(0xFF2ED573);
      case 'EWS':
        return Color(0xFFFDAA5E);
      case 'PwD':
        return Color(0xFFE17055);
      default:
        return context.colors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = selected == cat;
        final color = _getColor(context, cat);
        return GestureDetector(
          onTap: () => onSelect(cat),
          child: AnimatedContainer(
            duration: AppAnimations.fast,
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.15) : context.colors.bgCardLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : context.colors.glassBorder,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getIcon(cat),
                  color: isSelected ? color : context.colors.textHint,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? color : context.colors.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (isSelected) ...[
                  SizedBox(width: 6),
                  Icon(Icons.check_circle_rounded, color: color, size: 14),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
