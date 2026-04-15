class OcrProfileValidator {
  static String? validateDob(String dob) {
    if (dob.trim().isEmpty) return null;
    final m = RegExp(r'^(\d{2})\/(\d{2})\/(\d{4})$').firstMatch(dob.trim());
    if (m == null) return 'DOB format invalid';

    final dd = int.parse(m.group(1)!);
    final mm = int.parse(m.group(2)!);
    final yyyy = int.parse(m.group(3)!);

    final dt = DateTime(yyyy, mm, dd);
    if (dt.year != yyyy || dt.month != mm || dt.day != dd) {
      return 'DOB invalid date';
    }

    int age = DateTime.now().year - yyyy;
    if (DateTime.now().month < mm ||
        (DateTime.now().month == mm && DateTime.now().day < dd)) {
      age--;
    }
    if (age < 10 || age > 80) return 'DOB seems invalid';
    return null;
  }

  static String? validateYear(String year) {
    if (year.trim().isEmpty) return null;
    final y = int.tryParse(year.trim());
    if (y == null) return 'Passing year invalid';
    if (y < 1990 || y > DateTime.now().year + 1) return 'Passing year out of range';
    return null;
  }

  static String? validatePercentageOrCgpa(String value, {required bool isGraduation}) {
    final v = value.trim().toLowerCase();
    if (v.isEmpty) return null;

    final m = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(v);
    if (m == null) return 'Score invalid';

    final n = double.tryParse(m.group(1)!);
    if (n == null) return 'Score invalid';

    if (isGraduation) {
      if (v.contains('cgpa') || n <= 10) {
        if (n < 0 || n > 10) return 'CGPA must be 0-10';
      } else {
        if (n < 0 || n > 100) return 'Percentage must be 0-100';
      }
    } else {
      if (n < 0 || n > 100) return 'Percentage must be 0-100';
    }
    return null;
  }
}