// chatbotScreen.dart
import 'package:flutter/material.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import 'home.dart'; // Import HomeScreen for navigation

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> with SingleTickerProviderStateMixin {
  // --------------------------------------
  // STATE VARIABLES
  // --------------------------------------
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, String>> messages = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // --------------------------------------
  // INITIALIZATION
  // --------------------------------------
  @override
  void initState() {
    super.initState();
    // Initialize welcome message
    _addWelcomeMessage();

    // Setup animation for fade-in effect
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // --------------------------------------
  // CHAT MANAGEMENT
  // --------------------------------------
  /// Adds a welcome message on screen load
  void _addWelcomeMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      addMessage("Assistant", "Hello! I'm your AI assistant 🤖\nAsk me anything!");
    });
  }

  /// Sends a user message and triggers AI response
  void sendMessage(String text) {
    if (text.trim().isNotEmpty) {
      addMessage("User", text);
      _messageController.clear();
      Future.delayed(const Duration(seconds: 1), () {
        String response = _getAIResponse(text);
        addMessage("Assistant", response);
      });
    }
  }

  /// Generates a simple AI response based on input
  String _getAIResponse(String input) {
    String lower = input.toLowerCase();
    if (lower.contains('hello') || lower.contains('hi')) {
      return "👋 Hello! How can I assist you today? ✨";
    }
    if (lower.contains('time')) {
      return "🕐 It's ${DateTime.now().hour}:${DateTime.now().minute}! ⏰";
    }
    return "🤖 Processing: '$input' ✨";
  }

  /// Adds a message to the chat list
  void addMessage(String sender, String text) {
    setState(() {
      messages.add({"sender": sender, "text": text});
    });
  }

  // --------------------------------------
  // UI WIDGETS
  // --------------------------------------
  /// Builds the chat header
  Widget _buildChatHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[400]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "🤖 AI Chatbot",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const Icon(Icons.smart_toy, color: Colors.white, size: 28),
        ],
      ),
    );
  }

  /// Builds the chat messages list
  Widget _buildChatMessages() {
    return Expanded(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: messages.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.smart_toy, color: Colors.blue, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        "Welcome to AI Chatbot!",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            final msgIndex = messages.length - (index);
            if (msgIndex < 0) return const SizedBox.shrink();
            final msg = messages[msgIndex];
            bool isUser = msg["sender"] == "User";

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: BubbleNormal(
                text: msg["text"]!,
                isSender: isUser,
                color: isUser ? Colors.blue[600]! : Colors.blue[100]!,
                tail: true,
                textStyle: TextStyle(
                  color: isUser ? Colors.white : Colors.blue[800],
                  fontSize: 16,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds the chat input field
  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: const Border(top: BorderSide(color: Colors.blueGrey)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Ask AI anything...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  sendMessage(text);
                  _messageController.clear();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.blue),
              onPressed: () {
                if (_messageController.text.trim().isNotEmpty) {
                  sendMessage(_messageController.text);
                  _messageController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------
  // MAIN UI BUILD
  // --------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Chat header
          _buildChatHeader(),
          // Chat messages
          _buildChatMessages(),
          // Chat input
          _buildChatInput(),
        ],
      ),
    );
  }
}