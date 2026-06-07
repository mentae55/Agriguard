import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../model/chat_message.dart';
import '../model/chat_session.dart';
import '../services/classification_service.dart';
import '../services/gemini_service.dart';
import '../services/chat_firebase_service.dart';

class ChatbotViewModel extends ChangeNotifier {
  final ClassificationService _classificationService = ClassificationService();
  final GeminiService _geminiService = GeminiService();
  final ChatFirebaseService _chatFirebaseService = ChatFirebaseService();

  // State flags
  bool _isClassifying = false;
  bool _isSendingMessage = false;
  String? _classificationError;
  String? _chatError;
  ClassificationResult? _latestResult;
  ChatSession? _currentSession;
  List<ChatSession> _pastSessions = [];

  // Stream Subscription for historical chats
  StreamSubscription<List<ChatSession>>? _historySubscription;

  // Selection Mode State
  bool _isSelectionMode = false;
  Set<String> _selectedMessageIds = {};

  // Getters
  bool get isClassifying => _isClassifying;
  bool get isSendingMessage => _isSendingMessage;
  String? get classificationError => _classificationError;
  String? get chatError => _chatError;
  ClassificationResult? get latestResult => _latestResult;
  ChatSession? get currentSession => _currentSession;
  List<ChatSession> get pastSessions => _pastSessions;
  bool get isSelectionMode => _isSelectionMode;
  Set<String> get selectedMessageIds => _selectedMessageIds;

  void clearResult() {
    _latestResult = null;
    _classificationError = null;
    _currentSession = null;
    _isSelectionMode = false;
    _selectedMessageIds.clear();
    notifyListeners();
  }

  /// Manually update/set the Gemini API Key from Settings UI if needed
  void updateApiKey(String apiKey) {
    _geminiService.setApiKey(apiKey);
  }

  /// Initialize real-time history sync stream from Firebase
  void initHistoryListener(String userId) {
    debugPrint('[ChatbotViewModel] Initializing chat history listener for user: $userId');
    _historySubscription?.cancel();
    _historySubscription = _chatFirebaseService
        .getChatSessionsStream(userId)
        .listen((sessions) async {
      _pastSessions = sessions;

      // Automatically restore last active session if none is currently active
      if (_currentSession == null) {
        final lastId = await _chatFirebaseService.getLastActiveSessionId(userId);
        if (lastId != null) {
          final matched = _pastSessions.any((s) => s.id == lastId);
          if (matched) {
            _currentSession = _pastSessions.firstWhere((s) => s.id == lastId);
          }
        }
      } else {
        // Sync the current session with the incoming stream data (new messages, favorites, etc.)
        final currentId = _currentSession!.id;
        final matched = _pastSessions.any((s) => s.id == currentId);
        if (matched) {
          _currentSession = _pastSessions.firstWhere((s) => s.id == currentId);
        }
      }
      notifyListeners();
    }, onError: (err) {
      debugPrint('[ChatbotViewModel] History sync error: $err');
    });
  }

  /// Close subscription to prevent memory leaks
  void disposeHistoryListener() {
    _historySubscription?.cancel();
    _historySubscription = null;
  }

  /// Runs the plant classification flow using selected image file
  Future<bool> classifyImage({
    required File imageFile,
    required String cropType, // 'wheat', 'tomato' or 'both'
  }) async {
    _isClassifying = true;
    _classificationError = null;
    _latestResult = null;
    notifyListeners();

    final result = await _classificationService.classifyImage(
      imageFile: imageFile,
      cropType: cropType,
    );

    _isClassifying = false;
    if (result.error != null) {
      _classificationError = result.error;
      notifyListeners();
      return false;
    }

    _latestResult = result;
    notifyListeners();
    return true;
  }

