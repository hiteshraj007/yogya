import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/remote/firestore_exam_service.dart';
import '../../core/constants/exam_data.dart';

String examIdsToKey(Set<String>? examIds) {
  if (examIds == null || examIds.isEmpty) return '';
  final sorted = examIds.toList()..sort();
  return sorted.join(',');
}

Set<String>? keyToExamIds(String key) {
  if (key == 'NONE') return {};
  if (key.trim().isEmpty) return null;
  return key
      .split(',')
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toSet();
}

final allExamsProvider = FutureProvider<List<ExamInfo>>((ref) async {
  final rawData = await FirestoreExamService.instance.fetchExams();
  if (rawData.isEmpty) return ExamData.allExams;
  
  return rawData.map((m) => ExamInfo(
    id: (m['id'] ?? '').toString(),
    name: (m['name'] ?? '').toString(),
    code: (m['code'] ?? '').toString(),
    conductingBody: (m['conductingBody'] ?? '').toString(),
    qualification: (m['qualification'] ?? '').toString(),
    minAge: m['minAge'] ?? 18,
    maxAgeGeneral: m['maxAgeGeneral'] ?? 30,
    maxAgeOBC: m['maxAgeOBC'] ?? 33,
    maxAgeSC: m['maxAgeSC'] ?? 35,
    maxAgeST: m['maxAgeST'] ?? 35,
    maxAttemptsGeneral: m['maxAttemptsGeneral'] ?? -1,
    maxAttemptsOBC: m['maxAttemptsOBC'] ?? -1,
    maxAttemptsSCST: m['maxAttemptsSCST'] ?? -1,
    category: (m['category'] ?? 'General').toString(),
    description: (m['description'] ?? '').toString(),
    icon: (m['icon'] ?? '📝').toString(),
    registrationUrl: (m['registrationUrl'] ?? '').toString(),
    officialInfoUrl: (m['officialInfoUrl'] ?? '').toString(),
  )).toList();
});

final deadlinesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, key) async {
  return FirestoreExamService.instance.fetchDeadlines(
    prioritizedExamIds: keyToExamIds(key),
  );
});

final timelineEventsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, key) async {
  return FirestoreExamService.instance.fetchTimelineEvents(
    prioritizedExamIds: keyToExamIds(key),
  );
});