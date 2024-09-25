import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() {
  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'reminder_channel',
        channelName: 'Reminder Notifications',
        channelDescription: 'Channel for reminder notifications',
        defaultColor: Colors.teal,
        ledColor: Colors.white,
      ),
    ],
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reminder App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ReminderPage(),
    );
  }
}

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  String? _selectedDay;
  TimeOfDay? _selectedTime;
  String? _selectedActivity;

  final List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  final List<String> activities = [
    'Wake up',
    'Go to gym',
    'Breakfast',
    'Meetings',
    'Lunch',
    'Quick nap',
    'Go to library',
    'Dinner',
    'Go to sleep'
  ];

  List<NotificationDetails> _notifications = [];

  void _setReminder() {
    if (_selectedDay == null || _selectedTime == null || _selectedActivity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select day, time, and activity.')),
      );
      return;
    }


    final now = DateTime.now();


    final reminderDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );


    if (reminderDateTime.isBefore(now)) {
      reminderDateTime.add(const Duration(days: 7));
    }


    final notificationId = now.millisecondsSinceEpoch.remainder(100000);
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: 'reminder_channel',
        title: 'Reminder: $_selectedActivity',
        body: 'It\'s time for $_selectedActivity on $_selectedDay!',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar.fromDate(date: reminderDateTime),
    );


    _notifications.add(NotificationDetails(
      id: notificationId,
      activity: _selectedActivity!,
      day: _selectedDay!,
      time: '${_selectedTime!.hour}:${_selectedTime!.minute}',
    ));


    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reminder set for $_selectedActivity on $_selectedDay at ${_selectedTime!.hour}:${_selectedTime!.minute}')),
    );

    // Clear selections
    setState(() {
      _selectedDay = null;
      _selectedTime = null;
      _selectedActivity = null;
    });
  }

  void _viewNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NotificationListPage(notifications: _notifications, onDelete: _deleteNotification)),
    );
  }

  void _deleteNotification(int id) {
    setState(() {
      _notifications.removeWhere((notification) => notification.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _viewNotifications,
            tooltip: 'View Notifications',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Heading
            const Text(
              'Remainder Application',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 100),

            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Day',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.deepPurple.shade50,
              ),
              value: _selectedDay,
              items: daysOfWeek.map((day) {
                return DropdownMenuItem(
                  value: day,
                  child: Text(day, style: const TextStyle(fontSize: 20)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDay = value;
                });
              },
              isExpanded: true,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                final TimeOfDay? time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() {
                    _selectedTime = time;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: Text(
                _selectedTime == null
                    ? 'Select Time'
                    : 'Selected Time: ${_selectedTime!.hour}:${_selectedTime!.minute}',
                style: const TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
            const SizedBox(height: 50),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Activity',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.deepPurple.shade50,
              ),
              value: _selectedActivity,
              items: activities.map((activity) {
                return DropdownMenuItem(
                  value: activity,
                  child: Text(activity, style: const TextStyle(fontSize: 20)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedActivity = value;
                });
              },
              isExpanded: true,
            ),
            const SizedBox(height: 70),
            ElevatedButton(
              onPressed: _setReminder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                padding: const EdgeInsets.symmetric(vertical: 15.0),
                minimumSize: const Size(double.infinity, 55), // Full-width button
              ),
              child: const Text('Set Reminder', style: TextStyle(fontSize: 22, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationDetails {
  final int id;
  final String activity;
  final String day;
  final String time;

  NotificationDetails({
    required this.id,
    required this.activity,
    required this.day,
    required this.time,
  });
}

class NotificationListPage extends StatelessWidget {
  final List<NotificationDetails> notifications;
  final Function(int) onDelete;

  const NotificationListPage({super.key, required this.notifications, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheduled Notifications', style: TextStyle(fontSize: 22)),
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return ListTile(
            title: Text(notification.activity, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            subtitle: Text('On ${notification.day} at ${notification.time}', style: const TextStyle(fontSize: 18)),
            leading: const Icon(Icons.notifications, size: 45, color: Colors.indigo),
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                onDelete(notification.id);
              },
            ),
          );
        },
      ),
    );
  }
}
