import '../../../core/theme/theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/exam_data.dart';
import '../../../core/constants/india_data.dart';
import '../../../core/utils/profile_validators.dart';
import '../../../data/providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/common/app_button.dart';
import 'widgets/category_selector.dart';
import 'dart:async';

class ProfileScreen extends ConsumerStatefulWidget {
  ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  // Personal Info
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // DOB — three separate micro-fields
  final _dobDayCtrl = TextEditingController();
  final _dobMonthCtrl = TextEditingController();
  final _dobYearCtrl = TextEditingController();
  final _dayFocus = FocusNode();
  final _monthFocus = FocusNode();
  final _yearFocus = FocusNode();

  // 10th (from OCR — mostly read-only)
  final _tenthBoardCtrl = TextEditingController();
  final _tenthYearCtrl = TextEditingController();
  final _tenthPercentCtrl = TextEditingController();

  // 12th
  String? _twelfthBoardSelection; // selected from picker
  final _customBoardCtrl = TextEditingController();
  final _twelfthYearCtrl = TextEditingController();
  final _twelfthPercentCtrl = TextEditingController();

  // Graduation
  String? _gradCourseSelection;
  String? _gradUniSelection;
  final _customUniCtrl = TextEditingController();
  final _gradYearCtrl = TextEditingController();
  final _gradPercentCtrl = TextEditingController();
  String _gradStatus = 'Pursuing';
  int _cgpaScale = 10; // 10-point or 4-point

  // Additional
  final _stateCtrl = TextEditingController();
  final _examGoalCtrl = TextEditingController();

  // Dropdowns
  String _selectedCategory = 'General';
  String _selectedGender = 'Male';
  String? _selectedQualification;

  // Inline errors
  String? _nameError;
  String? _dobError;
  String? _phoneError;
  String? _emailError;
  String? _boardError;
  String? _twelfthYearError;
  String? _twelfthPercentError;
  String? _gradYearError;
  String? _gradPercentError;

  bool _isLoading = false;

  // Debounce timers
  Timer? _nameTimer;
  Timer? _phoneTimer;
  Timer? _emailTimer;

