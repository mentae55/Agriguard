import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agriguard_project/core/core.dart';
import '../view_model/chatbot_view_model.dart';
import '../model/chat_message.dart';
import '../model/chat_session.dart';

class ChatFavoritesScreen extends StatelessWidget {
  const ChatFavoritesScreen({super.key});

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return "${months[dt.month - 1]} ${dt.day}, ${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final chatbotVm = context.watch<ChatbotViewModel>();
    final user = FirebaseAuth.instance.currentUser;
    final List<Map<String, dynamic>> favorites = chatbotVm.favoriteMessages;

    if (user == null) {
      return const Center(child: Text('Please log in to view favorites.'));
    }

    if (favorites.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final item = favorites[index];
        final ChatSession session = item['session'] as ChatSession;
        final ChatMessage message = item['message'] as ChatMessage;

        return _buildFavoriteCard(context, session, message, chatbotVm, user.uid);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.star_outline_rounded, size: 64, color: primaryColor),
            ),
            const SizedBox(height: 20),
            Text(
              'No saved messages',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontFamily: 'AbhayaLibre',
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Star important answers in your chat to save them here for quick access.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(
    BuildContext context,
    ChatSession session,
    ChatMessage message,
    ChatbotViewModel chatbotVm,
    String userId,
  ) {
    final cleanDisease = session.diagnosisResult.replaceAll('___', ' ').replaceAll('_', ' ').trim();
    final bool isUser = message.senderType == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () {
          // 1. Load the corresponding session
          chatbotVm.loadSession(session, userId);
          // 2. Animate tab controller back to Chat tab (index 0)
          final tabController = DefaultTabController.of(context);
          tabController.animateTo(0);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Loaded chat session: $cleanDisease'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.withAlpha(20), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Session context and Star button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${session.cropType} — $cleanDisease',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: Colors.grey, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: message.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied text to clipboard'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.star_rounded, color: Colors.orange, size: 22),
                        onPressed: () {
                          chatbotVm.toggleMessageFavorite(userId, session.id, message.id, message.isFavorite);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Removed from Favorites'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Message content
              Text(
                message.text,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              // Footer: Timestamp and Sender type tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(message.timestamp),
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isUser ? primaryColor.withAlpha(20) : Colors.grey.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isUser ? 'USER QUESTION' : 'AI RESPONSE',
                      style: TextStyle(
                        color: isUser ? primaryColor : Colors.black54,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
