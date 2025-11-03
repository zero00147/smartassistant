import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Hugging Face Inference API Service
class HuggingFaceService {
  final String _apiToken;
  final String modelUrl;

  HuggingFaceService({
    String? model,
    String? apiToken,
  })  : _apiToken = apiToken ?? dotenv.env['HF_API_TOKEN'] ?? '',
        modelUrl =
        'https://api-inference.huggingface.co/models/${model ?? 'google/flan-t5-small'}' {
    if (_apiToken.isEmpty) {
      throw Exception('Hugging Face token missing. Add HF_API_TOKEN to .env file.');
    }
  }

  /// Get AI response from Hugging Face
  Future<String> getResponse(String userInput) async {
    if (userInput.trim().isEmpty) return "Please enter a question.";

    try {
      final response = await http.post(
        Uri.parse(modelUrl),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "inputs": userInput,
          "parameters": {
            "max_length": 200,
            "temperature": 0.7,
          },
          "options": {
            "use_cache": false,
            "wait_for_model": true, // Waits for model to load instead of 503
          },
        }),
      ).timeout(const Duration(seconds: 30));

      switch (response.statusCode) {
        case 200:
          final data = jsonDecode(response.body);
          return _parseGeneratedText(data);

        case 401:
          return "Unauthorized: Invalid API token.";

        case 403:
          return "Forbidden: You may need to accept model terms on Hugging Face.";

        case 404:
          return "Model not found. Check the model name.";

        case 503:
          final errorData = jsonDecode(response.body);
          final waitTime = (errorData['estimated_time'] ?? 20).toInt();
          return "Model is loading... Try again in ~$waitTime seconds.";

        default:
          return "Error ${response.statusCode}: ${response.body}";
      }
    } on http.ClientException catch (e) {
      return "Network error: $e";
    } on FormatException {
      return "Invalid response from server.";
    } catch (e) {
      return "Unexpected error: $e";
    }
  }

  /// Safely extract text from HF response (supports List and Map)
  String _parseGeneratedText(dynamic data) {
    try {
      // flan-t5-small returns: [{"generated_text": "answer"}]
      if (data is List && data.isNotEmpty) {
        final item = data[0];
        if (item is Map && item.containsKey('generated_text')) {
          return item['generated_text'].toString().trim();
        }
      }

      // Fallback: some models return plain map
      if (data is Map && data['generated_text'] != null) {
        return data['generated_text'].toString().trim();
      }

      // If error field exists
      if (data is Map && data['error'] != null) {
        return "HF Error: ${data['error']}";
      }

      return "No valid response: $data";
    } catch (e) {
      return "Parse error: $e";
    }
  }
}