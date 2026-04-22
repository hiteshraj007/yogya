import '../../../core/theme/theme_colors.dart';
import 'package:flutter/material.dart';
import '../../widgets/common/app_button.dart';
import 'widgets/wizard_step.dart';
import 'widgets/eligibility_pulse_card.dart';
import '../../../core/services/report_service.dart';
import '../../../core/services/ocr_service.dart';
import '../../../core/services/eligibility_service.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/profile_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../providers/eligibility_provider.dart';
import '../../providers/remote_data_provider.dart';
import '../../../core/constants/exam_data.dart';

class EligibilityScreen extends ConsumerStatefulWidget {
  const EligibilityScreen({super.key});

  @override
  ConsumerState<EligibilityScreen> createState() => _EligibilityScreenState();
}

class _EligibilityScreenState extends ConsumerState<EligibilityScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;

  late AnimationController _stepCtrl;
  late Animation<double> _stepFade;
  late AnimationController _resultCtrl;

  int _calculateAge(String dob) {
    if (dob.trim().isEmpty) return 0;
    try {
      final parts = dob.split('/');
      if (parts.length != 3) return 0;
      final birth =
          DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      final now = DateTime.now();
      var age = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return 0;
    }
  }

  Map<String, String> _profileSnapshot() {
    final profile = ref.read(profileNotifierProvider).profile;
    if (profile == null) {
      return {
        'age': '0',
        'category': 'General',
        'qualification': 'Unknown',
      };
    }
    return {
      'age': _calculateAge(profile.dateOfBirth).toString(),
      'category': profile.category,
      'qualification':
          profile.qualification.isEmpty ? 'Unknown' : profile.qualification,
    };
  }

  @override
  void initState() {
    super.initState();
    _stepCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _stepFade = CurvedAnimation(parent: _stepCtrl, curve: Curves.easeOut);
    _stepCtrl.forward();

    _resultCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _stepCtrl.dispose();
    _resultCtrl.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    if (_currentStep == 0) {
      final profile = ref.read(profileNotifierProvider).profile;
      if (profile == null || profile.dateOfBirth.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please complete your profile to check eligibility.',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
              ),
              backgroundColor: context.colors.ineligible,
            ),
          );
        }
        return;
      }

      final allExams = await ref.read(allExamsProvider.future).catchError((_) => ExamData.allExams);
      await ref.read(eligibilityProvider.notifier).computeAll(profile, allExams);

      final eligState = ref.read(eligibilityProvider);
      if (eligState.errorMessage != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(eligState.errorMessage!),
              backgroundColor: context.colors.ineligible,
            ),
          );
        }
        return;
      }

      setState(() => _currentStep = 1);
      _stepCtrl.reset();
      _stepCtrl.forward();
      _resultCtrl.forward(from: 0);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _stepCtrl.reset();
      _stepCtrl.forward();
      if (_currentStep < 1) {
        _resultCtrl.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eligState = ref.watch(eligibilityProvider);
    final isChecking = eligState.isLoading;

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
          'Eligibility Engine',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step indicator
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              child: WizardStepIndicator(
                currentStep: _currentStep,
                steps: ['Verify Details', 'Results'],
              ),
            ),

            // Content
            Expanded(
              child: FadeTransition(
                opacity: _stepFade,
                child: _buildStepContent(eligState),
              ),
            ),

            // Bottom buttons
            if (_currentStep < 1 || isChecking)
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: AppButton(
                          label: 'Back',
                          onPressed: _prevStep,
                          isOutlined: true,
                        ),
                      ),
                    if (_currentStep > 0) SizedBox(width: 16),
                    if (_currentStep == 0)
                      Expanded(
                        flex: 1,
                        child: AppButton(
                          label: 'Check Eligibility',
                          onPressed: () {
                              _nextStep();
                          },
                          isLoading: isChecking,
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

  Widget _buildStepContent(EligibilityState eligState) {
    switch (_currentStep) {
      case 0:
        return _buildVerifyDetails();
      case 1:
        return _buildResults(eligState);
      default:
        return SizedBox();
    }
  }

  // Step 2: Verify Details
  Widget _buildVerifyDetails() {
    final profile = ref.watch(profileNotifierProvider).profile;
    bool needsProfile = profile == null || profile.dateOfBirth.isEmpty;
    
    if (needsProfile) {
       return Center(
         child: Padding(
           padding: EdgeInsets.symmetric(horizontal: 20),
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Icon(Icons.person_off_rounded, size: 60, color: context.colors.textHint),
               SizedBox(height: 16),
               Text(
                 'Profile Incomplete',
                 style: TextStyle(color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
               ),
               SizedBox(height: 8),
               Text(
                 'You must enter your details first to automatically generate the list of exams you are eligible for.',
                 textAlign: TextAlign.center,
                 style: TextStyle(color: context.colors.textSecondary, fontSize: 14, fontFamily: 'Poppins'),
               ),
               SizedBox(height: 24),
               AppButton(
                 label: 'Complete Profile',
                 icon: Icons.edit_rounded,
                 onPressed: () {
                   Navigator.of(context).pop();
                   context.push('/profile');
                 },
               ),
             ],
           ),
         ),
       );
    }

    final snapshot = _profileSnapshot();
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          Text(
            'Verify your details to check eligibility',
            style: TextStyle(
              color: context.colors.textHint,
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 20),
          _buildVerifyField(
              'Age', '${snapshot['age']} years', Icons.cake_rounded),
          _buildVerifyField(
              'Date of Birth', profile.dateOfBirth.isEmpty ? '—' : profile.dateOfBirth, Icons.calendar_today_rounded),
          _buildVerifyField(
              'Category', snapshot['category'] ?? 'General', Icons.groups_rounded),
          _buildVerifyField('Qualification', snapshot['qualification'] ?? 'Unknown',
              Icons.school_rounded),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildVerifyField(String label, String value, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: context.colors.primaryLight, size: 20),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: context.colors.textHint,
                    fontSize: 11,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          // Display-only — no edit action
          Icon(Icons.info_outline_rounded, color: context.colors.textHint.withValues(alpha: 0.4), size: 16),
        ],
      ),
    );
  }

  // Step 3: Results
  Widget _buildResults(EligibilityState eligState) {
    if (eligState.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: context.colors.primary),
            SizedBox(height: 20),
            Text(
              'Checking eligibility...',
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 15,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      );
    }

    final evaluations = eligState.evaluations;
    if (evaluations.isEmpty) {
      return Center(
        child: Text(
          'No results yet. Tap "Check Eligibility" first.',
          style: TextStyle(
            color: context.colors.textHint,
            fontSize: 14,
            fontFamily: 'Poppins',
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(height: 8),
          // Summary
          _buildResultSummary(evaluations),
          SizedBox(height: 20),
          // Individual results
          ...evaluations.asMap().entries.map((entry) {
            final index = entry.key;
            final evaluation = entry.value;
            final primaryGoal = eligState.primaryGoal;
            final isGoalMatch = primaryGoal.isNotEmpty &&
                (evaluation.exam.name.toLowerCase().contains(primaryGoal.toLowerCase()) ||
                 evaluation.exam.code.toLowerCase().contains(primaryGoal.toLowerCase()) ||
                 primaryGoal.toLowerCase().contains(evaluation.exam.code.toLowerCase()));

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 600 + (index * 200)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Stack(
                children: [
                  EligibilityPulseCard(
                    examName: evaluation.exam.name,
                    examCode: evaluation.exam.code,
                    status: evaluation.status,
                    criteria: evaluation.criteria,
                    attemptsUsed: evaluation.attemptsUsed,
                    attemptsAllowed: evaluation.attemptsAllowed,
                  ),
                  if (isGoalMatch)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: context.colors.eligible.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.colors.eligible.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, size: 11, color: context.colors.eligible),
                            SizedBox(width: 4),
                            Text('Your Goal', style: TextStyle(
                              color: context.colors.eligible,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            )),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
          SizedBox(height: 12),
          if (evaluations.any((e) => e.isEligible))
            _buildNextStepsCard(
              evaluations.firstWhere((e) => e.isEligible),
            ),
          SizedBox(height: 20),
          AppButton(
            label: 'Download PDF Report',
            icon: Icons.picture_as_pdf_rounded,
            onPressed: () async {
              if (evaluations.isNotEmpty) {
                final profileState = ref.read(profileNotifierProvider);
                final user = ref.read(currentUserProvider);

                final realName =
                    profileState.profile?.name ?? user?.displayName ?? 'Aspirant';
                final realDob = profileState.profile?.dateOfBirth ?? '';
                final realQual = profileState.profile?.qualification ?? '';
                final realCategory = profileState.profile?.category ?? 'General';
                final realAgg = profileState.profile?.percentage ?? '';

                List<Map<String, dynamic>> examResults = [];
                for (final eval in evaluations) {
                  examResults.add({
                    'examName': eval.exam.name,
                    'isEligible': eval.isEligible,
                    'missingCriteria': eval.missingCriteria,
                  });
                }

                await ReportService.instance.generateAndSavePdf(
                  userName: realName,
                  ocrResult: OcrResult(
                    success: true,
                    rawText: '',
                    docType: realQual,
                    aggregate: realAgg,
                    stream: realCategory,
                    dateOfBirth: realDob,
                  ),
                  examResults: examResults,
                );
              }
            },
          ),
          SizedBox(height: 16),
          AppButton(
            label: 'Back to Dashboard',
            onPressed: () => Navigator.of(context).pop(),
            icon: Icons.dashboard_rounded,
            isOutlined: true,
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildNextStepsCard(EligibilityEvaluation evaluation) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Next Steps - ${evaluation.exam.code}',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 10),
          ...evaluation.nextSteps.take(4).map(
            (step) => Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 14, color: context.colors.eligible),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step,
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSummary(List<EligibilityEvaluation> evaluations) {
    final eligible = evaluations.where((e) => e.isEligible).length;
    final total = evaluations.length;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: eligible == total
            ? context.colors.eligibleGradient
            : eligible > 0
                ? context.colors.amberGradient
                : context.colors.ineligibleGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (eligible == total
                    ? context.colors.eligible
                    : eligible > 0
                        ? context.colors.partial
                        : context.colors.ineligible)
                .withValues(alpha: 0.3),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              eligible == total
                  ? Icons.celebration_rounded
                  : eligible > 0
                      ? Icons.info_outline_rounded
                      : Icons.warning_amber_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Eligible for $eligible of $total exams',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  eligible == total
                      ? 'Congratulations! You meet all criteria!'
                      : 'Check details below',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
