// database_helper.dart
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Record {
  final int? id;
  final String type; // 'chat', 'file', 'recording'
  final String content; // message text, file name, audio path
  final String timestamp;
  final String metadata; // JSON for extra data (e.g., file size, duration)

  Record({
    this.id,
    required this.type,
    required this.content,
    required this.timestamp,
    required this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'content': content,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }

  factory Record.fromMap(Map<String, dynamic> map) {
    return Record(
      id: map['id'],
      type: map['type'],
      content: map['content'],
      timestamp: map['timestamp'],
      metadata: map['metadata'],
    );
  }
}

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._privateConstructor();
  factory DatabaseHelper() => _instance ??= DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'smart_assistant_records.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        metadata TEXT
      )
    ''');
  }

  // Get current user ID (from SharedPreferences, fallback to 'guest')
  Future<String> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_user_id') ?? 'guest';
  }

  // Save a record
  Future<int> insertRecord(Record record) async {
    final db = await database;
    final userId = await _getCurrentUserId();
    final recordWithUser = Record(
      type: record.type,
      content: record.content,
      timestamp: record.timestamp,
      metadata: jsonEncode({
        ...jsonDecode(record.metadata ?? '{}'),
        'user_id': userId,
      }),
    );
    return await db.insert('records', recordWithUser.toMap());
  }

  // Get all records for current user (latest first)
  Future<List<Record>> getRecords({String? type, int limit = 50}) async {
    final db = await database;
    final userId = await _getCurrentUserId();
    var whereArgs = ['user_id = ?', userId];
    var whereString = 'metadata LIKE ?';
    whereArgs.insert(0, '%$userId%'); // For JSON metadata search

    if (type != null) {
      whereString += ' AND type = ?';
      whereArgs.add(type);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'records',
      where: whereString,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) => Record.fromMap(maps[i]));
  }

  // Clear all records for current user
  Future<void> clearRecords() async {
    final db = await database;
    final userId = await _getCurrentUserId();
    await db.delete('records', where: 'metadata LIKE ?', whereArgs: ['%$userId%']);
  }
}