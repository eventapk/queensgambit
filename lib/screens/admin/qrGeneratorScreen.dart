import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRGeneratorScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const QRGeneratorScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Use plain text for QR code (e.g., phone number or event name)
    String qrData = userData['phone_number'] ?? userData['event'] ?? 'No data';

    // Debug: Print QR code content
    print('Generated QR Code: $qrData');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0090FF),
        title: const Text('Your QR Code', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(width * 0.05),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: width * 0.6,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 20),
              Text(
                'QR Code for: $qrData',
                style: TextStyle(
                  fontSize: width * 0.04,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}