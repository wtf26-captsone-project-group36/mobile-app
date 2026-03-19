import 'package:flutter/material.dart';
import 'chat_bubble.dart';
import 'gemini_mock_services.dart';
import 'thinking_indicator.dart';

class AiDonationAssistantScreen extends StatefulWidget {
  const AiDonationAssistantScreen({super.key});

  @override
  State<AiDonationAssistantScreen> createState() =>
      _AiDonationAssistantScreenState();
}

class _AiDonationAssistantScreenState extends State<AiDonationAssistantScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController _listController = ScrollController();
  final MockGeminiService service = MockGeminiService();
  final List<Map<String, dynamic>> messages = <Map<String, dynamic>>[];

  bool thinking = false;

  @override
  void initState() {
    super.initState();
    messages.add({
      'text':
          'Hi, I am Gemini! How can I help you today?  \n'
          'Ask for donation locations, for example: An orphanage near Surulere.',
      'user': false,
    });
  }

  @override
  void dispose() {
    controller.dispose();
    _listController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final String text = controller.text.trim();
    if (text.isEmpty || thinking) return;

    setState(() {
      messages.add({'text': text, 'user': true});
      thinking = true;
    });

    controller.clear();
    _scrollToBottom();

    final String res = await service.getSuggestion(text);

    if (!mounted) return;
    setState(() {
      thinking = false;
      messages.add({'text': res, 'user': false});
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_listController.hasClients) return;
      _listController.animateTo(
        _listController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF3E63FF), Color(0xFF9E57FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Gemini Assistant'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _listController,
              padding: const EdgeInsets.all(10),
              children: [
                ...messages.map(
                  (Map<String, dynamic> m) => ChatBubble(
                    text: (m['text'] ?? '').toString(),
                    user: m['user'] == true,
                  ),
                ),
                if (thinking)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: ThinkingIndicator(),
                  ),
              ],
            ),
          ),
          _inputField(),
          const Padding(
            padding: EdgeInsets.all(6),
            child: Text(
              'Gemini can make mistakes. Check important info.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _inputField() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.purple],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Ask for donation location...',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            IconButton(
              onPressed: _send,
              icon: const Icon(
                Icons.send,
                color: Colors.white,
              ),
            )
          ],
        ),
      ),
    );
  }
}
