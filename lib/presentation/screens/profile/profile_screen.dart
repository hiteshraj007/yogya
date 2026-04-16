import '../../../core/theme/theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/exam_data.dart';
import '../../../core/constants/app_animations.dart';
import '../../../data/providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import 'widgets/category_selector.dart';
import 'package:go_router/go_router.dart';

// â”€â”€ Change 1: ConsumerStatefulWidget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class ProfileScreen extends ConsumerStatefulWidget {
  ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

// â”€â”€ Change 2: ConsumerState â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _qualCtrl = TextEditingController();
  final _tenthBoardCtrl = TextEditingController();
  final _tenthYearCtrl = TextEditingController();
  final _tenthPercentCtrl = TextEditingController();
  final _twelfthBoardCtrl = TextEditingController();
  final _twelfthYearCtrl = TextEditingController();
  final _twelfthPercentCtrl = TextEditingController();
  final _gradCourseCtrl = TextEditingController();
  final _gradUniCtrl = TextEditingController();
  final _gradYearCtrl = TextEditingController();
  final _gradPercentCtrl = TextEditingController();
  final _uniCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _percentCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _examGoalCtrl = TextEditingController();
  
  String _gradStatus = 'Pursuing';

  String _selectedCategory = 'General';
  String _selectedGender = 'Male';
  bool _isLoading = false;

  late AnimationController _ctrl;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  @override
  // void initState() {
  //   super.initState();

  //   _ctrl = AnimationController(
  //     vsync:    this,
  //     duration: Duration(milliseconds: 1500),
  //   );

  //   _fadeAnims = List.generate(6, (i) {
  //     return Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
  //       parent: _ctrl,
  //       curve: Interval(i * 0.12, 0.5 + i * 0.1, curve: Curves.easeOut),
  //     ));
  //   });

  //   _slideAnims = List.generate(6, (i) {
  //     return Tween<Offset>(
  //       begin: Offset(0, 0.15),
  //       end:   Offset.zero,
  //     ).animate(CurvedAnimation(
  //       parent: _ctrl,
  //       curve: Interval(i * 0.12, 0.5 + i * 0.1, curve: Curves.easeOutCubic),
  //     ));
  //   });

  //   _ctrl.forward();

  //   // â”€â”€ Hive se saved profile load karo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     _loadSavedProfile();
  //   });
  // }
  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _fadeAnims = List.generate(6, (i) {
      return Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _ctrl,
        curve: Interval(i * 0.12, 0.5 + i * 0.1, curve: Curves.easeOut),
      ));
    });

    _slideAnims = List.generate(6, (i) {
      return Tween<Offset>(
        begin: Offset(0, 0.15),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _ctrl,
        curve: Interval(i * 0.12, 0.5 + i * 0.1, curve: Curves.easeOutCubic),
      ));
    });

    _ctrl.forward();

    // â”€â”€ Pehle load karo, phir fields fill karo â”€â”€
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await ref.read(profileNotifierProvider.notifier).loadProfile(user.uid);
      }
      _loadSavedProfile();
    });
  }

  // â”€â”€ Hive se data load karke fields fill karo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _loadSavedProfile() {
    final user = ref.read(currentUserProvider);
    final profile = ref.read(profileNotifierProvider).profile;

    if (profile != null) {
      // Saved profile hai â€” fields fill karo
      _nameCtrl.text = profile.name;
      _emailCtrl.text = profile.email;
      _phoneCtrl.text = profile.phone;
      _dobCtrl.text = profile.dateOfBirth;

      if (profile.graduationStatus == 'Pursuing' && !profile.qualification.toLowerCase().contains('pursuing')) {
          _qualCtrl.text = '${profile.qualification} (Pursuing)';
      } else {
          _qualCtrl.text = profile.qualification;
      }
      
      _uniCtrl.text = profile.university;
      _yearCtrl.text = profile.passingYear;
      _percentCtrl.text = profile.percentage;
      _stateCtrl.text = profile.stateOfDomicile;
      _examGoalCtrl.text = profile.primaryExamGoal;
      setState(() {
        _selectedGender = profile.gender;
        _gradStatus = profile.graduationStatus.isNotEmpty ? profile.graduationStatus : 'Pursuing';
      });

      // 10th Info
      _tenthBoardCtrl.text = profile.tenthBoard;
      _tenthYearCtrl.text = profile.tenthYear;
      _tenthPercentCtrl.text = profile.tenthPercentage;

      // 12th Info
      _twelfthBoardCtrl.text = profile.twelfthBoard;
      _twelfthYearCtrl.text = profile.twelfthYear;
      _twelfthPercentCtrl.text = profile.twelfthPercentage;

      // Grad Info
      _gradCourseCtrl.text = profile.gradCourse;
      _gradUniCtrl.text = profile.gradUniversity;
      _gradYearCtrl.text = profile.gradYear;
      _gradPercentCtrl.text = profile.gradPercentage;
    } else if (user != null) {
      // Pehli baar â€” Firebase user se basic info lo
      _nameCtrl.text = user.displayName ?? '';
      _emailCtrl.text = user.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _percentCtrl.dispose();
    _tenthBoardCtrl.dispose();
    _tenthYearCtrl.dispose();
    _tenthPercentCtrl.dispose();
    _twelfthBoardCtrl.dispose();
    _twelfthYearCtrl.dispose();
    _twelfthPercentCtrl.dispose();
    _gradCourseCtrl.dispose();
    _gradUniCtrl.dispose();
    _gradYearCtrl.dispose();
    _gradPercentCtrl.dispose();
    _stateCtrl.dispose();
    _examGoalCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  String _computeHighestQual() {
    if (_gradStatus == 'Completed' && _gradCourseCtrl.text.isNotEmpty) {
      return 'Graduation';
    }
    if (_twelfthBoardCtrl.text.isNotEmpty) {
      return '12th Pass';
    }
    if (_tenthBoardCtrl.text.isNotEmpty) {
      return '10th Pass';
    }
    return 'Not Specified';
  }

  Widget _buildSubHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.colors.primary.withOpacity(0.7)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.colors.textPrimary.withOpacity(0.8),
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildDisabledField({required String label, required String value, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.bgCardLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: context.colors.textSecondary, fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: context.colors.primary),
                const SizedBox(width: 8),
              ],
              Text(
                value.isEmpty ? 'Not set' : value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: value.isEmpty ? context.colors.textSecondary : context.colors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Graduation Status',
          style: TextStyle(fontSize: 12, color: context.colors.textSecondary, fontFamily: 'Poppins'),
        ),
        const SizedBox(height: 8),
        Row(
          children: ['Pursuing', 'Completed'].map((s) {
            final isSelected = _gradStatus == s;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _gradStatus = s),
                child: Container(
                  margin: EdgeInsets.only(right: s == 'Pursuing' ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? context.colors.primary.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? context.colors.primary : context.colors.glassBorder),
                  ),
                  child: Center(
                    child: Text(
                      s,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? context.colors.primary : context.colors.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _animItem(int index, Widget child) {
    final i = index.clamp(0, 5);
    return SlideTransition(
      position: _slideAnims[i],
      child: FadeTransition(opacity: _fadeAnims[i], child: child),
    );
  }

  // â”€â”€ Save button action â€” real Hive save â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _handleSave() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);

    await ref.read(profileNotifierProvider.notifier).saveProfile(
          uid: user.uid,
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          category: _selectedCategory,
          gender: _selectedGender,
          dateOfBirth: _dobCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          stateOfDomicile: _stateCtrl.text.trim(),
          primaryExamGoal: _examGoalCtrl.text.trim(),
          tenthBoard: _tenthBoardCtrl.text.trim(),
          tenthYear: _tenthYearCtrl.text.trim(),
          tenthPercentage: _tenthPercentCtrl.text.trim(),
          twelfthBoard: _twelfthBoardCtrl.text.trim(),
          twelfthYear: _twelfthYearCtrl.text.trim(),
          twelfthPercentage: _twelfthPercentCtrl.text.trim(),
          gradCourse: _gradCourseCtrl.text.trim(),
          gradUniversity: _gradUniCtrl.text.trim(),
          gradYear: _gradYearCtrl.text.trim(),
          gradPercentage: _gradPercentCtrl.text.trim(),
          graduationStatus: _gradStatus,
        );

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text(
                'Profile saved successfully!',
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
    }
  }

  @override
  Widget build(BuildContext context) {
    // Profile state watch karo
    final profileState = ref.watch(profileNotifierProvider);
    final user = ref.watch(currentUserProvider);

    // Completion percentage
    final completion = profileState.profile?.profileCompletion ?? 0;

    // Display name aur email
    final displayName =
        profileState.profile?.name ?? user?.displayName ?? 'Aspirant';
    final displayEmail = profileState.profile?.email ?? user?.email ?? '';

    // Initials for avatar
    final initials = displayName.isNotEmpty
        ? displayName
            .trim()
            .split(' ')
            .map((e) => e[0])
            .take(2)
            .join()
            .toUpperCase()
        : 'YG';

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            children: [
              // â”€â”€ Profile Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _animItem(
                0,
                _buildProfileHeader(
                  initials: initials,
                  name: displayName,
                  email: displayEmail,
                  completion: completion,
                ),
              ),

              SizedBox(height: 24),

              // â”€â”€ Personal Info â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _animItem(
                1,
                _buildSection(
                  'Personal Information',
                  Icons.person_outline_rounded,
                  [
                    AppTextField(
                      label: 'Full Name',
                      controller: _nameCtrl,
                      prefixIcon: Icons.person_rounded,
                    ),
                    SizedBox(height: 16),
                    AppTextField(
                      label: 'Date of Birth',
                      controller: _dobCtrl,
                      hintText: 'DD/MM/YYYY',
                      prefixIcon: Icons.calendar_today_rounded,
                    ),
                    SizedBox(height: 16),
                    _buildGenderSelector(),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // â”€â”€ Category â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _animItem(
                2,
                _buildSection(
                  'Category',
                  Icons.category_rounded,
                  [
                    CategorySelector(
                      categories: ExamData.userCategories,
                      selected: _selectedCategory,
                      onSelect: (cat) =>
                          setState(() => _selectedCategory = cat),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // â”€â”€ Academic Info â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _animItem(
                3,
                _buildSection(
                  'Academic Information',
                  Icons.school_outlined,
                  [
                    // Computed Highest Qualification (Read Only)
                    _buildDisabledField(
                      label: 'Highest Qualification',
                      value: _computeHighestQual(),
                      icon: Icons.workspace_premium_rounded,
                    ),
                    
                    const SizedBox(height: 24),
                    _buildSubHeader('10th Standard', Icons.looks_one_rounded),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildDisabledField(label: 'Board', value: _tenthBoardCtrl.text)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDisabledField(label: 'Year', value: _tenthYearCtrl.text)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDisabledField(label: 'Percentage', value: _tenthPercentCtrl.text),

                    const SizedBox(height: 24),
                    _buildSubHeader('12th Standard', Icons.looks_two_rounded),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Board',
                      controller: _twelfthBoardCtrl,
                      prefixIcon: Icons.account_balance_rounded,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Year',
                            controller: _twelfthYearCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            label: 'Percentage',
                            controller: _twelfthPercentCtrl,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _buildSubHeader('Graduation (College)', Icons.school_rounded),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Course',
                      controller: _gradCourseCtrl,
                      prefixIcon: Icons.book_rounded,
                      hintText: 'e.g. B.Tech, B.Sc',
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'University',
                      controller: _gradUniCtrl,
                      prefixIcon: Icons.account_balance_rounded,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Year',
                            controller: _gradYearCtrl,
                            keyboardType: TextInputType.number,
                            hintText: 'Passing/Exp. Year',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            label: 'CGPA / Percentage',
                            controller: _gradPercentCtrl,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStatusSelector(),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // â”€â”€ Academic Documents (Phase 3) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _animItem(
                3,
                _buildSection(
                  'Academic Documents',
                  Icons.folder_shared_outlined,
                  [
                    _buildDocUploadCard('10th Marksheet', true, profileState),
                    SizedBox(height: 12),
                    _buildDocUploadCard('12th Marksheet', false, profileState),
                    SizedBox(height: 12),
                    _buildDocUploadCard('Graduation Degree', false, profileState),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // â”€â”€ Contact Info â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _animItem(
                4,
                _buildSection(
                  'Contact Information',
                  Icons.phone_outlined,
                  [
                    AppTextField(
                      label: 'Email',
                      controller: _emailCtrl,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 16),
                    AppTextField(
                      label: 'Phone',
                      controller: _phoneCtrl,
                      prefixIcon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // â”€â”€ Additional Info (Section 9.1) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _animItem(
                5,
                _buildSection(
                  'Additional Information',
                  Icons.info_outline_rounded,
                  [
                    AppTextField(
                      label: 'State of Domicile',
                      controller: _stateCtrl,
                      prefixIcon: Icons.location_on_rounded,
                    ),
                    SizedBox(height: 16),
                    AppTextField(
                      label: 'Primary Exam Goal',
                      controller: _examGoalCtrl,
                      hintText: 'e.g. UPSC CSE, SSC CGL',
                      prefixIcon: Icons.flag_rounded,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // â”€â”€ Check Eligibility Button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _animItem(
                5,
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: AppButton(
                    label: 'Check My Eligibility',
                    onPressed: () => context.push('/eligibility-engine'),
                    icon: Icons.verified_rounded,
                  ),
                ),
              ),

              SizedBox(height: 16),

              // â”€â”€ Save Button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _animItem(
                5,
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: AppButton(
                    label: 'Save Profile',
                    onPressed: _handleSave,
                    isLoading: _isLoading,
                    icon: Icons.save_rounded,
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

  // â”€â”€ Profile Header widget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildProfileHeader({
    required String initials,
    required String name,
    required String email,
    required int completion,
  }) {
    return Container(
      padding: EdgeInsets.all(24),
      margin: EdgeInsets.all(20),
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
          // Avatar with real initials
          Stack(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  color: Colors.white.withOpacity(0.2),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: 14,
                    color: context.colors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Real name from Hive/Firebase
                Text(
                  name,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                // Real email
                Text(
                  email,
                  style: TextStyle(
                    color: context.colors.textPrimary.withOpacity(0.7),
                    fontSize: 13,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 8),
                // Real completion bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: completion / 100,
                          backgroundColor: context.colors.primary.withOpacity(0.2),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(context.colors.primary),
                          minHeight: 5,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '$completion%',
                      style: TextStyle(
                        color: context.colors.textPrimary.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: EdgeInsets.all(20),
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
                Icon(icon, color: context.colors.primaryLight, size: 20),
                SizedBox(width: 10),
                Text(
                  title,
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
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: context.colors.textSecondary,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: ['Male', 'Female', 'Other'].map((g) {
            final isSelected = _selectedGender == g;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedGender = g),
                child: AnimatedContainer(
                  duration: AppAnimations.fast,
                  margin: EdgeInsets.only(right: g != 'Other' ? 8 : 0),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.colors.primary.withOpacity(0.15)
                        : context.colors.bgCardLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? context.colors.primary
                          : context.colors.glassBorder,
                    ),
                  ),
                  child: Text(
                    g,
                    style: TextStyle(
                      color: isSelected
                          ? context.colors.primary
                          : context.colors.textSecondary,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDocUploadCard(String title, bool isCompulsory, ProfileState state) {
    // If the qualification contains 10th/12th/Grad, we assume it's "verified" based on the doc loaded from OCR
    bool isVerified = false;
    if (state.profile?.qualification != null) {
      if (title.contains('10') && state.profile!.qualification.contains('10')) isVerified = true;
      if (title.contains('12') && state.profile!.qualification.contains('12')) isVerified = true;
      if (title.contains('Grad') && state.profile!.qualification.contains('Grad')) isVerified = true;
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.bgDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isVerified ? context.colors.eligible.withOpacity(0.15) : context.colors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isVerified ? Icons.check_circle_rounded : Icons.insert_drive_file_rounded,
              color: isVerified ? context.colors.eligible : context.colors.primaryLight,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCompulsory) ...[
                      SizedBox(width: 6),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.colors.ineligible.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('COMPULSORY', style: TextStyle(color: context.colors.ineligible, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  isVerified ? 'Extracted & Verified' : 'Tap to scan and verify',
                  style: TextStyle(
                    color: isVerified ? context.colors.eligible : context.colors.textHint,
                    fontSize: 11,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          if (!isVerified)
            GestureDetector(
              onTap: () => context.push('/documents'),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: context.colors.bgCardLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.colors.glassBorder),
                ),
                child: Text(
                  'Go to Documents',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
