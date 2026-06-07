import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agriguard_project/core/core.dart';
import '../view_model/chatbot_view_model.dart';
import 'chat_screen.dart';
import 'chat_history_screen.dart';
import 'chat_favorites_screen.dart';

class ChatbotMainScreen extends StatefulWidget {
  final int initialIndex;
  const ChatbotMainScreen({super.key, this.initialIndex = 0});

  @override
  State<ChatbotMainScreen> createState() => _ChatbotMainScreenState();
}

class _ChatbotMainScreenState extends State<ChatbotMainScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure the history listener is active
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ChatbotViewModel>().initHistoryListener(user.uid);
      });
    }
  }

  void _confirmDelete(BuildContext context, ChatbotViewModel chatbotVm) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Messages?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('This action cannot be undone. Selected messages will be permanently removed.'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final user = FirebaseAuth.instance.currentUser;
                final session = chatbotVm.currentSession;
                if (user != null && session != null) {
                  chatbotVm.deleteSelectedMessages(user.uid, session.id);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatbotVm = context.watch<ChatbotViewModel>();
    final isSelectionMode = chatbotVm.isSelectionMode;
    final selectedCount = chatbotVm.selectedMessageIds.length;

    return DefaultTabController(
      initialIndex: widget.initialIndex,
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FBF8),
        appBar: isSelectionMode
            ? AppBar(
                backgroundColor: primaryColor.withAlpha(20),
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.black87),
                  onPressed: () => chatbotVm.unselectAllMessages(),
                ),
                title: Text(
                  '$selectedCount Selected',
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.select_all_rounded, color: Colors.black87),
                    onPressed: () => chatbotVm.selectAllMessages(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    onPressed: () => _confirmDelete(context, chatbotVm),
                  ),
                ],
                bottom: const PreferredSize(
                  preferredSize: Size.fromHeight(0), // Hide TabBar gracefully while selecting
                  child: SizedBox.shrink(),
                ),
              )
            : AppBar(
                backgroundColor: Colors.white,
                elevation: 1,
                shadowColor: Colors.black12,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'AgriGuard AI',
                  style: TextStyle(
                    color: primaryColor,
                    fontFamily: 'AbhayaLibre',
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                centerTitle: true,
                bottom: TabBar(
                  labelColor: primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: primaryColor,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.chat_bubble_outline_rounded, size: 20),
                      text: 'Chat',
                    ),
                    Tab(
                      icon: Icon(Icons.history_rounded, size: 20),
                      text: 'History',
                    ),
                    Tab(
                      icon: Icon(Icons.star_outline_rounded, size: 20),
                      text: 'Favorites',
                    ),
                  ],
                ),
              ),
        body: const TabBarView(
          physics: BouncingScrollPhysics(),
          children: [
            ChatScreen(),
            ChatHistoryScreen(),
            ChatFavoritesScreen(),
          ],
        ),
      ),
    );
  }
}
