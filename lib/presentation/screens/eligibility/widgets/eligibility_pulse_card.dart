import '../../../../core/theme/theme_colors.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import 'criteria_breakdown.dart';

class EligibilityPulseCard extends StatefulWidget {
  final String examName;
  final String examCode;
  final bool isEligible;
  final Map<String, bool> criteria;
  final int attemptsUsed;
  final int attemptsAllowed;

  EligibilityPulseCard({
    super.key,
    required this.examName,
    required this.examCode,
    required this.isEligible,
    required this.criteria,
    required this.attemptsUsed,
    required this.attemptsAllowed,
  });

  @override
  State<EligibilityPulseCard> createState() => _EligibilityPulseCardState();
}

class _EligibilityPulseCardState extends State<EligibilityPulseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    if (widget.isEligible) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor =
        widget.isEligible ? context.colors.eligible : context.colors.ineligible;

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: statusColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Pulse indicator
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, child) {
                    return Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor.withOpacity(0.15),
                        boxShadow: widget.isEligible
                            ? [
                                BoxShadow(
                                  color: statusColor
                                      .withOpacity(0.2 * _pulse.value),
                                  blurRadius: 12 * _pulse.value,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        widget.isEligible
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: statusColor,
                        size: 24,
                      ),
                    );
                  },
                ),
                SizedBox(width: 14),
                // Exam info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.examCode,
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        widget.examName,
                        style: TextStyle(
                          color: context.colors.textHint,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Attempts badge
                if (widget.isEligible)
                  Container(
                    margin: EdgeInsets.only(right: 8),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.attemptsAllowed == -1
                          ? '∞ Left'
                          : '${widget.attemptsAllowed - widget.attemptsUsed} Left',
                      style: TextStyle(
                        color: context.colors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                // Status badge
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.isEligible ? 'Eligible' : 'Not Eligible',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: context.colors.textHint,
                  size: 20,
                ),
              ],
            ),
            // Expandable criteria
            AnimatedCrossFade(
              firstChild: SizedBox.shrink(),
              secondChild: Padding(
                padding: EdgeInsets.only(top: 16),
                child: CriteriaBreakdown(criteria: widget.criteria),
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }
}
