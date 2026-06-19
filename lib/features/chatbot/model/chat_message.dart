class ChatMessage {
  final String id;
  final String senderType; // 'user' or 'ai'
  final String text;
  final DateTime timestamp;
  final bool isFavorite;
  final List<Map<String, dynamic>>? sources;

  ChatMessage({
    required this.id,
    required this.senderType,
    required this.text,
    required this.timestamp,
    this.isFavorite = false,
    this.sources,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderType': senderType,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isFavorite': isFavorite,
      if (sources != null) 'sources': sources,
    };
  }

  factory ChatMessage.fromMap(Map<dynamic, dynamic> map) {
    List<Map<String, dynamic>>? parsedSources;
    if (map['sources'] != null) {
      final List<dynamic> rawSources = map['sources'] as List<dynamic>;
      parsedSources = rawSources.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    return ChatMessage(
      id: map['id']?.toString() ?? '',
      senderType: map['senderType']?.toString() ?? 'user',
      text: map['text']?.toString() ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] is int
            ? map['timestamp'] as int
            : int.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now().millisecondsSinceEpoch,
      ),
      isFavorite: map['isFavorite'] is bool
          ? map['isFavorite'] as bool
          : (map['isFavorite']?.toString() == 'true'),
      sources: parsedSources,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? senderType,
    String? text,
    DateTime? timestamp,
    bool? isFavorite,
    List<Map<String, dynamic>>? sources,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderType: senderType ?? this.senderType,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isFavorite: isFavorite ?? this.isFavorite,
      sources: sources ?? this.sources,
    );
  }
}
