import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'ViewDetailsScreen.dart';
import 'RegistrationScreen.dart';
import 'package:queens_gambit/homePage.dart';
import 'package:queens_gambit/screens/admin/adminLoginPage.dart';

class ThankYouScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final bool isUpdate;

  const ThankYouScreen({
    super.key,
    required this.userData,
    this.isUpdate = false,
  });

  @override
  State<ThankYouScreen> createState() => _ThankYouScreenState();
}

class _ThankYouScreenState extends State<ThankYouScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play(); // start the animation on load
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.blue,
          automaticallyImplyLeading: false,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => HomePage()),
                    (route) => false,
              );
            },
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset('assets/images/adminheadlogo.png', height: height * 0.05),
            ],
          ),
        ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: width * 0.06),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🎉 Confetti + Logo
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ConfettiWidget(
                        confettiController: _confettiController,
                        blastDirectionality: BlastDirectionality.explosive,
                        shouldLoop: false,
                        emissionFrequency: 0.05,
                        numberOfParticles: 30,
                        maxBlastForce: 20,
                        minBlastForce: 8,
                        gravity: 0.2,
                        colors: const [
                          Colors.blue,
                          Colors.red,
                          Colors.yellow,
                          Colors.green,
                          Colors.purple,
                          Colors.orange,
                        ],
                      ),
                      Container(
                        height: height * 0.2,
                        width: height * 0.2,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDCEEFB),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: height * 0.14,
                            width: height * 0.14,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: height * 0.04),

                  // Thank You Text
                  Text(
                    "Thank You!",
                    style: TextStyle(
                      fontSize: width * 0.08,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: height * 0.015),

                  Text(
                    widget.isUpdate
                        ? "For your registration update"
                        : "For your registration",
                    style: TextStyle(
                      fontSize: width * 0.05,
                      color: Colors.blue.shade300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: height * 0.03),

                  Text(
                    "Once approved kindly check your Email",
                    style: TextStyle(
                      fontSize: width * 0.042,
                      color: Colors.blue.shade300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: height * 0.05),

                  // View Details Button
                  if (!widget.isUpdate)
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ViewDetailsScreen(
                              userData: widget.userData,
                            ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                      ),
                      child: Text(
                        "View your details",
                        style: TextStyle(
                          fontSize: width * 0.045,
                          decoration: TextDecoration.underline,
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
