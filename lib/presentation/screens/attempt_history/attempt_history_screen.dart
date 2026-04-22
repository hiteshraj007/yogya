import '../../../core/theme/theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/exam_data.dart';
import '../../widgets/common/empty_state_widget.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/remote_data_provider.dart';

class AttemptHistoryScreen extends ConsumerStatefulWidget {
  AttemptHistoryScreen({super.key});

  @override
  ConsumerState<AttemptHistoryScreen> createState() => _AttemptHistoryScreenState();
}

class _AttemptHistoryScreenState extends ConsumerState<AttemptHistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Box _attemptsBox;
  List<Map<String, dynamic>> _attempts = [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..forward();
    _loadAttempts();
  }

  Future<void> _loadAttempts() async {
    _attemptsBox = await Hive.openBox('attemptHistory');
    final data = _attemptsBox.values.toList();
    final countByExam = <String, int>{};
    final normalized = <Map<String, dynamic>>[];
    for (final raw in data) {
      final record = Map<String, dynamic>.from(raw as Map);
      final examId = _resolveExamId((record['exam'] ?? '').toString());
      final key = (examId ?? (record['exam'] ?? '').toString().toLowerCase());
      countByExam[key] = (countByExam[key] ?? 0) + 1;
      record['examId'] = examId;
      record['attemptNumber'] = record['attemptNumber'] ?? countByExam[key];
      normalized.add(record);
    }
    setState(() {
      _attempts = normalized;
    });
  }

  Future<void> _saveAttempt(Map<String, dynamic> attempt) async {
    await _attemptsBox.add(attempt);
    _loadAttempts();
  }

  Future<void> _deleteAttempt(int index) async {
    await _attemptsBox.deleteAt(index);
    _loadAttempts();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _getResultColor(String result) {
    switch (result) {
      case 'Qualified':
        return context.colors.eligible;
      case 'Not Qualified':
        return context.colors.ineligible;
      case 'Pending':
        return context.colors.urgencyMedium;
      default:
        return context.colors.textHint;
    }
  }

  IconData _getResultIcon(String result) {
    switch (result) {
      case 'Qualified':
        return Icons.check_circle_rounded;
      case 'Not Qualified':
        return Icons.cancel_rounded;
      case 'Pending':
        return Icons.hourglass_top_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: context.colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Attempt History',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: SafeArea(
        child: _attempts.isEmpty
            ? EmptyStateWidget(
                icon: Icons.history_rounded,
                title: AppStrings.noAttemptsTitle,
                subtitle: AppStrings.noAttemptsSubtitle,
                actionLabel: 'Add Attempt',
                onAction: _showAddAttemptSheet,
              )
            : Column(
                children: [
                  // Summary stats
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _ctrl,
                      curve: Curves.easeOut,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: _buildSummary(),
                    ),
                  ),

                  // Attempts list
                  Expanded(
                    child: ListView.builder(
                      physics: BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _attempts.length,
                      itemBuilder: (context, index) {
                        final attempt = _attempts[index];
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 500 + (index * 150)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: _buildAttemptCard(attempt, index),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAttemptSheet,
        backgroundColor: context.colors.primary,
        elevation: 8,
        child: Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildSummary() {
    final qualified = _attempts.where((a) => a['result'] == 'Qualified').length;
    final pending = _attempts.where((a) => a['result'] == 'Pending').length;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.glassBorder),
      ),
      child: Row(
        children: [
          _buildStatItem('${_attempts.length}', 'Total', context.colors.primary),
          _buildStatDivider(),
          _buildStatItem('$qualified', 'Passed', context.colors.eligible),
          _buildStatDivider(),
          _buildStatItem(
            '${_attempts.length - qualified - pending}',
            'Failed',
            context.colors.ineligible,
          ),
          _buildStatDivider(),
          _buildStatItem('$pending', 'Pending', context.colors.urgencyMedium),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: context.colors.textHint,
              fontSize: 11,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: context.colors.glassBorder,
    );
  }

  Widget _buildAttemptCard(Map<String, dynamic> attempt, int index) {
    final resultColor = _getResultColor(attempt['result'] ?? 'Pending');
    final attemptNumber = (attempt['attemptNumber'] ?? 1).toString();

    return Dismissible(
      key: ValueKey('attempt_$index'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteAttempt(index),
      background: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: context.colors.ineligible.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        child: Icon(Icons.delete_rounded, color: context.colors.ineligible),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colors.glassBorder),
        ),
        child: Row(
          children: [
            // Exam icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: context.colors.bgCardLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  attempt['icon'] ?? '📝',
                  style: TextStyle(fontSize: 22),
                ),
              ),
            ),
            SizedBox(width: 14),
            // Exam info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attempt['exam'] ?? 'Unknown Exam',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.colors.bgCardLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          attempt['stage'] ?? 'Prelims',
                          style: TextStyle(
                            color: context.colors.textHint,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.colors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Attempt #$attemptNumber',
                          style: TextStyle(
                            color: context.colors.primaryLight,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      Text(
                        'Score: ${attempt['score'] ?? 'N/A'}',
                        style: TextStyle(
                          color: context.colors.textHint,
                          fontSize: 11,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Result
            Column(
              children: [
                Icon(_getResultIcon(attempt['result'] ?? 'Pending'),
                    color: resultColor, size: 22),
                SizedBox(height: 2),
                Text(
                  attempt['result'] ?? 'Pending',
                  style: TextStyle(
                    color: resultColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAttemptSheet() {
    final examCtrl = TextEditingController();
    final scoreCtrl = TextEditingController();
    String selectedStage = 'Prelims';
    String selectedResult = 'Pending';

    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.bgCard,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 28,
                right: 28,
                top: 28,
                bottom: MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.colors.glassBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Add Attempt',
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Record your exam attempt details',
                      style: TextStyle(
                        color: context.colors.textHint,
                        fontSize: 13,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 24),

                    // Exam name
                    _buildFormField('Exam Name', examCtrl, 'e.g. UPSC CSE 2026'),

                    SizedBox(height: 16),

                    // Stage selector
                    Text(
                      'Stage',
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['Prelims', 'Mains', 'Interview', 'Tier I', 'Tier II']
                          .map((stage) {
                        final isSelected = selectedStage == stage;
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedStage = stage),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? context.colors.primary.withOpacity(0.15)
                                  : context.colors.bgCardLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? context.colors.primary
                                    : context.colors.glassBorder,
                              ),
                            ),
                            child: Text(
                              stage,
                              style: TextStyle(
                                color: isSelected
                                    ? context.colors.primary
                                    : context.colors.textHint,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 16),

                    // Score
                    _buildFormField('Score', scoreCtrl, 'e.g. 118/200'),

                    SizedBox(height: 16),

                    // Result
                    Text(
                      'Result',
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['Qualified', 'Not Qualified', 'Pending']
                          .map((result) {
                        final isSelected = selectedResult == result;
                        final color = _getResultColor(result);
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedResult = result),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withOpacity(0.15)
                                  : context.colors.bgCardLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? color : context.colors.glassBorder,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getResultIcon(result),
                                    size: 14, color: color),
                                SizedBox(width: 6),
                                Text(
                                  result,
                                  style: TextStyle(
                                    color: isSelected
                                        ? color
                                        : context.colors.textHint,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 28),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (examCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please enter exam name'),
                                backgroundColor: context.colors.ineligible,
                              ),
                            );
                            return;
                          }

                          final examName = examCtrl.text.trim();
                          final examId = _resolveExamId(examName);
                          final nextAttempt =
                              _nextAttemptNumber(examId, examName);
                          String icon = '📝';
                          if (examName.contains('UPSC')) icon = '🏛️';
                          if (examName.contains('SSC')) icon = '📋';
                          if (examName.contains('IBPS') || examName.contains('SBI') || examName.contains('RBI')) icon = '🏦';
                          if (examName.contains('NDA') || examName.contains('CDS') || examName.contains('AFCAT')) icon = '⚔️';
                          if (examName.contains('RRB')) icon = '🚂';

                          _saveAttempt({
                            'exam': examName,
                            'year': '${DateTime.now().year}',
                            'result': selectedResult,
                            'stage': selectedStage,
                            'score': scoreCtrl.text.trim().isNotEmpty
                                ? scoreCtrl.text.trim()
                                : 'N/A',
                            'examId': examId,
                            'attemptNumber': nextAttempt,
                            'icon': icon,
                          });

                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      color: Colors.white, size: 18),
                                  SizedBox(width: 10),
                                  Text(
                                    'Attempt saved!',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: context.colors.eligible,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Save Attempt',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFormField(
      String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(
            color: context.colors.textPrimary,
            fontFamily: 'Poppins',
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: context.colors.textHint,
              fontSize: 13,
            ),
            filled: true,
            fillColor: context.colors.bgCardLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.colors.glassBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.colors.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.colors.primary),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  String? _resolveExamId(String examName) {
    final lower = examName.toLowerCase().trim();
    if (lower.isEmpty) return null;
    final examsList = ref.read(allExamsProvider).value ?? ExamData.allExams;
    for (final exam in examsList) {
      if (lower.contains(exam.code.toLowerCase()) ||
          lower.contains(exam.name.toLowerCase())) {
        return exam.id;
      }
    }
    return null;
  }

  int _nextAttemptNumber(String? examId, String examName) {
    final key = (examId ?? examName.toLowerCase().trim());
    final count = _attempts.where((a) {
      final existingKey = ((a['examId'] ?? a['exam'] ?? '')
              .toString()
              .toLowerCase()
              .trim());
      return existingKey == key;
    }).length;
    return count + 1;
  }
}
