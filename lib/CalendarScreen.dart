// CalendarScreen.dart
import 'package:flutter/material.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentDate = DateTime.now();
  DateTime? _selectedDate;

  // Bangla month names
  final List<String> _banglaMonths = [
    'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
    'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
  ];

  // English month names
  final List<String> _englishMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  // Weekday names
  final List<String> _weekdaysBn = ['রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহস্পতি', 'শুক্র', 'শনি'];
  final List<String> _weekdaysEn = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  String _getMonthName(int month, bool isBangla) {
    return isBangla ? _banglaMonths[month] : _englishMonths[month];
  }

  void _previousMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + 1);
    });
  }

  List<Widget> _buildCalendarDays() {
    final List<Widget> days = [];

    final firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    final lastDayOfMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0);
    final firstDayWeekday = firstDayOfMonth.weekday % 7; // Sun = 0

    // Empty cells before first day
    for (int i = 0; i < firstDayWeekday; i++) {
      days.add(const SizedBox(width: 40, height: 40));
    }

    // Actual days
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(_currentDate.year, _currentDate.month, day);
      final isToday = date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day;
      final isSelected = _selectedDate != null &&
          _selectedDate!.year == date.year &&
          _selectedDate!.month == date.month &&
          _selectedDate!.day == date.day;

      days.add(
        GestureDetector(
          onTap: () {
            setState(() => _selectedDate = date);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Selected: ${date.day} ${_getMonthName(date.month - 1, true)} ${date.year}"),
                backgroundColor: Colors.green,
              ),
            );
          },
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.deepPurple
                  : isToday
                  ? Colors.orange
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: isToday ? Border.all(color: Colors.orange[800]!, width: 2) : null,
            ),
            alignment: Alignment.center,
            child: Text(
              day.toString(),
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : isToday
                    ? Colors.white
                    : Colors.black87,
                fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    final isBangla = Localizations.localeOf(context).languageCode == 'bn';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isBangla ? 'ক্যালেন্ডার' : 'Calendar',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        elevation: 4,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[50]!, Colors.white],
          ),
        ),
        child: Column(
          children: [
            // Header with month/year
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 32, color: Colors.white),
                    onPressed: _previousMonth,
                  ),
                  Column(
                    children: [
                      Text(
                        _getMonthName(_currentDate.month - 1, isBangla),
                        style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _currentDate.year.toString(),
                        style: const TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 32, color: Colors.white),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Weekdays
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: (isBangla ? _weekdaysBn : _weekdaysEn).map((day) {
                  return SizedBox(
                    width: 40,
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  );
                }).toList(),
              ),
            ),

            const Divider(height: 30, thickness: 1, indent: 20, endIndent: 20),

            // Calendar Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 7,
                padding: const EdgeInsets.all(16),
                children: _buildCalendarDays(),
              ),
            ),

            // Selected Date Display
            if (_selectedDate != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.event_available, color: Colors.green),
                    const SizedBox(width: 12),
                    Text(
                      "Selected: ${_selectedDate!.day} ${_getMonthName(_selectedDate!.month - 1, isBangla)} ${_selectedDate!.year}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}