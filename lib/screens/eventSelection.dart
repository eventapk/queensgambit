import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  EventSelectionScreen({required this.userData});

  @override
  _EventSelectionScreenState createState() => _EventSelectionScreenState();
}

class _EventSelectionScreenState extends State<EventSelectionScreen> {
  int? selectedEventIndex;

  final List<Map<String, String>> events = [
    {"name": "Chennai Chess", "date": "2025-06-24"},
    {"name": "Bangalore Open", "date": "2025-07-01"},
    {"name": "Chennai Chess Champion", "date": "2025-07-10"},
  ];

  void registerUser(BuildContext context) async {
    if (selectedEventIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select an event')));
      return;
    }

    try {
      final selectedEvent = events[selectedEventIndex!];
      final phone = widget.userData['phone_number'];

      final docRef = FirebaseFirestore.instance.collection('users').doc(phone);

      await docRef.set({
        ...widget.userData,
        "event": selectedEvent['name'],
        "event_date": selectedEvent['date'],
        "status": "registered",
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User Registered Successfully')));
      Navigator.pop(context);
    } catch (e) {
      print("❌ Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Events")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                final isSelected = selectedEventIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedEventIndex = index;
                    });
                  },
                  child: Card(
                    color: isSelected ? Colors.blue[100] : null,
                    child: ListTile(
                      title: Text(event['name']!),
                      subtitle: Text(event['date']!),
                      trailing: isSelected ? Icon(Icons.check_circle, color: Colors.green) : null,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => registerUser(context),
              child: Text("Register"),
              style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(50)),
            ),
          ),
        ],
      ),
    );
  }
}
