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

final _baseExamsStreamProvider = StreamProvider<List<ExamInfo>>((ref) {
  return FirestoreExamService.instance.watchExams().map((rawData) {
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
      annualFrequency: m['annualFrequency'] ?? 1,
    )).toList();
  });
});

final allExamsProvider = Provider<AsyncValue<List<ExamInfo>>>((ref) {
  final baseExamsAsync = ref.watch(_baseExamsStreamProvider);
  final timelineAsync = ref.watch(timelineStreamProvider(''));

  if (baseExamsAsync.isLoading || timelineAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final baseExams = baseExamsAsync.value ?? ExamData.allExams;
  final timelineEvents = timelineAsync.value ?? [];

  final Map<String, ExamInfo> combinedMap = {};
  for (final exam in baseExams) {
    combinedMap[exam.name.toLowerCase()] = exam;
  }

  ExamInfo _createDynamicExam(String name, String code, String url, Map<String, dynamic> event) {
    int minAge = event['minAge'] as int? ?? 18;
    int maxAge = event['maxAge'] as int? ?? 40;
    
    // If we haven't successfully scraped yet, fallback to '10th Pass' so it still appears
    String qualification = (event['qualification'] as String? ?? '').trim();
    if (qualification.isEmpty) {
      qualification = '10th Pass'; 
    }
    int frequency = 1;
    int maxAttempts = -99;

    final lower = name.toLowerCase();
    
    // Apply basic heuristics for missing fields
    if (lower.contains(RegExp(r'\bmppsc\b|\bbpsc\b|\buppsc\b|\brpsc\b|\bupessc\b'))) {
      if (event['maxAge'] == null) maxAge = 40;
      if (event['minAge'] == null) minAge = 21;
      maxAttempts = -1;
    } else if (lower.contains(RegExp(r'\bairforce\b|\bnavy\b|\barmy\b|\bdefence\b'))) {
      if (event['maxAge'] == null) maxAge = 23;
      if (event['minAge'] == null) minAge = 17;
      frequency = 2;
      maxAttempts = -1;
    } else if (lower.contains(RegExp(r'\bbank\b|\bsbi\b|\bibps\b|\brbi\b'))) {
      if (event['maxAge'] == null) maxAge = 30;
      if (event['minAge'] == null) minAge = 20;
      maxAttempts = -1;
    } else if (lower.contains(RegExp(r'\bssc\b'))) {
      if (event['maxAge'] == null) maxAge = 32;
      if (event['minAge'] == null) minAge = 18;
      maxAttempts = -1;
    } else {
      if (event['maxAge'] == null) maxAge = 45;
    }

    return ExamInfo(
      id: name.toLowerCase().replaceAll(' ', '_'),
      name: name,
      code: code.toUpperCase().replaceAll('_', ' '),
      conductingBody: 'Government/Public Sector',
      qualification: qualification,
      minAge: minAge,
      maxAgeGeneral: maxAge,
      maxAgeOBC: maxAge + 3,
      maxAgeSC: maxAge + 5,
      maxAgeST: maxAge + 5,
      maxAttemptsGeneral: maxAttempts,
      maxAttemptsOBC: maxAttempts,
      maxAttemptsSCST: maxAttempts,
      category: 'Other',
      description: 'Live update from Sarkari Result',
      icon: '🔔',
      registrationUrl: '',
      officialInfoUrl: url,
      annualFrequency: frequency,
    );
  }

  for (final event in timelineEvents) {
    final name = (event['examName'] as String? ?? '').trim();
    final lowerName = name.toLowerCase();

    // Skip obvious non-exams or spam entries
    if (lowerName.contains('urgent hiring') || 
        lowerName.contains('sarkari result') || 
        lowerName.contains('download') ||
        lowerName.contains('rojgar result')) {
      continue;
    }

    final code = (event['examId'] as String? ?? '').trim();

    if (name.isNotEmpty && !combinedMap.containsKey(name.toLowerCase())) {
      combinedMap[name.toLowerCase()] = _createDynamicExam(
        name,
        code,
        (event['sourceUrl'] as String? ?? '').trim(),
        event,
      );
    }
  }

  return AsyncValue.data(combinedMap.values.toList());
});

// ── One-shot fetch (legacy, kept for backward compatibility) ──
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

// ── REAL-TIME STREAM PROVIDERS ────────────────────────────
// These use Firestore snapshots — UI auto-refreshes when
// Cloud Function pushes new data. No manual sync needed!

final timelineStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, key) {
  return FirestoreExamService.instance.watchTimelineEvents(
    prioritizedExamIds: keyToExamIds(key),
  );
});

final deadlinesStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, key) {
  return FirestoreExamService.instance.watchDeadlines(
    prioritizedExamIds: keyToExamIds(key),
  );
});







