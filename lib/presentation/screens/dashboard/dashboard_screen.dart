import '../../../core/theme/theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/exam_data.dart';
import '../../../core/services/exam_timeline_service.dart';
import '../../../data/local/hive_service.dart';
import '../../../data/providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/remote_data_provider.dart';
import 'widgets/greeting_header.dart';
import 'widgets/donut_card.dart';
import 'widgets/deadline_carousel.dart';
import 'widgets/quote_card.dart';
import 'widgets/notifications_sheet.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _staggerCtrl;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _fadeAnims = List.generate(7, (i) {
      return Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _staggerCtrl,
        curve: Interval(i * 0.10, 0.4 + i * 0.10, curve: Curves.easeOut),
      ));
    });

    _slideAnims = List.generate(7, (i) {
      return Tween<Offset>(
        begin: Offset(0, 0.15),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _staggerCtrl,
        curve: Interval(i * 0.10, 0.4 + i * 0.10, curve: Curves.easeOutCubic),
      ));
    });

    _staggerCtrl.forward();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  Widget _animItem(int index, Widget child) {
    final i = index.clamp(0, 6);
    return SlideTransition(
      position: _slideAnims[i],
      child: FadeTransition(opacity: _fadeAnims[i], child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quoteIndex = DateTime.now().day % AppStrings.motivationalQuotes.length;
    final profileState = ref.watch(profileNotifierProvider);
    final user = ref.watch(currentUserProvider);
    final cachedResults = HiveService.getAllEligibilityResults();

    final userName = profileState.profile?.name ?? user?.displayName ?? 'Aspirant';
    final firstName = userName.split(' ').first;

    final eligibleExamIds = cachedResults
        .where((r) => r.isEligible)
        .map((r) => r.examId)
        .toSet();
    final examKey = examIdsToKey(
      eligibleExamIds.isEmpty ? {'ALL_EXAMS'} : eligibleExamIds,
    );
    final deadlinesAsync = ref.watch(deadlinesStreamProvider(examKey));
    
    // Fallback removed, direct assignment from stream
    final dynamicDeadlines = deadlinesAsync.value ?? [];
    
    final isLiveSyncing = deadlinesAsync.isLoading;

    int eligibleCount = 0;
    if (cachedResults.isNotEmpty) {
      eligibleCount = cachedResults.where((r) => r.isEligible).length;
    } else if (profileState.profile != null) {
      final p = profileState.profile!;
      int age = 22;
      if (p.dateOfBirth.isNotEmpty) {
        try {
          final parts = p.dateOfBirth.split('/');
          if (parts.length == 3) {
            final dob = DateTime(
                int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
            age = DateTime.now().difference(dob).inDays ~/ 365;
          }
        } catch (_) {}
      }
      final qual = p.qualification.toLowerCase().contains('grad')
          ? 'Graduation'
          : p.qualification.toLowerCase().contains('12')
              ? '12th Pass'
              : p.qualification.toLowerCase().contains('10')
                  ? '10th Pass'
                  : 'Graduation';
      final cat = p.category;

      final examsAsync = ref.watch(allExamsProvider);
      final examsList = examsAsync.value ?? ExamData.allExams;
      for (final exam in examsList) {
        bool ageOk = false;
        if (cat == 'OBC') {
          ageOk = age >= exam.minAge && age <= exam.maxAgeOBC;
        } else if (cat == 'SC' || cat == 'ST') {
          ageOk = age >= exam.minAge && age <= exam.maxAgeSC;
        } else {
          ageOk = age >= exam.minAge && age <= exam.maxAgeGeneral;
        }

        final qualOrder = [
          '10th Pass',
          '12th Pass',
          'Graduation',
          'Post Graduation',
          'PhD'
        ];
        final userQualIdx = qualOrder.indexOf(qual);
        final reqQual = exam.qualification.contains('Graduation')
            ? 'Graduation'
            : exam.qualification.contains('12th')
                ? '12th Pass'
                : '10th Pass';
        final reqIdx = qualOrder.indexOf(reqQual);
        final qualOk = userQualIdx >= reqIdx;

        if (ageOk && qualOk) eligibleCount++;
      }
    }
    final examsAsync = ref.watch(allExamsProvider);
    final totalCount = (examsAsync.value ?? ExamData.allExams).length;

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Header — uses real user name
              _animItem(
                0,
                Column(
                  children: [
                    GreetingHeader(
                      userName: firstName,
                      onMenuTap: () => Scaffold.of(context).openDrawer(),
                      onNotificationTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (context) => Padding(
                            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20),
                            child: const NotificationsSheet(),
                          ),
                        );
                      },
                    ),
                    if (isLiveSyncing)
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
                                'Syncing latest exam deadlines...',
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
                  ],
                ),
              ),

              SizedBox(height: 16),

              // ── Eligibility Alert Banner (Section 7.2.2) ─────
              _animItem(
                1,
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _buildAlertBanner(context, dynamicDeadlines),
                ),
              ),

              SizedBox(height: 20),

              // Eligibility Donut Card
              _animItem(
                2,
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: DonutCard(
                    eligibleCount: eligibleCount,
                    totalCount: totalCount,
                    onTap: () => context.push('/eligibility-engine'),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // ── Scan Marksheet CTA (Section 7.2.2) ──────────
              _animItem(
                3,
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _buildScanCTA(context),
                ),
              ),

              SizedBox(height: 24),

              // Upcoming Deadlines
              _animItem(
                4,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        AppStrings.upcomingDeadlines,
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    DeadlineCarousel(
                      deadlines: dynamicDeadlines,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // ── Recent Document Verified (Section 7.2.2) ────
              _animItem(
                5,
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _buildRecentDocCard(context),
                ),
              ),

              SizedBox(height: 24),

              // Motivational Quote
              _animItem(
                6,
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: QuoteCard(
                    quote: AppStrings.motivationalQuotes[quoteIndex],
                    author: AppStrings.quoteAuthors[quoteIndex],
                  ),
                ),
              ),

              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ── Eligibility Alert Banner ─────────────────────────────
  Widget _buildAlertBanner(
    BuildContext context,
    List<Map<String, dynamic>> deadlines,
  ) {
    if (deadlines.isEmpty) return SizedBox.shrink();
      
    // Find the nearest upcoming deadline
    final now = DateTime.now();
    final upcoming = deadlines
        .where((d) => (d['date'] as DateTime).isAfter(now))
        .toList()
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    if (upcoming.isEmpty) return SizedBox.shrink();

    final nearest = upcoming.first;
    final daysLeft = (nearest['date'] as DateTime).difference(now).inDays;

    return GestureDetector(
      onTap: () => context.push('/eligibility-engine'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFF3E0),
              Color(0xFFFFE0B2),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFCC80)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.colors.partial.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.campaign_rounded, color: Color(0xFFE65100), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You may be eligible for ${nearest['examName']}',
                    style: const TextStyle(
                      color: Color(0xFF4E342E),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    '${nearest['event']} — $daysLeft days left',
                    style: TextStyle(
                      color: Color(0xFF4E342E).withValues(alpha: 0.7),
                      fontSize: 11,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFE65100)),
          ],
        ),
      ),
    );
  }

  // ── Scan Marksheet CTA Card ──────────────────────────────
  Widget _buildScanCTA(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/documents'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: context.colors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: context.colors.primary.withValues(alpha: 0.35),
              blurRadius: 16,
               offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.document_scanner_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scan Marksheet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Upload 10th, 12th or Graduation docs for instant eligibility check',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  // ── Recent Document Verified Card ────────────────────────
  Widget _buildRecentDocCard(BuildContext context) {
    return Container(
       padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.colors.eligible.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                 child: Icon(Icons.verified_rounded,
                     color: context.colors.eligible, size: 22),
               ),
               const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Document',
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      'No documents scanned yet',
                      style: TextStyle(
                        color: context.colors.textHint,
                        fontSize: 11,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: context.colors.eligible.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'VERIFIED',
                  style: TextStyle(
                    color: context.colors.eligible,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
           const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.go('/documents'),
                  child: Container(
                     padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'View Document',
                        style: TextStyle(
                          color: context.colors.primaryLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
               const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.go('/documents'),
                  child: Container(
                     padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: context.colors.bgCardLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.colors.glassBorder),
                    ),
                    child: Center(
                      child: Text(
                        'Update Data',
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
