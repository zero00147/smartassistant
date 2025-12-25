// HistoryScreen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'database_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Record> _allRecords = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    final records = await _dbHelper.getRecords(limit: 100);
    setState(() => _allRecords = records);
    debugPrint('Loaded ${_allRecords.length} records');
  }

  List<Record> _getFilteredRecords(String type) {
    final filtered = _allRecords.where((r) => r.type == type).toList();
    debugPrint('Filtered $type: ${filtered.length} items');
    return filtered;
  }

  Future<void> _playRecording(String? path) async {
    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No audio file found')),
      );
      return;
    }
    try {
      await _audioPlayer.play(DeviceFileSource(path));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Play error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: Colors.indigo,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chats'),
            Tab(text: 'Files'),
            Tab(text: 'Recordings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecordList('chat'),
          _buildRecordList('file'),
          _buildRecordList('recording'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _clearAll,
        child: const Icon(Icons.delete_sweep),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildRecordList(String type) {
    final records = _getFilteredRecords(type);
    if (records.isEmpty) {
      return Center(child: Text('No $type yet'));
    }

    return ListView.builder(
      itemCount: records.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, i) {
        final record = records[i];
        final meta = jsonDecode(record.metadata ?? '{}');
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Icon(
              type == 'chat' ? Icons.chat_bubble :
              type == 'file' ? Icons.insert_drive_file :
              Icons.mic,
              color: type == 'recording' ? Colors.red : Colors.blue,
            ),
            title: Text(record.content),
            subtitle: Text(record.timestamp.substring(0, 16).replaceFirst('T', ' ')),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_formatSize(meta['size'] ?? 0)),
                if (type == 'recording') ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.play_arrow, color: Colors.green),
                    onPressed: () => _playRecording(meta['path']),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatSize(int bytes) {
    if (bytes == 0) return 'Unknown';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Records?'),
        content: const Text('This will delete all chats, files, and recordings.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.clearRecords();
      _loadRecords();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All records cleared')),
      );
    }
  }
}