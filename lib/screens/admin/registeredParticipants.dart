import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:excel/excel.dart' as ExcelLib;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'participant.dart';
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
  StreamSubscription<QuerySnapshot>? _subscription;
  bool selectionMode = false;
  Set<String> selectedPhones = {};
  String filterName = '';
  String filterAge = '';
  String filterEvent = '';
  bool showAllParticipants = false;

  // EmailJS credentials
  static const serviceId = 'service_vgb2gw6';
  static const registrationTemplateId = 'template_bvs05a3';
  static const qrTemplateId = 'template_xul6stb';
  static const publicKey = 'egEVzJXbC3OT3SSYE';

  @override
  void initState() {
    super.initState();
    listenToParticipants();
  }

  void listenToParticipants() {
    final query = widget.status == 'approved'
        ? FirebaseFirestore.instance
        .collection('users')
        .where('status', whereIn: ['approved', 'completed'])
        : FirebaseFirestore.instance
        .collection('users')
        .where('status', isEqualTo: widget.status);

    _subscription = query.snapshots().listen(
          (snapshot) {
        final List<Participant> loaded = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Participant(
            sNo: 0,
            name: data['name'] ?? 'N/A',
            event: data['event'] ?? 'N/A',
            phone: doc.id,
            email: data['email'] ?? '',
            age: data['age'] ?? '',
            dob: data['dob'] ?? '',
            gender: data['gender'] ?? '',
            status: data['status'] ?? 'approved',
            eventDate: data['event_date'] ?? 'Not Assigned',
          );
        }).toList();

        setState(() {
          allParticipants = loaded;
          _applySearch();
          isLoading = false;
        });
      },
      onError: (error) {
        print("Error listening to participants: $error");
        setState(() => isLoading = false);
      },
    );
  }

  void updateSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          searchQuery = query.toLowerCase();
          _applySearch();
        });
      }
    });
  }

  void _applySearch() {
    filteredParticipants = allParticipants.where((p) {
      return p.name.toLowerCase().contains(searchQuery) &&
          (filterName.isEmpty || p.name.toLowerCase().contains(filterName)) &&
          (filterAge.isEmpty || p.age == filterAge) &&
          (filterEvent.isEmpty || p.event == filterEvent);
    }).toList();

    filteredParticipants.sort((a, b) {
      if (a.status == 'completed' && b.status != 'completed') return 1;
      if (a.status != 'completed' && b.status == 'completed') return -1;
      return 0;
    });

    for (int i = 0; i < filteredParticipants.length; i++) {
      filteredParticipants[i].sNo = i + 1;
    }
  }

  void toggleSelectionMode() {
    if (mounted) {
      setState(() {
        selectionMode = !selectionMode;
        if (!selectionMode) selectedPhones.clear();
      });
    }
  }

  void togglePhoneSelection(String phone) {
    if (mounted) {
      setState(() {
        if (selectedPhones.contains(phone)) {
          selectedPhones.remove(phone);
        } else {
          selectedPhones.add(phone);
        }
      });
    }
  }

  bool allUsersSelected() {
    final selectableParticipants =
    filteredParticipants.where((p) => p.status != 'completed').toList();
    return selectedPhones.length == selectableParticipants.length &&
        selectableParticipants.isNotEmpty;
  }

  void selectAllUsers() {
    if (mounted) {
      setState(() {
        if (allUsersSelected()) {
          selectedPhones.clear();
        } else {
          selectedPhones = filteredParticipants
              .where((p) => p.status != 'completed')
              .map((p) => p.phone)
              .toSet();
        }
      });
    }
  }

  Future<String> generateAndUploadQR(String userId, String data) async {
    try {
      final painter = QrPainter(
        data: data,
        version: QrVersions.auto,
        gapless: true,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
      );

      final image = await painter.toImage(300);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${userId}_$timestamp.png';
      final storageRef = FirebaseStorage.instance.ref().child('qrcodes/$fileName');

      await storageRef.putData(
        pngBytes,
        SettableMetadata(
          contentType: 'image/png',
          customMetadata: {
            'userId': userId,
            'generatedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      return await storageRef.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to generate or upload QR code: $e');
    }
  }

  Future<void> sendRegistrationEmail({
    required String toEmail,
    required String participantName,
    required String eventName,
    required String eventDate,
  }) async {
    final paymentLink =
        "https://your-payment-portal.com/pay?event=${Uri.encodeComponent(eventName)}&participant=${Uri.encodeComponent(participantName)}";

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': serviceId,
          'template_id': registrationTemplateId,
          'user_id': publicKey,
          'template_params': {
            'to_email': toEmail,
            'participant_name': participantName,
            'event_name': eventName,
            'event_date': eventDate,
            'payment_link': paymentLink,
            'subject': 'Registration Approved - Complete Your Payment',
            'message':
            'Congratulations! Your registration for $eventName has been approved. Please complete your payment to secure your spot.',
          },
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send registration email: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending registration email: $e');
    }
  }

  Future<void> sendQREmail({
    required String toEmail,
    required String qrUrl,
    required String participantName,
    required String eventName,
  }) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': serviceId,
          'template_id': qrTemplateId,
          'user_id': publicKey,
          'template_params': {
            'to_email': toEmail,
            'user_name': participantName,
            'subject': 'Your Event QR Code',
            'qr_url': qrUrl,
            'qr_data': 'Event Ticket - $eventName',
            'message': 'Please find your QR code attached. Use this for event entry.',
            'sender_name': 'QR Mailer App',
          },
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send QR email: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending QR email: $e');
    }
  }

  Future<void> approveSelectedUsers() async {
    if (selectedPhones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No users selected to approve.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            SizedBox(width: MediaQuery.of(context).size.width * 0.05),
            Flexible(
              child: Text(
                'Approving users and sending emails...',
                style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.035),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final batch = FirebaseFirestore.instance.batch();
      int successCount = 0;
      int failCount = 0;

      for (final phone in selectedPhones) {
        try {
          final docRef = FirebaseFirestore.instance.collection('users').doc(phone);
          final userDoc = await docRef.get();

          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final currentStatus = userData['status'] ?? '';

            if (currentStatus == 'registered') {
              batch.update(docRef, {'status': 'waiting'});
              await sendRegistrationEmail(
                toEmail: userData['email'] ?? '',
                participantName: userData['name'] ?? '',
                eventName: userData['event'] ?? '',
                eventDate: userData['event_date'] ?? 'TBD',
              );
              successCount++;
            } else if (currentStatus == 'approved' && widget.status == 'approved') {
              final qrUrl = await generateAndUploadQR(
                phone,
                'Event Ticket - ${userData['event'] ?? 'Unknown Event'}',
              );
              await sendQREmail(
                toEmail: userData['email'] ?? '',
                qrUrl: qrUrl,
                participantName: userData['name'] ?? '',
                eventName: userData['event'] ?? '',
              );
              batch.update(docRef, {'status': 'completed'});
              successCount++;
            }
          }
        } catch (e) {
          print('Error processing user $phone: $e');
          failCount++;
        }
      }

      await batch.commit();
      Navigator.of(context).pop();
      toggleSelectionMode();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            successCount > 0
                ? '✅ $successCount users processed and emails sent${failCount > 0 ? '. $failCount failed.' : '.'}'
                : '❌ Failed to process all selected users.',
          ),
          backgroundColor: successCount > 0 ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      if (androidInfo.version.sdkInt >= 33) {
        return true; // No special permissions needed for app-specific directories
      } else if (androidInfo.version.sdkInt >= 30) {
        try {
          var status = await Permission.manageExternalStorage.status;
          if (!status.isGranted) {
            bool shouldRequest = await _showPermissionDialog();
            if (shouldRequest) {
              status = await Permission.manageExternalStorage.request();
              if (!status.isGranted) {
                await _showPermissionSettingsDialog();
                return false;
              }
            } else {
              return false;
            }
          }
          return status.isGranted;
        } catch (e) {
          print('Permission error: $e');
          return false;
        }
      } else {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        return status.isGranted;
      }
    }
    return true; // iOS doesn't need explicit permission
  }

  Future<bool> _showPermissionDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Permission Required'),
        content: const Text(
          'This app needs storage permission to save Excel files to your Downloads folder. '
              'This will make it easier for you to find and share the exported files.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<void> _showPermissionSettingsDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Storage permission is required to save files to Downloads folder. '
              'Please enable it manually in app settings, or we can save to app folder instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Use App Folder'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, String>> _getExportDirectory() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      try {
        if (androidInfo.version.sdkInt >= 30) {
          final downloadDir = Directory('/storage/emulated/0/Download');
          if (await downloadDir.exists()) {
            return {
              'path': downloadDir.path,
              'location': 'Downloads folder',
              'instructions': 'File Manager > Downloads',
            };
          }
        } else {
          final downloadDir = Directory('/storage/emulated/0/Download');
          if (await downloadDir.exists()) {
            return {
              'path': downloadDir.path,
              'location': 'Downloads folder',
              'instructions': 'File Manager > Downloads',
            };
          }
        }
      } catch (e) {
        print('Downloads directory access failed: $e');
      }

      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          return {
            'path': externalDir.path,
            'location': 'App storage folder',
            'instructions': 'File Manager > Android > data > com.yourapp.name > files',
          };
        }
      } catch (e) {
        print('External storage access failed: $e');
      }

      final appDir = await getApplicationDocumentsDirectory();
      return {
        'path': appDir.path,
        'location': 'App documents folder',
        'instructions': 'Files may be in app-specific storage',
      };
    } else {
      final directory = await getApplicationDocumentsDirectory();
      return {
        'path': directory.path,
        'location': 'App Documents',
        'instructions': 'Files app > On My iPhone/iPad > Queens Gambit',
      };
    }
  }

  Future<void> exportToExcel(List<Participant> participantsToExport) async {
    try {
      // Show brief loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preparing Excel file...'),
          duration: Duration(seconds: 1),
        ),
      );

      final excel = ExcelLib.Excel.createExcel();
      excel.delete('Sheet1');
      final sheet = excel['Participants'];

      sheet.appendRow([
        ExcelLib.TextCellValue('S.No'),
        ExcelLib.TextCellValue('Name'),
        ExcelLib.TextCellValue('Event'),
        ExcelLib.TextCellValue('Phone'),
        ExcelLib.TextCellValue('Email'),
        ExcelLib.TextCellValue('Age'),
        ExcelLib.TextCellValue('DOB'),
        ExcelLib.TextCellValue('Gender'),
        ExcelLib.TextCellValue('Status'),
        ExcelLib.TextCellValue('Event Date'),
      ]);

      for (final p in participantsToExport) {
        sheet.appendRow([
          ExcelLib.IntCellValue(p.sNo),
          ExcelLib.TextCellValue(p.name),
          ExcelLib.TextCellValue(p.event),
          ExcelLib.TextCellValue(p.phone),
          ExcelLib.TextCellValue(p.email),
          ExcelLib.TextCellValue(p.age),
          ExcelLib.TextCellValue(p.dob),
          ExcelLib.TextCellValue(p.gender),
          ExcelLib.TextCellValue(p.status),
          ExcelLib.TextCellValue(p.eventDate),
        ]);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'Participants_$timestamp.xlsx';
      final directory = await getApplicationDocumentsDirectory();
      final outputPath = '${directory.path}/$fileName';
      final file = File(outputPath);
      await file.writeAsBytes(excel.encode()!);

      // Try copying to Downloads in background
      if (Platform.isAndroid && await _requestStoragePermission()) {
        _copyToDownloadsInBackground(file, fileName);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Excel file created! ${participantsToExport.length} participants exported',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OPEN',
            textColor: Colors.white,
            onPressed: () async {
              try {
                await OpenFile.open(outputPath);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Couldn't open file")),
                );
              }
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _copyToDownloadsInBackground(File sourceFile, String fileName) async {
    try {
      if (Platform.isAndroid) {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (await downloadsDir.exists()) {
          final targetFile = File('${downloadsDir.path}/$fileName');
          await sourceFile.copy(targetFile.path);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File also saved to Downloads folder'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Background copy to Downloads failed: $e');
    }
  }

  void showFilterPopup() {
    showDialog(
      context: context,
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Filter',
                    style: TextStyle(fontSize: width * 0.045),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width * 0.85),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: 'Name'),
                      onChanged: (value) => filterName = value.toLowerCase(),
                      style: TextStyle(fontSize: width * 0.035),
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Age'),
                      onChanged: (value) => filterAge = value,
                      style: TextStyle(fontSize: width * 0.035),
                    ),
                    DropdownButtonFormField<String>(
                      value: filterEvent.isEmpty ? null : filterEvent,
                      decoration: const InputDecoration(labelText: 'Event'),
                      items: [
                        'Bangalore Open',
                        'Chennai Chess Champion',
                        'Chennai Chess',
                      ].map((event) => DropdownMenuItem(value: event, child: Text(event))).toList(),
                      onChanged: (value) => filterEvent = value ?? '',
                      style: TextStyle(fontSize: width * 0.035),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (mounted) {
                    setState(() {
                      filterName = '';
                      filterAge = '';
                      filterEvent = '';
                      _applySearch();
                    });
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('Clear'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () {
                  if (mounted) {
                    setState(() => _applySearch());
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('Filter', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(String name, String phone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Confirm Delete'),
        content: Text("Are you sure you want to delete '$name'?"),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('users').doc(phone).delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Participant deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting: $e')),
                  );
                }
              }
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (selectionMode) {
          toggleSelectionMode();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.blue,
          elevation: 0,
          leading: LayoutBuilder(
            builder: (context, constraints) => IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white, size: constraints.maxWidth * 0.06),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: Text(
            "${widget.status[0].toUpperCase()}${widget.status.substring(1)} Participants",
            style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.045),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.filter_list,
                color: Colors.white,
                size: MediaQuery.of(context).size.width * 0.05,
              ),
              onPressed: showFilterPopup,
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            return Column(
              children: [
                _buildHeader(width, height),
                SizedBox(height: height * 0.01),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredParticipants.isEmpty
                      ? const Center(child: Text('No participants found'))
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
                            physics: const ClampingScrollPhysics(),
                            itemCount: showAllParticipants
                                ? filteredParticipants.length
                                : (filteredParticipants.length > 6
                                ? 7
                                : filteredParticipants.length),
                            itemBuilder: (context, index) {
                              if (!showAllParticipants &&
                                  index == 6 &&
                                  filteredParticipants.length > 6) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.04,
                                    vertical: height * 0.02,
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (mounted) {
                                        setState(() => showAllParticipants = true);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      minimumSize: Size(double.infinity, height * 0.07),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                    child: Text(
                                      'View more',
                                      style: TextStyle(
                                        fontSize: width * 0.04,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return _buildParticipantRow(filteredParticipants[index], width);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
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
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.03,
                  vertical: height * 0.008,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.casino, color: Colors.white, size: width * 0.045),
                    SizedBox(width: width * 0.01),
                    Text(
                      'Queens',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: width * 0.04,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Gambit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: width * 0.035,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'HI ADMIN',
                style: TextStyle(
                  fontSize: width * 0.035,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: width * 0.02),
              CircleAvatar(
                backgroundColor: Colors.blue,
                radius: width * 0.04,
                child: Icon(
                  Icons.notifications,
                  color: Colors.white,
                  size: width * 0.05,
                ),
              ),
            ],
          ),
          SizedBox(height: height * 0.02),
          TextField(
            onChanged: updateSearch,
            decoration: InputDecoration(
              hintText: 'Search by name',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: EdgeInsets.symmetric(
                vertical: height * 0.015,
                horizontal: width * 0.04,
              ),
            ),
            style: TextStyle(fontSize: width * 0.035),
          ),
          SizedBox(height: height * 0.02),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.status[0].toUpperCase()}${widget.status.substring(1)} participants',
                  style: TextStyle(
                    fontSize: width * 0.04,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: selectionMode ? approveSelectedUsers : toggleSelectionMode,
                child: _tagButton(
                  selectionMode ? 'Approve & Email' : 'Select',
                  Colors.white,
                  Colors.blue,
                ),
              ),
              SizedBox(width: width * 0.02),
              GestureDetector(
                onTap: () async {
                  final participantsToExport = selectionMode
                      ? allParticipants.where((p) => selectedPhones.contains(p.phone)).toList()
                      : allParticipants;
                  await exportToExcel(participantsToExport);
                },
                child: _tagButton(
                  'Export',
                  Colors.blue,
                  Colors.transparent,
                  border: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(double width) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.vertical(top: Radius.circular(width * 0.02)),
      ),
      child: Row(
        children: [
          if (selectionMode)
            Expanded(
              flex: 1,
              child: Checkbox(
                value: allUsersSelected(),
                onChanged: (_) => selectAllUsers(),
                checkColor: Colors.blue,
                activeColor: Colors.white,
              ),
            ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Serial no',
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: width * 0.035,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Name',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: width * 0.035,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Events',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: width * 0.035,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Action',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: width * 0.035,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantRow(Participant p, double width) {
    final bgColor = p.status == 'completed' && widget.status == 'approved'
        ? const Color(0xFFE0E0E0)
        : Colors.white;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        color: bgColor,
      ),
      child: Row(
        children: [
          if (selectionMode && p.status != 'completed')
            Expanded(
              flex: 1,
              child: Checkbox(
                value: selectedPhones.contains(p.phone),
                onChanged: (_) => togglePhoneSelection(p.phone),
              ),
            )
          else
            const Expanded(flex: 1, child: SizedBox()),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 1),
              child: Text(
                p.sNo.toString(),
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: width * 0.035,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              child: Text(
                p.name,
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: width * 0.035,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              child: Text(
                p.event,
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: width * 0.035,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
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
                        if (doc.exists && mounted) {
                          final userData = doc.data()!;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserDetailScreen(
                                userData: {
                                  'name': p.name,
                                  'event': p.event,
                                  'phone_number': p.phone,
                                  'email': p.email,
                                  'age': p.age,
                                  'dob': p.dob,
                                  'gender': p.gender,
                                  'status': p.status,
                                  'event_date': p.eventDate,
                                },
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to fetch user details')),
                          );
                        }
                      }
                    },
                    child: _iconBtn(Icons.visibility, Colors.blue),
                  ),
                  if (widget.status != 'approved') ...[
                    SizedBox(width: width * 0.02),
                    GestureDetector(
                      onTap: () => _confirmDelete(p.name, p.phone),
                      child: _iconBtn(Icons.delete, Colors.red, filled: true),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagButton(String text, Color textColor, Color bgColor, {Color? border}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: border ?? bgColor),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: MediaQuery.of(context).size.width * 0.035,
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, {bool filled = false}) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: filled ? color.withOpacity(0.1) : null,
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }
}