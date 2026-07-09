// import 'dart:io';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../core/services/ocr_service.dart';
// import '../../data/local/hive_service.dart';
// import '../../data/models/academic_doc_model.dart';

// // ── OCR State ─────────────────────────────────────────────
// enum OcrStatus { idle, picking, processing, done, error }

// class OcrState {
//   final OcrStatus status;
//   final double    progress;
//   final String    statusMessage;
//   final OcrResult? result;
//   final String?   errorMessage;

//   const OcrState({
//     this.status        = OcrStatus.idle,
//     this.progress      = 0.0,
//     this.statusMessage = '',
//     this.result,
//     this.errorMessage,
//   });

//   OcrState copyWith({
//     OcrStatus? status,
//     double?    progress,
//     String?    statusMessage,
//     OcrResult? result,
//     String?    errorMessage,
//   }) {
//     return OcrState(
//       status:        status        ?? this.status,
//       progress:      progress      ?? this.progress,
//       statusMessage: statusMessage ?? this.statusMessage,
//       result:        result        ?? this.result,
//       errorMessage:  errorMessage  ?? this.errorMessage,
//     );
//   }
// }

// // ── OCR Notifier ──────────────────────────────────────────
// class OcrNotifier extends StateNotifier<OcrState> {
//   OcrNotifier() : super(const OcrState());

//   final _ocrService = OcrService.instance;

//   // ── Camera se scan karo ───────────────────────────────
//   Future<OcrResult?> scanFromCamera() async {
//     return _processImage(() => _ocrService.pickFromCamera());
//   }

//   // ── Gallery se pick karo ──────────────────────────────
//   Future<OcrResult?> scanFromGallery() async {
//     return _processImage(() => _ocrService.pickFromGallery());
//   }

//   // ── Common processing logic ───────────────────────────
//   Future<OcrResult?> _processImage(
//     Future<File?> Function() picker,
//   ) async {
//     // Step 1 — Picking
//     state = state.copyWith(
//       status:        OcrStatus.picking,
//       progress:      0.1,
//       statusMessage: 'Opening camera...',
//     );

//     final imageFile = await picker();
//     if (imageFile == null) {
//       state = const OcrState(); // reset
//       return null;
//     }

//     // Step 2 — Pre-processing
//     state = state.copyWith(
//       status:        OcrStatus.processing,
//       progress:      0.3,
//       statusMessage: 'Layer 1: Pre-processing image...',
//     );
//     await Future.delayed(const Duration(milliseconds: 600));

//     // Step 3 — Layout detection
//     state = state.copyWith(
//       progress:      0.5,
//       statusMessage: 'Layer 2: Detecting document layout...',
//     );
//     await Future.delayed(const Duration(milliseconds: 500));

//     // Step 4 — Text extraction
//     state = state.copyWith(
//       progress:      0.7,
//       statusMessage: 'Layer 3: Extracting text...',
//     );

//     final result = await _ocrService.extractText(imageFile);

//     // Step 5 — Parsing
//     state = state.copyWith(
//       progress:      0.9,
//       statusMessage: 'Layer 4: Parsing data...',
//     );
//     await Future.delayed(const Duration(milliseconds: 400));

//     if (!result.success) {
//       state = state.copyWith(
//         status:       OcrStatus.error,
//         progress:     0.0,
//         errorMessage: result.errorMessage,
//       );
//       return null;
//     }

//     // Step 6 — Save to Hive
//     final doc = AcademicDocModel(
//       id:            DateTime.now().millisecondsSinceEpoch.toString(),
//       docType:       result.docType,
//       extractedText: result.rawText,
//       board:         result.board,
//       year:          result.year,
//       aggregate:     result.aggregate,
//       stream:        result.stream,
//       confidence:    result.confidence,
//       isVerified:    true, // Marked as verified upon successful extraction
//       uploadedAt:    DateTime.now(),
//     );
//     await HiveService.saveDoc(doc);

//     // Done
//     state = state.copyWith(
//       status:        OcrStatus.done,
//       progress:      1.0,
//       statusMessage: 'Done! Data extracted successfully.',
//       result:        result,
//     );

//     return result;
//   }

//   void reset() => state = const OcrState();
// }

// // ── Provider ──────────────────────────────────────────────
// final ocrProvider =
//     StateNotifierProvider<OcrNotifier, OcrState>(
//         (ref) => OcrNotifier());


import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:image/image.dart' as img;
import '../../core/constants/ai_config.dart';
import '../../core/services/groq_doc_service.dart';
import '../../core/services/gemini_doc_service.dart';
import '../../core/services/ai_consensus_merger.dart';
import '../../core/services/ocr_post_processor.dart';
import '../../core/services/ocr_service.dart';
import '../../data/local/hive_service.dart';
import '../../data/models/academic_doc_model.dart';
import '../providers/auth_provider.dart';

