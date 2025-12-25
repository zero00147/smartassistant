// ProfileScreen.dart
import 'package:flutter/material.dart';
import 'user_service.dart';
import 'HomeScreen.dart';
import 'LoggingScreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic> userProfile = {
    'name': '',
    'email': '',
    'avatar': '👤',
    'phone': '',
    'joined': DateTime.now().toIso8601String(),
    'usageStats': {
      'totalMessages': 0,
      'filesUploaded': 0,
      'recordings': 0,
    },
  };
  bool isDarkTheme = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool isEditing = false;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final user = await _userService.currentUserObject;
    if (user == null) {

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoggingScreen()));
      return;
    }

    setState(() {
      userProfile = {
        'name': user.displayName,
        'email': user.email ?? 'No email',
        'phone': user.phone ?? 'Not set',
        'joined': user.createdAt.toIso8601String(),
        'avatar': '👤',
        'usageStats': user.usageStats,
      };
      _nameController.text = userProfile['name'];
      _emailController.text = userProfile['email'];
      _phoneController.text = userProfile['phone'];
    });
  }

  void _toggleEditMode() {
    setState(() {
      if (isEditing) {
        userProfile['name'] = _nameController.text.trim();
        userProfile['email'] = _emailController.text.trim();
        userProfile['phone'] = _phoneController.text.trim();

        _userService.updateUser(
          userProfile['name'],
          displayName: userProfile['name'],
          email: userProfile['email'],
          phone: userProfile['phone'],
        );
      }
      isEditing = !isEditing;
    });
  }

  Widget _buildProfileHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        margin: const EdgeInsets.all(16),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[600]!, Colors.blue[400]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Text(
                    userProfile['avatar'] ?? '👤',
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              isEditing
                  ? TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Enter name',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              )
                  : Text(
                userProfile['name'] ?? 'User',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              isEditing
                  ? TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.85),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Enter email',
                  hintStyle: const TextStyle(color: Colors.grey),
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.blueAccent),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              )
                  : Text(
                userProfile['email'] ?? 'No email',
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
              ),
              const SizedBox(height: 12),
              isEditing
                  ? TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.85),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Enter phone',
                  hintStyle: const TextStyle(color: Colors.grey),
                  labelText: 'Phone',
                  labelStyle: const TextStyle(color: Colors.blueAccent),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              )
                  : Text(
                'Phone: ${userProfile['phone'] ?? 'Not set'}',
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text(
                'Joined: ${DateTime.parse(userProfile['joined']).toLocal().toString().split(' ')[0]}',
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _toggleEditMode,
                icon: Icon(isEditing ? Icons.save : Icons.edit, size: 20),
                label: Text(isEditing ? 'Save Profile' : 'Edit Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String title, String value, Color color) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "📊 Activity Stats",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    Icons.message,
                    "Messages",
                    (userProfile['usageStats']['totalMessages'] ?? 0).toString(),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    Icons.upload_file,
                    "Files",
                    (userProfile['usageStats']['filesUploaded'] ?? 0).toString(),
                    Colors.blueAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              Icons.mic,
              "Recordings",
              (userProfile['usageStats']['recordings'] ?? 0).toString(),
              Colors.blueGrey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(isDarkTheme ? Icons.dark_mode : Icons.light_mode, color: Colors.blue, size: 24),
            title: const Text('Toggle Theme', style: TextStyle(fontSize: 16, color: Colors.blue)),
            trailing: Switch(
              value: isDarkTheme,
              onChanged: (value) {
                setState(() {
                  isDarkTheme = value;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Theme switched to ${value ? 'Dark' : 'Light'} mode!")),
                  );
                });
              },
              activeColor: Colors.blue,
            ),
          ),
          const Divider(height: 1, color: Colors.blueGrey),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.blue, size: 24),
            title: const Text('Settings', style: TextStyle(fontSize: 16, color: Colors.blue)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Settings coming soon! ⚙️")));
            },
          ),
          const Divider(height: 1, color: Colors.blueGrey),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red, size: 24),
            title: const Text('Logout', style: TextStyle(fontSize: 16, color: Colors.red)),
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoggingScreen()));
            },
          ),
          const Divider(height: 1, color: Colors.blueGrey),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 24),
            title: const Text('Delete Account', style: TextStyle(fontSize: 16, color: Colors.redAccent)),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Account'),
                  content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.blue))),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account deletion coming soon!")));
                        Navigator.pop(context);
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 3,
        shadowColor: Colors.blue.withOpacity(0.4),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            _buildStatsSection(),
            _buildOptionsSection(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 20),
                label: const Text('Back to Home', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}