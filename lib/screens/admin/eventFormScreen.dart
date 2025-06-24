import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:queens_gambit/homePage.dart';
import 'adminhomepage.dart'; // ✅ Adjust path if needed

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

  bool _isUploading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

    if (number == null) throw Exception('Invalid event_id format');

    final newId = number + 1;
    return 'EVE${newId.toString().padLeft(3, '0')}';
  }

  Future<void> _uploadEvent() async {
    if (_eventNameController.text.isEmpty ||
        _eventDateController.text.isEmpty ||
        _mailSubController.text.isEmpty ||
        _mailContentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final eventId = await _generateEventId();

      await _firestore.collection('events').doc(eventId).set({
        'event_id': eventId,
        'event_name': _eventNameController.text,
        'event_date': _eventDateController.text,
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
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.withOpacity(0.6)),
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.blue),
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.blue),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.blue, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const SizedBox(width: 10),
            Image.asset('assets/images/adminheadlogo.png', height: 32),
            const Spacer(),
            const Text(
              'Admin',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => AdminHomePage
                        ( adminName: '',)),
                    );
                  },
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Form',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),

            buildLabel("Event Name"),
            TextField(
              controller: _eventNameController,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r"[a-zA-Z\s!@#\$&*~(),.?:;'\\-]"),
                ),
              ],
              decoration: _inputDecoration(),
            ),

            buildLabel("Event Date"),
            TextField(
              controller: _eventDateController,
              readOnly: true,
              onTap: _selectEventDate,
              decoration: _inputDecoration(),
            ),

            buildLabel("Event Image"),
            TextField(
              controller: _imageNameController,
              readOnly: true,
              decoration: _inputDecoration(hintText: "Choose Image"),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  // image picker logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Upload", style: TextStyle(color: Colors.white)),
              ),
            ),

            buildLabel("Mail Subject"),
            TextField(
              controller: _mailSubController,
              decoration: _inputDecoration(
                hintText: "Email subject for registration confirmation",
              ),
            ),

            buildLabel("Mail Content"),
            TextField(
              controller: _mailContentController,
              maxLines: 5,
              decoration: _inputDecoration(
                hintText: "Email body sent to user after registration",
              ),
            ),

            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Upload", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
