import 'package:flutter/material.dart';
import 'package:queens_gambit/screens/admin/adminLoginPage.dart';
import 'package:queens_gambit/screens/user/registrationScreen.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _slideAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background + content
            SingleChildScrollView(
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/boarddesign.jpeg',
                    width: width,
                    height: height * 0.28,
                    fit: BoxFit.cover,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: height * 0.04),
                    child: Container(
                      width: width * 0.9,
                      padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: height * 0.015),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6)),
                          BoxShadow(color: Colors.black12, blurRadius: 25, offset: Offset(0, 10)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Image.asset(
                              'assets/images/knightlogo.jpeg',
                              width: width * 0.25,
                            ),
                          ),
                          SizedBox(width: width * 0.04),
                          Flexible(
                            child: AnimatedBuilder(
                              animation: _slideAnimation,
                              builder: (_, __) => Transform.translate(
                                offset: Offset(_slideAnimation.value, 0),
                                child: Image.asset(
                                  'assets/images/chesscoin.jpeg',
                                  width: width * 0.3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Image.asset(
                    'assets/images/boarddesign.jpeg',
                    width: width,
                    height: height * 0.28,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: height * 0.13),
                ],
              ),
            ),

            // Top-right login button
            Positioned(
              top: height * 0.03,
              right: width * 0.04,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminLoginPage()),
                    );
                  },
                  icon: Icon(
                    Icons.person,
                    color: const Color(0xFF0090FF),
                    size: width * 0.07,
                  ),
                  tooltip: 'Admin Login',
                ),
              ),
            ),

            // Bottom-center register button
            Positioned(
              bottom: height * 0.03,
              left: width * 0.15,
              right: width * 0.15,
              child: SizedBox(
                height: height * 0.06,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RegistrationScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0090FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 10,
                    shadowColor: Colors.black38,
                  ),
                  child: Text(
                    "Register Now",
                    style: TextStyle(
                      fontSize: width * 0.045,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
