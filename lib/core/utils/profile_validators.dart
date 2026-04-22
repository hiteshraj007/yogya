/// Pure static validation functions for all profile fields.
/// Each returns `null` if valid, or an error message string if invalid.
class ProfileValidators {
  ProfileValidators._();

  // ── Full Name ──────────────────────────────────────────────────────────────
  /// Letters, spaces, hyphens, dots. Min 3, max 100 chars.
  static String? validateName(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Name is required';
    if (v.length < 3) return 'Name must be at least 3 characters';
    if (v.length > 100) return 'Name must be under 100 characters';
    final regex = RegExp(r"^[A-Za-z\s\-\.]+$");
    if (!regex.hasMatch(v)) return 'Name can only contain letters, spaces, hyphens, or dots';
    return null;
  }

  // ── Date of Birth — three-part validation ─────────────────────────────────
  /// Validates day (01-31), month (01-12), year (4 digits, min 13 yrs, max 100 yrs from today).
  static String? validateDob(String day, String month, String year) {
    if (day.isEmpty || month.isEmpty || year.isEmpty) {
      return 'Please enter a complete date of birth';
    }

    final d = int.tryParse(day);
    final m = int.tryParse(month);
    final y = int.tryParse(year);

    if (d == null || d < 1 || d > 31) return 'Day must be between 01 and 31';
    if (m == null || m < 1 || m > 12) return 'Month must be between 01 and 12';
    if (y == null || year.length != 4) return 'Year must be a valid 4-digit number';

    final now = DateTime.now();
    final minYear = now.year - 100;
    final maxYear = now.year - 13;

    if (y < minYear) return 'Year $y is too far in the past (max 100 years old)';
    if (y > maxYear) {
      return 'You must be at least 13 years old';
    }

    // Validate actual date exists
    try {
      final dob = DateTime(y, m, d);
      if (dob.isAfter(now)) return 'Date of birth cannot be in the future';
      // Cross-check day validity for given month/year (e.g. Feb 30)
      if (dob.month != m || dob.day != d) {
        return 'Invalid date — $day/$month/$y does not exist';
      }
    } catch (_) {
      return 'Invalid date of birth';
    }

    return null;
  }

  /// Returns dd/MM/yyyy formatted string from parts (no validation, assumes valid).
  static String formatDob(String day, String month, String year) {
    return '${day.padLeft(2, '0')}/${month.padLeft(2, '0')}/$year';
  }

  /// Splits a dd/MM/yyyy string into parts. Returns ['', '', ''] if invalid.
  static List<String> splitDob(String dob) {
    final parts = dob.split('/');
    if (parts.length == 3) return parts;
    return ['', '', ''];
  }

  // ── Board Name (custom entry) ──────────────────────────────────────────────
  /// Letters, spaces, hyphens, commas, parentheses only. Min 3, max 150.
  static String? validateBoardName(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Board name is required';
    if (v.length < 3) return 'Board name must be at least 3 characters';
    if (v.length > 150) return 'Board name must be under 150 characters';
    final regex = RegExp(r'^[A-Za-z\s\-,\(\)\.]+$');
    if (!regex.hasMatch(v)) {
      return 'Board name cannot contain numbers or special symbols (@, #, \$, %)';
    }
    // Reject pure whitespace entries
    if (v.replaceAll(' ', '').isEmpty) {
      return 'Board name cannot be blank';
    }
    return null;
  }

  // ── 12th / 10th Percentage ─────────────────────────────────────────────────
  /// Decimal between 0.00 and 100.00, max 2 decimal places.
  static String? validatePercentage(String value) {
    if (value.trim().isEmpty) return null; // optional
    final v = double.tryParse(value.trim());
    if (v == null) return 'Enter a valid number (e.g. 85.5)';
    if (v < 0) return 'Percentage cannot be negative';
    if (v > 100) return 'Percentage cannot exceed 100';
    // Check decimal places
    final parts = value.trim().split('.');
    if (parts.length == 2 && parts[1].length > 2) {
      return 'Percentage can have at most 2 decimal places';
    }
    return null;
  }

  // ── CGPA ───────────────────────────────────────────────────────────────────
  /// For CGPA on 10-point scale: 0.00 – 10.00; on 4-point: 0.00 – 4.00.
  static String? validateCgpa(String value, {int scale = 10}) {
    if (value.trim().isEmpty) return null;
    final v = double.tryParse(value.trim());
    if (v == null) return 'Enter a valid CGPA (e.g. 8.5)';
    if (v < 0) return 'CGPA cannot be negative';
    if (v > scale) return 'CGPA cannot exceed $scale';
    return null;
  }

  // ── Academic Year ──────────────────────────────────────────────────────────
  /// 4-digit year between [minYear] and [maxYear] (inclusive).
  static String? validateYear(String value, {int minYear = 1950, int? maxYear}) {
    if (value.trim().isEmpty) return null;
    final max = maxYear ?? DateTime.now().year + 4;
    if (value.trim().length != 4) return 'Year must be a 4-digit number';
    final y = int.tryParse(value.trim());
    if (y == null) return 'Enter a valid year';
    if (y < minYear) return 'Year cannot be before $minYear';
    if (y > max) return 'Year cannot be after $max';
    return null;
  }

  // ── Phone (Indian mobile) ─────────────────────────────────────────────────
  /// Exactly 10 digits, starting with 6, 7, 8, or 9.
  static String? validatePhone(String value) {
    if (value.trim().isEmpty) return null;
    final v = value.trim();
    if (v.length != 10) return 'Mobile number must be exactly 10 digits';
    final regex = RegExp(r'^[6-9]\d{9}$');
    if (!regex.hasMatch(v)) {
      return 'Enter a valid Indian mobile number (starts with 6-9)';
    }
    return null;
  }

  // ── Email ────────────────────────────────────────────────────────────────
  static String? validateEmail(String value) {
    if (value.trim().isEmpty) return null;
    final regex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!regex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // ── Primary Exam Goal — fuzzy-match helper ────────────────────────────────
  /// Returns true if [goal] likely refers to [examName] or [examCode].
  static bool matchesGoal(String goal, String examName, String examCode) {
    final g = goal.toLowerCase().trim();
    if (g.isEmpty) return false;
    final name = examName.toLowerCase();
    final code = examCode.toLowerCase();
    return name.contains(g) || code.contains(g) || g.contains(code);
  }
}
