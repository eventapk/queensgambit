import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:queens_gambit/screens/admin/qrResultScreen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController controller = MobileScannerController(
    torchEnabled: false,
    facing: CameraFacing.back,
    formats: [BarcodeFormat.qrCode],
  );
  bool hasScanned = false;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required to scan QR codes')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller.stop();
    }
    controller.start();
  }

  Future<void> _onDetect(BarcodeCapture barcodeCapture) async {
    if (!hasScanned && !isProcessing && barcodeCapture.barcodes.isNotEmpty) {
      setState(() {
        isProcessing = true;
        hasScanned = true;
      });

      try {
        final barcode = barcodeCapture.barcodes.first;
        if (barcode.rawValue != null) {
          String scannedValue = barcode.rawValue!;
          // Normalize phone number: remove non-digits and try with country code
          String normalizedPhone = scannedValue.replaceAll(RegExp(r'[^0-9]'), '');
          String phoneWithCountryCode = scannedValue.startsWith('+')
              ? scannedValue.replaceAll(RegExp(r'[^0-9+]'), '')
              : '+91$normalizedPhone';
          print('Scanned QR code raw value: "$scannedValue"');
          print('Normalized phone: "$normalizedPhone"');
          print('Phone with country code: "$phoneWithCountryCode"');

          await controller.stop();

          // Query Firestore for user with matching phone_number field
          QuerySnapshot userQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('phone_number', isEqualTo: normalizedPhone)
              .get();
          print('Query by phone_number ($normalizedPhone) returned ${userQuery.docs.length} documents');

          // Try querying with country code if no results
          if (userQuery.docs.isEmpty) {
            userQuery = await FirebaseFirestore.instance
                .collection('users')
                .where('phone_number', isEqualTo: phoneWithCountryCode)
                .get();
            print('Query by phone_number ($phoneWithCountryCode) returned ${userQuery.docs.length} documents');
          }

          // Try querying by document ID if still no results
          if (userQuery.docs.isEmpty) {
            final docSnapshot = await FirebaseFirestore.instance
                .collection('users')
                .doc(normalizedPhone)
                .get();
            if (docSnapshot.exists) {
              userQuery = await FirebaseFirestore.instance
                  .collection('users')
                  .where(FieldPath.documentId, isEqualTo: normalizedPhone)
                  .get();
              print('Query by document ID ($normalizedPhone) found document');
            }
          }

          // Try alternative field name 'phone' if no results
          if (userQuery.docs.isEmpty) {
            userQuery = await FirebaseFirestore.instance
                .collection('users')
                .where('phone', isEqualTo: normalizedPhone)
                .get();
            print('Query by phone ($normalizedPhone) returned ${userQuery.docs.length} documents');
          }

          // Create scanResult map
          Map<String, dynamic> scanResult = {
            'phone_number': normalizedPhone,
            'status': 'not_found',
            'name': 'Unknown',
            'event': 'No event',
            'error': 'User not found in database (Scanned: $scannedValue)',
          };

          if (userQuery.docs.isNotEmpty) {
            final userData = userQuery.docs.first.data() as Map<String, dynamic>;
            print('User data found: $userData');
            scanResult = {
              'phone_number': normalizedPhone,
              'status': userData['status'] ?? 'unknown',
              'name': userData['name'] ?? 'Unknown',
              'event': userData['event'] ?? 'No event',
              'email': userData['email'] ?? '',
              'age': userData['age']?.toString() ?? '',
              'dob': userData['dob'] ?? '',
              'gender': userData['gender'] ?? '',
              'event_date': userData['event_date'] ?? 'Not Assigned',
              'error': null,
            };
          } else {
            print('No user found for any query. Raw QR value: "$scannedValue"');
          }

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QRResultScreen(scanResult: scanResult),
              ),
            ).then((_) {
              if (mounted) {
                setState(() {
                  hasScanned = false;
                  isProcessing = false;
                });
                controller.start();
              }
            });
          }
        } else {
          _handleScanError('Invalid QR code format');
        }
      } catch (e) {
        _handleScanError('Error processing QR code: $e');
      }
    }
  }

  void _handleScanError(String message) {
    if (mounted) {
      setState(() {
        hasScanned = false;
        isProcessing = false;
      });
      controller.start();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0090FF),
        title: const Text('Scan QR Code', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              controller.torchEnabled ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: () async {
              await controller.toggleTorch();
              setState(() {});
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
            fit: BoxFit.cover,
            errorBuilder: (context, error, child) {
              return Center(
                child: Text(
                  'Camera error: $error',
                  style: TextStyle(color: Colors.white, fontSize: width * 0.04),
                  textAlign: TextAlign.center,
                ),
              );
            },
            scanWindow: Rect.fromCenter(
              center: Offset(width * 0.5, height * 0.5 - 50),
              width: width * 0.7,
              height: width * 0.7,
            ),
          ),
          CustomPaint(
            painter: ScannerOverlay(
              scanWindow: Rect.fromCenter(
                center: Offset(width * 0.5, height * 0.5 - 50),
                width: width * 0.7,
                height: width * 0.7,
              ),
            ),
            child: Container(),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.all(width * 0.04),
              child: Text(
                isProcessing
                    ? 'Processing QR code...'
                    : 'Point camera at QR code to scan',
                style: TextStyle(
                  fontSize: width * 0.04,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlay extends CustomPainter {
  final Rect scanWindow;

  ScannerOverlay({required this.scanWindow});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.5);
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRect(scanWindow),
      ),
      paint,
    );

    canvas.drawRect(scanWindow, borderPaint);

    final cornerLength = 20.0;
    final corners = [
      [
        scanWindow.topLeft,
        Offset(scanWindow.left + cornerLength, scanWindow.top),
        Offset(scanWindow.left, scanWindow.top + cornerLength)
      ],
      [
        scanWindow.topRight,
        Offset(scanWindow.right - cornerLength, scanWindow.top),
        Offset(scanWindow.right, scanWindow.top + cornerLength)
      ],
      [
        scanWindow.bottomLeft,
        Offset(scanWindow.left + cornerLength, scanWindow.bottom),
        Offset(scanWindow.left, scanWindow.bottom - cornerLength)
      ],
      [
        scanWindow.bottomRight,
        Offset(scanWindow.right - cornerLength, scanWindow.bottom),
        Offset(scanWindow.right, scanWindow.bottom - cornerLength)
      ],
    ];

    for (var corner in corners) {
      canvas.drawLine(corner[0], corner[1], borderPaint);
      canvas.drawLine(corner[0], corner[2], borderPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}