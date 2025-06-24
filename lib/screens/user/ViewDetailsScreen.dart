import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'thank_you_screen.dart';
import 'package:queens_gambit/homePage.dart';

class ViewDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ViewDetailsScreen({super.key, required this.userData});

  @override
  State<ViewDetailsScreen> createState() => _ViewDetailsScreenState();
}

class _ViewDetailsScreenState extends State<ViewDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _dobController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  String? _selectedGender;
  String? _selectedEvent;
  bool _canEdit = false;
  bool _isEditing = false;
  bool _hasChanged = false;

  List<String> availableEvents = ['Bangalore Open', 'Delhi', 'Chennai Chess'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name']);
    _ageController = TextEditingController(text: widget.userData['age']);
    _dobController = TextEditingController(text: widget.userData['dob']);
    _emailController = TextEditingController(text: widget.userData['email']);
    _phoneController = TextEditingController(text: widget.userData['phone_number']);
    _selectedGender = widget.userData['gender'];
    _selectedEvent = widget.userData['event'] ?? availableEvents.first;

    _nameController.addListener(_checkForChanges);
    _dobController.addListener(_checkForChanges);

    _fetchStatusFromFirebase();
  }

  void _fetchStatusFromFirebase() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userData['phone_number'])
        .get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['status'] == 'registered') {
        setState(() {
          _canEdit = true;
        });
      }
    }
  }

  void _checkForChanges() {
    bool changed = _nameController.text != widget.userData['name'] ||
        _dobController.text != widget.userData['dob'] ||
        _selectedGender != widget.userData['gender'] ||
        _selectedEvent != widget.userData['event'];

    if (changed != _hasChanged) {
      setState(() {
        _hasChanged = changed;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    if (!_isEditing) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dobController.text) ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
        _calculateAge(picked);
        _checkForChanges();
      });
    }
  }

  void _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    _ageController.text = age.clamp(0, 100).toString();
  }

  Future<void> _goToNextStep() async {
    if (_isEditing) {
      if (_formKey.currentState!.validate()) {
        final userData = {
          'name': _nameController.text.trim(),
          'age': _ageController.text.trim(),
          'dob': _dobController.text.trim(),
          'email': _emailController.text.trim(),
          'phone_number': widget.userData['phone_number'],
          'gender': _selectedGender ?? '',
          'event': _selectedEvent ?? '',
          'status': 'registered',
        };

        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userData['phone_number'])
              .set(userData,SetOptions(merge:true));

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Details updated successfully')),
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ThankYouScreen(
                userData: userData,
                isUpdate: true,
              ),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update: $e')),
          );
        }
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    }
  }

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType inputType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        readOnly: readOnly,
        onTap: onTap,
        cursorColor: Colors.blueAccent,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "Please enter your $label";
          }
          if (label == "Name" && !RegExp(r"^[a-zA-Z\s]+$").hasMatch(value.trim())) {
            return "Name should contain only letters and spaces";
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: "$label *",
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue.shade100),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
    );
  }

  Widget buildDropdownField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        validator: (value) => value == null || value.isEmpty ? "Please select gender" : null,
        items: const ['Female', 'Male', 'Others']
            .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
            .toList(),
        onChanged: _isEditing
            ? (value) {
          setState(() {
            _selectedGender = value;
            _checkForChanges();
          });
        }
            : null,
        decoration: InputDecoration(
          labelText: "Gender *",
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue.shade100),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
    );
  }

  Widget buildEventDropdownField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: _selectedEvent,
        validator: (value) => value == null || value.isEmpty ? "Please select event" : null,
        items: availableEvents
            .map((event) => DropdownMenuItem(value: event, child: Text(event)))
            .toList(),
        onChanged: _isEditing
            ? (value) {
          setState(() {
            _selectedEvent = value;
            _checkForChanges();
          });
        }
            : null,
        decoration: InputDecoration(
          labelText: "Event *",
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue.shade100),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

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
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          "View Your Details",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    if (_canEdit && !_isEditing)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        label: const Text("Edit", style: TextStyle(color: Colors.blueAccent)),
                      )
                    else
                      const SizedBox(width: 70),
                  ],
                ),
                const SizedBox(height: 20),
                buildTextField(label: "Name", controller: _nameController, readOnly: !_isEditing),
                buildTextField(label: "DOB", controller: _dobController, readOnly: true, onTap: _selectDate),
                buildTextField(label: "Age", controller: _ageController, inputType: TextInputType.number, readOnly: true),
                buildTextField(label: "Email", controller: _emailController, inputType: TextInputType.emailAddress, readOnly: true),
                buildTextField(label: "Phone Number", controller: _phoneController, readOnly: true),
                buildDropdownField(),
                buildEventDropdownField(),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _goToNextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: EdgeInsets.symmetric(vertical: height * 0.02),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                    ),
                    child: Text(
                      _isEditing && _hasChanged ? "Update & Continue" : "Continue",
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
