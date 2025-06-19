import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:queens_gambit/screens/thank_you_screen.dart';

class EventSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  EventSelectionScreen({required this.userData, required bool isUpdateMode});

  @override
  _EventSelectionScreenState createState() => _EventSelectionScreenState();
}

class _EventSelectionScreenState extends State<EventSelectionScreen> {
  int? selectedEventIndex;

  final List<Map<String, String>> events = [
    {
      "name": "Chennai Chess",
      "date": "24/06/2025",
      "image": "assets/images/madras.jpg"
    },
    {
      "name": "Bangalore Open",
      "date": "01/07/2025",
      "image": "assets/images/bangalore.jpg"
    },
    {
      "name": "Chennai Chess Champion",
      "date": "10/07/2025",
      "image": "assets/images/pondicherry.jpg"
    },
  ];

  void registerUser(BuildContext context) async {
    if (selectedEventIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an event')),
      );
      return;
    }

    try {
      final selectedEvent = events[selectedEventIndex!];
      final phone = widget.userData['phone_number'];

      final docRef = FirebaseFirestore.instance.collection('users').doc(phone);

      final updatedUserData = {
        ...widget.userData,
        "event": selectedEvent['name'],
        "event_date": selectedEvent['date'],
        "status": "registered",
      };

      await docRef.set(updatedUserData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User Registered Successfully')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ThankYouScreen(userData: updatedUserData),
        ),
      );
    } catch (e) {
      print("❌ Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF0090FF);

    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Events", style: TextStyle(fontSize: width * 0.05)),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.04,
          vertical: height * 0.02,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select an Event",
              style: TextStyle(
                fontSize: width * 0.06,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: height * 0.02),

            /// Events List
            Expanded(
              child: ListView.separated(
                itemCount: events.length,
                separatorBuilder: (_, __) => SizedBox(height: height * 0.02),
                itemBuilder: (context, index) {
                  final event = events[index];
                  final isSelected = selectedEventIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedEventIndex = index;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryBlue.withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? primaryBlue : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(width * 0.035),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              event['image']!,
                              width: width * 0.22,
                              height: width * 0.22,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: width * 0.04),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event['name']!,
                                  style: TextStyle(
                                    fontSize: width * 0.045,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  event['date']!,
                                  style: TextStyle(
                                    fontSize: width * 0.035,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle,
                                color: Colors.green, size: width * 0.06),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: height * 0.02),
            ElevatedButton(
              onPressed: () => registerUser(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                minimumSize: Size.fromHeight(height * 0.07),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Register",
                style: TextStyle(
                  fontSize: width * 0.045,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
