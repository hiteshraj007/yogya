import '../constants/exam_data.dart';

class ExamTimelineService {
  ExamTimelineService._();
  static final ExamTimelineService instance = ExamTimelineService._();

  // Approximate annual calendar templates (month/day) for major Indian exams.
  // These are used as smart defaults and can later be replaced by API data.
  static const Map<String, Map<String, ({int month, int day})>> _calendar = {
    'upsc_cse': {
      'notification': (month: 2, day: 14),
      'application_end': (month: 3, day: 5),
      'exam': (month: 6, day: 2),
    },
    'ssc_cgl': {
      'notification': (month: 6, day: 10),
      'application_end': (month: 7, day: 8),
      'exam': (month: 9, day: 20),
    },
    'ssc_chsl': {
      'notification': (month: 5, day: 8),
      'application_end': (month: 6, day: 6),
      'exam': (month: 8, day: 18),
    },
    'ibps_po': {
      'notification': (month: 8, day: 1),
      'application_end': (month: 8, day: 25),
      'exam': (month: 10, day: 15),
    },
    'ibps_clerk': {
      'notification': (month: 7, day: 1),
      'application_end': (month: 7, day: 22),
      'exam': (month: 9, day: 10),
    },
    'sbi_po': {
      'notification': (month: 9, day: 5),
      'application_end': (month: 10, day: 1),
      'exam': (month: 11, day: 20),
    },
    'rbi_grade_b': {
      'notification': (month: 4, day: 15),
      'application_end': (month: 5, day: 12),
      'exam': (month: 7, day: 16),
    },
    'nda': {
      'notification': (month: 1, day: 10),
      'application_end': (month: 2, day: 1),
      'exam': (month: 4, day: 21),
    },
    'cds': {
      'notification': (month: 12, day: 20),
      'application_end': (month: 1, day: 10),
      'exam': (month: 4, day: 14),
    },
    'afcat': {
      'notification': (month: 5, day: 20),
      'application_end': (month: 6, day: 12),
      'exam': (month: 8, day: 5),
    },
  };

  List<Map<String, dynamic>> upcomingDeadlines({
    Set<String>? prioritizedExamIds,
    int limit = 6,
  }) {
    final now = DateTime.now();
    final candidates = <Map<String, dynamic>>[];

    for (final exam in ExamData.allExams) {
      if (prioritizedExamIds != null &&
          prioritizedExamIds.isNotEmpty &&
          !prioritizedExamIds.contains('ALL_EXAMS') &&
          !prioritizedExamIds.contains('NONE') &&
          !prioritizedExamIds.contains(exam.id)) {
        continue;
      }

      final date = _nextDateFor(exam.id, 'application_end', now) ??
          now.add(const Duration(days: 30));
      final daysLeft = date.difference(now).inDays;
      final urgency =
          daysLeft <= 7 ? 'high' : (daysLeft <= 21 ? 'medium' : 'low');

      candidates.add({
        'examId': exam.id,
        'examName': exam.code,
        'event': 'Application Deadline',
        'date': date,
        'urgency': urgency,
      });
    }

    candidates.sort(
      (a, b) =>
          (a['date'] as DateTime).compareTo((b['date'] as DateTime)),
    );
    return candidates.take(limit).toList();
  }

  List<Map<String, dynamic>> timelineEvents({
    Set<String>? prioritizedExamIds,
    int limit = 24,
  }) {
    final now = DateTime.now();
    final events = <Map<String, dynamic>>[];

    for (final exam in ExamData.allExams) {
      if (prioritizedExamIds != null &&
          prioritizedExamIds.isNotEmpty &&
          !prioritizedExamIds.contains('ALL_EXAMS') &&
          !prioritizedExamIds.contains('NONE') &&
          !prioritizedExamIds.contains(exam.id)) {
        continue;
      }

      final notification = _dateForCurrentCycle(exam.id, 'notification', now);
      final deadline = _dateForCurrentCycle(exam.id, 'application_end', now);
      final examDate = _dateForCurrentCycle(exam.id, 'exam', now);

      if (notification != null) {
        events.add(_buildEvent(exam, 'Notification Released', notification,
            'notification', now));
      }
      if (deadline != null) {
        events.add(_buildEvent(exam, 'Application Deadline', deadline,
            'application_end', now));
      }
      if (examDate != null) {
        events.add(_buildEvent(exam, 'Exam Date', examDate, 'exam', now));
      }
    }

    events.sort(
      (a, b) =>
          (a['date'] as DateTime).compareTo((b['date'] as DateTime)),
    );
    return events.take(limit).toList();
  }

  Map<String, dynamic> _buildEvent(
    ExamInfo exam,
    String title,
    DateTime date,
    String type,
    DateTime now,
  ) {
    return {
      'examId': exam.id,
      'examName': exam.code,
      'event': title,
      'date': date,
      'completed': date.isBefore(now),
      'type': type,
    };
  }

  DateTime? _nextDateFor(String examId, String eventKey, DateTime now) {
    final template = _calendar[examId]?[eventKey];
    if (template == null) return null;
    final year = now.year;
    var date = DateTime(year, template.month, template.day);
    if (!date.isAfter(now)) {
      date = DateTime(year + 1, template.month, template.day);
    }
    return date;
  }

  DateTime? _dateForCurrentCycle(String examId, String eventKey, DateTime now) {
    final template = _calendar[examId]?[eventKey];
    if (template == null) return null;
    final currentYearDate = DateTime(now.year, template.month, template.day);
    if (currentYearDate.isBefore(now.subtract(const Duration(days: 120)))) {
      return DateTime(now.year + 1, template.month, template.day);
    }
    return currentYearDate;
  }
}

