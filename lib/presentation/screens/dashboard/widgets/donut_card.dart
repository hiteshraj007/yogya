import '../../../../core/theme/theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DonutCard extends StatefulWidget {
  final int eligibleCount;
  final int totalCount;
  final VoidCallback? onTap;

  DonutCard({
    super.key,
    required this.eligibleCount,
    required this.totalCount,
    this.onTap,
  });

  @override
  State<DonutCard> createState() => _DonutCardState();
}

class _DonutCardState extends State<DonutCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double get percentage =>
      widget.totalCount > 0 ? (widget.eligibleCount / widget.totalCount * 100) : 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: context.colors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: context.colors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Donut chart
            SizedBox(
              width: 100,
              height: 100,
              child: AnimatedBuilder(
                animation: _anim,
                builder: (context, _) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 32,
                          startDegreeOffset: -90,
                          sections: [
                            PieChartSectionData(
                              value: widget.eligibleCount * _anim.value,
                              color: Colors.white,
                              radius: 14,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: (widget.totalCount - widget.eligibleCount) *
                                      _anim.value +
                                  (widget.totalCount * (1 - _anim.value)),
                              color: Colors.white.withOpacity(0.2),
                              radius: 14,
                              showTitle: false,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${(percentage * _anim.value).toInt()}%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ELIGIBILITY OVERVIEW',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '${widget.eligibleCount} of ${widget.totalCount} Exams',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'You are eligible for',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                      ],
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
