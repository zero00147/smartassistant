// lib/services/user_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String username;
  final String password;
  final String displayName;
  final String? email;
  final String? phone;
  final DateTime createdAt;
  final Map<String, int> usageStats;

  User({
    required this.username,
    required this.password,
    this.displayName = '',
    this.email,
    this.phone,
    required this.createdAt,
    this.usageStats = const {'totalMessages': 0, 'filesUploaded': 0, 'recordings': 0},
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
    'displayName': displayName,
    'email': email,
    'phone': phone,
    'createdAt': createdAt.toIso8601String(),
    'usageStats': usageStats,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    username: json['username'] as String,
    password: json['password'] as String,
    displayName: json['displayName'] as String? ?? json['username'] as String,
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    usageStats: (json['usageStats'] as Map?)?.map((k, v) => MapEntry(k as String, v as int)) ?? {'totalMessages': 0, 'filesUploaded': 0, 'recordings': 0},
  );
}

/// Handles sign-up, login, logout and current-user persistence.
class UserService {

  static const _kUsersKey = 'app_users';
  static const _kCurrentUserKey = 'current_user';

  /// Private constructor – singleton
  UserService._();
  static final UserService _instance = UserService._();
  factory UserService() => _instance;

  /// -----------------------------------------------------------------------
  /// Helper – get SharedPreferences instance
  /// -----------------------------------------------------------------------
  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  /// -----------------------------------------------------------------------
  /// Load all stored users (returns empty list if none)
  /// -----------------------------------------------------------------------
  Future<List<User>> _loadAllUsers() async {
    final prefs = await _prefs();
    final jsonStr = prefs.getString(_kUsersKey);
    if (jsonStr == null) return [];

    final List<dynamic> list = jsonDecode(jsonStr);
    return list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// -----------------------------------------------------------------------
  /// Save all users back to storage
  /// -----------------------------------------------------------------------
  Future<void> _saveAllUsers(List<User> users) async {
    final prefs = await _prefs();
    final jsonStr = jsonEncode(users.map((u) => u.toJson()).toList());
    await prefs.setString(_kUsersKey, jsonStr);
  }

  /// -----------------------------------------------------------------------
  /// SIGN-UP
  /// -----------------------------------------------------------------------
  Future<String?> signUp({
    required String username,
    required String password,
    String? email,
    String? phone,
  }) async {
    if (username.trim().isEmpty) {
      return 'Username is required';
    }

    final users = await _loadAllUsers();

    // Username must be unique
    if (users.any((u) => u.username.toLowerCase() == username.toLowerCase())) {
      return 'Username already taken';
    }

    final newUser = User(
      username: username.trim(),
      password: password,
      displayName: username.trim(),
      email: email?.trim(),
      phone: phone?.trim(),
      createdAt: DateTime.now(),
    );

    users.add(newUser);
    await _saveAllUsers(users);
    return null;
  }

  /// -----------------------------------------------------------------------
  /// LOGIN
  /// -----------------------------------------------------------------------
  Future<String?> login({
    required String username,
    required String password,
  }) async {
    final users = await _loadAllUsers();

    final match = users.firstWhere(
          (u) => u.username.toLowerCase() == username.toLowerCase() && u.password == password,
      orElse: () => User(username: '', password: '', createdAt: DateTime.now()),
    );

    if (match.username.isEmpty) {
      return 'Invalid username or password';
    }

    final prefs = await _prefs();
    await prefs.setString(_kCurrentUserKey, match.username);
    return null;
  }

  /// -----------------------------------------------------------------------
  /// LOGOUT
  /// -----------------------------------------------------------------------
  Future<void> logout() async {
    final prefs = await _prefs();
    await prefs.remove(_kCurrentUserKey);
  }

  /// -----------------------------------------------------------------------
  /// GET CURRENT LOGGED-IN USER (returns username or null)
  /// -----------------------------------------------------------------------
  Future<String?> get currentUser async {
    final prefs = await _prefs();
    return prefs.getString(_kCurrentUserKey);
  }

  /// -----------------------------------------------------------------------
  /// GET FULL USER OBJECT FOR CURRENT USER (or null)
  /// -----------------------------------------------------------------------
  Future<User?> get currentUserObject async {
    final username = await currentUser;
    if (username == null) return null;

    final users = await _loadAllUsers();
    return users.firstWhere((u) => u.username == username, orElse: () => User(username: '', password: '', createdAt: DateTime.now()));
  }

  /// -----------------------------------------------------------------------
  /// UPDATE USER PROFILE (displayName, email, phone)
  /// -----------------------------------------------------------------------
  Future<void> updateUser(String username, {String? displayName, String? email, String? phone}) async {
    final users = await _loadAllUsers();
    final index = users.indexWhere((u) => u.username.toLowerCase() == username.toLowerCase());
    if (index == -1) return;

    final updatedUser = User(
      username: users[index].username,
      password: users[index].password,
      displayName: displayName ?? users[index].displayName,
      email: email ?? users[index].email,
      phone: phone ?? users[index].phone,
      createdAt: users[index].createdAt,
      usageStats: users[index].usageStats,
    );

    users[index] = updatedUser;
    await _saveAllUsers(users);
  }

  /// -----------------------------------------------------------------------
  /// UPDATE USER STATS (increment a stat key)
  /// -----------------------------------------------------------------------
  Future<void> updateUserStats(String statKey, int increment) async {
    final username = await currentUser;
    if (username == null) return;

    final users = await _loadAllUsers();
    final index = users.indexWhere((u) => u.username == username);
    if (index == -1) return;

    final stats = users[index].usageStats;
    stats[statKey] = (stats[statKey] ?? 0) + increment;

    final updatedUser = User(
      username: users[index].username,
      password: users[index].password,
      displayName: users[index].displayName,
      email: users[index].email,
      phone: users[index].phone,
      createdAt: users[index].createdAt,
      usageStats: stats,
    );

    users[index] = updatedUser;
    await _saveAllUsers(users);
  }

  /// -----------------------------------------------------------------------
  /// DELETE USER
  /// -----------------------------------------------------------------------
  Future<bool> deleteUser(String username) async {
    final users = await _loadAllUsers();
    final before = users.length;
    users.removeWhere((u) => u.username.toLowerCase() == username.toLowerCase());
    if (users.length == before) return false;

    await _saveAllUsers(users);
    final current = await currentUser;
    if (current?.toLowerCase() == username.toLowerCase()) await logout();
    return true;
  }
}