import 'package:flutter/material.dart';
import 'registeredParticipants.dart';

class AdminHomePage extends StatelessWidget {
  final String adminEmail;

  const AdminHomePage({super.key, required this.adminEmail});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Admin Panel?'),
            content: const Text('Do you really want to go back?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
        ) ??
            false;

        if (shouldExit) {
          Navigator.of(context).pop(); // this is how you exit with PopScope
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.blue,
          elevation: 0,
          toolbarHeight: 0,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          'HI ADMIN\n${adminEmail.toUpperCase()}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: const Icon(Icons.notifications_none, color: Colors.blue),
                    ),
                  ],
                ),
              ),
              Flexible(
                flex: 3,
                child: Image.asset(
                  'assets/images/knight.png',
                  width: MediaQuery.of(context).size.width * 0.6,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              Flexible(
                flex: 4,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  shrinkWrap: true,
                  children: [
                    _buildButton(context, 'Registered participants', 'registered'),
                    _buildButton(context, 'Waiting Participants', 'waiting'),
                    _buildButton(context, 'Approved Participants', 'approved'),
                    _buildButton(context, 'Form', 'form'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String label, String routeType) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          if (routeType == 'form') {
            // TODO: Implement your form screen navigation
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
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