  /// Create a fresh chat session pre-populated with the latest classification result
  Future<void> startChatSession({
    required String userId,
    required String cropType,
    required String imageUrl,
  }) async {
    if (_latestResult == null) return;

    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    final cleanDisease = _latestResult!.prediction.replaceAll('___', ' ').replaceAll('_', ' ').trim();
    final title = '$cropType - $cleanDisease';

    // 1. Prepare initial system contextual welcome message
    final welcomeMessage = ChatMessage(
      id: 'msg_welcome_${DateTime.now().millisecondsSinceEpoch}',
      senderType: 'ai',
      text: "Hello! I am AgriGuard AI, your agricultural assistant.\n\n"
          "I see we have diagnosed your **$cropType** plant with **$cleanDisease** (confidence: ${(latestResult!.confidence * 100).toStringAsFixed(1)}%).\n\n"
          "How can I help you manage this? Ask me about organic treatments, chemical controls, preventative care, or farming advice!",
      timestamp: DateTime.now(),
    );

    // 2. Instantiate the session object
    final session = ChatSession(
      id: sessionId,
      title: title,
      cropType: cropType,
      diagnosisResult: _latestResult!.prediction,
      confidence: _latestResult!.confidence,
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
      messages: [welcomeMessage],
    );

    _currentSession = session;
    notifyListeners();

    // 3. Save to Firebase asynchronously
    await _chatFirebaseService.saveChatSession(userId, session);
  }

  /// Load a previously saved chat session into current active view
  void loadSession(ChatSession session, [String? userId]) {
    _currentSession = session;
    _isSelectionMode = false;
    _selectedMessageIds.clear();
    notifyListeners();
    if (userId != null) {
      _chatFirebaseService.saveLastActiveSessionId(userId, session.id);
    }
  }

  /// Send a user message and fetch an AI response from Gemini
  Future<void> sendMessage({
    required String text,
    required String userId,
  }) async {
    final session = _currentSession;
    if (session == null || text.trim().isEmpty) return;

    _isSendingMessage = true;
    _chatError = null;

    // 1. Create and append the user message locally & in Firebase
    final userMessage = ChatMessage(
      id: 'msg_user_${DateTime.now().millisecondsSinceEpoch}',
      senderType: 'user',
      text: text,
      timestamp: DateTime.now(),
    );

    final updatedMessages = List<ChatMessage>.from(session.messages)..add(userMessage);
    _currentSession = session.copyWith(messages: updatedMessages);
    notifyListeners();

    // Sync user message to Firebase
    await _chatFirebaseService.addMessageToSession(userId, session.id, userMessage);

    // Save this session as last active since the user just messaged
    await _chatFirebaseService.saveLastActiveSessionId(userId, session.id);

    // 2. Prepare conversation history for the Gemini API call
    final List<Map<String, String>> historyForAi = [];
    // We pass the last 6 messages to provide conversational history while keeping context size small
    final historyMessages = session.messages.length > 6 
        ? session.messages.sublist(session.messages.length - 6)
        : session.messages;

    for (var msg in historyMessages) {
      historyForAi.add({
        'role': msg.senderType == 'user' ? 'user' : 'model',
        'text': msg.text,
      });
    }

    // 3. Fetch the reply from Gemini API
    final aiReplyText = await _geminiService.generateAgriculturalReply(
      prompt: text,
      crop: session.cropType,
      disease: session.diagnosisResult,
      history: historyForAi,
    );

    // 4. Create and append the AI reply locally & in Firebase
    final aiMessage = ChatMessage(
      id: 'msg_ai_${DateTime.now().millisecondsSinceEpoch}',
      senderType: 'ai',
      text: aiReplyText,
      timestamp: DateTime.now(),
    );

    final finalMessages = List<ChatMessage>.from(_currentSession!.messages)..add(aiMessage);
    _currentSession = _currentSession!.copyWith(messages: finalMessages);
    _isSendingMessage = false;
    notifyListeners();

    // Sync AI response to Firebase
    await _chatFirebaseService.addMessageToSession(userId, session.id, aiMessage);
  }

