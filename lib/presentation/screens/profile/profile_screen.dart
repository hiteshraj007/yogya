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

// ── Change 1: ConsumerStatefulWidget ──────────────────────
class ProfileScreen extends ConsumerStatefulWidget {
  ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

// ── Change 2: ConsumerState ────────────────────────────────
class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _qualCtrl = TextEditingController();
  final _uniCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _percentCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _examGoalCtrl = TextEditingController();

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

  //   // ── Hive se saved profile load karo ─────────────────
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

    // ── Pehle load karo, phir fields fill karo ──
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await ref.read(profileNotifierProvider.notifier).loadProfile(user.uid);
      }
      _loadSavedProfile();
    });
  }

  // ── Hive se data load karke fields fill karo ──────────
  void _loadSavedProfile() {
    final user = ref.read(currentUserProvider);
    final profile = ref.read(profileNotifierProvider).profile;

    if (profile != null) {
      // Saved profile hai — fields fill karo
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
        _selectedCategory = profile.category;
        _selectedGender = profile.gender;
      });
    } else if (user != null) {
      // Pehli baar — Firebase user se basic info lo
      _nameCtrl.text = user.displayName ?? '';
      _emailCtrl.text = user.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _qualCtrl.dispose();
    _uniCtrl.dispose();
    _yearCtrl.dispose();
    _percentCtrl.dispose();
    _stateCtrl.dispose();
    _examGoalCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Widget _animItem(int index, Widget child) {
    final i = index.clamp(0, 5);
    return SlideTransition(
      position: _slideAnims[i],
      child: FadeTransition(opacity: _fadeAnims[i], child: child),
    );
  }

  // ── Save button action — real Hive save ───────────────
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
          qualification: _qualCtrl.text.trim(),
          university: _uniCtrl.text.trim(),
          passingYear: _yearCtrl.text.trim(),
          percentage: _percentCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          stateOfDomicile: _stateCtrl.text.trim(),
          primaryExamGoal: _examGoalCtrl.text.trim(),
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
              // ── Profile Header ──────────────────────────
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

              // ── Personal Info ───────────────────────────
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

              // ── Category ────────────────────────────────
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

              // ── Academic Info ───────────────────────────
              _animItem(
                3,
                _buildSection(
                  'Academic Information',
                  Icons.school_outlined,
                  [
                    AppTextField(
                      label: 'Highest Qualification',
                      controller: _qualCtrl,
                      prefixIcon: Icons.school_rounded,
                    ),
                    SizedBox(height: 16),
                    AppTextField(
                      label: 'University / Board',
                      controller: _uniCtrl,
                      prefixIcon: Icons.account_balance_rounded,
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Year',
                            controller: _yearCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: AppTextField(
                            label: 'Percentage/CGPA',
                            controller: _percentCtrl,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // ── Academic Documents (Phase 3) ────────────
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

              // ── Contact Info ────────────────────────────
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

              // ── Additional Info (Section 9.1) ─────────────
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

              // ── Check Eligibility Button ────────────────
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

              // ── Save Button ─────────────────────────────
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

  // ── Profile Header widget ────────────────────────────────
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
