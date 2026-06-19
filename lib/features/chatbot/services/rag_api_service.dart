import 'dart:convert';
import 'package:http/http.dart' as http;

class RagApiService {
  static const String _baseUrl = 'https://malakmohamed21-robot-api.hf.space';

  Future<({String response, List<Map<String, dynamic>>? sources})> sendMessage({
    required String message,
    String? plant,
    String? disease,
    List<Map<String, String>> history = const [],
  }) async {
    int attempt = 0;
    while (true) {
      try {
        final payload = {
          "message": message,
          "plant": plant ?? "Unknown",
          "disease": disease ?? "Unknown",
          "history": history,
        };

        final res = await http
            .post(
              Uri.parse('$_baseUrl/chat'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 90));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final responseText = data['response'] as String? ?? 'No response received from AI.';
          
          List<Map<String, dynamic>>? sources;
          if (data['sources'] != null) {
             sources = (data['sources'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }

          return (response: responseText, sources: sources);
        } else {
          throw Exception('Failed to get RAG response: \${res.statusCode}');
        }
      } catch (e) {
        attempt++;
        if (attempt >= 3) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }
  }
}
