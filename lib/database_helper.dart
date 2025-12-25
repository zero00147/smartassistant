// database_helper.dart
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Record {
  final int? id;
  final String userId;
  final String type;
  final String content;
  final String timestamp;
  final String metadata;

  Record({
    this.id,
    required this.userId,
    required this.type,
    required this.content,
    required this.timestamp,
    required this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'content': content,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }

  factory Record.fromMap(Map<String, dynamic> map) {
    return Record(
      id: map['id'],
      userId: map['user_id'] ?? 'guest',
      type: map['type'],
      content: map['content'],
      timestamp: map['timestamp'],
      metadata: map['metadata'] ?? '',
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
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL DEFAULT 'guest',
        type TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        metadata TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE records ADD COLUMN user_id TEXT NOT NULL DEFAULT "guest"');

      final prefs = await SharedPreferences.getInstance();
      final currentUser = prefs.getString('current_user_id') ?? 'guest';
      await db.rawUpdate('UPDATE records SET user_id = ?', [currentUser]);
    }
  }

  Future<int> insertRecord(Record record) async {
    final db = await database;
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('current_user_id') ?? 'guest';

    final map = record.toMap();
    map['user_id'] = currentUserId;

    return await db.insert('records', map);
  }

  Future<List<Record>> getRecords({String? type, int limit = 50}) async {
    final db = await database;
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('current_user_id') ?? 'guest';

    String where = 'user_id = ?';
    List<dynamic> whereArgs = [currentUserId];

    if (type != null) {
      where += ' AND type = ?';
      whereArgs.add(type);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'records',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) => Record.fromMap(maps[i]));
  }

  Future<void> clearRecords() async {
    final db = await database;
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('current_user_id') ?? 'guest';

    await db.delete(
      'records',
      where: 'user_id = ?',
      whereArgs: [currentUserId],
    );
  }
}