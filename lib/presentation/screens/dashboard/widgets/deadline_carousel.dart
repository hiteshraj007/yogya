import '../../../../core/theme/theme_colors.dart';
import 'package:flutter/material.dart';

class DeadlineCarousel extends StatelessWidget {
  final List<Map<String, dynamic>> deadlines;

  const DeadlineCarousel({super.key, required this.deadlines});

  Color _getUrgencyColor(BuildContext context, String urgency) {
    switch (urgency) {
      case 'high':
        return context.colors.urgencyHigh;
      case 'medium':
        return context.colors.urgencyMedium;
      default:
        return context.colors.urgencyLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20),
        itemCount: deadlines.length,
        itemBuilder: (context, index) {
          final d = deadlines[index];
          final date = d['date'] as DateTime;
          final daysLeft = date.difference(DateTime.now()).inDays;
          final urgencyColor = _getUrgencyColor(context, d['urgency']);

          return Container(
            width: 200,
            margin: EdgeInsets.only(right: index < deadlines.length - 1 ? 12 : 0),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.colors.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: urgencyColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: urgencyColor.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        d['event'],
                        style: TextStyle(
                          color: urgencyColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  d['examName'],
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${date.day}/${date.month}/${date.year}',
                      style: TextStyle(
                        color: context.colors.textHint,
                        fontSize: 11,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: urgencyColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$daysLeft days',
                        style: TextStyle(
                          color: urgencyColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
