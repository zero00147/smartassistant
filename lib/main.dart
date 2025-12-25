// main.dart (Updated for Groq Key Loading)
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'LoggingScreen.dart';

String? groqApiKey;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    groqApiKey = dotenv.env['GROQ_API_KEY'];
    if (groqApiKey == null || groqApiKey!.isEmpty) {
      print("ERROR: GROQ_API_KEY is missing in .env");
    } else {
      print("SUCCESS: Groq key loaded: ${groqApiKey!.substring(0, 8)}...");
    }
  } catch (e) {
    print("Failed to load .env: $e");
    groqApiKey = null;
  }

  runApp(const SmartAssistantApp());
}

class SmartAssistantApp extends StatelessWidget {
  const SmartAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Assistant',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const LoggingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}