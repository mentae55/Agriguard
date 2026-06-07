import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:agriguard_project/core/core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../view_model/chatbot_view_model.dart';
import '../model/chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(animated: false));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollController.hasClients) return;
      if (animated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _messageController.clear();
    _scrollToBottom();

    await context.read<ChatbotViewModel>().sendMessage(
          text: text,
          userId: user.uid,
        );

    _scrollToBottom();
  }

  void _showMsgActions(BuildContext context, ChatMessage message, String userId, String sessionId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isFavorite = message.isFavorite;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: Colors.black87),
                title: const Text('Copy Text'),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: message.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied message text to clipboard'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isFavorite ? Colors.orange : Colors.black87,
                ),
                title: Text(isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
                onTap: () {
                  Navigator.pop(context);
                  context.read<ChatbotViewModel>().toggleMessageFavorite(
                    userId,
                    sessionId,
                    message.id,
                    isFavorite,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isFavorite ? 'Removed from Favorites' : 'Saved to Favorites'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatbotVm = context.watch<ChatbotViewModel>();
    final session = chatbotVm.currentSession;
    final user = FirebaseAuth.instance.currentUser;

    if (session == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FBF8),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 20),
                Text(
                  'No Active Chat',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'AbhayaLibre',
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select a previous scan from the History tab, or go back to diagnose a new leaf.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final cleanDisease = session.diagnosisResult.replaceAll('___', ' ').replaceAll('_', ' ').trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      body: SafeArea(
        child: Column(
          children: [
            // Sub-header showing current context context
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.withAlpha(10),
              width: double.infinity,
              child: Text(
                'Active Session: ${session.cropType} — $cleanDisease',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // 1. Message Bubble list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: session.messages.length + (chatbotVm.isSendingMessage ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == session.messages.length) {
                    return _buildTypingIndicatorBubble();
                  }

                  final message = session.messages[index];
                  // Slide + Fade transition builder for bubbles
                  return TweenAnimationBuilder<double>(
                    key: ValueKey(message.id),
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 300),
                    builder: (context, animValue, child) {
                      return Opacity(
                        opacity: animValue,
                        child: Transform.translate(
                          offset: Offset(0, 15 * (1.0 - animValue)),
                          child: child,
                        ),
                      );
                    },
                    child: _buildMessageBubble(message, user?.uid ?? '', session.id, chatbotVm),
                  );
                },
              ),
            ),

            // 2. Suggestion Quick Chips
            if (!chatbotVm.isSendingMessage && !chatbotVm.isSelectionMode) _buildSuggestionChips(session.cropType, cleanDisease),

            // 3. Message Input Bar
            if (!chatbotVm.isSelectionMode) _buildInputBar(chatbotVm),
          ],
        ),
      ),
    );
  }

  // Message Bubble builder
  Widget _buildMessageBubble(ChatMessage message, String userId, String sessionId, ChatbotViewModel chatbotVm) {
    final bool isUser = message.senderType == 'user';
    final formatTime = "${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}";
    final isSelectionMode = chatbotVm.isSelectionMode;
    final isSelected = chatbotVm.selectedMessageIds.contains(message.id);

    return GestureDetector(
      onLongPress: () {
        if (!isSelectionMode) chatbotVm.enableSelectionMode(message.id);
      },
      onTap: () {
        if (isSelectionMode) {
          chatbotVm.toggleMessageSelection(message.id);
        } else {
          _showMsgActions(context, message, userId, sessionId);
        }
      },
      child: Container(
        color: isSelected ? primaryColor.withAlpha(20) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isSelectionMode) ...[
              Checkbox(
                value: isSelected,
                activeColor: primaryColor,
                onChanged: (_) => chatbotVm.toggleMessageSelection(message.id),
              ),
              const SizedBox(width: 4),
            ],
            
            if (!isUser) ...[
              CircleAvatar(
                backgroundColor: primaryColor.withAlpha(30),
                radius: 16,
                child: Icon(Icons.smart_toy_rounded, size: 20, color: primaryColor),
              ),
              const SizedBox(width: 8),
            ],

            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser ? primaryColor : const Color(0xFFEFECE7), // Forest green vs. Warm gray
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
                    bottomRight: isUser ? Radius.zero : const Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(3),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatTime,
                          style: TextStyle(
                            color: isUser ? Colors.white60 : Colors.black38,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (message.isFavorite) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.star_rounded, color: Colors.orange, size: 12),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            if (isUser) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: primaryColor.withAlpha(30),
                radius: 16,
                child: Icon(Icons.person_rounded, size: 20, color: primaryColor),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Pure text typing indicator with AI avatar
  Widget _buildTypingIndicatorBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            backgroundColor: primaryColor.withAlpha(30),
            radius: 16,
            child: Icon(Icons.smart_toy_rounded, size: 20, color: primaryColor),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFEFECE7),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.zero,
                bottomRight: Radius.circular(20),
              ),
            ),
            child: const Text(
              'AgriGuard AI is typing...',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Suggestion Quick Chips
  Widget _buildSuggestionChips(String cropType, String cleanDisease) {
    final chips = [
      'Organic treatments?',
      'Chemical control?',
      'Prevention steps?',
      'Is it contagious?',
    ];

    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        itemBuilder: (context, index) {
          final text = chips[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              side: BorderSide(color: primaryColor.withAlpha(60), width: 1),
              label: Text(
                text,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              onPressed: () => _sendMessage(text),
            ),
          );
        },
      ),
    );
  }

  // Message Input Bar builder
  Widget _buildInputBar(ChatbotViewModel chatbotVm) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.withAlpha(30), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _messageController,
                textInputAction: TextInputAction.send,
                onSubmitted: (val) => _sendMessage(val),
                decoration: const InputDecoration(
                  hintText: 'Ask AgriGuard AI...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(_messageController.text),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withAlpha(60),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
