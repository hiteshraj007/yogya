import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreExamService {
  FirestoreExamService._();
  static final FirestoreExamService instance = FirestoreExamService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchExams() async {
    try {
      final snap = await _db.collection('exams').get();
      if (snap.docs.isEmpty) return [];
      return snap.docs.map((d) => d.data()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchDeadlines({
    Set<String>? prioritizedExamIds,
  }) async {
    Query<Map<String, dynamic>> query =
        _db.collection('exam_deadlines');

    if (prioritizedExamIds != null) {
      if (prioritizedExamIds.isEmpty) return [];
      if (prioritizedExamIds.length <= 10) {
        query = query.where('examId', whereIn: prioritizedExamIds.toList());
      }
    }

    final snap = await query.get();

    final results = snap.docs.map((d) {
      final m = d.data();
      final ts = m['date'];
      return {
        'examId': (m['examId'] ?? '').toString(),
        'examName': (m['examName'] ?? '').toString(),
        'event': (m['event'] ?? '').toString(),
        'date': ts is Timestamp ? ts.toDate() : DateTime.now(),
        'urgency': (m['urgency'] ?? 'low').toString(),
      };
    }).toList();
    
    results.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    return results;
  }

  Future<List<Map<String, dynamic>>> fetchTimelineEvents({
    Set<String>? prioritizedExamIds,
  }) async {
    Query<Map<String, dynamic>> query =
        _db.collection('timeline_events');

    if (prioritizedExamIds != null) {
      if (prioritizedExamIds.isEmpty) return [];
      if (prioritizedExamIds.length <= 10) {
        query = query.where('examId', whereIn: prioritizedExamIds.toList());
      }
    }

    final snap = await query.get();

    final results = snap.docs.map((d) {
      final m = d.data();
      final ts = m['date'];
      return {
        'examId': (m['examId'] ?? '').toString(),
        'examName': (m['examName'] ?? '').toString(),
        'event': (m['event'] ?? '').toString(),
        'type': (m['type'] ?? 'notification').toString(),
        'date': ts is Timestamp ? ts.toDate() : DateTime.now(),
        'completed': m['completed'] == true,
        'sourceUrl': (m['sourceUrl'] ?? '').toString(),
      };
    }).toList();
    
    results.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    return results;
  }

  // ── REAL-TIME STREAMS ──────────────────────────────────
  // These streams auto-update in the UI whenever Cloud Function
  // pushes new data to Firestore — no manual sync needed!

  Stream<List<Map<String, dynamic>>> watchExams() async* {
    try {
      await for (final snap in _db.collection('exams').snapshots()) {
        if (snap.docs.isEmpty) {
          yield <Map<String, dynamic>>[];
        } else {
          yield snap.docs.map((d) => d.data()).toList();
        }
      }
    } catch (_) {
      // Fallback if firestore rules deny access or offline
      yield <Map<String, dynamic>>[];
    }
  }

  Stream<List<Map<String, dynamic>>> watchTimelineEvents({
    Set<String>? prioritizedExamIds,
  }) async* {
    try {
      Query<Map<String, dynamic>> query = _db.collection('timeline_events');

      if (prioritizedExamIds != null) {
        if (prioritizedExamIds.contains('NONE')) {
          yield <Map<String, dynamic>>[];
          return;
        }
        if (!prioritizedExamIds.contains('ALL_EXAMS') && prioritizedExamIds.isNotEmpty) {
          if (prioritizedExamIds.length <= 10) {
            query = query.where('examId', whereIn: prioritizedExamIds.toList());
          }
        }
      }

      await for (final snap in query.snapshots()) {
        final results = snap.docs.map((d) {
          final m = d.data();
          final ts = m['date'];
          return {
            'examId': (m['examId'] ?? '').toString(),
            'examName': (m['examName'] ?? '').toString(),
            'event': (m['event'] ?? '').toString(),
            'type': (m['type'] ?? 'notification').toString(),
            'date': ts is Timestamp ? ts.toDate() : DateTime.now(),
            'completed': m['completed'] == true,
            'sourceUrl': (m['sourceUrl'] ?? '').toString(),
          };
        }).toList();

        results.sort(
            (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
        yield results;
      }
    } catch (_) {
      yield <Map<String, dynamic>>[];
    }
  }

  Stream<List<Map<String, dynamic>>> watchDeadlines({
    Set<String>? prioritizedExamIds,
  }) async* {
    try {
      Query<Map<String, dynamic>> query = _db.collection('exam_deadlines');

      if (prioritizedExamIds != null) {
        if (prioritizedExamIds.contains('NONE')) {
          yield <Map<String, dynamic>>[];
          return;
        }
        if (!prioritizedExamIds.contains('ALL_EXAMS') && prioritizedExamIds.isNotEmpty) {
          if (prioritizedExamIds.length <= 10) {
            query = query.where('examId', whereIn: prioritizedExamIds.toList());
          }
        }
      }

      await for (final snap in query.snapshots()) {
        final results = snap.docs.map((d) {
          final m = d.data();
          final ts = m['date'];
          return {
            'examId': (m['examId'] ?? '').toString(),
            'examName': (m['examName'] ?? '').toString(),
            'event': (m['event'] ?? '').toString(),
            'date': ts is Timestamp ? ts.toDate() : DateTime.now(),
            'urgency': (m['urgency'] ?? 'low').toString(),
          };
        }).toList();

        results.sort(
            (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
        yield results;
      }
    } catch (_) {
      yield <Map<String, dynamic>>[];
    }
  }
}