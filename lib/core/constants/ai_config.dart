import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiConfig {
  // Free tier cloud APIs for OCR fallback
  static String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static String get groqModel =>
      dotenv.env['GROQ_MODEL'] ?? 'meta-llama/llama-4-scout-17b-16e-instruct';
  
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get geminiModel => dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.5-flash';
  
  // Thresholds for routing
  static const double tierUpgradeConfidence = 0.85;
  static const double manualReviewConfidence = 0.60;
}
