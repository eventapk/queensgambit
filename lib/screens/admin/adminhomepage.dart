import 'package:flutter/material.dart';
import 'registeredParticipants.dart';

class AdminHomePage extends StatelessWidget {
  final String adminEmail;

  const AdminHomePage({super.key, required this.adminEmail});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Exit Admin Panel?'),
            content: Text('Do you really want to go back?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Yes'),
              ),
            ],
          ),
        ) ??
            false;
        return shouldExit;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.blue,
          elevation: 0,
          toolbarHeight: 0,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'HI ${adminEmail.toUpperCase()}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: Icon(Icons.notifications_none, color: Colors.blue),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Image.asset(
                'assets/images/knight.png',
                width: 250,
                height: 250,
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildButton(context, 'Registered participants', 'registered'),
                    _buildButton(context, 'Waiting Participants', 'waiting'),
                    _buildButton(context, 'Approved Participants', 'approved'),
                    _buildButton(context, 'Form', 'form'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String label, String routeType) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          minimumSize: Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          if (routeType == 'form') {
            // Navigate to your form screen
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ParticipantsScreen(status: routeType),
              ),
            );
          }
        },
        child: Text(
          label,
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
