import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QRResultScreen extends StatelessWidget {
  final Map<String, dynamic> scanResult;

  const QRResultScreen({super.key, required this.scanResult});

  Future<void> _updateAdmissionStatus(BuildContext context) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(scanResult['phone_number']);
      await docRef.update({
        'status': 'admitted',
        'admission_timestamp': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User successfully admitted')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error admitting user: $e')),
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String value, double width) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: width * 0.015),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: width * 0.3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: width * 0.04,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          SizedBox(width: width * 0.02),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: TextStyle(
                fontSize: width * 0.04,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    Color statusColor;
    IconData statusIcon;
    String statusMessage;

    switch (scanResult['status']) {
      case 'admitted':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusMessage = 'User Already Admitted';
        break;
      case 'completed':
      case 'approved':
      case 'registered':
        statusColor = Colors.blue;
        statusIcon = Icons.person;
        statusMessage = 'User Registered - Ready to Admit';
        break;
      case 'not_found':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusMessage = 'User Not Found';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.question_mark;
        statusMessage = 'Unknown Status';
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0090FF),
        title: const Text('QR Scan Result', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Colors.grey[100],
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(width * 0.05),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(width * 0.05),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: width * 0.2,
                      height: width * 0.2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor.withOpacity(0.1),
                      ),
                      child: Icon(
                        statusIcon,
                        color: statusColor,
                        size: width * 0.12,
                      ),
                    ),
                    SizedBox(height: height * 0.02),
                    Text(
                      statusMessage,
                      style: TextStyle(
                        fontSize: width * 0.05,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: height * 0.02),
                    if (scanResult['status'] != 'not_found') ...[
                      _buildInfoRow('Name', scanResult['name'] ?? 'N/A', width),
                      _buildInfoRow('Phone', scanResult['phone_number'] ?? 'N/A', width),
                      _buildInfoRow('Event', scanResult['event'] ?? 'N/A', width),
                      _buildInfoRow('Email', scanResult['email'] ?? 'N/A', width),
                      _buildInfoRow('Age', scanResult['age'] ?? 'N/A', width),
                      _buildInfoRow('DOB', scanResult['dob'] ?? 'N/A', width),
                      _buildInfoRow('Gender', scanResult['gender'] ?? 'N/A', width),
                      _buildInfoRow('Event Date', scanResult['event_date'] ?? 'N/A', width),
                    ],
                    if (scanResult['status'] == 'not_found' && scanResult['error'] != null)
                      _buildInfoRow('Error', scanResult['error'], width),
                    SizedBox(height: height * 0.03),
                    if (scanResult['status'] == 'registered' ||
                        scanResult['status'] == 'approved' ||
                        scanResult['status'] == 'completed')
                      ElevatedButton(
                        onPressed: () => _updateAdmissionStatus(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.1,
                            vertical: height * 0.015,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, color: Colors.white, size: width * 0.05),
                            SizedBox(width: width * 0.02),
                            Text(
                              'Admit User',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: width * 0.04,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (scanResult['status'] == 'admitted' || scanResult['status'] == 'not_found')
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.1,
                            vertical: height * 0.015,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back, color: Colors.white, size: width * 0.05),
                            SizedBox(width: width * 0.02),
                            Text(
                              'Back to Scanner',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: width * 0.04,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}