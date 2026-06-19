import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agriguard_project/core/core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../view_model/chatbot_view_model.dart';
import '../model/chat_session.dart';

class ChatHistoryScreen extends StatelessWidget {
  const ChatHistoryScreen({super.key});

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return "${months[dt.month - 1]} ${dt.day}, ${dt.year}";
  }

  void _showRenameDialog(BuildContext context, ChatSession session, ChatbotViewModel chatbotVm, String userId) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textController = TextEditingController(text: session.title);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text('Rename Chat Session', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: textController,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Enter new session name...',
              hintStyle: const TextStyle(color: grayColor),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colorScheme.onSurface.withAlpha(60))),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: grayColor, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () {
                final newTitle = textController.text.trim();
                if (newTitle.isNotEmpty) {
                  chatbotVm.renameSession(userId, session.id, newTitle);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Renamed chat session to "$newTitle"')),
                  );
                }
                Navigator.pop(context);
              },
              child: const Text('Save', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final chatbotVm = context.watch<ChatbotViewModel>();
    final user = FirebaseAuth.instance.currentUser;
    final List<ChatSession> sessions = List.from(chatbotVm.pastSessions);
    
    // Sort to pin General Chats to the top, then by timestamp descending
    sessions.sort((a, b) {
      if (a.isGeneralChat && !b.isGeneralChat) return -1;
      if (!a.isGeneralChat && b.isGeneralChat) return 1;
      return b.timestamp.compareTo(a.timestamp);
    });

    if (user == null) {
      return Center(
        child: Text(
          'Please log in to view chat history.',
          style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
        ),
      );
    }

    if (sessions.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _buildHistoryCard(context, session, chatbotVm, user.uid);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor.withAlpha(isDark ? 35 : 20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history_edu_rounded, size: 64, color: primaryColor),
            ),
            const SizedBox(height: 20),
            const Text(
              'No diagnostic history',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontFamily: 'AbhayaLibre',
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your completed plant scan diagnoses and AI chat sessions will be stored here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurface.withAlpha(160), fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    ChatSession session,
    ChatbotViewModel chatbotVm,
    String userId,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    final bool isGeneral = session.isGeneralChat;
    final cleanDisease = isGeneral ? 'General Chat' : session.diagnosisResult.replaceAll('___', ' ').replaceAll('_', ' ').trim();
    final bool isHealthy = cleanDisease.toLowerCase().contains('healthy');
    final String lastMessage = session.messages.isNotEmpty 
        ? session.messages.last.text.replaceAll('\n', ' ')
        : 'No messages yet';

    final bool isTomato = session.cropType.toLowerCase() == 'tomato';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Dismissible(
        key: Key(session.id),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) {
          chatbotVm.deleteSession(session.id, userId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted chat session: ${session.title}')),
          );
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: redColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.delete_sweep_rounded, color: colorScheme.onPrimary, size: 28),
        ),
        child: GestureDetector(
          onTap: () {
            // Load selected session state
            chatbotVm.loadSession(session, userId);
            // Animate to Chat Tab (index 0)
            final tabController = DefaultTabController.of(context);
            tabController.animateTo(0);
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 40 : 4),
                  blurRadius: isDark ? 8 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.withAlpha(20), width: 1),
            ),
            child: Row(
              children: [
                // Clean Text-Based Crop Chip instead of icons/images
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isGeneral
                        ? primaryColor.withAlpha(isDark ? 35 : 20)
                        : (isTomato 
                            ? Colors.red.withAlpha(isDark ? 35 : 20) 
                            : Colors.amber.withAlpha(isDark ? 35 : 20)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: isGeneral
                      ? const Text('🌱', style: TextStyle(fontSize: 14))
                      : Text(
                          session.cropType.toUpperCase(),
                          style: TextStyle(
                            color: isTomato 
                                ? (isDark ? Colors.red.shade300 : Colors.red.shade800) 
                                : (isDark ? Colors.amber.shade300 : Colors.amber.shade900),
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                // Texts details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              session.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              if (isGeneral)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4.0),
                                  child: Icon(Icons.push_pin_rounded, size: 12, color: primaryColor),
                                ),
                              Text(
                                _formatDate(session.timestamp),
                                style: TextStyle(
                                  color: colorScheme.onSurface.withAlpha(120),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        cleanDisease,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'AbhayaLibre',
                          color: isHealthy 
                              ? (isDark ? Colors.green.shade300 : Colors.green.shade800) 
                              : colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        lastMessage,
                        style: TextStyle(
                          color: colorScheme.onSurface.withAlpha(160),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Edit/Rename Trigger Button
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, color: grayColor, size: 22),
                  onPressed: () => _showRenameDialog(context, session, chatbotVm, userId),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
