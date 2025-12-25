// ChatbotScreen.dart
import 'package:flutter/material.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'HomeScreen.dart';
import 'groq_service.dart';
import 'database_helper.dart';

class ChatbotScreen extends StatefulWidget {
  final String? initialText;

  const ChatbotScreen({super.key, this.initialText});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final SpeechToText _speechToText = SpeechToText();
  final GroqService _ai = GroqService();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Language control
  bool _isBangla = false;

  String get _localeId => _isBangla ? 'bn_BD' : 'en_US';

  Map<String, String> get _texts => _isBangla
      ? {
    'title': 'ভয়েস এআই চ্যাটবট',
    'welcome': 'এআই প্রস্তুত! মাইক টিপে কথা বলুন',
    'hint': 'টাইপ করুন অথবা মাইক টিপুন...',
    'thinking': 'এআই চিন্তা করছে...',
  }
      : {
    'title': 'Voice AI Chatbot',
    'welcome': 'AI is ready! Tap mic or type',
    'hint': 'Type or tap mic...',
    'thinking': 'AI is thinking...',
  };

  bool _isListening = false;
  bool _speechEnabled = false;
  bool _isLoading = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _addMessage("Assistant", _texts['welcome']!);

    if (widget.initialText != null && widget.initialText!.trim().isNotEmpty) {
      _controller.text = widget.initialText!.trim();
      // Optional for Auto-focus
      Future.delayed(const Duration(milliseconds: 300), () {
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      });
    }
  }

  void _initSpeech() async {
    await Permission.microphone.request();
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _toggleLanguage() {
    setState(() => _isBangla = !_isBangla);
    if (_messages.isNotEmpty && _messages.first['sender'] == 'Assistant') {
      _messages[0]['text'] = _texts['welcome']!;
      setState(() {});
    }
  }

  void _startListening() async {
    if (!_speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isBangla ? "মাইক্রোফোন অনুমতি দিন" : "Allow microphone")),
      );
      return;
    }

    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _lastWords = result.recognizedWords;
          _controller.text = _lastWords;
          if (result.finalResult && _lastWords.isNotEmpty) {
            _stopListeningAndSend();
          }
        });
      },
      localeId: _localeId,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      partialResults: true,
    );
    setState(() => _isListening = true);
  }

  void _stopListeningAndSend() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
    if (_lastWords.trim().isNotEmpty) {
      _sendMessage(_lastWords.trim());
    }
  }

  void _addMessage(String sender, String text) {
    setState(() {
      _messages.add({"sender": sender, "text": text});
    });

    // Save every message to database
    _saveMessageToDB(sender, text);
  }

  Future<void> _saveMessageToDB(String sender, String text) async {
    try {
      final record = Record(
        type: 'chat',
        content: text,
        timestamp: DateTime.now().toIso8601String(),
        metadata: jsonEncode({
          'sender': sender,
          'source': 'ai_chat',
        }),
        userId: '',
      );
      await _dbHelper.insertRecord(record);
    } catch (e) {
      debugPrint('Failed to save AI chat to DB: $e');
    }
  }

  Future<void> _sendMessage([String? text]) async {
    final input = text ?? _controller.text.trim();
    if (input.isEmpty || _isLoading) return;

    _addMessage("User", input);
    _controller.clear();
    _lastWords = '';
    setState(() => _isLoading = true);

    final response = await _ai.getResponse(input);
    _addMessage("Assistant", response);

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_texts['title']!, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        elevation: 4,
        actions: [
          IconButton(
            icon: Image.asset(
              _isBangla ? 'assets/flags/bd.png' : 'assets/flags/us.png',
              width: 28,
            ),
            onPressed: _toggleLanguage,
            tooltip: _isBangla ? 'Switch to English' : 'বাংলায় যান',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length && _isLoading) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                        const SizedBox(width: 12),
                        Text(_texts['thinking']!, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                final msg = _messages[i];
                final isUser = msg["sender"] == "User";
                return BubbleNormal(
                  text: msg["text"]!,
                  isSender: isUser,
                  color: isUser ? Colors.deepPurple : Colors.purple[100]!,
                  tail: true,
                  textStyle: TextStyle(fontSize: 16, color: isUser ? Colors.white : Colors.black87),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: _texts['hint']!,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                AvatarGlow(
                  animate: _isListening,
                  glowColor: Colors.red,
                  duration: const Duration(milliseconds: 2000),
                  repeat: true,
                  child: FloatingActionButton(
                    heroTag: "mic",
                    backgroundColor: _isListening ? Colors.red : Colors.deepPurple,
                    onPressed: _isListening ? _stopListeningAndSend : _startListening,
                    child: Icon(_isListening ? Icons.mic : Icons.mic_none, size: 28, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  heroTag: "send",
                  backgroundColor: _isLoading ? Colors.grey : Colors.green,
                  onPressed: _isLoading ? null : () => _sendMessage(),
                  child: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _speechToText.stop();
    _controller.dispose();
    super.dispose();
  }
}