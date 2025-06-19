import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:queens_gambit/screens/admin/userDetailScreen.dart';

class ParticipantsScreen extends StatefulWidget {
  final String status;

  const ParticipantsScreen({Key? key, required this.status}) : super(key: key);

  @override
  _ParticipantsScreenState createState() => _ParticipantsScreenState();
}

class _ParticipantsScreenState extends State<ParticipantsScreen> {
  List<Participant> allParticipants = [];
  List<Participant> filteredParticipants = [];
  bool isLoading = true;
  String searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    fetchParticipantsFromFirestore();
  }

  void fetchParticipantsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('status', isEqualTo: widget.status)
          .get();

      final List<Participant> loaded = snapshot.docs
          .map((doc) => Participant(
        0,
        doc.data()['name'] ?? 'N/A',
        doc.data()['event'] ?? 'N/A',
        doc.id,
      ))
          .toList();

      for (int i = 0; i < loaded.length; i++) {
        loaded[i].sNo = i + 1;
      }

      setState(() {
        allParticipants = loaded;
        filteredParticipants = List.from(allParticipants);
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching participants: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void deleteParticipant(int index) async {
    final phoneNumber = filteredParticipants[index].phone;
    try {
      await FirebaseFirestore.instance.collection('users').doc(phoneNumber).delete();

      setState(() {
        allParticipants.removeWhere((p) => p.phone == phoneNumber);
        filteredParticipants.removeAt(index);
        for (int i = 0; i < filteredParticipants.length; i++) {
          filteredParticipants[i].sNo = i + 1;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Participant deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting: $e')),
      );
    }
  }

  void updateSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        searchQuery = query.toLowerCase();
        filteredParticipants = allParticipants
            .where((p) => p.name.toLowerCase().contains(searchQuery))
            .toList();

        for (int i = 0; i < filteredParticipants.length; i++) {
          filteredParticipants[i].sNo = i + 1;
        }
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: width * 0.06),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(""),
      ),
      body: Column(
        children: [
          _buildHeader(width, height),
          SizedBox(height: height * 0.01),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredParticipants.isEmpty
                ? const Center(child: Text("No participants found"))
                : Container(
              margin: EdgeInsets.symmetric(horizontal: width * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(width * 0.02),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _tableHeader(width),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredParticipants.length,
                      itemBuilder: (context, index) =>
                          _buildParticipantRow(filteredParticipants[index], index, width),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: height * 0.02),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, height * 0.07),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text("View more", style: TextStyle(fontSize: width * 0.04, fontWeight: FontWeight.w500)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeader(double width, double height) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(width * 0.04),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: width * 0.03, vertical: height * 0.008),
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Icon(Icons.casino, color: Colors.white, size: width * 0.045),
                    SizedBox(width: width * 0.01),
                    Text("Queens",
                        style: TextStyle(color: Colors.white, fontSize: width * 0.04, fontWeight: FontWeight.bold)),
                    Text("Gambit", style: TextStyle(color: Colors.white, fontSize: width * 0.035)),
                  ],
                ),
              ),
              const Spacer(),
              Text("HI USER NAME",
                  style: TextStyle(fontSize: width * 0.035, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              SizedBox(width: width * 0.02),
              CircleAvatar(
                backgroundColor: Colors.blue,
                radius: width * 0.04,
                child: Icon(Icons.notifications, color: Colors.white, size: width * 0.05),
              ),
            ],
          ),
          SizedBox(height: height * 0.02),
          TextField(
            onChanged: updateSearch,
            decoration: InputDecoration(
              hintText: "Search by name",
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          SizedBox(height: height * 0.02),
          Row(
            children: [
              Expanded(
                child: Text(
                  "${widget.status[0].toUpperCase()}${widget.status.substring(1)} participants",
                  style: TextStyle(fontSize: width * 0.04, fontWeight: FontWeight.w600),
                ),
              ),
              _tagButton("Select", Colors.white, Colors.blue),
              SizedBox(width: width * 0.02),
              _tagButton("Export", Colors.blue, Colors.transparent, border: Colors.blue),
              SizedBox(width: width * 0.02),
              Container(
                padding: EdgeInsets.all(width * 0.02),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.menu, color: Colors.grey[600], size: width * 0.05),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(double width) => Container(
    decoration: BoxDecoration(
      color: Colors.blue,
      borderRadius: BorderRadius.vertical(top: Radius.circular(width * 0.02)),
    ),
    child: Row(
      children: [
        _buildHeaderCell("S No", flex: 1, fontSize: width * 0.035),
        _buildHeaderCell("Name", flex: 2, fontSize: width * 0.035),
        _buildHeaderCell("Events", flex: 2, fontSize: width * 0.035),
        _buildHeaderCell("Action", flex: 2, fontSize: width * 0.035),
      ],
    ),
  );

  Widget _buildHeaderCell(String title, {required int flex, required double fontSize}) => Expanded(
    flex: flex,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(title,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: fontSize)),
    ),
  );

  Widget _buildRowCell(String content, {required int flex, required double width}) => Expanded(
    flex: flex,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text(content,
          textAlign: TextAlign.center, style: TextStyle(fontSize: width * 0.035, fontWeight: FontWeight.w500)),
    ),
  );

  Widget _buildParticipantRow(Participant p, int index, double width) => Container(
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
    child: Row(
      children: [
        _buildRowCell(p.sNo.toString(), flex: 1, width: width),
        _buildRowCell(p.name, flex: 2, width: width),
        _buildRowCell(p.events, flex: 2, width: width),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async {
                    try {
                      final doc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(p.phone)
                          .get();

                      if (doc.exists) {
                        final userData = doc.data()!;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserDetailScreen(userData: userData),
                          ),
                        );
                      }
                    } catch (e) {
                      print("Error fetching user detail: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to fetch user details')),
                      );
                    }
                  },
                  child: _iconBtn(Icons.visibility, Colors.blue),
                ),
                SizedBox(width: width * 0.02),
                GestureDetector(
                  onTap: () => deleteParticipant(index),
                  child: _iconBtn(Icons.delete, Colors.red, filled: true),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _tagButton(String text, Color textColor, Color bgColor, {Color? border}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    decoration: BoxDecoration(
        color: bgColor, border: Border.all(color: border ?? bgColor), borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
  );

  Widget _iconBtn(IconData icon, Color color, {bool filled = false}) => Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: filled ? color.withOpacity(0.1) : null,
      border: Border.all(color: color),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Icon(icon, color: color, size: 16),
  );
}

class Participant {
  int sNo;
  final String name;
  final String events;
  final String phone;

  Participant(this.sNo, this.name, this.events, this.phone);
}
