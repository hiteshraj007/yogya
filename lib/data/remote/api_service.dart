import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/exam_data.dart';
import '../../core/services/exam_timeline_service.dart';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const String baseUrl = 'https://api.example.com/v1';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Set this to false when real backend is available.
  bool simulateRealtime = false;

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'yogya_api_jwt');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    if (simulateRealtime) {
      return _simulate(
        () => {
          'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
          'user': {'email': email.trim()},
        },
      );
    }

    final response = await _safePost(
      '/auth/login',
      data: {
        'email': email.trim(),
        'password': password,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final token = data['token']?.toString();
    if (token != null && token.isNotEmpty) {
      await _storage.write(key: 'yogya_api_jwt', value: token);
    }
    return data;
  }

  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
  }) async {
    if (simulateRealtime) {
      return _simulate(
        () => {
          'token': 'mock_google_token_${DateTime.now().millisecondsSinceEpoch}',
          'provider': 'google',
        },
      );
    }

    final response = await _safePost(
      '/auth/google',
      data: {'idToken': idToken},
    );
    final data = response.data as Map<String, dynamic>;
    final token = data['token']?.toString();
    if (token != null && token.isNotEmpty) {
      await _storage.write(key: 'yogya_api_jwt', value: token);
    }
    return data;
  }

  Future<List<Map<String, dynamic>>> fetchExams() async {
    if (simulateRealtime) {
      return _simulate(
        () => ExamData.allExams
            .map(
              (exam) => {
                'id': exam.id,
                'name': exam.name,
                'code': exam.code,
                'conductingBody': exam.conductingBody,
                'qualification': exam.qualification,
                'category': exam.category,
                'icon': exam.icon,
              },
            )
            .toList(),
      );
    }

    final response = await _safeGet('/exams');
    final list = (response.data as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchTrackedExams({
    Set<String>? trackedExamIds,
  }) async {
    if (simulateRealtime) {
      return _simulate(() {
        final ids = trackedExamIds ?? <String>{};
        final selected = ids.isEmpty
            ? ExamData.allExams.take(5).toList()
            : ExamData.allExams.where((exam) => ids.contains(exam.id)).toList();

        return selected
            .map(
              (exam) => {
                'examId': exam.id,
                'examName': exam.code,
                'isTracked': true,
              },
            )
            .toList();
      });
    }

    final response = await _safeGet('/exams/tracked');
    final list = (response.data as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchDeadlines({
    Set<String>? prioritizedExamIds,
  }) async {
    if (simulateRealtime) {
      return _simulate(
        () => ExamTimelineService.instance.upcomingDeadlines(
          prioritizedExamIds: prioritizedExamIds,
        ),
      );
    }

    final response = await _safeGet('/deadlines');
    final list = (response.data as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchTimelineEvents({
    Set<String>? prioritizedExamIds,
  }) async {
    if (simulateRealtime) {
      return _simulate(
        () => ExamTimelineService.instance.timelineEvents(
          prioritizedExamIds: prioritizedExamIds,
        ),
      );
    }

    final response = await _safeGet('/timeline/events');
    final list = (response.data as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> syncEligibility({
    required List<Map<String, dynamic>> results,
  }) async {
    if (simulateRealtime) {
      await _simulate(() => true);
      return;
    }

    await _safePost('/eligibility/sync', data: {'results': results});
  }

  Future<void> syncDeviceToken({
    required String token,
    String platform = 'android',
  }) async {
    if (simulateRealtime) {
      await _simulate(() => true, minMs: 250, maxMs: 700);
      return;
    }

    await _safePost(
      '/devices/register',
      data: {
        'token': token,
        'platform': platform,
      },
    );
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'yogya_api_jwt');
  }

  Future<T> _simulate<T>(
    T Function() builder, {
    int minMs = 450,
    int maxMs = 1200,
  }) async {
    final jitterBase = DateTime.now().microsecondsSinceEpoch;
    final delta = maxMs - minMs;
    final jitter = delta <= 0 ? 0 : (jitterBase % (delta + 1));

    await Future.delayed(Duration(milliseconds: minMs + jitter));
    return builder();
  }

  Future<Response<dynamic>> _safeGet(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  Future<Response<dynamic>> _safePost(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  String _errorMessage(DioException e) {
    final status = e.response?.statusCode;
    final message = e.response?.data is Map
        ? (e.response!.data['message']?.toString() ?? 'Request failed')
        : e.message ?? 'Request failed';
    if (status == null) return 'Network error: $message';
    return 'HTTP $status: $message';
  }
}
