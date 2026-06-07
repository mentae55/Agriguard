class ChatMessage {
  final String id;
  final String senderType; // 'user' or 'ai'
  final String text;
  final DateTime timestamp;
  final bool isFavorite;

  ChatMessage({
    required this.id,
    required this.senderType,
    required this.text,
    required this.timestamp,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderType': senderType,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isFavorite': isFavorite,
    };
  }

  factory ChatMessage.fromMap(Map<dynamic, dynamic> map) {
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
    );
  }

  ChatMessage copyWith({
    String? id,
    String? senderType,
    String? text,
    DateTime? timestamp,
    bool? isFavorite,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderType: senderType ?? this.senderType,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
