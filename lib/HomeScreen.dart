// HomeScreen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'LoggingScreen.dart';
import 'ProfileScreen.dart';
import 'ChatbotScreen.dart';
import 'CalendarScreen.dart';
import 'HistoryScreen.dart';
import 'database_helper.dart';
import 'package:http/http.dart' as http;
import '../main.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'user_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // -------------------------------------------------------------------------
  // STATE VARIABLES
  // -------------------------------------------------------------------------
  final _audioRecorder = AudioRecorder();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _messageController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final UserService _userService = UserService();

  bool isListening = false;
  bool isRecording = false;

  List<Map<String, String>> messages = [];
  List<Map<String, dynamic>> uploadedFiles = [];

  String? _lastWords = '';

  late AnimationController _backgroundController;
  late AnimationController _recordController;
  late Animation<double> _recordAnimation;

  // -------------------------------------------------------------------------
  // INITIALISATION / DISPOSAL
  // -------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadFileHistory();
    _addWelcomeMessage();

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _recordController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _recordAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _recordController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _speech.stop();
    _messageController.dispose();
    _backgroundController.dispose();
    _recordController.dispose();
    super.dispose();
  }
  // -------------------------------------------------------------------------
  // BACKGROUND
  // -------------------------------------------------------------------------
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        final double sine = sin(_backgroundController.value * 2 * pi);
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.indigo.withOpacity(0.1 + sine * 0.1),
                Colors.purple.withOpacity(0.05 + sine * 0.05),
                Colors.blue.withOpacity(0.1 + sine * 0.1),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // UNIFIED SAVE METHOD (Files & Recordings)
  // -------------------------------------------------------------------------
  Future<void> _saveFileToHistory(String name, String path, {bool isRecording = false}) async {
    try {
      final stat = await File(path).stat();
      final meta = jsonEncode({
        'path': path,
        'size': stat.size,
        'is_recording': isRecording,
      });

      final recordType = isRecording ? 'recording' : 'file';
      final record = Record(
        type: recordType,
        content: name,
        timestamp: DateTime.now().toIso8601String(),
        metadata: meta, userId: '',
      );
      await _dbHelper.insertRecord(record);

      setState(() {
        uploadedFiles.insert(0, {
          'name': name,
          'path': path,
          'timestamp': DateTime.now().toIso8601String(),
          'size': stat.size,
          'is_recording': isRecording,
        });
        if (uploadedFiles.length > 50) uploadedFiles = uploadedFiles.sublist(0, 50);
      });

      addMessage('User', isRecording ? 'Recorded audio' : 'Selected: $name');
      addMessage('Assistant', isRecording ? 'Audio recorded and saved!' : 'File uploaded and saved!');
    } catch (e) {
      debugPrint('save file history error: $e');
      addMessage('Assistant', 'Save error: $e');
    }
  }
  // -------------------------------------------------------------------------
  // LOAD BOTH FILES AND RECORDINGS FOR UPLOAD MODAL
  // -------------------------------------------------------------------------
  Future<void> _loadFileHistory() async {
    try {
      final fileRecords = await _dbHelper.getRecords(type: 'file');
      final recordingRecords = await _dbHelper.getRecords(type: 'recording');

      final allRecords = [...fileRecords, ...recordingRecords];

      setState(() {
        uploadedFiles = allRecords.map((r) {
          final meta = jsonDecode(r.metadata ?? '{}');
          return {
            'name': r.content,
            'path': meta['path'] ?? '',
            'timestamp': r.timestamp,
            'size': meta['size'] ?? 0,
            'is_recording': r.type == 'recording',
          };
        }).toList()
          ..sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      });
    } catch (e) {
      debugPrint('load file history error: $e');
    }
  }
  // -------------------------------------------------------------------------
  // FILE PICKER + STATS UPDATE
  // -------------------------------------------------------------------------
  Future<void> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false);
      if (result == null) return;

      final srcPath = result.files.single.path!;
      final name = result.files.single.name;

      final dir = await getApplicationDocumentsDirectory();
      final destPath = '${dir.path}/$name';
      await File(srcPath).copy(destPath);

      await _saveFileToHistory(name, destPath, isRecording: false);
      await _userService.updateUserStats('filesUploaded', 1); // ← Stats update
    } catch (e) {
      addMessage('Assistant', 'File picker error: $e');
    }
  }
  // -------------------------------------------------------------------------
  // UPLOAD MODAL
  // -------------------------------------------------------------------------
  void _showUploadSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollCtrl) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -10))
              ],
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.orange, Colors.orange[400]!]),
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
                          "Upload File",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        "Select a file to upload",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await pickFile();
                          },
                          icon: const Icon(Icons.cloud_upload),
                          label: const Text("Choose File"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (uploadedFiles.isNotEmpty) ...[
                        const Text("Recently uploaded:", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...uploadedFiles.take(3).map((f) => ListTile(
                          leading: Icon(
                            f['is_recording'] == true ? Icons.mic : Icons.insert_drive_file,
                            color: f['is_recording'] == true ? Colors.red : Colors.grey,
                          ),
                          title: Text(f['name'] ?? '—'),
                          subtitle: Text(_formatFileSize(f['size'] ?? 0)),
                          dense: true,
                        )),
                      ],
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  // -------------------------------------------------------------------------
  // AUDIO RECORDING + TRANSCRIPTION + STATS + CHATBOT OPTION
  // -------------------------------------------------------------------------
  Future<void> toggleRecording() async {
    try {
      if (await _audioRecorder.isRecording()) {
        String? path = await _audioRecorder.stop();
        setState(() => isRecording = false);
        _recordController.reverse();

        if (path != null) {
          final filename = 'Recording ${DateTime.now().toString().substring(0, 19).replaceAll(':', '-')}.m4a';

          await _saveFileToHistory(filename, path, isRecording: true);
          await _userService.updateUserStats('recordings', 1); // ← Stats update

          addMessage('Assistant', 'Transcribing your audio... 🎤→📝');
          final transcription = await _transcribeWithGroq(path);

          String finalTranscription = transcription.trim();
          if (finalTranscription.isEmpty || finalTranscription.toLowerCase().contains('error')) {
            finalTranscription = '[Transcription not available]';
            addMessage('Assistant', '⚠️ Transcription failed.');
          } else {
            addMessage('Assistant', '📝 Transcription ready:\n\n"$finalTranscription"');
          }

          final bool? sendToChatbot = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Use in Chatbot?'),
              content: const Text('Do you want to send this transcription to the AI Chatbot?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          );

          if (sendToChatbot == true) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatbotScreen(initialText: finalTranscription),
              ),
            );
          }
        }
      } else {
        if (await _audioRecorder.hasPermission()) {
          final dir = await getApplicationDocumentsDirectory();
          final path = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _audioRecorder.start(const RecordConfig(), path: path);
          setState(() => isRecording = true);
          _recordController.forward();
          addMessage('Assistant', '🔴 RECORDING... (tap to stop)');
        } else {
          addMessage('Assistant', '❌ Microphone permission needed');
        }
      }
    } catch (e) {
      debugPrint('Recording error: $e');
      addMessage('Assistant', '❌ Recording error: $e');
    }
  }

  // -------------------------------------------------------------------------
  // GROQ WHISPER TRANSCRIPTION
  // -------------------------------------------------------------------------
  Future<String> _transcribeWithGroq(String filePath) async {
    if (groqApiKey == null || groqApiKey!.isEmpty) {
      return 'Missing GROQ_API_KEY';
    }

    try {
      final uri = Uri.parse('https://api.groq.com/openai/v1/audio/transcriptions');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $groqApiKey';
      request.fields['model'] = 'whisper-large-v3';
      request.fields['response_format'] = 'text';

      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send().timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        return await response.stream.bytesToString();
      } else {
        final errorBody = await response.stream.bytesToString();
        debugPrint('Groq error ${response.statusCode}: $errorBody');
        return 'Server error ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('Transcription exception: $e');
      return 'Failed: $e';
    }
  }

  // -------------------------------------------------------------------------
  // SPEECH-TO-TEXT (Live microphone)
  // -------------------------------------------------------------------------
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

  void _stopListening() async {
    await _speech.stop();
    setState(() => isListening = false);
  }

  // -------------------------------------------------------------------------
  // CHAT LOGIC + STATS UPDATE
  // -------------------------------------------------------------------------
  void _addWelcomeMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      addMessage("Assistant", "🎙️ Tap the green mic button to record! 👤 Check your profile! 🤖 Open chatbot!");
    });
  }

  void sendMessage(String text) {
    if (text.trim().isNotEmpty) {
      addMessage("User", text);
      _messageController.clear();
      Future.delayed(const Duration(seconds: 1), () {
        String response = _getAIResponse(text);
        addMessage("Assistant", response);
        _userService.updateUserStats('totalMessages', 2); // ← Stats update
      });
    }
  }

  String _getAIResponse(String input) {
    String lower = input.toLowerCase();
    if (lower.contains('hello') || lower.contains('hi')) {
      return "👋 Hello! Check your profile for stats! 👤✨";
    }
    if (lower.contains('time')) {
      return "🕐 It's ${DateTime.now().hour}:${DateTime.now().minute}! ⏰";
    }
    return "🤖 Processing: '$input' ✨";
  }

  void addMessage(String sender, String text) {
    setState(() => messages.add({"sender": sender, "text": text}));
  }
  // -------------------------------------------------------------------------
  // NAVIGATION
  // -------------------------------------------------------------------------
  void _showCalendar() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CalendarScreen()),
    );
  }

  void _showHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
  }
  // -------------------------------------------------------------------------
  // QUICK BUTTON
  // -------------------------------------------------------------------------
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
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // BUILD
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(),

          SafeArea(
            child: Column(
              children: [
                // Custom App Bar with Recorder Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.indigo, Colors.indigo[700]!]),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.smart_toy, color: Colors.indigo)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Smart Assistant', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('Welcome!', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ),
                      // Green Recorder Button
                      AvatarGlow(
                        animate: isRecording,
                        glowColor: Colors.green,
                        duration: const Duration(milliseconds: 2000),
                        repeat: true,
                        child: FloatingActionButton(
                          onPressed: toggleRecording,
                          backgroundColor: Colors.green[600],
                          child: Icon(
                            isRecording ? Icons.stop : Icons.mic,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Profile Menu
                      PopupMenuButton<String>(
                        icon: CircleAvatar(backgroundColor: Colors.white.withOpacity(0.2), child: const Icon(Icons.person, color: Colors.white)),
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
                        _buildQuickButton(Icons.history, "History", Colors.blueGrey, _showHistory),
                        const SizedBox(width: 12),
                        _buildQuickButton(Icons.upload_file, "Upload", Colors.orange, _showUploadSheet),
                      ],
                    ),
                  ),
                ),

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
        ],
      ),
    );
  }
}