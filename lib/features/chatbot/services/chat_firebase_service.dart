import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../model/chat_session.dart';
import '../model/chat_message.dart';

class ChatFirebaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Returns a real-time stream of all chat sessions for a specific user.
  /// Ordered by timestamp descending (newest first).
  Stream<List<ChatSession>> getChatSessionsStream(String userId) {
    debugPrint('[ChatFirebaseService] Listening to chats for user: $userId');
    return _db.child('Users/$userId/chats').onValue.map((event) {
      final List<ChatSession> sessions = [];
      final snapshotValue = event.snapshot.value;
      
      if (snapshotValue != null) {
        if (snapshotValue is Map) {
          snapshotValue.forEach((key, val) {
            if (val is Map) {
              try {
                sessions.add(ChatSession.fromMap(val));
              } catch (e) {
                debugPrint('[ChatFirebaseService] Error parsing session $key: $e');
              }
            }
          });
        } else if (snapshotValue is List) {
          // If Firebase returns it as a list (e.g. index-based keys)
          for (var i = 0; i < snapshotValue.length; i++) {
            final val = snapshotValue[i];
            if (val is Map) {
              try {
                sessions.add(ChatSession.fromMap(val));
              } catch (e) {
                debugPrint('[ChatFirebaseService] Error parsing session index $i: $e');
              }
            }
          }
        }
      }

      // Sort newest first
      sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return sessions;
    });
  }

  /// Save or update a full chat session in Firebase RTDB
  Future<void> saveChatSession(String userId, ChatSession session) async {
    try {
      final path = 'Users/$userId/chats/${session.id}';
      await _db.child(path).set(session.toMap());
      debugPrint('[ChatFirebaseService] Saved session: ${session.id} at path: $path');
    } catch (e) {
      debugPrint('[ChatFirebaseService] Error saving session: $e');
      rethrow;
    }
  }

  /// Add a single message to an existing chat session directly
  Future<void> addMessageToSession(String userId, String sessionId, ChatMessage message) async {
    try {
      // Instead of reading and writing the whole session, we write to the messages list node
      // We can push it or set it with the message's ID. Using message.id as key is very stable.
      final path = 'Users/$userId/chats/$sessionId/messages/${message.id}';
      await _db.child(path).set(message.toMap());
      debugPrint('[ChatFirebaseService] Added message: ${message.id} to session: $sessionId');
    } catch (e) {
      debugPrint('[ChatFirebaseService] Error adding message: $e');
      rethrow;
    }
  }

  /// Delete a chat session from Firebase RTDB
  Future<void> deleteChatSession(String userId, String sessionId) async {
    try {
      final path = 'Users/$userId/chats/$sessionId';
      await _db.child(path).remove();
      debugPrint('[ChatFirebaseService] Deleted session: $sessionId at path: $path');
    } catch (e) {
      debugPrint('[ChatFirebaseService] Error deleting session: $e');
      rethrow;
    }
  }

  /// Update the isFavorite status of a specific message in Firebase RTDB
  Future<void> updateMessageFavoriteStatus(
    String userId,
    String sessionId,
    String messageId,
    bool isFavorite,
  ) async {
    try {
      final path = 'Users/$userId/chats/$sessionId/messages/$messageId/isFavorite';
      await _db.child(path).set(isFavorite);
      debugPrint('[ChatFirebaseService] Updated message favorite status: $messageId to $isFavorite');
    } catch (e) {
      debugPrint('[ChatFirebaseService] Error updating favorite status: $e');
      rethrow;
    }
  }

  /// Delete a single message from a chat session in Firebase RTDB
  Future<void> deleteMessageFromSession(String userId, String sessionId, String messageId) async {
    try {
      final path = 'Users/$userId/chats/$sessionId/messages/$messageId';
      await _db.child(path).remove();
      debugPrint('[ChatFirebaseService] Deleted message: $messageId from session: $sessionId');
    } catch (e) {
      debugPrint('[ChatFirebaseService] Error deleting message from session: $e');
      rethrow;
    }
  }

  /// Rename an existing chat session in Firebase RTDB
  Future<void> renameChatSession(String userId, String sessionId, String newTitle) async {
    try {
      final path = 'Users/$userId/chats/$sessionId/title';
      await _db.child(path).set(newTitle);
      debugPrint('[ChatFirebaseService] Renamed session: $sessionId to: $newTitle');
    } catch (e) {
      debugPrint('[ChatFirebaseService] Error renaming session: $e');
      rethrow;
    }
  }

  /// Save the last active session ID for the user
  Future<void> saveLastActiveSessionId(String userId, String sessionId) async {
    try {
      final path = 'Users/$userId/lastActiveSessionId';
      await _db.child(path).set(sessionId);
      debugPrint('[ChatFirebaseService] Saved last active session ID: $sessionId');
    } catch (e) {
      debugPrint('[ChatFirebaseService] Error saving last active session ID: $e');
      rethrow;
    }
  }

  /// Retrieve the last active session ID for the user
  Future<String?> getLastActiveSessionId(String userId) async {
    try {
      final path = 'Users/$userId/lastActiveSessionId';
      final snapshot = await _db.child(path).get();
      if (snapshot.exists) {
        return snapshot.value?.toString();
      }
      return null;
    } catch (e) {
      debugPrint('[ChatFirebaseService] Error loading last active session ID: $e');
      return null;
    }
  }
}
