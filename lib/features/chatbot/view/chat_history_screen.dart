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
    final textController = TextEditingController(text: session.title);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Rename Chat Session'),
          content: TextField(
            controller: textController,
            decoration: InputDecoration(
              hintText: 'Enter new session name...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
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
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatbotVm = context.watch<ChatbotViewModel>();
    final user = FirebaseAuth.instance.currentUser;
    final List<ChatSession> sessions = chatbotVm.pastSessions;

    if (user == null) {
      return Center(child: Text('Please log in to view chat history.'));
    }

    if (sessions.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(20.0),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _buildHistoryCard(context, session, chatbotVm, user.uid);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history_edu_rounded, size: 64, color: primaryColor),
            ),
            SizedBox(height: 20),
            Text(
              'No diagnostic history',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontFamily: 'AbhayaLibre',
                color: primaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your completed plant scan diagnoses and AI chat sessions will be stored here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
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
    final cleanDisease = session.diagnosisResult.replaceAll('___', ' ').replaceAll('_', ' ').trim();
    final bool isHealthy = cleanDisease.toLowerCase().contains('healthy');
    final String lastMessage = session.messages.isNotEmpty 
        ? session.messages.last.text.replaceAll('\n', ' ')
        : 'No messages yet';

    final bool isTomato = session.cropType.toLowerCase() == 'tomato';

    return Padding(
      padding: EdgeInsets.only(bottom: 16.0),
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
          padding: EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.red.shade800,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
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
            padding: EdgeInsets.all(18),
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
            child: Row(
              children: [
                // Clean Text-Based Crop Chip instead of icons/images
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isTomato ? Colors.red.withAlpha(20) : Colors.amber.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    session.cropType.toUpperCase(),
                    style: TextStyle(
                      color: isTomato ? Colors.red.shade800 : Colors.amber.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(width: 14),
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
                                color: Colors.black87,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            _formatDate(session.timestamp),
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 3),
                      Text(
                        cleanDisease,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'AbhayaLibre',
                          color: isHealthy ? Colors.green.shade800 : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 5),
                      Text(
                        lastMessage,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                // Edit/Rename Trigger Button
                IconButton(
                  icon: Icon(Icons.edit_note_rounded, color: Colors.grey, size: 22),
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
