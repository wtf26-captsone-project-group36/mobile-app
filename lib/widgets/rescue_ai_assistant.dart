import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hervest_ai/provider/inventory_provider.dart';
import 'package:hervest_ai/provider/profile_controller.dart';
import 'package:hervest_ai/provider/rescue_provider.dart';
import 'package:provider/provider.dart';

class RescueAIAssistantButton extends StatelessWidget {
  const RescueAIAssistantButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'rescue_ai_assistant_fab',
      onPressed: () => _openAssistant(context),
      backgroundColor: const Color(0xFF006B4D),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.smart_toy_outlined),
      label: const Text('Ask me anything'),
    );
  }

  void _openAssistant(BuildContext context) {
    openRescueAssistantSheet(context); 
  }
}

void openRescueAssistantSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _RescueAssistantSheet(),
  );
}

class _RescueAssistantSheet extends StatefulWidget {
  const _RescueAssistantSheet();

  @override
  State<_RescueAssistantSheet> createState() => _RescueAssistantSheetState();
}

class _RescueAssistantSheetState extends State<_RescueAssistantSheet> {
  bool _isLoading = false;
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      role: _ChatRole.assistant,
      text: 'Hi, I\'m Hervy! Ask me about rescue suggestions, your impact, or '
          'general questions about reducing food waste.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileController>();
    if (!profile.isLoaded) {
      profile.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.72,
        margin: const EdgeInsets.only(top: 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'HerVest AI Rescue Assistant',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _quickPromptRow(),
            const Divider(height: 16),
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (_, index) {
                  if (_isLoading && index == _messages.length) {
                    return _buildLoadingBubble();
                  }
                  return _buildMessageBubble(_messages[index]);
                },
                separatorBuilder: (_, __) => const SizedBox(height: 8),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + bottomInset),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Ask about rescue suggestions...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                      ),
                      onSubmitted: _isLoading ? null : (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isLoading ? null : _send,
                    icon: const Icon(Icons.send_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF006B4D),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickPromptRow() {
    final prompts = [
      'What should I rescue today?',
      'Any critical items?',
      'Show my impact',
      'How to reduce waste?',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: prompts.map((prompt) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(prompt),
              onPressed: () {
                _controller.text = prompt;
                if (!_isLoading) _send();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    final isUser = message.role == _ChatRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) _assistantAvatar(),
          if (!isUser) const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            constraints: const BoxConstraints(maxWidth: 290),
            decoration: BoxDecoration(
              color: isUser
                  ? const Color(0xFF006B4D)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.text,
              style: TextStyle(color: isUser ? Colors.white : Colors.black87),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _userAvatar(),
        ],
      ),
    );
  }

  Widget _assistantAvatar() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: ClipOval(
        child: Image.asset('assets/hervbypd.png', fit: BoxFit.cover),
      ),
    );
  }

  Widget _userAvatar() {
    return Selector<ProfileController, Uint8List?>(
      selector: (_, profile) => profile.avatarBytes,
      builder: (_, avatarBytes, __) {
        return CircleAvatar(
          radius: 15,
          backgroundColor: const Color(0xFF006B4D).withOpacity(0.12),
          backgroundImage: avatarBytes != null
              ? MemoryImage(avatarBytes)
              : null,
          child: avatarBytes == null
              ? const Icon(Icons.person, size: 16, color: Color(0xFF006B4D))
              : null,
        );
      },
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _assistantAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Hervy is typing...',
              style: TextStyle(
                  color: Colors.black54, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  void _send() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(role: _ChatRole.user, text: prompt));
      _isLoading = true;
    });

    // Simulate a small delay for a more natural "typing" feel
    await Future.delayed(const Duration(milliseconds: 500));

    // This part remains synchronous as per the architecture doc,
    // but the UI is now non-blocking.
    final rescue = context.read<RescueProvider>();
    final inventory = context.read<InventoryProvider>();
    final response = rescue.answerAssistantQuery(prompt, inventory.items);
    setState(() {
      _messages.add(_ChatMessage(role: _ChatRole.assistant, text: response));
      _isLoading = false;
    });
  }
}

enum _ChatRole { user, assistant }

class _ChatMessage {
  final _ChatRole role;
  final String text;

  const _ChatMessage({required this.role, required this.text});
}
