import '../../../../core/theme/theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/exam_data.dart';
import '../../../providers/remote_data_provider.dart';

class TimelineNode extends ConsumerStatefulWidget {
  final String examName;
  final String eventTitle;
  final DateTime date;
  final bool isCompleted;
  final bool isFirst;
  final bool isLast;
  final String eventType;

  TimelineNode({
    super.key,
    required this.examName,
    required this.eventTitle,
    required this.date,
    required this.isCompleted,
    required this.isFirst,
    required this.isLast,
    required this.eventType,
  });

  @override
  ConsumerState<TimelineNode> createState() => _TimelineNodeState();
}

class _TimelineNodeState extends ConsumerState<TimelineNode>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  IconData get _icon {
    switch (widget.eventType) {
      case 'notification':
        return Icons.notifications_active_rounded;
      case 'application_start':
        return Icons.edit_calendar_rounded;
      case 'application_end':
        return Icons.timer_off_rounded;
      case 'exam':
        return Icons.school_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  Color get _nodeColor {
    if (widget.isCompleted) return context.colors.eligible;
    final daysLeft = widget.date.difference(DateTime.now()).inDays;
    if (daysLeft <= 0) return context.colors.primary;
    if (daysLeft <= 7) return context.colors.urgencyHigh;
    if (daysLeft <= 30) return context.colors.urgencyMedium;
    return context.colors.primaryLight;
  }

  String get _daysText {
    final diff = widget.date.difference(DateTime.now()).inDays;
    if (diff < 0) return '${-diff}d ago';
    if (diff == 0) return 'Today';
    return '${diff}d left';
  }

  // Find exam info for portal link
  ExamInfo? get _examInfo {
    try {
      final examsList = ref.read(allExamsProvider).value ?? ExamData.allExams;
      return examsList.firstWhere(
        (e) => widget.examName.contains(e.code) || widget.examName.contains(e.name),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nodeColor = _nodeColor;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline connector
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Top line
                if (!widget.isFirst)
                  Container(
                    width: 2,
                    height: 16,
                    color: widget.isCompleted
                        ? context.colors.eligible.withOpacity(0.4)
                        : context.colors.glassBorder,
                  ),
                // Node circle
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: widget.isCompleted
                        ? nodeColor.withOpacity(0.2)
                        : nodeColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: nodeColor, width: 2),
                    boxShadow: widget.isCompleted
                        ? null
                        : [
                            BoxShadow(
                              color: nodeColor.withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ],
                  ),
                  child: Icon(
                    widget.isCompleted ? Icons.check_rounded : _icon,
                    color: nodeColor,
                    size: 16,
                  ),
                ),
                // Bottom line
                if (!widget.isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: widget.isCompleted
                          ? context.colors.eligible.withOpacity(0.4)
                          : context.colors.glassBorder,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 12),
          // Event card — now tappable
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isExpanded
                        ? context.colors.primary.withOpacity(0.4)
                        : widget.isCompleted
                            ? context.colors.eligible.withOpacity(0.2)
                            : context.colors.glassBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.examName,
                            style: TextStyle(
                              color: widget.isCompleted
                                  ? context.colors.textHint
                                  : context.colors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              decoration: widget.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: nodeColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _daysText,
                                style: TextStyle(
                                  color: nodeColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                            SizedBox(width: 6),
                            AnimatedRotation(
                              turns: _isExpanded ? 0.5 : 0,
                              duration: Duration(milliseconds: 200),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: context.colors.textHint,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      widget.eventTitle,
                      style: TextStyle(
                        color: widget.isCompleted
                            ? context.colors.textHint
                            : context.colors.textSecondary,
                        fontSize: 13,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '${widget.date.day}/${widget.date.month}/${widget.date.year}',
                      style: TextStyle(
                        color: context.colors.textHint,
                        fontSize: 11,
                        fontFamily: 'Poppins',
                      ),
                    ),

                    // ── Expanded Details (Section 7.2.5) ───────────
                    if (_isExpanded) ...[
                      Divider(color: context.colors.glassBorder, height: 24),
                      // Eligibility detail rows
                      _buildDetailRow(
                        'Qualification',
                        'Verified',
                        Icons.school_rounded,
                        context.colors.eligible,
                      ),
                      SizedBox(height: 8),
                      _buildDetailRow(
                        'Age Limit',
                        'Within range',
                        Icons.cake_rounded,
                        context.colors.eligible,
                      ),
                      SizedBox(height: 8),
                      _buildDetailRow(
                        'Category',
                        'Applied',
                        Icons.groups_rounded,
                        context.colors.primaryLight,
                      ),
                      // Register Now button
                      if (_examInfo != null && _examInfo!.registrationUrl.isNotEmpty && !widget.isCompleted)
                        Padding(
                          padding: EdgeInsets.only(top: 14),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final url = Uri.parse(_examInfo!.registrationUrl);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url, mode: LaunchMode.externalApplication);
                                }
                              },
                              icon: Icon(Icons.open_in_new_rounded, size: 16),
                              label: Text('Register Now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.colors.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: context.colors.textHint,
            fontSize: 12,
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}
