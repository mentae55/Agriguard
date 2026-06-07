import 'chat_message.dart';

class ChatSession {
  final String id;
  final String title;
  final String cropType;
  final String diagnosisResult;
  final double confidence;
  final String imageUrl;
  final DateTime timestamp;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.cropType,
    required this.diagnosisResult,
    required this.confidence,
    required this.imageUrl,
    required this.timestamp,
    required this.messages,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'cropType': cropType,
      'diagnosisResult': diagnosisResult,
      'confidence': confidence,
      'imageUrl': imageUrl,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'messages': messages.map((m) => m.toMap()).toList(),
    };
  }

  factory ChatSession.fromMap(Map<dynamic, dynamic> map) {
    // Process messages list safely
    final List<ChatMessage> parsedMessages = [];
    if (map['messages'] != null) {
      if (map['messages'] is List) {
        for (var m in (map['messages'] as List)) {
          if (m is Map) {
            parsedMessages.add(ChatMessage.fromMap(m));
          }
        }
      } else if (map['messages'] is Map) {
        // Firebase RTDB sometimes returns List as a Map of index keys
        (map['messages'] as Map).forEach((key, val) {
          if (val is Map) {
            parsedMessages.add(ChatMessage.fromMap(val));
          }
        });
      }
    }

    // Sort messages by timestamp just to be sure they display in order
    parsedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return ChatSession(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'AgriGuard Diagnosis Chat',
      cropType: map['cropType']?.toString() ?? '',
      diagnosisResult: map['diagnosisResult']?.toString() ?? '',
      confidence: double.tryParse(map['confidence']?.toString() ?? '0.0') ?? 0.0,
      imageUrl: map['imageUrl']?.toString() ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] is int
            ? map['timestamp'] as int
            : int.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now().millisecondsSinceEpoch,
      ),
      messages: parsedMessages,
    );
  }

  ChatSession copyWith({
    String? id,
    String? title,
    String? cropType,
    String? diagnosisResult,
    double? confidence,
    String? imageUrl,
    DateTime? timestamp,
    List<ChatMessage>? messages,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      cropType: cropType ?? this.cropType,
      diagnosisResult: diagnosisResult ?? this.diagnosisResult,
      confidence: confidence ?? this.confidence,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      messages: messages ?? this.messages,
    );
  }
}