  /// Delete a past chat session permanently
  Future<void> deleteSession(String sessionId, String userId) async {
    try {
      await _chatFirebaseService.deleteChatSession(userId, sessionId);
      if (_currentSession?.id == sessionId) {
        _currentSession = null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[ChatbotViewModel] Error deleting session: $e');
    }
  }

  /// Toggle favorite status of a message
  Future<void> toggleMessageFavorite(
    String userId,
    String sessionId,
    String messageId,
    bool currentStatus,
  ) async {
    try {
      await _chatFirebaseService.updateMessageFavoriteStatus(userId, sessionId, messageId, !currentStatus);
      
      // Update local state immediately for snappy UI
      if (_currentSession != null && _currentSession!.id == sessionId) {
        final updated = _currentSession!.messages.map((m) {
          if (m.id == messageId) {
            return m.copyWith(isFavorite: !currentStatus);
          }
          return m;
        }).toList();
        _currentSession = _currentSession!.copyWith(messages: updated);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ChatbotViewModel] Error toggling message favorite: $e');
    }
  }

  /// Delete a single message from the current session
  Future<void> deleteMessage(String userId, String sessionId, String messageId) async {
    try {
      await _chatFirebaseService.deleteMessageFromSession(userId, sessionId, messageId);
      
      // Update local state immediately for snappy UI
      if (_currentSession != null && _currentSession!.id == sessionId) {
        final updated = _currentSession!.messages.where((m) => m.id != messageId).toList();
        _currentSession = _currentSession!.copyWith(messages: updated);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ChatbotViewModel] Error deleting message: $e');
    }
  }

  // --- SELECTION MODE METHODS ---

  void enableSelectionMode(String messageId) {
    _isSelectionMode = true;
    _selectedMessageIds = {messageId};
    notifyListeners();
  }

  void toggleMessageSelection(String messageId) {
    if (_selectedMessageIds.contains(messageId)) {
      _selectedMessageIds.remove(messageId);
      if (_selectedMessageIds.isEmpty) {
        _isSelectionMode = false;
      }
    } else {
      _selectedMessageIds.add(messageId);
    }
    notifyListeners();
  }

  void selectAllMessages() {
    if (_currentSession != null) {
      _selectedMessageIds = _currentSession!.messages.map((m) => m.id).toSet();
      notifyListeners();
    }
  }

  void unselectAllMessages() {
    _selectedMessageIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  Future<void> deleteSelectedMessages(String userId, String sessionId) async {
    final selectedIds = List<String>.from(_selectedMessageIds);
    
    // Optimistic UI Update for snappy feeling
    if (_currentSession != null && _currentSession!.id == sessionId) {
      final updated = _currentSession!.messages.where((m) => !selectedIds.contains(m.id)).toList();
      _currentSession = _currentSession!.copyWith(messages: updated);
    }
    unselectAllMessages();

    // Perform deletions in the background
    for (String msgId in selectedIds) {
      try {
        await _chatFirebaseService.deleteMessageFromSession(userId, sessionId, msgId);
      } catch (e) {
        debugPrint('[ChatbotViewModel] Error deleting selected message $msgId: $e');
      }
    }
  }

  /// Rename an existing chat session
  Future<void> renameSession(String userId, String sessionId, String newTitle) async {
    try {
      await _chatFirebaseService.renameChatSession(userId, sessionId, newTitle);
      
      // Update local state immediately
      if (_currentSession != null && _currentSession!.id == sessionId) {
        _currentSession = _currentSession!.copyWith(title: newTitle);
      }
      _pastSessions = _pastSessions.map((s) {
        if (s.id == sessionId) {
          return s.copyWith(title: newTitle);
        }
        return s;
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('[ChatbotViewModel] Error renaming session: $e');
    }
  }

  /// Compile real-time favorite messages across all synced sessions
  List<Map<String, dynamic>> get favoriteMessages {
    final List<Map<String, dynamic>> favorites = [];
    for (var session in _pastSessions) {
      for (var msg in session.messages) {
        if (msg.isFavorite) {
          favorites.add({
            'session': session,
            'message': msg,
          });
        }
      }
    }
    // Sort newest favorites first
    favorites.sort((a, b) {
      final ChatMessage msgA = a['message'] as ChatMessage;
      final ChatMessage msgB = b['message'] as ChatMessage;
      return msgB.timestamp.compareTo(msgA.timestamp);
    });
    return favorites;
  }

  @override
  void dispose() {
    disposeHistoryListener();
    super.dispose();
  }
}
