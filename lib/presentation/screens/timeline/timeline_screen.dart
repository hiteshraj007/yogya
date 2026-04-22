import '../../../core/theme/theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/exam_data.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/services/exam_timeline_service.dart';
import '../../../core/services/eligibility_service.dart';
import '../../../data/local/hive_service.dart';
import '../../providers/eligibility_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/remote_data_provider.dart';
import '../../../data/providers/auth_provider.dart';
import 'widgets/deadline_banner.dart';
import 'widgets/timeline_node.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = 'All';
  bool _hidePastEvents = false;
  bool _onlyShowDeadlines = false;
  late AnimationController _ctrl;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  List<Map<String, dynamic>> _filteredEvents(List<Map<String, dynamic>> events) {
    var filtered = events;
    if (_selectedCategory != 'All') {
      filtered = filtered.where((e) {
        final examName = e['examName'] as String;
        switch (_selectedCategory) {
          case 'UPSC': return examName.contains('UPSC');
          case 'SSC': return examName.contains('SSC');
          case 'Banking': return examName.contains('IBPS') || examName.contains('SBI') || examName.contains('RBI');
          case 'Defence': return examName.contains('NDA') || examName.contains('CDS');
          case 'Railways': return examName.contains('RRB');
          default: return true;
        }
      }).toList();
    }
    
    if (_hidePastEvents) {
      filtered = filtered.where((e) => (e['date'] as DateTime).isAfter(DateTime.now().subtract(Duration(days: 1)))).toList();
    }
    
    if (_onlyShowDeadlines) {
      filtered = filtered.where((e) => (e['event'] as String).toLowerCase().contains('deadline')).toList();
    }
    
    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1400),
    );

    _fadeAnims = List.generate(10, (i) {
      return Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _ctrl,
        curve: Interval(
          (i * 0.08).clamp(0.0, 1.0),
          (0.4 + i * 0.08).clamp(0.0, 1.0),
          curve: Curves.easeOut,
        ),
      ));
    });

    _slideAnims = List.generate(10, (i) {
      return Tween<Offset>(
        begin: Offset(0, 0.15),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _ctrl,
        curve: Interval(
          (i * 0.08).clamp(0.0, 1.0),
          (0.4 + i * 0.08).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      ));
    });

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _animItem(int index, Widget child) {
    final i = index.clamp(0, 9);
    return SlideTransition(
      position: _slideAnims[i],
      child: FadeTransition(opacity: _fadeAnims[i], child: child),
    );
  }

  // (nearest deadline now computed inline in build)

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileNotifierProvider).profile;
    final providerEvals = ref.watch(eligibilityProvider).evaluations;
    Set<String> validExamIds;
    
    if (providerEvals.isNotEmpty) {
      validExamIds = providerEvals
          .where((e) => e.status == 'ELIGIBLE' || e.status == 'UPCOMING')
          .map((e) => e.exam.id)
          .toSet();
    } else {
      validExamIds = HiveService.getAllEligibilityResults()
          .where((r) => r.isEligible || r.matchPercent >= 60)
          .map((r) => r.examId)
          .toSet();
    }
    final examKey = examIdsToKey(
      validExamIds.isEmpty ? {'ALL_EXAMS'} : validExamIds,
    );
    final timelineAsync = ref.watch(timelineStreamProvider(examKey));
    final fallbackEvents = ExamTimelineService.instance.timelineEvents(
      prioritizedExamIds: validExamIds.isEmpty ? {'NONE'} : validExamIds,
    );
    final dynamicEvents = timelineAsync.value ?? fallbackEvents;
    final isTimelineSyncing = timelineAsync.isLoading;
    final events = _filteredEvents(dynamicEvents);
    final deadline = events
        .where((e) =>
            e['type'] == 'application_end' &&
            (e['date'] as DateTime).isAfter(DateTime.now()))
        .cast<Map<String, dynamic>>()
        .toList()
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    final currentAge = _profileAge(profile?.dateOfBirth ?? '');
    final attemptSummary = _attemptSummary();
    final projections = profile == null
        ? const <FutureEligibilityProjection>[]
        : EligibilityService.instance.projectFutureEligibility(
            profile: profile,
            docs: HiveService.getAllDocs(uid: ref.read(currentUserProvider)?.uid),
            attemptsByExam: _attemptCountsByExam(),
            examIds: validExamIds.isEmpty ? null : validExamIds,
            allExams: ref.watch(allExamsProvider).value ?? ExamData.allExams,
            yearsAhead: 2,
          );

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Exam Timeline',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (_hidePastEvents || _onlyShowDeadlines) ? context.colors.primary : context.colors.glassWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.colors.glassBorder),
              ),
              child: Icon(Icons.filter_list_rounded,
                  color: (_hidePastEvents || _onlyShowDeadlines) ? Colors.white : context.colors.textPrimary, size: 20),
            ),
            onPressed: _showAdvancedFiltersDialog,
          ),
          SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showLogAttemptDialog,
        backgroundColor: context.colors.primary,
        child: Icon(Icons.add_rounded, color: Colors.white),
        tooltip: 'Log Exam Attempt',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),
              if (isTimelineSyncing)
                _animItem(
                  0,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: context.colors.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.colors.glassBorder),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.colors.primaryLight,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Syncing timeline from live simulation...',
                            style: TextStyle(
                              color: context.colors.textSecondary,
                              fontSize: 12,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (isTimelineSyncing) const SizedBox(height: 10),

              // Deadline banner
              if (deadline.isNotEmpty)
                _animItem(
                  0,
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: DeadlineBanner(
                      examName: deadline.first['examName'],
                      event: deadline.first['event'],
                      date: deadline.first['date'],
                      daysLeft: (deadline.first['date'] as DateTime)
                          .difference(DateTime.now())
                          .inDays,
                    ),
                  ),
                ),

              SizedBox(height: 20),

              // Filter chips
              _animItem(
                1,
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    itemCount: ExamData.examCategories.length,
                    itemBuilder: (context, index) {
                      final cat = ExamData.examCategories[index];
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedCategory = cat);
                          },
                          child: AnimatedContainer(
                            duration: AppAnimations.fast,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? context.colors.primary
                                  : context.colors.bgCard,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? context.colors.primary
                                    : context.colors.glassBorder,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : context.colors.textSecondary,
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Timeline list
              if (events.isEmpty)
                _animItem(
                  2,
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        children: [
                          Icon(Icons.event_busy_rounded,
                              size: 60,
                              color: context.colors.textHint.withValues(alpha: 0.5)),
                          SizedBox(height: 16),
                          Text(
                            'No events in this category',
                            style: TextStyle(
                              color: context.colors.textHint,
                              fontSize: 15,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final isCompleted = event['completed'] as bool;
                      final isFirst = index == 0;
                      final isLast = index == events.length - 1;

                      return _animItem(
                        (index + 2).clamp(0, 9),
                        TimelineNode(
                          examName: event['examName'],
                          eventTitle: event['event'],
                          date: event['date'],
                          isCompleted: isCompleted,
                          isFirst: isFirst,
                          isLast: isLast,
                          eventType: event['type'],
                        ),
                      );
                    },
                  ),
                ),

              SizedBox(height: 20),

              // ── Strategic Overview Card (Section 7.2.5) ───
              _animItem(
                3,
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.colors.glassBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.insights_rounded,
                                color: context.colors.primaryLight, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Strategic Overview',
                              style: TextStyle(
                                color: context.colors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            _buildStratStat('Current Age', '$currentAge yrs'),
                            Container(width: 1, height: 36, color: context.colors.glassBorder),
                            _buildStratStat('Valid Exams', '${events.length}'),
                            Container(width: 1, height: 36, color: context.colors.glassBorder),
                            _buildStratStat('Attempts', attemptSummary),
                          ],
                        ),
                        SizedBox(height: 14),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.tips_and_updates_rounded,
                                  color: context.colors.primaryLight, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _strategyMessage(profile?.primaryExamGoal ?? ''),
                                  style: TextStyle(
                                    color: context.colors.textSecondary,
                                    fontSize: 11,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // ── Future Eligibility Predictions ─────────────
              _animItem(
                4,
                _buildFuturePredictionsCard(projections),
              ),

              SizedBox(height: 20),

              // ── Age Relief Claims ────────────────────────
              _animItem(
                5,
                _buildAgeReliefCard(profile?.category ?? 'General'),
              ),

              SizedBox(height: 100), // padding for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStratStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: context.colors.primaryLight,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: context.colors.textHint,
              fontSize: 10,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturePredictionsCard(
    List<FutureEligibilityProjection> projections,
  ) {
    String message =
        'Complete profile and scan your latest marksheets to unlock year-wise predictions.';

    if (projections.isNotEmpty) {
      final best = projections.first;
      if (best.projectedEligible) {
        final yearSuffix = best.yearsToEligibility == 0
            ? 'this year'
            : 'in ${best.yearsToEligibility} year(s)';
        message =
            'You are projected eligible for ${best.exam.code} by ${best.year} ($yearSuffix). Projected age: ${best.projectedAge}.';
      } else {
        final blocker = best.blockers.isEmpty
            ? 'criteria mismatch'
            : best.blockers.first;
        message =
            'By ${best.year}, ${best.exam.code} still shows: $blocker. Update profile/docs for better projection.';
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.colors.bgCardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_graph_rounded, color: context.colors.eligible, size: 20),
                SizedBox(width: 8),
                Text(
                  'Future Eligibility',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeReliefCard(String category) {
    final normalized = category.trim().toUpperCase();
    String message;
    if (normalized == 'OBC') {
      message =
          'Category OBC: generally 3-year age relaxation applies in exams like UPSC CSE (check latest notification).';
    } else if (normalized == 'SC' || normalized == 'ST') {
      message =
          'Category $normalized: generally 5-year age relaxation applies in exams like UPSC CSE (check latest notification).';
    } else {
      message =
          'General/EWS: standard age limits apply. Keep documents updated to claim any valid relaxations (PwD, ex-servicemen, etc.).';
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.colors.bgCardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_rounded, color: context.colors.partial, size: 20),
                SizedBox(width: 8),
                Text(
                  'Age Relief Claims',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _profileAge(String dob) {
    if (dob.trim().isEmpty) return 0;
    try {
      final p = dob.split('/');
      if (p.length != 3) return 0;
      final birth = DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
      final now = DateTime.now();
      var age = now.year - birth.year;
      if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return 0;
    }
  }

  String _attemptSummary() {
    try {
      final box = Hive.isBoxOpen('attemptHistory')
          ? Hive.box('attemptHistory')
          : null;
      final totalAttempts = box?.values.length ?? 0;
      return '$totalAttempts tracked';
    } catch (_) {
      return '0 tracked';
    }
  }

  Map<String, int> _attemptCountsByExam() {
    final counts = <String, int>{};
    try {
      if (!Hive.isBoxOpen('attemptHistory')) return counts;
      final box = Hive.box('attemptHistory');
      for (final value in box.values) {
        if (value is! Map) continue;
        final record = Map<String, dynamic>.from(value);
        final examId = _resolveExamId((record['exam'] ?? '').toString());
        if (examId == null) continue;
        counts[examId] = (counts[examId] ?? 0) + 1;
      }
    } catch (_) {
      return counts;
    }
    return counts;
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

  String _strategyMessage(String goal) {
    if (goal.trim().isEmpty) {
      return 'Complete profile details and run eligibility check for tailored guidance.';
    }
    return 'Focus on $goal preparation and keep documents updated for faster application flow.';
  }

  void _showAdvancedFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: context.colors.bgCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Advanced Filters', style: TextStyle(color: context.colors.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: Text('Hide Past Events', style: TextStyle(color: context.colors.textPrimary)),
                    value: _hidePastEvents,
                    activeColor: context.colors.primary,
                    onChanged: (val) {
                      setDialogState(() => _hidePastEvents = val);
                      setState(() => _hidePastEvents = val);
                    },
                  ),
                  SwitchListTile(
                    title: Text('Only Show Deadlines', style: TextStyle(color: context.colors.textPrimary)),
                    value: _onlyShowDeadlines,
                    activeColor: context.colors.primary,
                    onChanged: (val) {
                      setDialogState(() => _onlyShowDeadlines = val);
                      setState(() => _onlyShowDeadlines = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close', style: TextStyle(color: context.colors.primary)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showLogAttemptDialog() {
    final examsList = ref.read(allExamsProvider).value ?? ExamData.allExams;
    String selectedExam = examsList.first.id;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: context.colors.bgCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Log Exam Attempt', style: TextStyle(color: context.colors.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select the exam you have recently attempted. This will update your eligibility tracking.',
                    style: TextStyle(color: context.colors.textSecondary, fontSize: 14),
                  ),
                  SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedExam,
                    dropdownColor: context.colors.bgDark,
                    style: TextStyle(color: context.colors.textPrimary),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: context.colors.bgDark,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: examsList.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedExam = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final box = await Hive.openBox('attemptHistory');
                    await box.add({
                      'exam': examsList.firstWhere((e) => e.id == selectedExam).code,
                      'date': DateTime.now().toIso8601String(),
                    });
                    final profile = ref.read(profileNotifierProvider).profile;
                    ref.read(eligibilityProvider.notifier).computeAll(profile, examsList);
                    setState(() {});
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Attempt logged successfully!', style: TextStyle(color: Colors.white)),
                        backgroundColor: context.colors.eligible,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: context.colors.primary),
                  child: Text('Save Attempt', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