  late AnimationController _ctrl;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  // Whether specific 10th fields came from OCR
  bool _tenthFromOcr = false;

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
  }

  void _loadSavedProfile() {
    final user = ref.read(currentUserProvider);
    final profile = ref.read(profileNotifierProvider).profile;

    if (profile != null) {
      _nameCtrl.text = profile.name;
      _emailCtrl.text = profile.email;
      _phoneCtrl.text = profile.phone;

      // Split DOB into parts
      final dobParts = ProfileValidators.splitDob(profile.dateOfBirth);
      _dobDayCtrl.text = dobParts[0];
      _dobMonthCtrl.text = dobParts[1];
      _dobYearCtrl.text = dobParts[2];

      _stateCtrl.text = profile.stateOfDomicile;
      _examGoalCtrl.text = profile.primaryExamGoal;

      // 10th — if board is set, assume it came from OCR
      _tenthBoardCtrl.text = profile.tenthBoard;
      _tenthYearCtrl.text = profile.tenthYear;
      _tenthPercentCtrl.text = profile.tenthPercentage;
      _tenthFromOcr = profile.tenthBoard.isNotEmpty && profile.isVerified;

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
    final match = IndiaData.allCourses.firstWhere(
      (c) => c.toLowerCase().contains(value.toLowerCase()),
      orElse: () => 'Other UG Course',
    );
    _gradCourseSelection = match;
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
    _dayFocus.dispose(); _monthFocus.dispose(); _yearFocus.dispose();
    _tenthBoardCtrl.dispose(); _tenthYearCtrl.dispose(); _tenthPercentCtrl.dispose();
    _customBoardCtrl.dispose();
    _twelfthYearCtrl.dispose(); _twelfthPercentCtrl.dispose();
    _customUniCtrl.dispose();
    _gradYearCtrl.dispose(); _gradPercentCtrl.dispose();
    _stateCtrl.dispose(); _examGoalCtrl.dispose();
    _nameTimer?.cancel(); _phoneTimer?.cancel(); _emailTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  // ── Computed qualification string for saving ─────────────────────────────
  String _computeQualForSave() {
    if (_selectedQualification == 'PG') return 'Post Graduation';
    if (_selectedQualification == 'UG Completed') {
      final course = _gradCourseSelection ?? 'Graduation';
      return 'Graduation ($course)';
    }
    if (_selectedQualification == '12th Pass') return '12th Pass';
    if (_selectedQualification == '10th Pass') return '10th Pass';
    return 'Not Specified';
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

    final nameErr = ProfileValidators.validateName(_nameCtrl.text);
    final dobErr = ProfileValidators.validateDob(
      _dobDayCtrl.text, _dobMonthCtrl.text, _dobYearCtrl.text,
    );
    final phoneErr = ProfileValidators.validatePhone(_phoneCtrl.text);
    final emailErr = ProfileValidators.validateEmail(_emailCtrl.text);
    final boardErr = _twelfthBoardSelection == 'Other (not listed)'
        ? ProfileValidators.validateBoardName(_customBoardCtrl.text)
        : null;
    final twelfthYearErr = ProfileValidators.validateYear(
      _twelfthYearCtrl.text, minYear: 1950, maxYear: DateTime.now().year,
    );
    final twelfthPercentErr = ProfileValidators.validatePercentage(_twelfthPercentCtrl.text);
    final gradYearErr = ProfileValidators.validateYear(
      _gradYearCtrl.text, minYear: 1950, maxYear: DateTime.now().year + 4,
    );
    final gradPercentErr = ProfileValidators.validatePercentage(_gradPercentCtrl.text);

    setState(() {
      _nameError = nameErr;
      _dobError = dobErr;
      _phoneError = phoneErr;
      _emailError = emailErr;
      _boardError = boardErr;
      _twelfthYearError = twelfthYearErr;
      _twelfthPercentError = twelfthPercentErr;
      _gradYearError = gradYearErr;
      _gradPercentError = gradPercentErr;
    });

    if (nameErr != null || dobErr != null) valid = false;
    if (phoneErr != null || emailErr != null) valid = false;
    if (boardErr != null || twelfthYearErr != null || twelfthPercentErr != null) valid = false;
    if (gradYearErr != null || gradPercentErr != null) valid = false;

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

              // Academic Information
              _animItem(3, _buildSection('Academic Information', Icons.school_outlined, [
                _buildQualificationDropdown(),
                const SizedBox(height: 16),

                // 10th — from OCR or editable
                _buildSubHeader('10th Standard', Icons.looks_one_rounded),
                const SizedBox(height: 8),
                if (_tenthFromOcr) ...[
                  _buildOcrChip('Board', _tenthBoardCtrl.text),
                  const SizedBox(height: 6),
                  _buildOcrChip('Year', _tenthYearCtrl.text),
                  const SizedBox(height: 6),
                  _buildOcrChip('Percentage', _tenthPercentCtrl.text),
                  const SizedBox(height: 4),
                  Text(
                    '📷 Data fetched from scanned marksheet',
                    style: TextStyle(color: context.colors.eligible, fontSize: 11, fontFamily: 'Poppins'),
                  ),
                ] else ...[
                  Row(children: [
                    Expanded(child: _buildSimpleField('Board', _tenthBoardCtrl)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildValidatedYearField('Year', _tenthYearCtrl, null)),
                  ]),
                  const SizedBox(height: 10),
                  _buildValidatedPercentField('Percentage', _tenthPercentCtrl, null),
                ],

                const SizedBox(height: 20),

                // 12th
                _buildSubHeader('12th Standard', Icons.looks_two_rounded),
                const SizedBox(height: 8),
                _buildBoardPicker(),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _buildValidatedYearField('Year', _twelfthYearCtrl, _twelfthYearError)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildValidatedPercentField('Percentage', _twelfthPercentCtrl, _twelfthPercentError)),
                ]),

                const SizedBox(height: 20),

                // Graduation
                _buildSubHeader('Graduation (College)', Icons.school_rounded),
                const SizedBox(height: 8),
                _buildCoursePicker(),
                const SizedBox(height: 10),
                _buildUniversityPicker(),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _buildValidatedYearField('Year', _gradYearCtrl, _gradYearError, maxYear: DateTime.now().year + 4)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildValidatedPercentField('CGPA / %', _gradPercentCtrl, _gradPercentError)),
                ]),
                const SizedBox(height: 10),
                _buildCgpaScaleSelector(),
                const SizedBox(height: 10),
                _buildGradStatusSelector(),
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
                _buildValidatedField(
                  label: 'Primary Exam Goal',
                  controller: _examGoalCtrl,
                  prefixIcon: Icons.flag_rounded,
                  hintText: 'e.g. SSC CGL, UPSC CSE, IBPS PO',
                  error: null,
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

  // ── DOB — three micro-fields ───────────────────────────────────────────────
  Widget _buildDobField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date of Birth', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.colors.textSecondary, fontFamily: 'Poppins')),
        const SizedBox(height: 8),
        Row(children: [
          // Day
          Expanded(flex: 2, child: _buildDobMicroField(
            ctrl: _dobDayCtrl, focus: _dayFocus, hint: 'DD', label: 'Day',
            onChanged: (v) {
              if (v.length == 2) FocusScope.of(context).requestFocus(_monthFocus);
              _validateDob();
            },
          )),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('  /  ', style: TextStyle(color: context.colors.textHint, fontSize: 20, fontWeight: FontWeight.w300)),
          ),
          // Month
          Expanded(flex: 2, child: _buildDobMicroField(
            ctrl: _dobMonthCtrl, focus: _monthFocus, hint: 'MM', label: 'Month',
            onChanged: (v) {
              if (v.length == 2) FocusScope.of(context).requestFocus(_yearFocus);
              _validateDob();
            },
          )),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('  /  ', style: TextStyle(color: context.colors.textHint, fontSize: 20, fontWeight: FontWeight.w300)),
          ),
          // Year
          Expanded(flex: 3, child: _buildDobMicroField(
            ctrl: _dobYearCtrl, focus: _yearFocus, hint: 'YYYY', label: 'Year',
            maxLength: 4, onChanged: (_) => _validateDob(),
          )),
        ]),
        if (_dobError != null) ...[
          const SizedBox(height: 4),
          Text(_dobError!, style: TextStyle(color: context.colors.ineligible, fontSize: 11, fontFamily: 'Poppins')),
        ],
      ],
    );
  }

  Widget _buildDobMicroField({
    required TextEditingController ctrl,
    required FocusNode focus,
    required String hint,
    required String label,
    required ValueChanged<String> onChanged,
    int maxLength = 2,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: context.colors.textHint, fontFamily: 'Poppins')),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          focusNode: focus,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(maxLength)],
          textAlign: TextAlign.center,
          onChanged: onChanged,
          style: TextStyle(color: context.colors.textPrimary, fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.colors.textHint, fontSize: 13),
            filled: true,
            fillColor: context.colors.bgCard,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.colors.glassBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.colors.primary, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.colors.ineligible)),
          ),
        ),
      ],
    );
  }

  void _validateDob() {
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _dobError = ProfileValidators.validateDob(_dobDayCtrl.text, _dobMonthCtrl.text, _dobYearCtrl.text));
    });
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

  // ── Board Picker ──────────────────────────────────────────────────────────
  Widget _buildBoardPicker() {
    final isOther = _twelfthBoardSelection == 'Other (not listed)';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPickerTile(
          label: '12th Board',
          icon: Icons.account_balance_rounded,
          value: _twelfthBoardSelection,
          placeholder: 'Select board',
          onTap: _showBoardPicker,
        ),
        if (isOther) ...[
          const SizedBox(height: 8),
          _buildValidatedField(
            label: 'Enter board name',
            controller: _customBoardCtrl,
            prefixIcon: Icons.edit_note_rounded,
            hintText: 'e.g. Assam State Open School (ASOS)',
            error: _boardError,
            maxLength: 150,
            autocorrect: false,
            maxLines: 1,
            onChanged: (v) {
              Timer(const Duration(milliseconds: 600), () {
                if (mounted) setState(() => _boardError = ProfileValidators.validateBoardName(v));
              });
            },
          ),
        ],
      ],
    );
  }

  void _showBoardPicker() {
    _showSearchablePicker(
      title: 'Select 12th Board',
      items: IndiaData.boards,
      selected: _twelfthBoardSelection,
      onSelect: (v) => setState(() {
        _twelfthBoardSelection = v;
        if (v != 'Other (not listed)') _customBoardCtrl.clear();
        _boardError = null;
      }),
    );
  }

  // ── Course Picker ─────────────────────────────────────────────────────────
  Widget _buildCoursePicker() {
    return _buildPickerTile(
      label: 'Graduation Course',
      icon: Icons.book_rounded,
      value: _gradCourseSelection,
      placeholder: 'Select course (B.Tech, MBA…)',
      onTap: () => _showSearchablePicker(
        title: 'Select Graduation Course',
        items: IndiaData.allCourses,
        selected: _gradCourseSelection,
        onSelect: (v) => setState(() => _gradCourseSelection = v),
      ),
    );
  }

  // ── University Picker ─────────────────────────────────────────────────────
  Widget _buildUniversityPicker() {
    final isOther = _gradUniSelection == 'Other (not listed)';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPickerTile(
          label: 'Graduation University',
          icon: Icons.account_balance_rounded,
          value: _gradUniSelection,
          placeholder: 'Search university…',
          onTap: () => _showSearchablePicker(
            title: 'Select University',
            items: IndiaData.universities,
            selected: _gradUniSelection,
            onSelect: (v) => setState(() {
              _gradUniSelection = v;
              if (v != 'Other (not listed)') _customUniCtrl.clear();
            }),
          ),
        ),
        if (isOther) ...[
          const SizedBox(height: 8),
          _buildValidatedField(
            label: 'Enter university name',
            controller: _customUniCtrl,
            prefixIcon: Icons.edit_note_rounded,
            hintText: 'Max 100 characters',
            error: null,
            maxLength: 100,
          ),
        ],
      ],
    );
  }

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

  // ── OCR fetched chip ──────────────────────────────────────────────────────
  Widget _buildOcrChip(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.eligible.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.colors.eligible.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(Icons.camera_alt_rounded, size: 14, color: context.colors.eligible),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(color: context.colors.textHint, fontSize: 12, fontFamily: 'Poppins')),
        Expanded(child: Text(value.isEmpty ? '—' : value, style: TextStyle(color: context.colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Poppins'))),
      ]),
    );
  }

  // ── Validated year field ──────────────────────────────────────────────────
  Widget _buildValidatedYearField(String label, TextEditingController ctrl, String? error, {int maxYear = 0}) {
    final max = maxYear == 0 ? DateTime.now().year : maxYear;
    return _buildValidatedField(
      label: label, controller: ctrl, error: error,
      hintText: 'YYYY', keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
      onChanged: (v) {
        if (v.length == 4) setState(() => error = ProfileValidators.validateYear(v, maxYear: max));
      },
    );
  }

  // ── Validated percent field ───────────────────────────────────────────────
  Widget _buildValidatedPercentField(String label, TextEditingController ctrl, String? error) {
    return _buildValidatedField(
      label: label, controller: ctrl, error: error,
      hintText: '0–100', keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (v) {
        Timer(const Duration(milliseconds: 600), () {
          if (mounted) setState(() => error = ProfileValidators.validatePercentage(v));
        });
      },
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

  // ── Simple field (no validation) ─────────────────────────────────────────
  Widget _buildSimpleField(String label, TextEditingController ctrl, {TextInputType? keyboardType}) {
    return _buildValidatedField(label: label, controller: ctrl, error: null, keyboardType: keyboardType ?? TextInputType.text);
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
              color: context.colors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.colors.primary.withOpacity(0.4)),
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

  // ── CGPA scale selector ───────────────────────────────────────────────────
  Widget _buildCgpaScaleSelector() {
    return Row(children: [
      Text('CGPA Scale: ', style: TextStyle(color: context.colors.textSecondary, fontSize: 12, fontFamily: 'Poppins')),
      const SizedBox(width: 8),
      ...[10, 4].map((s) {
        final sel = _cgpaScale == s;
        return GestureDetector(
          onTap: () => setState(() => _cgpaScale = s),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: sel ? context.colors.primary.withOpacity(0.15) : context.colors.bgCardLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: sel ? context.colors.primary : context.colors.glassBorder),
            ),
            child: Text('/$s', style: TextStyle(
              color: sel ? context.colors.primary : context.colors.textSecondary,
              fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
              fontSize: 13, fontFamily: 'Poppins',
            )),
          ),
        );
      }),
      Text('Percentage', style: TextStyle(color: context.colors.textSecondary, fontSize: 12, fontFamily: 'Poppins')),
    ]);
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
            color: sel ? context.colors.primary.withOpacity(0.15) : context.colors.bgCardLight,
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

  // ── Grad status selector ─────────────────────────────────────────────────
  Widget _buildGradStatusSelector() {
    return Row(children: ['Pursuing', 'Completed'].map((s) {
      final sel = _gradStatus == s;
      return Expanded(child: GestureDetector(
        onTap: () => setState(() => _gradStatus = s),
        child: Container(
          margin: EdgeInsets.only(right: s == 'Pursuing' ? 8 : 0),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? context.colors.primary : context.colors.glassBorder),
            color: sel ? context.colors.primary.withOpacity(0.15) : context.colors.bgCardLight,
          ),
          child: Center(child: Text(s, style: TextStyle(
            color: sel ? context.colors.primary : context.colors.textSecondary,
            fontWeight: sel ? FontWeight.w600 : FontWeight.normal, fontSize: 13, fontFamily: 'Poppins',
          ))),
        ),
      ));
    }).toList());
  }

  // ── Sub-header ────────────────────────────────────────────────────────────
  Widget _buildSubHeader(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 16, color: context.colors.primary.withOpacity(0.7)),
      const SizedBox(width: 6),
      Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textPrimary.withOpacity(0.85), fontFamily: 'Poppins')),
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
          backgroundColor: Colors.white.withOpacity(0.2),
          child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, fontFamily: 'Poppins')),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
          Text(email, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontFamily: 'Poppins')),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: completion / 100, minHeight: 5,
                backgroundColor: Colors.white.withOpacity(0.2),
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