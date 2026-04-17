import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreExamService {
  FirestoreExamService._();
  static final FirestoreExamService instance = FirestoreExamService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchDeadlines({
    Set<String>? prioritizedExamIds,
  }) async {
    Query<Map<String, dynamic>> query =
        _db.collection('exam_deadlines').orderBy('date');

    if (prioritizedExamIds != null &&
        prioritizedExamIds.isNotEmpty &&
        prioritizedExamIds.length <= 10) {
      query = query.where('examId', whereIn: prioritizedExamIds.toList());
    }

    final snap = await query.get();

    return snap.docs.map((d) {
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
  }

  Future<List<Map<String, dynamic>>> fetchTimelineEvents({
    Set<String>? prioritizedExamIds,
  }) async {
    Query<Map<String, dynamic>> query =
        _db.collection('timeline_events').orderBy('date');

    if (prioritizedExamIds != null &&
        prioritizedExamIds.isNotEmpty &&
        prioritizedExamIds.length <= 10) {
      query = query.where('examId', whereIn: prioritizedExamIds.toList());
    }

    final snap = await query.get();

    return snap.docs.map((d) {
      final m = d.data();
      final ts = m['date'];
      return {
        'examId': (m['examId'] ?? '').toString(),
        'examName': (m['examName'] ?? '').toString(),
        'event': (m['event'] ?? '').toString(),
        'type': (m['type'] ?? 'notification').toString(),
        'date': ts is Timestamp ? ts.toDate() : DateTime.now(),
        'completed': m['completed'] == true,
      };
    }).toList();
  }
}