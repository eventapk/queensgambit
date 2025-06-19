import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'dart:io';
// import 'package:image_picker/image_picker.dart';

class EventFormScreen extends StatefulWidget {
  const EventFormScreen({Key? key}) : super(key: key);

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _eventDateController = TextEditingController();
  final TextEditingController _mailSubController = TextEditingController();
  final TextEditingController _mailContentController = TextEditingController();
  final TextEditingController _imageNameController = TextEditingController();

  // File? _imageFile;
  bool _isUploading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Future<void> _pickImage() async {
  //   final ImagePicker picker = ImagePicker();
  //   final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
  //   if (pickedFile != null) {
  //     setState(() {
  //       _imageFile = File(pickedFile.path);
  //       _imageNameController.text = pickedFile.name;
  //     });
  //   }
  // }

  Future<void> _selectEventDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _eventDateController.text =
      "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  Future<String> _generateEventId() async {
    final snapshot = await _firestore
        .collection('events')
        .orderBy('event_id', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return 'EVE001';

    final lastId = snapshot.docs.first['event_id'] as String;
    final numericPart = lastId.replaceAll('EVE', '').trim();
    final number = int.tryParse(numericPart);

    if (number == null) {
      throw Exception('Invalid event_id format in Firestore: $lastId');
    }

    final newIdNumber = number + 1;
    return 'EVE${newIdNumber.toString().padLeft(3, '0')}';
  }

  Future<void> _uploadEvent() async {
    if (_eventNameController.text.isEmpty ||
        _eventDateController.text.isEmpty ||
        // _imageFile == null ||
        _mailSubController.text.isEmpty ||
        _mailContentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final eventId = await _generateEventId();
      // final imageUrl = await _uploadImage(eventId);

      await _firestore.collection('events').doc(eventId).set({
        'event_id': eventId,
        'event_name': _eventNameController.text,
        'event_date': _eventDateController.text,
        // 'event_image': imageUrl,
        'mail_subject': _mailSubController.text,
        'mail_content': _mailContentController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event uploaded successfully')),
      );

      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _clearForm() {
    _eventNameController.clear();
    _eventDateController.clear();
    _mailSubController.clear();
    _mailContentController.clear();
    _imageNameController.clear();
    // _imageFile = null;
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.blue),
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.blue),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.blue, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        leading: BackButton(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with Logo, Username, and Bell Icon
              Row(
                children: [
                  Image.asset('assets/images/Logo.png', height: 40),
                  const Spacer(),
                  const Text(
                    'HI USER NAME',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      shadows: [Shadow(blurRadius: 3)],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(blurRadius: 2, color: Colors.black12)],
                    ),
                    child: const Icon(Icons.notifications, color: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text('Event Name :'),
              const SizedBox(height: 6),
              TextField(
                controller: _eventNameController,
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 14),

              const Text('Event Date :'),
              const SizedBox(height: 6),
              TextField(
                controller: _eventDateController,
                readOnly: true,
                onTap: _selectEventDate,
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 14),

              const Text('Event Image :'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _imageNameController,
                      readOnly: true,
                      decoration: _inputDecoration().copyWith(hintText: "Choose Image"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // _pickImage();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: const Text(
                      'Upload',
                      style: TextStyle(color: Colors.white), // 👈 sets text color to white
                    ),

                  ),
                ],
              ),
              const SizedBox(height: 14),

              const Text('Mail Sub'),
              const SizedBox(height: 6),
              TextField(
                controller: _mailSubController,
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 14),

              const Text('Mail Content'),
              const SizedBox(height: 6),
              TextField(
                controller: _mailContentController,
                maxLines: 5,
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Upload',
                    style: TextStyle(color: Colors.white), // 👈 sets text color to white
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