// ── Top-Level Function for Isolate ─────────────────────────
// This must be a top-level function to be run in `compute`.
// It prevents the heavy image processing from freezing the main UI thread.
List<int> _flattenImageBackground(Uint8List pngBytes) {
  final rawImage = img.decodePng(pngBytes);
  if (rawImage != null) {
    final whiteBg = img.Image(width: rawImage.width, height: rawImage.height);
    img.fill(whiteBg, color: img.ColorRgb8(255, 255, 255));
    img.compositeImage(whiteBg, rawImage); // Draw PDF over white background
    return img.encodeJpg(whiteBg, quality: 90); // Use JPG to ensure no transparency
  }
  return pngBytes;
}

// ── OCR State ─────────────────────────────────────────────
enum OcrStatus { idle, picking, processing, done, error }

class OcrState {
  final OcrStatus status;
  final double progress;
  final String statusMessage;
  final OcrResult? result;
  final String? errorMessage;
  final bool needsReview;

  const OcrState({
    this.status = OcrStatus.idle,
    this.progress = 0.0,
    this.statusMessage = '',
    this.result,
    this.errorMessage,
    this.needsReview = false,
  });

  OcrState copyWith({
    OcrStatus? status,
    double? progress,
    String? statusMessage,
    OcrResult? result,
    String? errorMessage,
    bool? needsReview,
  }) {
    return OcrState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      statusMessage: statusMessage ?? this.statusMessage,
      result: result ?? this.result,
      errorMessage: errorMessage,
      needsReview: needsReview ?? this.needsReview,
    );
  }
}

// ── OCR Notifier ──────────────────────────────────────────
class OcrNotifier extends StateNotifier<OcrState> {
  final Ref ref;
  OcrNotifier(this.ref) : super(const OcrState());

  final _ocrService = OcrService.instance;
  int _runId = 0;

  Future<OcrResult?> scanFromCamera() async {
    return _processImage(() => _ocrService.pickFromCamera());
  }

  Future<OcrResult?> scanFromGallery() async {
    return _processImage(() => _ocrService.pickFromGallery());
  }

  Future<OcrResult?> parsePdfBytes(Uint8List bytes, String filename) async {
    state = state.copyWith(
      status: OcrStatus.picking,
      progress: 0.1,
      statusMessage: 'Preparing PDF...',
      errorMessage: null,
      needsReview: false,
    );

    state = state.copyWith(
      status: OcrStatus.processing,
      progress: 0.2,
      statusMessage: 'Converting PDF to Image...',
    );

    try {
      // Rasterize the first page of the PDF to an image
      final raster = await Printing.raster(bytes, pages: [0], dpi: 300).first;
      final pngBytes = await raster.toPng();

      // Run the heavy image decode/encode process on a background isolate to keep UI smooth
      final finalBytes = await compute(_flattenImageBackground, pngBytes);

      // Save the image bytes to a temporary file so _processImage can use it
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(p.join(tempDir.path, 'temp_pdf_page.jpg'));
      await tempFile.writeAsBytes(finalBytes);

      // Now pass this image file through our existing Smart Hybrid AI flow!
      return await _processImage(() async => tempFile, overrideSavedFileName: filename, overrideSavedFileBytes: bytes);
    } catch (e) {
      state = state.copyWith(
        status: OcrStatus.error,
        progress: 0.0,
        errorMessage: 'Failed to read PDF file. Make sure it is a valid document.',
        needsReview: false,
      );
      return null;
    }
  }

