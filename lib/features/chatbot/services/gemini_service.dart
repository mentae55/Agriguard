import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  // Let the user pass their key dynamically or compile with --dart-define=GEMINI_API_KEY=xxx
  static const String _envApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'AIzaSyBZLttquIgHbvDOtfuhbgDlYXkEZqNBas8');
  
  // A public free-tier fallback key if user hasn't supplied one, or can be set in run-time
  String _apiKey = _envApiKey;

  void setApiKey(String key) {
    _apiKey = key;
  }

  bool get hasApiKey => _apiKey.isNotEmpty;

  /// Sends the prompt and chat history to the Gemini API
  /// Supports crop, disease context, and falls back to local database if needed.
  Future<String> generateAgriculturalReply({
    required String prompt,
    required String crop,
    required String disease,
    List<Map<String, String>> history = const [],
  }) async {
    // 1. Guard against off-topic queries immediately in Flutter before calling API
    if (_isOffTopic(prompt)) {
      return "I am AgriGuard AI, your specialized agricultural assistant. I am programmed to only assist with plant diseases, soil health, farming advice, and crop management. Please ask a question related to these topics.";
    }

    if (_apiKey.isEmpty) {
      debugPrint('[GeminiService] API Key is missing. Using local fallback database.');
      return _getLocalResponse(prompt, crop, disease);
    }

    try {
      // Use gemini-2.5-flash as it is fast, free-tier friendly, and handles chat well
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey');

      // Build history and current context
      final List<Map<String, dynamic>> contents = [];

      final String localFact = _getLocalResponse(prompt, crop, disease);
      final String systemInstruction = 
          "You are AgriGuard AI, a helpful agricultural assistant.\n"
          "STRICT ROUTING RULES:\n"
          "1. GENERAL CHAT: If the user asks a casual/general question (e.g., 'Hello', 'How are you?', 'What can you do?'), answer naturally.\n"
          "2. HYBRID RESPONSE: If the user asks about plant diseases, symptoms, '$crop', or '$disease', you MUST base your answer EXACTLY on the following official API diagnosis. "
          "You may rephrase the explanation in simpler language, but you MUST NOT change the disease name, modify the diagnosis, or hallucinate new medical/agricultural facts.\n"
          "The official API diagnosis is the single source of truth.\n\n"
          "OFFICIAL API DIAGNOSIS & FACTS:\n"
          "$localFact\n\n"
          "Give concise, practical, and structured answers (use bold text and bullet points).";

      // Build contents array in the format expected by Gemini API
      // { "role": "user"|"model", "parts": [ { "text": "..." } ] }
      for (var turn in history) {
        contents.add({
          'role': turn['role'] == 'user' ? 'user' : 'model',
          'parts': [
            {'text': turn['text']}
          ]
        });
      }

      // Add the current prompt with context prefix to ensure strict compliance
      contents.add({
        'role': 'user',
        'parts': [
          {'text': "[Context: Crop = $crop, Condition = $disease]. User query: $prompt"}
        ]
      });

      final body = {
        'contents': contents,
        'systemInstruction': {
          'parts': [
            {'text': systemInstruction}
          ]
        },
        'generationConfig': {
          'temperature': 0.1, // Very low temp keeps AI focused and avoids hallucination of medical facts
          'maxOutputTokens': 800,
        }
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map?;
          final parts = content?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final String reply = parts[0]['text']?.toString() ?? '';
            if (reply.isNotEmpty) {
              return reply;
            }
          }
        }
      }

      debugPrint('[GeminiService] API error code: ${response.statusCode}. Body: ${response.body}');
      return _getLocalResponse(prompt, crop, disease);

    } catch (e) {
      debugPrint('[GeminiService] Exception in API call: $e');
      return _getLocalResponse(prompt, crop, disease);
    }
  }

  /// Check if the query is unrelated to agriculture
  bool _isOffTopic(String prompt) {
    final query = prompt.toLowerCase();
    
    // Keywords representing safe agriculture/farming topics
    final List<String> agriKeywords = [
      'plant', 'leaf', 'disease', 'fungus', 'fungi', 'pest', 'insect', 'bug', 'soil', 'irrigate',
      'irrigation', 'water', 'fertilize', 'fertilizer', 'tomato', 'wheat', 'crop', 'farm', 'harvest',
      'treatment', 'organic', 'chemical', 'prevention', 'agriculture', 'symptom', 'rust', 'blight',
      'mildew', 'spot', 'rot', 'nitrogen', 'potassium', 'phosphorus', 'npk', 'ph', 'drainage', 'prune',
      'weed', 'pesticide', 'growth', 'greenhouse', 'care', 'healthy', 'cure', 'spray', 'doctor', 'help'
    ];

    // If query contains any of the safe keywords, it is ON-topic
    for (var word in agriKeywords) {
      if (query.contains(word)) {
        return false;
      }
    }

    // Off-topic checks for common developer/non-farming triggers
    final List<String> offTopicTriggers = [
      'python', 'javascript', 'java', 'code', 'programming', 'joke', 'movie', 'song', 'sing', 'dance',
      'weather forecast', 'stock', 'crypto', 'game', 'play', 'recipe', 'cook', 'human', 'politics'
    ];

    for (var trigger in offTopicTriggers) {
      if (query.contains(trigger)) {
        return true;
      }
    }

    // Default to false (allow standard greetings/questions, let Gemini handle minor things, but block clear off-topic)
    return false;
  }

  /// Provides highly detailed and structured plant advice offline
  String _getLocalResponse(String prompt, String crop, String disease) {
    final cleanDisease = disease.replaceAll('___', ' ').replaceAll('_', ' ').trim();
    final lowercasePrompt = prompt.toLowerCase();

    // 1. Organic Treatment Request
    if (lowercasePrompt.contains('organic') || lowercasePrompt.contains('natural') || lowercasePrompt.contains('bio')) {
      return _getOrganicTreatment(crop, disease, cleanDisease);
    }

    // 2. Prevention Request
    if (lowercasePrompt.contains('prevent') || lowercasePrompt.contains('avoid') || lowercasePrompt.contains('protect')) {
      return _getPrevention(crop, disease, cleanDisease);
    }

    // 3. Chemical Treatment Request
    if (lowercasePrompt.contains('chemical') || lowercasePrompt.contains('medicine') || lowercasePrompt.contains('spray')) {
      return _getChemicalTreatment(crop, disease, cleanDisease);
    }

    // 4. Default dynamic agricultural response using our local expert database
    final explanation = _getDiseaseExplanation(crop, disease, cleanDisease);
    final organic = _getOrganicTreatment(crop, disease, cleanDisease);
    final chemical = _getChemicalTreatment(crop, disease, cleanDisease);
    final prevention = _getPrevention(crop, disease, cleanDisease);

    return "**AgriGuard Local Expert Diagnosis Guidance**\n\n"
        "*Currently operating in local offline mode.*\n\n"
        "Here is the expert guide for **$crop** affected by **$cleanDisease**:\n\n"
        "### 🔍 Disease Explanation\n"
        "$explanation\n\n"
        "### 🌿 Organic & Natural Treatments\n"
        "$organic\n\n"
        "### 🧪 Chemical Controls\n"
        "$chemical\n\n"
        "### 🛡️ Prevention Methods\n"
        "$prevention\n\n"
        "--- \n"
        "*Tip: For personalized questions, please configure your Gemini API Key in the settings.*";
  }

  String _getDiseaseExplanation(String crop, String disease, String cleanDisease) {
    if (disease.toLowerCase().contains('healthy')) {
      return "Your $crop plant appears healthy! Keep up the good work by maintaining appropriate watering, adequate sunlight, and proper nutrient levels.";
    }

    if (crop.toLowerCase() == 'tomato') {
      if (disease.contains('Late_blight')) {
        return "Late blight is a destructive fungal-like disease caused by the water mold *Phytophthora infestans*. It thrives in cool, wet weather and can rapidly defoliate leaves, kill stems, and rot fruit.";
      }
      if (disease.contains('Early_blight')) {
        return "Early blight is caused by the fungus *Alternaria solani*. It affects foliage, stems, and fruit, showing up as brown spots with concentric rings (target spots), starting on older bottom leaves.";
      }
      if (disease.contains('Yellow_Leaf_Curl')) {
        return "Tomato Yellow Leaf Curl Virus (TYLCV) is a severe viral disease transmitted by silverleaf whiteflies. It causes severe stunting of shoots, leaf rolling/cupping, and prevents fruit setting.";
      }
      return "This is a tomato leaf condition characterized by spots, lesions, or curling. Common triggers include fungal pathogens, humidity, lack of air circulation, or nutrient stress.";
    } else {
      // Wheat diseases
      if (disease.contains('rust')) {
        return "Rust is a fungal disease caused by *Puccinia* species. Stem rust (red rust) or leaf rust creates powdery orange-brown pustules on leaves and stems, sucking nutrients and weakening the crop.";
      }
      return "This is a wheat crop condition affecting leaves or stalks. It is typically caused by fungal pathogens (like Rust or Septoria) or environmental stresses like low nitrogen or moisture.";
    }
  }

  String _getOrganicTreatment(String crop, String disease, String cleanDisease) {
    if (disease.toLowerCase().contains('healthy')) {
      return "No treatment needed. You can apply compost tea or seaweed extract occasionally as a foliar tonic to boost natural immunity.";
    }

    if (crop.toLowerCase() == 'tomato') {
      if (disease.contains('Late_blight') || disease.contains('Early_blight')) {
        return "- **Pruning**: Cut off and destroy lower leaves to improve air flow.\n"
            "- **Baking Soda Spray**: Mix 1 tbsp baking soda, 1 tsp liquid soap, and 1 gallon of water. Spray leaves to alter leaf pH.\n"
            "- **Copper Fungicide**: Apply organic-certified copper soap fungicide at the first sign.";
      }
      if (disease.contains('Yellow_Leaf_Curl')) {
        return "- **Insecticidal Soap**: Spray neem oil or organic insecticidal soap to control the whitefly carriers.\n"
            "- **Reflective Mulch**: Place silver-colored reflective mulch around tomato beds to repel whiteflies.";
      }
      return "- **Neem Oil**: Apply a 1% neem oil solution thoroughly to both sides of the leaves.\n"
          "- **Sanitation**: Remove infected leaves immediately to prevent fungal spore spreading.";
    } else {
      // Wheat
      return "- **Sulfur Dusting**: Apply sulfur powder during early crop stages to discourage fungal spore germination.\n"
          "- **Weed Control**: Keep the field clean of wild grasses that serve as green bridges for fungal spores.";
    }
  }

  String _getChemicalTreatment(String crop, String disease, String cleanDisease) {
    if (disease.toLowerCase().contains('healthy')) {
      return "Chemical control is not recommended for healthy crops.";
    }

    if (crop.toLowerCase() == 'tomato') {
      if (disease.contains('Late_blight') || disease.contains('Early_blight')) {
        return "- **Fungicides**: Apply chlorothalonil, mancozeb, or copper-based chemicals every 7-10 days in wet conditions.\n"
            "- **Systemic Fungicides**: Use metalaxyl or mefenoxam-based products for advanced stages.";
      }
      if (disease.contains('Yellow_Leaf_Curl')) {
        return "- **Insecticides**: Apply systemic whitefly controls like imidacloprid or acetamiprid to manage whitefly vectors.";
      }
      return "- **Broad-spectrum Fungicide**: Chlorothalonil or Mancozeb sprays can prevent and suppress further spot development.";
    } else {
      // Wheat
      return "- **Triazole Fungicides**: Apply tebuconazole, propiconazole, or epoxiconazole at flag leaf or flowering stage.\n"
          "- **Strobilurins**: Use pyraclostrobin or azoxystrobin to protect wheat yields.";
    }
  }

  String _getPrevention(String crop, String disease, String cleanDisease) {
    if (crop.toLowerCase() == 'tomato') {
      return "- **Drip Irrigation**: Water plants at the base. Avoid wetting the leaves to prevent humid fungal breeding grounds.\n"
          "- **Crop Rotation**: Rotate tomatoes with non-nightshade plants (e.g., beans or corn) every 3 years.\n"
          "- **Resistant Varieties**: Choose disease-resistant seeds (labeled VFNT).";
    } else {
      return "- **Crop Rotation**: Rotate wheat with legume crops to break the disease cycle and restore nitrogen.\n"
          "- **Resistant Cultivars**: Always select certified rust-resistant wheat seed varieties.\n"
          "- **Spacing**: Avoid overly dense planting to promote proper ventilation and sun exposure.";
    }
  }
}
