import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:queens_gambit/screens/user/thank_you_screen.dart';

class EventSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final bool isUpdateMode;

  EventSelectionScreen({required this.userData, required this.isUpdateMode});

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
      "name": "Delhi",
      "date": "10/07/2025",
      "image": "assets/images/delhi.jpeg"
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
      final eventName = selectedEvent['name'];

      // 🔁 Check for duplicate registration
      final duplicateCheck = await FirebaseFirestore.instance
          .collection('users')
          .where('phone_number', isEqualTo: phone)
          .get();

      if (duplicateCheck.docs.isNotEmpty && !widget.isUpdateMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You have already registered .')),
        );
        return;
      }

      final docRef = FirebaseFirestore.instance.collection('users').doc(phone);

      final updatedUserData = {
        ...widget.userData,
        "event": selectedEvent['name'],
        "event_date": selectedEvent['date'],
        "status": "registered",
        "timestamp": FieldValue.serverTimestamp(),
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
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: MediaQuery.removeViewInsets(
          removeBottom: true,
          context: context,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    color: primaryBlue,
                    padding: EdgeInsets.only(
                      top: height * 0.02,
                      bottom: height * 0.015,
                      left: width * 0.04,
                    ),
                    alignment: Alignment.centerLeft,
                    child: Image.asset(
                      'assets/images/adminheadlogo.png',
                      width: width * 0.22,
                    ),
                  ),

                  // App Bar Row
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              "Events",
                              style: TextStyle(
                                fontSize: width * 0.05,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: width * 0.12),
                      ],
                    ),
                  ),

                  // Main Content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.04,
                        vertical: height * 0.02,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildTickStepper(width),
                          SizedBox(height: height * 0.03),

                          // Event List
                          Expanded(
                            child: ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              itemCount: events.length,
                              separatorBuilder: (_, __) =>
                                  SizedBox(height: height * 0.02),
                              itemBuilder: (context, index) {
                                final event = events[index];
                                final isSelected =
                                    selectedEventIndex == index;

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
                                        color: isSelected
                                            ? primaryBlue
                                            : Colors.grey.shade300,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    padding: EdgeInsets.all(width * 0.035),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                          BorderRadius.circular(10),
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
                                            crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                event['name']!,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: width * 0.045,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                event['date']!,
                                                textAlign: TextAlign.center,
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
                                              color: Colors.green,
                                              size: width * 0.06),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: height * 0.015),

                          // Register Button
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
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildTickStepper(double width) {
    double circleSize = width * 0.08;
    double tickSize = width * 0.095;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: circleSize,
          height: circleSize,
          decoration: const BoxDecoration(
            color: Color(0xFF0090FF),
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Container(
            height: 2,
            color: const Color(0xFF0090FF),
          ),
        ),
        Container(
          width: tickSize,
          height: tickSize,
          decoration: const BoxDecoration(
            color: Color(0xFF0090FF),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check, color: Colors.white, size: tickSize * 0.6),
        ),
        Expanded(
          child: Container(
            height: 2,
            color: const Color(0xFF0090FF),
          ),
        ),
      ],
    );
  }
}
