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
import 'package:queens_gambit/screens/admin/userDetailScreen.dart';

class Participant {
  int sNo;
  final String name;
  final String event;
  final String phone;
  final String email;
  final String? age;
  final String dob;
  final String gender;
  final String status;
  final String eventDate;
  final DateTime timestamp;

  Participant({
    required this.sNo,
    required this.name,
    required this.event,
    required this.phone,
    required this.email,
    this.age,
    required this.dob,
    required this.gender,
    required this.status,
    required this.eventDate,
    required this.timestamp,
  });
}

enum NotificationType { userLogin, newParticipant }

class NotificationItem {
  final String id;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final String userId;

  NotificationItem({
    required this.id,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.userId,
  });
}

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
  List<NotificationItem> notifications = [];
  int notificationCount = 0;
  bool showNotificationDropdown = false;
  Set<String> previousUserIds = {};
  Set<String> previousLoginIds = {};
  StreamSubscription<QuerySnapshot>? _loginSubscription;

  static const serviceId = 'service_vgb2gw6';
  static const registrationTemplateId = 'template_bvs05a3';
  static const qrTemplateId = 'template_xul6stb';
  static const publicKey = 'egEVzJXbC3OT3SSYE';

  @override
  void initState() {
    super.initState();
    listenToParticipants();
    listenToUserLogins();
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
        final List<Participant> loaded = [];
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          loaded.add(Participant(
            sNo: 0,
            name: data['name'] ?? 'N/A',
            event: data['event'] ?? 'N/A',
            phone: doc.id,
            email: data['email'] ?? '',
            age: data['age']?.toString(),
            dob: data['dob'] ?? '',
            gender: data['gender'] ?? '',
            status: data['status'] ?? 'approved',
            eventDate: data['event_date'] ?? 'Not Assigned',
            timestamp: _getTimestampFromData(data),
          ));
        }

        // Sort by timestamp (newest first)
        loaded.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        Set<String> currentUserIds = loaded.map((p) => p.phone).toSet();
        if (previousUserIds.isNotEmpty) {
          Set<String> newUserIds = currentUserIds.difference(previousUserIds);
          for (String newUserId in newUserIds) {
            Participant newUser =
            loaded.firstWhere((p) => p.phone == newUserId);
            NotificationItem notification = NotificationItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              message: "New ${widget.status} participant: ${newUser.name}",
              type: NotificationType.newParticipant,
              timestamp: DateTime.now(),
              userId: newUserId,
            );
            _addNotification(notification);
          }
        }
        previousUserIds = currentUserIds;

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

  DateTime _getTimestampFromData(Map<String, dynamic> data) {
    // Try to get timestamp from possible fields
    if (data['timestamp'] is Timestamp) {
      return (data['timestamp'] as Timestamp).toDate();
    } else if (data['createdAt'] is Timestamp) {
      return (data['createdAt'] as Timestamp).toDate();
    } else if (data['created_at'] is Timestamp) {
      return (data['created_at'] as Timestamp).toDate();
    } else if (data['updatedAt'] is Timestamp) {
      return (data['updatedAt'] as Timestamp).toDate();
    } else if (data['updated_at'] is Timestamp) {
      return (data['updated_at'] as Timestamp).toDate();
    }
    // Fallback to current time
    return DateTime.now();
  }

  void listenToUserLogins() {
    _loginSubscription = FirebaseFirestore.instance
        .collection('users')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      Set<String> currentLoginIds = snapshot.docs.map((doc) => doc.id).toSet();
      if (previousLoginIds.isNotEmpty) {
        Set<String> newLoginIds = currentLoginIds.difference(previousLoginIds);
        for (String userId in newLoginIds) {
          var userDoc = snapshot.docs.firstWhere((doc) => doc.id == userId);
          String userName = userDoc.data()['name'] ?? 'Unknown User';
          NotificationItem notification = NotificationItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            message: "$userName just logged in",
            type: NotificationType.userLogin,
            timestamp: DateTime.now(),
            userId: userId,
          );
          _addNotification(notification);
        }
      }
      previousLoginIds = currentLoginIds;
    }, onError: (error) {
      print("Error listening to user logins: $error");
    });
  }

  void _addNotification(NotificationItem notification) {
    setState(() {
      notifications.insert(0, notification);
      notificationCount++;
      if (notifications.length > 20) {
        notifications.removeLast();
      }
    });

    Timer(const Duration(seconds: 20), () {
      if (mounted) {
        setState(() {
          if (notificationCount > 0) {
            notificationCount = 0;
          }
        });
      }
    });
  }

  void _clearNotifications() {
    setState(() {
      notifications.clear();
      notificationCount = 0;
      showNotificationDropdown = false;
    });
  }

  void _toggleNotificationDropdown() {
    setState(() {
      showNotificationDropdown = !showNotificationDropdown;
      if (showNotificationDropdown) {
        notificationCount = 0;
      }
    });
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
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

    // First sort by status (completed at bottom)
    filteredParticipants.sort((a, b) {
      if (a.status == 'completed' && b.status != 'completed') return 1;
      if (a.status != 'completed' && b.status == 'completed') return -1;
      return 0; // Maintain existing timestamp order (newest first)
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
    final selectableParticipants = filteredParticipants
        .where((p) => p.status != 'completed')
        .toList();
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
      final storageRef =
      FirebaseStorage.instance.ref().child('qrcodes/$fileName');

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
    if (toEmail.isEmpty || !toEmail.contains('@')) {
      throw Exception('Invalid email address: $toEmail');
    }

    final paymentLink =
        "https://your-payment-portal.com/pay?event=${Uri.encodeComponent(eventName)}&participant=${Uri.encodeComponent(participantName)}";

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    try {
      print('Sending registration email to: $toEmail');
      final response = await http.post(
        url,
        headers: {
          'origin': 'http://localhost',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
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

      print('Email API Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to send registration email: ${response.statusCode} - ${response.body}');
      }
      print('Registration email sent successfully to: $toEmail');
    } catch (e) {
      print('Error sending registration email to $toEmail: $e');
      throw Exception('Error sending registration email to $toEmail: $e');
    }
  }

  Future<void> sendQREmail({
    required String toEmail,
    required String qrUrl,
    required String participantName,
    required String eventName,
  }) async {
    if (toEmail.isEmpty || !toEmail.contains('@')) {
      throw Exception('Invalid email address: $toEmail');
    }

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    try {
      print('Sending QR email to: $toEmail');
      final response = await http.post(
        url,
        headers: {
          'origin': 'http://localhost',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
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
            'message':
            'Please find your QR code attached. Use this for event entry.',
            'sender_name': 'QR Mailer App',
          },
        }),
      );

      print('QR Email API Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to send QR email: ${response.statusCode} - ${response.body}');
      }
      print('QR email sent successfully to: $toEmail');
    } catch (e) {
      print('Error sending QR email to $toEmail: $e');
      throw Exception('Error sending QR email to $toEmail: $e');
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
                'Processing users and sending emails...',
                style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.035),
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
      List<String> failedEmails = [];
      List<String> errorMessages = [];

      for (final phone in selectedPhones) {
        try {
          print('Processing user: $phone');
          final docRef =
          FirebaseFirestore.instance.collection('users').doc(phone);
          final userDoc = await docRef.get();

          if (!userDoc.exists) {
            print('User document not found: $phone');
            failCount++;
            errorMessages.add('User $phone not found');
            continue;
          }

          final userData = userDoc.data() as Map<String, dynamic>;
          final currentStatus = userData['status'] ?? '';
          final userEmail = userData['email'] ?? '';
          final userName = userData['name'] ?? '';

          print(
              'Processing user: $userName ($phone) - Status: $currentStatus, Email: $userEmail');

          if (userEmail.isEmpty || !userEmail.contains('@')) {
            print('Invalid email for user $userName: $userEmail');
            failCount++;
            failedEmails.add('$userName (invalid email)');
            continue;
          }

          if (currentStatus == 'registered') {
            try {
              await sendRegistrationEmail(
                toEmail: userEmail,
                participantName: userName,
                eventName: userData['event'] ?? '',
                eventDate: userData['event_date'] ?? 'TBD',
              );
              batch.update(docRef, {'status': 'waiting'});
              successCount++;
              print('Successfully processed registration for: $userName');
            } catch (emailError) {
              print(
                  'Failed to send registration email to $userName: $emailError');
              failCount++;
              failedEmails.add('$userName (email failed)');
              errorMessages.add('Email failed for $userName: $emailError');
            }
          } else if (currentStatus == 'approved' &&
              widget.status == 'approved') {
            try {
              final qrUrl = await generateAndUploadQR(
                phone,
                'Event Ticket - ${userData['event'] ?? 'Unknown Event'}',
              );
              await sendQREmail(
                toEmail: userEmail,
                qrUrl: qrUrl,
                participantName: userName,
                eventName: userData['event'] ?? '',
              );
              batch.update(docRef, {'status': 'completed'});
              successCount++;
              print('Successfully processed QR email for: $userName');
            } catch (emailError) {
              print('Failed to send QR email to $userName: $emailError');
              failCount++;
              failedEmails.add('$userName (QR email failed)');
              errorMessages.add('QR email failed for $userName: $emailError');
            }
          } else {
            print('User $userName has status $currentStatus - skipping');
          }
        } catch (e) {
          print('Error processing user $phone: $e');
          failCount++;
          errorMessages.add('Processing error for $phone: $e');
        }
      }

      if (successCount > 0) {
        await batch.commit();
        print('Batch committed successfully');
      }

      Navigator.of(context).pop();
      toggleSelectionMode();

      if (successCount > 0 && failCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
            Text('✅ Successfully processed $successCount users and sent emails'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (successCount > 0 && failCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ Processed $successCount users successfully. $failCount failed.\nFailed: ${failedEmails.join(', ')}',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Details',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Processing Results'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('✅ Successful: $successCount'),
                          Text('❌ Failed: $failCount'),
                          if (errorMessages.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            const Text('Error Details:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            ...errorMessages.map((msg) => Text('• $msg',
                                style: const TextStyle(fontSize: 12))),
                          ],
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Failed to process all selected users.\nReasons: ${errorMessages.take(3).join(', ')}${errorMessages.length > 3 ? '...' : ''}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('Critical error in approveSelectedUsers: $e');
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Critical error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      if (androidInfo.version.sdkInt >= 33) {
        return true;
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
    return true;
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
            'instructions':
            'File Manager > Android > data > com.yourapp.name > files',
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preparing Excel file...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Maintain the same order as UI (newest first, completed last)
      participantsToExport.sort((a, b) {
        if (a.status == 'completed' && b.status != 'completed') return 1;
        if (a.status != 'completed' && b.status == 'completed') return -1;
        return b.timestamp.compareTo(a.timestamp);
      });

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
          ExcelLib.TextCellValue(p.age ?? ''),
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

  Future<void> _copyToDownloadsInBackground(
      File sourceFile, String fileName) async {
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
    final screenWidth = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.all(screenWidth * 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: screenWidth * 0.9,
            maxHeight: screenWidth * 1.2,
          ),
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: screenWidth * 0.05),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                SizedBox(height: screenWidth * 0.04),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenWidth * 0.035,
                    ),
                  ),
                  onChanged: (value) => filterName = value.toLowerCase(),
                  style: TextStyle(fontSize: screenWidth * 0.04),
                ),
                SizedBox(height: screenWidth * 0.04),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenWidth * 0.035,
                    ),
                  ),
                  onChanged: (value) => filterAge = value,
                  style: TextStyle(fontSize: screenWidth * 0.04),
                ),
                SizedBox(height: screenWidth * 0.04),
                DropdownButtonFormField<String>(
                  value: filterEvent.isEmpty ? null : filterEvent,
                  decoration: InputDecoration(
                    labelText: 'Event',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenWidth * 0.035,
                    ),
                  ),
                  items: [
                    'Bangalore Open',
                    'Delhi',
                    'Chennai Chess',
                  ]
                      .map((event) => DropdownMenuItem(
                    value: event,
                    child: Text(
                      event,
                      style: TextStyle(fontSize: screenWidth * 0.04,color: Colors.black),
                    ),
                  ))
                      .toList(),
                  onChanged: (value) => filterEvent = value ?? '',
                  style: TextStyle(fontSize: screenWidth * 0.04),
                ),
                SizedBox(height: screenWidth * 0.06),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            filterName = '';
                            filterAge = '';
                            filterEvent = '';
                            _applySearch();
                          });
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              vertical: screenWidth * 0.035),
                        ),
                        child: Text(
                          'Clear',
                          style: TextStyle(fontSize: screenWidth * 0.04),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.04),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _applySearch());
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(
                              vertical: screenWidth * 0.035),
                        ),
                        child: Text(
                          'Filter',
                          style: TextStyle(
                              fontSize: screenWidth * 0.04, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(String name, String phone) {
    final screenWidth = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Confirm Delete',
          style: TextStyle(fontSize: screenWidth * 0.045),
        ),
        content: Text("Are you sure you want to delete '$name'?",
            style: TextStyle(fontSize: screenWidth * 0.04)),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(fontSize: screenWidth * 0.04)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete',
                style: TextStyle(
                    fontSize: screenWidth * 0.04, color: Colors.white)),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(phone)
                    .delete();
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
    _loginSubscription?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isPortrait = screenHeight > screenWidth;
    final isSmallScreen = screenWidth < 600;

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
          automaticallyImplyLeading: false,
          elevation: 0,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                'assets/images/adminheadlogo.png',
                height: isPortrait ? screenHeight * 0.045 : screenWidth * 0.045,
              ),
              Text(
                "Admin",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? screenWidth * 0.04 : screenWidth * 0.035,
                ),
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight,
                  minWidth: screenWidth,
                ),
                child: Column(
                  children: [
                    _buildHeader(screenWidth, screenHeight),
                    SizedBox(height: screenHeight * 0.01),
                    isLoading
                        ? SizedBox(
                      height: screenHeight * 0.6,
                      child: const Center(child: CircularProgressIndicator()),
                    )
                        : filteredParticipants.isEmpty
                        ? SizedBox(
                      height: screenHeight * 0.6,
                      child: const Center(child: Text('No participants found')),
                    )
                        : Container(
                      margin: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
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
                          _tableHeader(screenWidth, isSmallScreen),
                          SizedBox(
                            height: screenHeight * (isPortrait ? 0.5 : 0.7),
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
                                      horizontal: screenWidth * 0.04,
                                      vertical: screenHeight * 0.02,
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () => setState(
                                              () => showAllParticipants = true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        minimumSize: Size(
                                            double.infinity,
                                            screenHeight * 0.06),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(25),
                                        ),
                                      ),
                                      child: Text(
                                        'View more',
                                        style: TextStyle(
                                          fontSize: isSmallScreen
                                              ? screenWidth * 0.04
                                              : 16,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return _buildParticipantRow(
                                    filteredParticipants[index],
                                    screenWidth,
                                    isSmallScreen);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (showNotificationDropdown)
              Positioned(
                top: screenHeight * 0.12,
                right: screenWidth * 0.04,
                child: _buildNotificationDropdown(screenWidth, screenHeight),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double screenWidth, double screenHeight) {
    final isSmallScreen = screenWidth < 600;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back,
                    color: Colors.black, size: screenWidth * 0.06),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  "${widget.status[0].toUpperCase()}${widget.status.substring(1)} Participants",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallScreen ? screenWidth * 0.045 : screenWidth * 0.04,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: _toggleNotificationDropdown,
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue,
                      radius: screenWidth * 0.045,
                      child: Icon(Icons.notifications,
                          color: Colors.white, size: screenWidth * 0.05),
                    ),
                    if (notificationCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            notificationCount > 99
                                ? '99+'
                                : notificationCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          Row(
            children: [
              Expanded(
                child: TextField(
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
                      vertical: screenHeight * 0.015,
                      horizontal: screenWidth * 0.04,
                    ),
                  ),
                  style: TextStyle(fontSize: screenWidth * 0.04),
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              IconButton(
                icon: Icon(Icons.filter_list, size: screenWidth * 0.06),
                onPressed: showFilterPopup,
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          Row(mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Wrap(
                spacing: screenWidth * 0.02,
                runSpacing: screenHeight * 0.015,
                alignment: WrapAlignment.end,
                children: [


                  GestureDetector(
                    onTap: selectionMode ? approveSelectedUsers : toggleSelectionMode,
                    child: _tagButton(
                      selectionMode ? 'Approve' : 'Select',
                      Colors.white,
                      Colors.blue,
                      screenWidth,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final participantsToExport = selectionMode
                          ? allParticipants
                          .where((p) => selectedPhones.contains(p.phone))
                          .toList()
                          : allParticipants;
                      await exportToExcel(participantsToExport);
                    },
                    child: _tagButton(
                      'Export',
                      Colors.blue,
                      Colors.transparent,
                      screenWidth,
                      border: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(double screenWidth, bool isSmallScreen) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          if (selectionMode)
            SizedBox(
              width: screenWidth * 0.1,
              child: Checkbox(
                value: allUsersSelected(),
                onChanged: (_) => selectAllUsers(),
                checkColor: Colors.blue,
                activeColor: Colors.white,
              ),
            ),
          SizedBox(
            width: screenWidth * 0.1,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: screenWidth * 0.035),
              child: Text(
                'S.No',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? screenWidth * 0.035 : screenWidth * 0.03,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: screenWidth * 0.035),
              child: Text(
                'Name',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? screenWidth * 0.035 : screenWidth * 0.03,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: screenWidth * 0.035),
              child: Text(
                'Event',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? screenWidth * 0.035 : screenWidth * 0.03,
                ),
              ),
            ),
          ),
          SizedBox(
            width: screenWidth * 0.2,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: screenWidth * 0.035),
              child: Text(
                'Action',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? screenWidth * 0.035 : screenWidth * 0.03,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantRow(
      Participant p, double screenWidth, bool isSmallScreen) {
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
            SizedBox(
              width: screenWidth * 0.1,
              child: Checkbox(
                value: selectedPhones.contains(p.phone),
                onChanged: (_) => togglePhoneSelection(p.phone),
              ),
            ),
          SizedBox(
            width: screenWidth * 0.1,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
              child: Text(
                p.sNo.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? screenWidth * 0.035 : screenWidth * 0.03,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  vertical: screenWidth * 0.03, horizontal: screenWidth * 0.01),
              child: Text(
                p.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? screenWidth * 0.035 : screenWidth * 0.03,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  vertical: screenWidth * 0.03, horizontal: screenWidth * 0.01),
              child: Text(
                p.event,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? screenWidth * 0.035 : screenWidth * 0.03,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
          SizedBox(
            width: screenWidth * 0.2,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _iconBtn(Icons.visibility, Colors.blue, screenWidth, () {
                    _viewParticipantDetails(p);
                  }),
                  if (widget.status != 'approved') ...[
                    SizedBox(width: screenWidth * 0.02),
                    _iconBtn(Icons.delete, Colors.red, screenWidth, () {
                      _confirmDelete(p.name, p.phone);
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationDropdown(double screenWidth, double screenHeight) {
    return Container(
      width: screenWidth * 0.9,
      constraints: BoxConstraints(maxHeight: screenHeight * 0.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Notifications",
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
                Row(
                  children: [
                    if (notifications.isNotEmpty) ...[
                      GestureDetector(
                        onTap: _clearNotifications,
                        child: Text(
                          "Clear All",
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.03),
                    ],
                    GestureDetector(
                      onTap: () => setState(() => showNotificationDropdown = false),
                      child: Icon(Icons.close, size: screenWidth * 0.05, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (notifications.isEmpty)
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.06),
              child: Column(
                children: [
                  Icon(Icons.notifications_none,
                      size: screenWidth * 0.12, color: Colors.grey[400]),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    "No new notifications",
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.015,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey[200]!,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.02),
                          decoration: BoxDecoration(
                            color: notification.type == NotificationType.userLogin
                                ? Colors.green.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            notification.type == NotificationType.userLogin
                                ? Icons.login
                                : Icons.person_add,
                            color: notification.type == NotificationType.userLogin
                                ? Colors.green
                                : Colors.blue,
                            size: screenWidth * 0.05,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.message,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              Text(
                                _getTimeAgo(notification.timestamp),
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _viewParticipantDetails(Participant p) async {
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
  }

  Widget _tagButton(String text, Color textColor, Color bgColor,
      double screenWidth, {
        Color? border,
      }) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.03, vertical: screenWidth * 0.025),
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
          fontSize: screenWidth * 0.035,
        ),
      ),
    );
  }

  Widget _iconBtn(
      IconData icon, Color color, double screenWidth, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.015),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, color: color, size: screenWidth * 0.045),
      ),
    );
  }
}