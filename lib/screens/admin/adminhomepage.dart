import 'package:flutter/material.dart';
import 'package:queens_gambit/screens/admin/eventFormScreen.dart';
import 'participants_screen.dart';

class AdminHomePage extends StatelessWidget {
  final String adminName;

  const AdminHomePage({super.key, required this.adminName});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(height * 0.08),
          child: AppBar(
            backgroundColor: Colors.blue,
            automaticallyImplyLeading: false,
            elevation: 0,
            title: Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.03),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/adminheadlogo.png',
                    height: height * 0.045,
                  ),
                  Text(
                    adminName.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.04,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(width * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, size: width * 0.07),
                  onPressed: () => Navigator.pop(context),
                ),
                SizedBox(height: height * 0.01),
                Expanded(
                  child: isLandscape
                      ? Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Image.asset(
                            'assets/images/queen.jpg',
                            width: width * 0.4,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _buildButtons(context, width, height),
                      ),
                    ],
                  )
                      : Column(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Center(
                          child: Image.asset(
                            'assets/images/queen.jpg',
                            width: width * 0.6,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: _buildButtons(context, width, height),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context, double width, double height) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.05),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildButton(context, 'Registered participants', 'registered', width, height),
          _buildButton(context, 'Waiting Participants', 'waiting', width, height),
          _buildButton(context, 'Approved Participants', 'approved', width, height),
          _buildButton(context, 'Form', 'form', width, height),
        ],
      ),
    );
  }

  Widget _buildButton(
      BuildContext context, String label, String routeType, double width, double height) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: height * 0.015),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          minimumSize: Size(width * 0.75, height * 0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(width * 0.03),
          ),
        ),
        onPressed: () {
          if (routeType == 'form') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EventFormScreen()),
            );
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
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: width * 0.04,
          ),
        ),
      ),
    );
  }
}
