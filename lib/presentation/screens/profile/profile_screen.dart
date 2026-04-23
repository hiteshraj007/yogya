import '../../../core/theme/theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/exam_data.dart';
import '../../../core/constants/india_data.dart';
import '../../../core/utils/profile_validators.dart';
import '../../../data/providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/common/app_button.dart';
import 'widgets/category_selector.dart';
import 'dart:async';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  // Personal Info
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // DOB — read-only, stored in three controllers (populated from OCR)
  final _dobDayCtrl   = TextEditingController();
  final _dobMonthCtrl = TextEditingController();
  final _dobYearCtrl  = TextEditingController();

  // 10th — OCR-only, read-only in UI
  final _tenthBoardCtrl   = TextEditingController();
  final _tenthYearCtrl    = TextEditingController();
  final _tenthPercentCtrl = TextEditingController();

  // 12th — OCR-only, displayed via _effectiveTwelfthBoard
  String? _twelfthBoardSelection;
  final _customBoardCtrl     = TextEditingController();
  final _twelfthYearCtrl     = TextEditingController();
  final _twelfthPercentCtrl  = TextEditingController();

  // Graduation — OCR-only
  String? _gradCourseSelection;
  String? _gradUniSelection;
  final _customUniCtrl  = TextEditingController();
  final _gradYearCtrl   = TextEditingController();
  final _gradPercentCtrl = TextEditingController();
  String _gradStatus = 'Pursuing';

  // Additional
  final _stateCtrl    = TextEditingController();
  final _examGoalCtrl = TextEditingController();

  // Dropdowns
  String _selectedCategory   = 'General';
  String _selectedGender     = 'Male';
  String? _selectedQualification;

  // Inline errors (only personally-entered fields)
  String? _nameError;
  String? _phoneError;
  String? _emailError;

  bool _isLoading = false;

  // Debounce timers
  Timer? _nameTimer;
  Timer? _phoneTimer;
  Timer? _emailTimer;

  late AnimationController _ctrl;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;
  ProviderSubscription<ProfileState>? _profileSubscription;

  final List<String> _indianStates = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
    'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
    'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
    'Andaman and Nicobar Islands', 'Chandigarh', 'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi', 'Jammu and Kashmir', 'Ladakh', 'Lakshadweep', 'Puducherry',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _fadeAnims = List.generate(6, (i) => Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Interval(i * 0.12, 0.5 + i * 0.1, curve: Curves.easeOut)),
    ));
    _slideAnims = List.generate(6, (i) => Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Interval(i * 0.12, 0.5 + i * 0.1, curve: Curves.easeOutCubic)),
    ));
    _ctrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await ref.read(profileNotifierProvider.notifier).loadProfile(user.uid);
      }
      _loadSavedProfile();
    });

    _profileSubscription = ref.listenManual<ProfileState>(
      profileNotifierProvider,
      (previous, next) {
        final previousProfile = previous?.profile;
        final nextProfile = next.profile;
        if (nextProfile == null) return;

        final changed = previousProfile == null ||
            previousProfile.id != nextProfile.id ||
            previousProfile.tenthBoard != nextProfile.tenthBoard ||
            previousProfile.twelfthBoard != nextProfile.twelfthBoard ||
            previousProfile.gradCourse != nextProfile.gradCourse ||
            previousProfile.gradUniversity != nextProfile.gradUniversity ||
            previousProfile.gradYear != nextProfile.gradYear ||
            previousProfile.gradPercentage != nextProfile.gradPercentage ||
            previousProfile.graduationStatus != nextProfile.graduationStatus;

        if (changed && mounted) {
          _loadSavedProfile();
        }
      },
    );
  }

  void _loadSavedProfile() {
    final user = FirebaseAuth.instance.currentUser;
    final profile = ref.read(profileNotifierProvider).profile;

    if (profile != null) {
      _nameCtrl.text = profile.name.isNotEmpty ? profile.name : (user?.displayName ?? '');
      _emailCtrl.text = profile.email.isNotEmpty ? profile.email : (user?.email ?? '');
      _phoneCtrl.text = profile.phone;

      // Split DOB into parts
      final dobParts = ProfileValidators.splitDob(profile.dateOfBirth);
      _dobDayCtrl.text = dobParts[0];
      _dobMonthCtrl.text = dobParts[1];
      _dobYearCtrl.text = dobParts[2];

      _stateCtrl.text = profile.stateOfDomicile;
      _examGoalCtrl.text = profile.primaryExamGoal;

      // 10th — always OCR-only
      _tenthBoardCtrl.text   = profile.tenthBoard;
      _tenthYearCtrl.text    = profile.tenthYear;
      _tenthPercentCtrl.text = profile.tenthPercentage;

      // 12th
      _setTwelfthBoard(profile.twelfthBoard);
      _twelfthYearCtrl.text = profile.twelfthYear;
      _twelfthPercentCtrl.text = profile.twelfthPercentage;

      // Graduation
      _setGradCourse(profile.gradCourse);
      _setGradUniversity(profile.gradUniversity);
      _gradYearCtrl.text = profile.gradYear;
      _gradPercentCtrl.text = profile.gradPercentage;

      setState(() {
        _selectedCategory = profile.category.isNotEmpty ? profile.category : 'General';
        _selectedGender = profile.gender.isNotEmpty ? profile.gender : 'Male';
        _gradStatus = profile.graduationStatus.isNotEmpty ? profile.graduationStatus : 'Pursuing';
        _selectedQualification = _computeQualDropdown(profile.qualification);
      });
    } else if (user != null) {
      _nameCtrl.text = user.displayName ?? '';
      _emailCtrl.text = user.email ?? '';
    }
  }

  String? _computeQualDropdown(String saved) {
    if (saved.toLowerCase().contains('pg') || saved.toLowerCase().contains('post grad')) return 'PG';
    if (saved.toLowerCase().contains('grad') || saved.toLowerCase().contains('ug')) return 'UG Completed';
    if (saved.toLowerCase().contains('12')) return '12th Pass';
    if (saved.toLowerCase().contains('10')) return '10th Pass';
    return null;
  }

  void _setTwelfthBoard(String value) {
    if (value.isEmpty) {
      _twelfthBoardSelection = null;
    } else {
      final match = IndiaData.boards.firstWhere(
        (b) => b.toLowerCase().contains(value.toLowerCase()) || value.toLowerCase().contains(b.split('—')[0].trim().toLowerCase()),
        orElse: () => 'Other (not listed)',
      );
      if (match == 'Other (not listed)') {
        _twelfthBoardSelection = 'Other (not listed)';
        _customBoardCtrl.text = value;
      } else {
        _twelfthBoardSelection = match;
      }
    }
  }

  void _setGradCourse(String value) {
    if (value.isEmpty) { _gradCourseSelection = null; return; }
    final normalizedValue = _normalizeText(value);
    final match = IndiaData.allCourses.firstWhere(
      (c) {
        final normalizedCourse = _normalizeText(c);
        return normalizedCourse.contains(normalizedValue) ||
            normalizedValue.contains(normalizedCourse);
      },
      orElse: () => _sanitizeCourseFallback(value),
    );
    _gradCourseSelection = match;
  }

  String _normalizeText(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }

  String _sanitizeCourseFallback(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.length < 3 || cleaned.length > 120) return 'Other UG Course';
    if (!RegExp(r'^[A-Za-z0-9\s\.\-\,\/\(\)&]+$').hasMatch(cleaned)) {
      return 'Other UG Course';
    }
    return cleaned;
  }

  void _setGradUniversity(String value) {
    if (value.isEmpty) { _gradUniSelection = null; return; }
    final match = IndiaData.universities.firstWhere(
      (u) => u.toLowerCase().contains(value.toLowerCase()),
      orElse: () => 'Other (not listed)',
    );
    if (match == 'Other (not listed)') {
      _gradUniSelection = 'Other (not listed)';
      _customUniCtrl.text = value;
    } else {
      _gradUniSelection = match;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _dobDayCtrl.dispose(); _dobMonthCtrl.dispose(); _dobYearCtrl.dispose();
    _tenthBoardCtrl.dispose(); _tenthYearCtrl.dispose(); _tenthPercentCtrl.dispose();
    _customBoardCtrl.dispose();
    _twelfthYearCtrl.dispose(); _twelfthPercentCtrl.dispose();
    _customUniCtrl.dispose();
    _gradYearCtrl.dispose(); _gradPercentCtrl.dispose();
    _stateCtrl.dispose(); _examGoalCtrl.dispose();
    _nameTimer?.cancel(); _phoneTimer?.cancel(); _emailTimer?.cancel();
    _profileSubscription?.close();
    _ctrl.dispose();
    super.dispose();
  }

  String get _effectiveTwelfthBoard {
    if (_twelfthBoardSelection == 'Other (not listed)') {
      return _customBoardCtrl.text.trim();
    }
    return _twelfthBoardSelection ?? '';
  }

  String get _effectiveGradUniversity {
    if (_gradUniSelection == 'Other (not listed)') {
      return _customUniCtrl.text.trim();
    }
    return _gradUniSelection ?? '';
  }

  // ── Validation ────────────────────────────────────────────────────────────
  bool _validateAll() {
    bool valid = true;

    final nameErr  = ProfileValidators.validateName(_nameCtrl.text);
    final phoneErr = ProfileValidators.validatePhone(_phoneCtrl.text);
    final emailErr = ProfileValidators.validateEmail(_emailCtrl.text);

    setState(() {
      _nameError  = nameErr;
      _phoneError = phoneErr;
      _emailError = emailErr;
      // DOB and academic fields are OCR-only — no manual validation needed
    });

    if (nameErr != null || phoneErr != null || emailErr != null) valid = false;
    return valid;
  }

  Future<void> _handleSave() async {
    if (!_validateAll()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please fix the errors before saving', style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: context.colors.ineligible,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);

    final dob = ProfileValidators.formatDob(
      _dobDayCtrl.text, _dobMonthCtrl.text, _dobYearCtrl.text,
    );

    await ref.read(profileNotifierProvider.notifier).saveProfile(
      uid: user.uid,
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      category: _selectedCategory,
      gender: _selectedGender,
      dateOfBirth: dob,
      phone: _phoneCtrl.text.trim(),
      stateOfDomicile: _stateCtrl.text.trim(),
      primaryExamGoal: _examGoalCtrl.text.trim(),
      tenthBoard: _tenthBoardCtrl.text.trim(),
      tenthYear: _tenthYearCtrl.text.trim(),
      tenthPercentage: _tenthPercentCtrl.text.trim(),
      twelfthBoard: _effectiveTwelfthBoard,
      twelfthYear: _twelfthYearCtrl.text.trim(),
      twelfthPercentage: _twelfthPercentCtrl.text.trim(),
      gradCourse: _gradCourseSelection ?? '',
      gradUniversity: _effectiveGradUniversity,
      gradYear: _gradYearCtrl.text.trim(),
      gradPercentage: _gradPercentCtrl.text.trim(),
      graduationStatus: _gradStatus,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Profile saved successfully!', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
        backgroundColor: context.colors.eligible,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Widget _animItem(int index, Widget child) {
    final i = index.clamp(0, 5);
    return SlideTransition(position: _slideAnims[i], child: FadeTransition(opacity: _fadeAnims[i], child: child));
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    final user = ref.watch(currentUserProvider);

    final completion = profileState.profile?.profileCompletion ?? 0;
    final displayName = profileState.profile?.name ?? user?.displayName ?? 'Aspirant';
    final displayEmail = profileState.profile?.email ?? user?.email ?? '';
    final initials = displayName.isNotEmpty
        ? displayName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'YG';

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _animItem(0, _buildProfileHeader(initials, displayName, displayEmail, completion)),
              const SizedBox(height: 16),

              // Personal Information
              _animItem(1, _buildSection('Personal Information', Icons.person_outline_rounded, [
                _buildValidatedField(
                  label: 'Full Name',
                  controller: _nameCtrl,
                  prefixIcon: Icons.person_rounded,
                  error: _nameError,
                  onChanged: (v) {
                    _nameTimer?.cancel();
                    _nameTimer = Timer(const Duration(milliseconds: 600), () {
                      setState(() => _nameError = ProfileValidators.validateName(v));
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildDobField(),
                const SizedBox(height: 12),
                _buildGenderSelector(),
              ])),

              const SizedBox(height: 12),

              // Category
              _animItem(2, _buildSection('Category & Reservation', Icons.category_rounded, [
                CategorySelector(
                  categories: ExamData.userCategories,
                  selected: _selectedCategory,
                  onSelect: (cat) => setState(() => _selectedCategory = cat),
                ),
              ])),

              const SizedBox(height: 12),

              _animItem(3, _buildSection('Academic Information', Icons.school_outlined, [
                _buildQualificationDropdown(),
                const SizedBox(height: 16),

                // ── 10th (OCR only) ───────────────────────────────────────
                _buildSubHeader('10th Standard', Icons.looks_one_rounded),
                const SizedBox(height: 8),
                if (_tenthBoardCtrl.text.isNotEmpty) ...[
                  _buildOcrChip('Board', _tenthBoardCtrl.text),
                  const SizedBox(height: 6),
                  _buildOcrChip('Year', _tenthYearCtrl.text),
                  const SizedBox(height: 6),
                  _buildOcrChip('Percentage', _tenthPercentCtrl.text),
                  const SizedBox(height: 4),
                  _buildOcrNote('Data auto-filled from scanned 10th marksheet'),
                ] else
                  _buildScanBanner(
                    'Upload your 10th marksheet in the Documents tab to auto-fill board, year, percentage, DOB and name.',
                    Icons.looks_one_rounded,
                  ),

                const SizedBox(height: 20),

                // ── 12th (OCR only) ───────────────────────────────────────
                _buildSubHeader('12th Standard', Icons.looks_two_rounded),
                const SizedBox(height: 8),
                if (_twelfthYearCtrl.text.isNotEmpty || _effectiveTwelfthBoard.isNotEmpty) ...[
                  _buildOcrChip('Board', _effectiveTwelfthBoard),
                  const SizedBox(height: 6),
                  _buildOcrChip('Year', _twelfthYearCtrl.text),
                  const SizedBox(height: 6),
                  _buildOcrChip('Percentage', _twelfthPercentCtrl.text),
                  const SizedBox(height: 4),
                  _buildOcrNote('Data auto-filled from scanned 12th marksheet'),
                ] else
                  _buildScanBanner(
                    'Upload your 12th marksheet in the Documents tab to auto-fill board, year and percentage.',
                    Icons.looks_two_rounded,
                  ),

                const SizedBox(height: 20),

                // ── Graduation (OCR only) ─────────────────────────────────
                _buildSubHeader('Graduation (College)', Icons.school_rounded),
                const SizedBox(height: 8),
                if (_gradYearCtrl.text.isNotEmpty || (_gradCourseSelection?.isNotEmpty ?? false)) ...[
                  _buildOcrChip('Course', _gradCourseSelection ?? ''),
                  const SizedBox(height: 6),
                  _buildOcrChip('University', _effectiveGradUniversity),
                  const SizedBox(height: 6),
                  _buildOcrChip('Year', _gradYearCtrl.text),
                  const SizedBox(height: 6),
                  _buildOcrChip('CGPA / %', _gradPercentCtrl.text),
                  const SizedBox(height: 6),
                  _buildOcrChip('Status', _gradStatus),
                  const SizedBox(height: 4),
                  _buildOcrNote('Data auto-filled from scanned graduation marksheet'),
                ] else
                  _buildScanBanner(
                    'Upload your graduation marksheet in the Documents tab to auto-fill course, university and percentage.',
                    Icons.school_rounded,
                  ),
              ])),

              const SizedBox(height: 12),

              // Contact
              _animItem(4, _buildSection('Contact Information', Icons.phone_outlined, [
                _buildEmailField(),
                const SizedBox(height: 12),
                _buildPhoneField(),
              ])),

              const SizedBox(height: 12),

              // Additional
              _animItem(5, _buildSection('Additional Information', Icons.info_outline_rounded, [
                _buildPickerTile(
                  label: 'State of Domicile',
                  icon: Icons.location_on_rounded,
                  value: _stateCtrl.text.isEmpty ? null : _stateCtrl.text,
                  placeholder: 'Select your state',
                  onTap: _showStateSelector,
                ),
                const SizedBox(height: 12),
                _buildPickerTile(
                  label: 'Primary Exam Goal',
                  icon: Icons.flag_rounded,
                  value: _examGoalCtrl.text.isEmpty ? null : _examGoalCtrl.text,
                  placeholder: 'Select a primary exam goal',
                  onTap: _showExamGoalSelector,
                ),
              ])),

              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppButton(label: 'Save Profile', onPressed: _handleSave, isLoading: _isLoading, icon: Icons.save_rounded),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  // ── DOB — read-only, OCR-only ─────────────────────────────────────────────
  Widget _buildDobField() {
    final hasDay  = _dobDayCtrl.text.isNotEmpty;
    final hasMon  = _dobMonthCtrl.text.isNotEmpty;
    final hasYear = _dobYearCtrl.text.isNotEmpty;

    if (hasDay && hasMon && hasYear) {
      final dob = '${_dobDayCtrl.text}/${_dobMonthCtrl.text}/${_dobYearCtrl.text}';
      return _buildLockedField('Date of Birth', dob, Icons.cake_rounded);
    }

    return _buildScanBanner(
      'Date of Birth is auto-filled from your 10th marksheet scan. Upload it in the Documents tab.',
      Icons.cake_rounded,
    );
  }

  // ── Qualification Dropdown ─────────────────────────────────────────────────
  Widget _buildQualificationDropdown() {
    const options = ['10th Pass', '12th Pass', 'UG Completed', 'PG'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Highest Qualification', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.colors.textSecondary, fontFamily: 'Poppins')),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: context.colors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.colors.glassBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedQualification,
              hint: Text('Select qualification', style: TextStyle(color: context.colors.textHint, fontFamily: 'Poppins', fontSize: 14)),
              isExpanded: true,
              dropdownColor: context.colors.bgCard,
              icon: Icon(Icons.expand_more_rounded, color: context.colors.textHint),
              items: options.map((o) => DropdownMenuItem(
                value: o,
                child: Text(o, style: TextStyle(color: context.colors.textPrimary, fontFamily: 'Poppins', fontSize: 14)),
              )).toList(),
              onChanged: (v) => setState(() => _selectedQualification = v),
            ),
          ),
        ),
      ],
    );
  }

  // (Board, Course, University pickers removed — academic fields are OCR-only)

  // ── Reusable searchable bottom-sheet picker ───────────────────────────────
  void _showSearchablePicker({
    required String title,
    required List<String> items,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) {
    String query = '';
    List<String> filtered = List.from(items);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollCtrl) => Container(
            decoration: BoxDecoration(
              color: context.colors.bgCard,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(children: [
              // Handle
              Container(margin: const EdgeInsets.only(top: 10), width: 40, height: 4,
                decoration: BoxDecoration(color: context.colors.glassBorder, borderRadius: BorderRadius.circular(2))),
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(children: [
                  Expanded(child: Text(title, style: TextStyle(color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Poppins'))),
                  IconButton(icon: Icon(Icons.close_rounded, color: context.colors.textHint), onPressed: () => Navigator.pop(ctx)),
                ]),
              ),
              // Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  autofocus: true,
                  onChanged: (v) => setModalState(() {
                    query = v.toLowerCase();
                    filtered = items.where((i) => i.toLowerCase().contains(query)).toList();
                  }),
                  style: TextStyle(color: context.colors.textPrimary, fontFamily: 'Poppins', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search…',
                    hintStyle: TextStyle(color: context.colors.textHint),
                    prefixIcon: Icon(Icons.search_rounded, color: context.colors.textHint),
                    filled: true,
                    fillColor: context.colors.bgDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              Divider(color: context.colors.glassBorder, height: 1),
              // List
              Expanded(child: ListView.builder(
                controller: scrollCtrl,
                physics: const BouncingScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final item = filtered[i];
                  final isSel = item == selected;
                  return ListTile(
                    title: Text(item, style: TextStyle(
                      color: isSel ? context.colors.primary : context.colors.textSecondary,
                      fontFamily: 'Poppins', fontSize: 13,
                      fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
                    )),
                    trailing: isSel ? Icon(Icons.check_circle_rounded, color: context.colors.primary, size: 18) : null,
                    onTap: () { onSelect(item); Navigator.pop(ctx); },
                  );
                },
              )),
            ]),
          ),
        );
      }),
    );
  }

  // ── Picker tile (tap to open sheet) ──────────────────────────────────────
  Widget _buildPickerTile({
    required String label,
    required IconData icon,
    required String? value,
    required String placeholder,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.colors.textSecondary, fontFamily: 'Poppins')),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: context.colors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.colors.glassBorder),
            ),
            child: Row(children: [
              Icon(icon, color: context.colors.textHint, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(
                value ?? placeholder,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: value != null ? context.colors.textPrimary : context.colors.textHint,
                  fontFamily: 'Poppins', fontSize: 14,
                ),
              )),
              Icon(Icons.expand_more_rounded, color: context.colors.textHint, size: 20),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Locked read-only field (OCR-sourced data) ─────────────────────────────
  Widget _buildLockedField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.colors.textSecondary, fontFamily: 'Poppins')),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: context.colors.eligible.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.colors.eligible.withValues(alpha: 0.35)),
          ),
          child: Row(children: [
            Icon(icon, size: 18, color: context.colors.eligible),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value.isEmpty ? '—' : value,
                style: TextStyle(color: context.colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
              ),
            ),
            Icon(Icons.lock_outline_rounded, size: 15, color: context.colors.eligible.withValues(alpha: 0.7)),
          ]),
        ),
      ],
    );
  }

  // ── Scan-prompt banner (shown when OCR data is missing) ──────────────────
  Widget _buildScanBanner(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.colors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.document_scanner_rounded, size: 18, color: context.colors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Scan Required', style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Poppins')),
            const SizedBox(height: 3),
            Text(message, style: TextStyle(color: context.colors.textHint, fontSize: 11, fontFamily: 'Poppins', height: 1.4)),
          ]),
        ),
      ]),
    );
  }

  // ── OCR note label ────────────────────────────────────────────────────────
  Widget _buildOcrNote(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.verified_rounded, size: 13, color: context.colors.eligible),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.colors.eligible, fontSize: 11, fontFamily: 'Poppins'),
          ),
        ),
      ]),
    );
  }

  // ── OCR fetched chip ──────────────────────────────────────────────────────
  Widget _buildOcrChip(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.eligible.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.colors.eligible.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(Icons.lock_outline_rounded, size: 13, color: context.colors.eligible),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(color: context.colors.textHint, fontSize: 12, fontFamily: 'Poppins')),
        Expanded(child: Text(value.isEmpty ? '—' : value, style: TextStyle(color: context.colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Poppins'))),
      ]),
    );
  }

  // ── Generic validated field ───────────────────────────────────────────────
  Widget _buildValidatedField({
    required String label,
    required TextEditingController controller,
    IconData? prefixIcon,
    String? hintText,
    String? error,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    bool autocorrect = true,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.colors.textSecondary, fontFamily: 'Poppins')),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          autocorrect: autocorrect,
          maxLines: maxLines,
          style: TextStyle(color: context.colors.textPrimary, fontFamily: 'Poppins', fontSize: 14),
          decoration: InputDecoration(
            hintText: hintText,
            counterText: '',
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: error != null ? context.colors.ineligible : context.colors.textHint, size: 20) : null,
            hintStyle: TextStyle(color: context.colors.textHint, fontSize: 13),
            filled: true,
            fillColor: context.colors.bgCard,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: error != null ? context.colors.ineligible : context.colors.glassBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: error != null ? context.colors.ineligible : context.colors.primary, width: 1.5)),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(error, style: TextStyle(color: context.colors.ineligible, fontSize: 11, fontFamily: 'Poppins')),
        ],
      ],
    );
  }

  // ── Phone field with +91 prefix ───────────────────────────────────────────
  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Phone Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.colors.textSecondary, fontFamily: 'Poppins')),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // +91 chip
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.colors.primary.withValues(alpha: 0.4)),
            ),
            child: Center(child: Text('+91', style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.w700, fontSize: 15, fontFamily: 'Poppins'))),
          ),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              onChanged: (v) {
                _phoneTimer?.cancel();
                _phoneTimer = Timer(const Duration(milliseconds: 500), () {
                  if (mounted) setState(() => _phoneError = ProfileValidators.validatePhone(v));
                });
              },
              style: TextStyle(color: context.colors.textPrimary, fontFamily: 'Poppins', fontSize: 14),
              decoration: InputDecoration(
                hintText: '9876543210',
                counterText: '',
                hintStyle: TextStyle(color: context.colors.textHint, fontSize: 13),
                filled: true, fillColor: context.colors.bgCard,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _phoneError != null ? context.colors.ineligible : context.colors.glassBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _phoneError != null ? context.colors.ineligible : context.colors.primary, width: 1.5)),
              ),
            ),
            if (_phoneError != null) ...[
              const SizedBox(height: 4),
              Text(_phoneError!, style: TextStyle(color: context.colors.ineligible, fontSize: 11, fontFamily: 'Poppins')),
            ],
          ])),
        ]),
      ],
    );
  }

  // ── Email field ──────────────────────────────────────────────────────────
  Widget _buildEmailField() {
    return _buildValidatedField(
      label: 'Email Address',
      controller: _emailCtrl,
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      error: _emailError,
      onChanged: (v) {
        _emailTimer?.cancel();
        _emailTimer = Timer(const Duration(milliseconds: 600), () {
          if (mounted) setState(() => _emailError = ProfileValidators.validateEmail(v));
        });
      },
    );
  }

  // ── State selector ────────────────────────────────────────────────────────
  void _showStateSelector() {
    _showSearchablePicker(
      title: 'Select State of Domicile',
      items: _indianStates,
      selected: _stateCtrl.text.isEmpty ? null : _stateCtrl.text,
      onSelect: (v) => setState(() => _stateCtrl.text = v),
    );
  }

  // ── Exam Goal selector ────────────────────────────────────────────────────
  List<String> get _suggestedGoals {
    final list = <String>{};
    final profile = ref.read(profileNotifierProvider).profile;
    
    if (profile == null) {
      return ['UPSC CSE', 'SSC CGL', 'IBPS PO', 'NDA', 'SSC CHSL', 'SSC MTS'];
    }
    
    final course = profile.gradCourse.toLowerCase();
    final isBtech = course.contains('b.tech') || course.contains('b.e') || course.contains('engineering');
    if (isBtech) list.addAll(['GATE', 'UPSC ESE', 'SSC JE', 'RRB JE']);
    
    final qual = profile.qualification.toLowerCase();
    if (qual.contains('grad') || profile.gradCourse.isNotEmpty) {
      list.addAll(['UPSC CSE', 'SSC CGL', 'IBPS PO', 'SBI PO', 'CDS', 'AFCAT']);
    }
    
    if (profile.twelfthBoard.isNotEmpty || qual.contains('12')) {
      list.addAll(['SSC CHSL', 'NDA', 'RRB NTPC']);
    }
    
    if (profile.tenthBoard.isNotEmpty || qual.contains('10')) {
      list.addAll(['SSC MTS', 'SSC GD', 'RRB Group D']);
    }
    
    if (list.isEmpty) list.addAll(['UPSC CSE', 'SSC CGL', 'IBPS PO', 'NDA', 'SSC CHSL']);
    
    return list.toList();
  }

  void _showExamGoalSelector() {
    _showSearchablePicker(
      title: 'Suggested Exam Goals',
      items: _suggestedGoals,
      selected: _examGoalCtrl.text.isEmpty ? null : _examGoalCtrl.text,
      onSelect: (v) => setState(() => _examGoalCtrl.text = v),
    );
  }

  // ── Gender selector ───────────────────────────────────────────────────────
  Widget _buildGenderSelector() {
    return Row(children: ['Male', 'Female', 'Other'].map((g) {
      final sel = _selectedGender == g;
      return Expanded(child: GestureDetector(
        onTap: () => setState(() => _selectedGender = g),
        child: Container(
          margin: EdgeInsets.only(right: g != 'Other' ? 8 : 0),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? context.colors.primary : context.colors.glassBorder),
            color: sel ? context.colors.primary.withValues(alpha: 0.15) : context.colors.bgCardLight,
          ),
          child: Center(child: Text(g, style: TextStyle(
            color: sel ? context.colors.primary : context.colors.textSecondary,
            fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13, fontFamily: 'Poppins',
          ))),
        ),
      ));
    }).toList());
  }

  // ── Sub-header ────────────────────────────────────────────────────────────
  Widget _buildSubHeader(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 16, color: context.colors.primary.withValues(alpha: 0.7)),
      const SizedBox(width: 6),
      Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textPrimary.withValues(alpha: 0.85), fontFamily: 'Poppins')),
    ]);
  }

  // ── Section wrapper ───────────────────────────────────────────────────────
  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.glassBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: context.colors.primaryLight, size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
          ]),
          const SizedBox(height: 14),
          ...children,
        ]),
      ),
    );
  }

  // ── Profile header ────────────────────────────────────────────────────────
  Widget _buildProfileHeader(String initials, String name, String email, int completion) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: context.colors.primaryGradient, borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        CircleAvatar(
          radius: 34,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, fontFamily: 'Poppins')),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
          Text(email, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontFamily: 'Poppins')),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: completion / 100, minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white)),
            )),
            const SizedBox(width: 8),
            Text('$completion%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
          ]),
        ])),
      ]),
    );
  }
}
