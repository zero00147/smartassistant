// groq_service.dart (New for Groq API)
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../main.dart';

class GroqService {
  final String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  GroqService() {
    if (groqApiKey == null || groqApiKey!.isEmpty) {
      throw Exception('GROQ_API_KEY not loaded. Check .env file in project root.');
    }
  }

  Future<String> getResponse(String userInput) async {
    if (userInput.trim().isEmpty) return "Ask me anything!";

    try {
      final response = await http
          .post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "llama-3.1-8b-instant",
          "messages": [
            {"role": "user", "content": userInput},
          ],
          "temperature": 0.7,
          "max_tokens": 150,
        }),
      )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content']?.toString().trim() ?? "No response.";
      } else {
        return "Server error (${response.statusCode}). Try again.";
      }
    } on TimeoutException {
      return "Request timed out.";
    } catch (e) {
      return "AI error: $e";
    }
  }
}