  Future<OcrResult?> _processImage(
    Future<File?> Function() picker, {
    String? overrideSavedFileName,
    Uint8List? overrideSavedFileBytes,
  }) async {
    final runId = ++_runId;
    state = state.copyWith(
      status: OcrStatus.picking,
      progress: 0.1,
      statusMessage: 'Opening document...',
      errorMessage: null,
      needsReview: false,
    );

    final imageFile = await picker();
    if (runId != _runId) return null;
    if (imageFile == null) {
      state = const OcrState();
      return null;
    }

    state = state.copyWith(
      status: OcrStatus.processing,
      progress: 0.3,
      statusMessage: 'Layer 1: Pre-processing image...',
    );
    await Future.delayed(const Duration(milliseconds: 350));

    state = state.copyWith(
      progress: 0.5,
      statusMessage: 'Layer 2: Detecting document layout...',
    );
    await Future.delayed(const Duration(milliseconds: 300));

    state = state.copyWith(
      progress: 0.7,
      statusMessage: 'Layer 3: Extracting text...',
    );

    final result = await _ocrService.extractText(imageFile);
    if (runId != _runId) return null;

    state = state.copyWith(
      progress: 0.9,
      statusMessage: 'Layer 4: Parsing data...',
    );
    await Future.delayed(const Duration(milliseconds: 250));

    if (!result.success) {
      state = state.copyWith(
        status: OcrStatus.error,
        progress: 0.0,
        errorMessage: result.errorMessage ?? 'OCR failed',
        needsReview: false,
      );
      return null;
    }

    OcrResult finalResult = result;

    // ── TIER 2: Smart Dual-AI Analysis ──────────────────────
    // Runs both Groq + Gemini in PARALLEL, sends OCR raw text
    // as a second reference, then merges their results.
    if (result.confidence < AiConfig.tierUpgradeConfidence) {
      state = state.copyWith(
        progress: 0.92,
        statusMessage: 'Layer 5: AI analyzing document...',
      );

      try {
        final imageBytes = await imageFile.readAsBytes();
        final ocrRawText = result.rawText; // Pass OCR text as second reference

        // Run BOTH AI models in parallel for consensus
        final results = await Future.wait([
          GroqDocService.instance
              .analyzeDocument(imageBytes, ocrRawText: ocrRawText)
              .timeout(const Duration(seconds: 45), onTimeout: () => null),
          GeminiDocService.instance
              .analyzeDocument(imageBytes, ocrRawText: ocrRawText)
              .timeout(const Duration(seconds: 45), onTimeout: () => null),
        ]);

        final groqResult = results[0];
        final geminiResult = results[1];

        state = state.copyWith(
          progress: 0.96,
          statusMessage: 'Layer 6: Cross-verifying results...',
        );

        if (groqResult != null && groqResult.success && geminiResult != null && geminiResult.success) {
          // BEST CASE: Both models returned results → merge them
          finalResult = AiConsensusMerger.merge(groqResult, geminiResult);
          finalResult = finalResult.copyWith(imagePath: imageFile.path);
        } else if (groqResult != null && groqResult.success) {
          // Only Groq succeeded
          finalResult = groqResult.copyWith(imagePath: imageFile.path);
        } else if (geminiResult != null && geminiResult.success) {
          // Only Gemini succeeded
          finalResult = geminiResult.copyWith(imagePath: imageFile.path);
        }
        // If both failed, keep the original ML Kit result
      } catch (e) {
        print('Dual AI analysis error: $e');
      }
    }

    // ── TIER 3: Post-Processing Validation & Fix ────────────
    state = state.copyWith(
      progress: 0.98,
      statusMessage: 'Layer 7: Validating extracted data...',
    );
    finalResult = OcrPostProcessor.process(finalResult);

    if (runId != _runId) return null;

    finalResult = finalResult.copyWith(
      docType: OcrService.canonicalDocType(finalResult.docType),
    );

    final needsReview = finalResult.confidence < AiConfig.manualReviewConfidence;

    // Save image permanently for the viewer feature
    String savedFileName = '';
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      if (overrideSavedFileBytes != null && overrideSavedFileName != null) {
        final ext = p.extension(overrideSavedFileName).isNotEmpty ? p.extension(overrideSavedFileName) : '.pdf';
        final newFileName = 'doc_${DateTime.now().millisecondsSinceEpoch}$ext';
        final newPath = p.join(docsDir.path, newFileName);
        await File(newPath).writeAsBytes(overrideSavedFileBytes);
        savedFileName = newPath;
      } else {
        final ext = p.extension(imageFile.path);
        final newFileName = 'doc_${DateTime.now().millisecondsSinceEpoch}$ext';
        final newPath = p.join(docsDir.path, newFileName);
        final savedFile = await imageFile.copy(newPath);
        savedFileName = savedFile.path;
      }
    } catch (e) {
      print('Failed to save document: $e');
    }

    final doc = AcademicDocModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      docType: finalResult.docType,
      fileName: savedFileName,
      extractedText: finalResult.rawText,
      board: finalResult.board,
      year: finalResult.year,
      aggregate: finalResult.aggregate,
      stream: finalResult.stream,
      confidence: finalResult.confidence,
      isVerified: false,
      uploadedAt: DateTime.now(),
    );
    final uid = ref.read(currentUserProvider)?.uid;
    await HiveService.saveDoc(doc, uid: uid);

    state = state.copyWith(
      status: OcrStatus.done,
      progress: 1.0,
      statusMessage: needsReview ? 'Extraction done. Please review detected fields.' : 'Extracted successfully!',
      result: finalResult,
      needsReview: needsReview,
      errorMessage: null,
    );

    return finalResult;
  }

  void markReviewed() {
    state = state.copyWith(needsReview: false);
  }

  void reset() {
    _runId++;
    state = const OcrState();
  }
}

// ── Provider ──────────────────────────────────────────────
final ocrProvider = StateNotifierProvider<OcrNotifier, OcrState>(
  (ref) => OcrNotifier(ref),
);
