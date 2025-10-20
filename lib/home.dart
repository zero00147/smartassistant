// home.dart
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart'; // For Gradient
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'loggingScreen.dart';
import 'profile.dart';
import 'chatbotScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // --------------------------------------
  // STATE VARIABLES
  // --------------------------------------
  final _audioRecorder = AudioRecorder();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _messageController = TextEditingController();
  bool isListening = false;
  bool isRecording = false;
  List<Map<String, String>> messages = [];
  List<Map<String, dynamic>> uploadedFiles = [];
  String? _lastWords = '';
  late AnimationController _backgroundController;
  late AnimationController _recordController;
  late Animation<double> _recordAnimation;

  // --------------------------------------
  // INITIALIZATION AND DISPOSAL
  // --------------------------------------
  @override
  void initState() {
    super.initState();
    // Initialize services and animations
    _initSpeech();
    _loadFileHistory();
    _addWelcomeMessage();

    // Setup background animation
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Setup record button animation
    _recordController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _recordAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _recordController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    // Clean up resources
    _audioRecorder.dispose();
    _speech.stop();
    _messageController.dispose();
    _backgroundController.dispose();
    _recordController.dispose();
    super.dispose();
  }

  // --------------------------------------
  // BACKGROUND ANIMATION MODULE
  // --------------------------------------
  /// Builds an animated gradient background that changes opacity over time
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        final double sineValue = sin(_backgroundController.value * 2 * pi);
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.indigo.withOpacity(0.1 + sineValue * 0.1),
                Colors.purple.withOpacity(0.05 + sineValue * 0.05),
                Colors.blue.withOpacity(0.1 + sineValue * 0.1),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }

  // --------------------------------------
  // FILE MANAGEMENT MODULE
  // --------------------------------------
  /// Loads file history from SharedPreferences
  Future<void> _loadFileHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fileHistoryJson = prefs.getString('uploaded_files') ?? '[]';
      final List<dynamic> fileList = json.decode(fileHistoryJson);
      setState(() {
        uploadedFiles = fileList.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      debugPrint("Error loading file history: $e");
    }
  }

  /// Saves a file to history
  Future<void> _saveFileToHistory(String fileName, String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fileStat = await File(filePath).stat();
      final newFile = {
        'name': fileName,
        'path': filePath,
        'timestamp': DateTime.now().toIso8601String(),
        'size': fileStat.size,
      };

      setState(() {
        uploadedFiles.insert(0, newFile);
        if (uploadedFiles.length > 50) {
          uploadedFiles = uploadedFiles.sublist(0, 50);
        }
      });

      final fileHistoryJson = json.encode(uploadedFiles);
      await prefs.setString('uploaded_files', fileHistoryJson);
      addMessage("User", "📁 Selected: $fileName");
      addMessage("Assistant", "✅ File uploaded and saved!");
    } catch (e) {
      debugPrint("Error saving file history: $e");
      addMessage("Assistant", "❌ File picker error: $e");
    }
  }

  /// Picks a file and saves it to app directory
  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result != null) {
        String filePath = result.files.single.path!;
        String fileName = result.files.single.name;

        final directory = await getApplicationDocumentsDirectory();
        final newPath = '${directory.path}/$fileName';
        await File(filePath).copy(newPath);

        await _saveFileToHistory(fileName, newPath);
      }
    } catch (e) {
      addMessage("Assistant", "❌ File picker error: $e");
    }
  }

  // --------------------------------------
  // AUDIO RECORDING MODULE
  // --------------------------------------
  /// Toggles audio recording on or off
  Future<void> toggleRecording() async {
    try {
      if (await _audioRecorder.isRecording()) {
        String? path = await _audioRecorder.stop();
        setState(() {
          isRecording = false;
        });
        _recordController.reverse();
        if (path != null) {
          await _saveFileToHistory("Audio Recording", path);
          addMessage("Assistant", "🎙️ Audio saved!");
        }
      } else {
        if (await _audioRecorder.hasPermission()) {
          final directory = await getApplicationDocumentsDirectory();
          final path =
              '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _audioRecorder.start(const RecordConfig(), path: path);
          setState(() => isRecording = true);
          _recordController.forward();
          addMessage("Assistant", "🔴 RECORDING... (tap center to stop)");
        } else {
          addMessage("Assistant", "❌ Microphone permission needed");
        }
      }
    } catch (e) {
      addMessage("Assistant", "❌ Recording error: $e");
    }
  }

  // --------------------------------------
  // SPEECH RECOGNITION MODULE
  // --------------------------------------
  /// Initializes speech-to-text service
  Future<void> _initSpeech() async {
    try {
      bool available = await _speech.initialize();
      if (!available) {
        addMessage("Assistant", "❌ Voice recognition not available");
      }
    } catch (e) {
      debugPrint("Speech init error: $e");
    }
  }

  /// Starts listening for speech input
  void _startListening() async {
    try {
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _lastWords = result.recognizedWords;
          });
          if (result.finalResult && _lastWords!.isNotEmpty) {
            sendMessage(_lastWords!);
          }
        },
      );
      setState(() => isListening = true);
    } catch (e) {
      addMessage("Assistant", "❌ Listening error");
    }
  }

  /// Stops listening for speech input
  void _stopListening() async {
    await _speech.stop();
    setState(() => isListening = false);
  }

  // --------------------------------------
  // CHAT MODULE
  // --------------------------------------
  /// Adds a welcome message after initialization
  void _addWelcomeMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      addMessage(
          "Assistant",
          "🎙️ Tap center to record! 👤 Check your profile! 🤖 Open chatbot!");
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
      return "👋 Hello! Try the chatbot for more AI features! 🤖";
    }
    if (lower.contains('time')) {
      return "🕐 It's ${DateTime.now().hour}:${DateTime.now().minute}! ⏰";
    }
    return "🤖 Processing: '$input' ✨";
  }

  /// Adds a message to the chat list
  void addMessage(String sender, String text) {
    setState(() => messages.add({"sender": sender, "text": text}));
  }

  // --------------------------------------
  // CALENDAR MODULE
  // --------------------------------------
  /// Displays the calendar interface in a modal bottom sheet
  void _showCalendar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -10))],
            ),
            child: Column(
              children: [
                // Calendar header
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.green, Colors.green[400]!]),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          "📅 Calendar",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Calendar content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        "📅 Calendar View",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                "Today's Date: ${_formatDate(DateTime.now())}",
                                style: const TextStyle(fontSize: 18),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  sendMessage("show calendar events");
                                },
                                child: const Text("View Events"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Add event button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            sendMessage("add calendar event");
                          },
                          icon: const Icon(Icons.add),
                          label: const Text("Add Event"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Formats a date for display (e.g., "Today" or "DD/MM/YYYY")
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return "Today";
    }
    return "${date.day}/${date.month}/${date.year}";
  }

  // --------------------------------------
  // QUICK BUTTON MODULE
  // --------------------------------------
  /// Builds a quick action button with icon and label
  Widget _buildQuickButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(colors: [color.withOpacity(0.1), color.withOpacity(0.05)]),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------
  // MAIN UI BUILD
  // --------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          _buildAnimatedBackground(),

          SafeArea(
            child: Column(
              children: [
                // App bar with menu
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.indigo, Colors.indigo[700]!]),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.smart_toy, color: Colors.indigo),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Smart Assistant",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Welcome!",
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      // Profile menu
                      PopupMenuButton<String>(
                        icon: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'profile':
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ProfileScreen()),
                              );
                              break;
                            case 'logout':
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const LoggingScreen()),
                              );
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'profile',
                            child: ListTile(
                              leading: Icon(Icons.person, color: Colors.blue),
                              title: Text('Profile'),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'logout',
                            child: ListTile(
                              leading: Icon(Icons.logout, color: Colors.red),
                              title: Text('Logout'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Chat messages display
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: ListView.builder(
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[messages.length - 1 - index];
                        bool isUser = msg["sender"] == "User";
                        return BubbleNormal(
                          text: msg["text"]!,
                          isSender: isUser,
                          color: isUser ? Colors.blue : Colors.grey[200]!,
                          tail: true,
                          textStyle: TextStyle(color: isUser ? Colors.white : Colors.black87),
                        );
                      },
                    ),
                  ),
                ),

                // Quick action buttons
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickButton(Icons.calendar_today, "Calendar", Colors.green, _showCalendar),
                        const SizedBox(width: 12),
                        _buildQuickButton(Icons.smart_toy, "Chatbot", Colors.purple, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ChatbotScreen()),
                          );
                        }),
                        const SizedBox(width: 12),
                        _buildQuickButton(Icons.upload_file, "Upload", Colors.orange, pickFile),
                      ],
                    ),
                  ),
                ),

                // Message input field
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: isListening ? '🎤 Listening...' : '💬 Type a message...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey[500]),
                          ),
                          onSubmitted: sendMessage,
                          enabled: !isListening,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(isListening ? Icons.stop : Icons.mic),
                        onPressed: isListening ? _stopListening : _startListening,
                        color: isListening ? Colors.red : Colors.indigo,
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () => sendMessage(_messageController.text),
                        color: Colors.indigo,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Center record button
          Center(
            child: AnimatedBuilder(
              animation: _recordAnimation,
              builder: (context, child) => Transform.scale(
                scale: _recordAnimation.value,
                child: GestureDetector(
                  onTap: toggleRecording,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isRecording ? Colors.red : Colors.indigo,
                      boxShadow: [
                        BoxShadow(
                          color: (isRecording ? Colors.red : Colors.indigo).withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}