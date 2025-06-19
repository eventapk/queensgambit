import 'package:flutter/material.dart';

import 'ViewDetailsScreen.dart';


class ThankYouScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  final bool isUpdate;

  ThankYouScreen({required this.userData, this.isUpdate = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.jpg',
                    height: 100,
                  ),
                  SizedBox(height: 30),
                  Text(
                    "Thank You!",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    isUpdate
                        ? "For your registration update"
                        : "For your registration",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.blue.shade300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  Text(
                    "Your registration is under approval\nkindly check your",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue.shade300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Email',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 40),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ViewDetailsScreen(userData: userData),
                          ),
                        );
                      },
                      child: Text(
                        "View your details",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
