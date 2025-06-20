import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'eventSelection.dart';

class ViewDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ViewDetailsScreen({super.key, required this.userData});

  @override
  _ViewDetailsScreenState createState() => _ViewDetailsScreenState();
}

class _ViewDetailsScreenState extends State<ViewDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _dobController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  String? _selectedGender;
  bool _isEditable = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name']);
    _ageController = TextEditingController(text: widget.userData['age']);
    _dobController = TextEditingController(text: widget.userData['dob']);
    _emailController = TextEditingController(text: widget.userData['email']);
    _phoneController = TextEditingController(text: widget.userData['phone_number']);
    _selectedGender = widget.userData['gender'];
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
    if (!_isEditable) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dobController.text) ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blueAccent,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
        _calculateAge(picked);
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

  void _goToEventSelection() {
    if (_formKey.currentState!.validate()) {
      final userData = {
        'name': _nameController.text.trim(),
        'age': _ageController.text.trim(),
        'dob': _dobController.text.trim(),
        'email': _emailController.text.trim(),
        'phone_number': widget.userData['phone_number'],
        'gender': _selectedGender ?? '',
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EventSelectionScreen(userData: userData, isUpdateMode: true),
        ),
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
            return "Please enter your ${label.replaceAll(':', '')}";
          }
          if (label.toLowerCase().contains("age")) {
            final age = int.tryParse(value.trim());
            if (age == null || age < 0 || age > 100) {
              return "Enter a valid age (0-100)";
            }
          }
          return null;
        },
        decoration: InputDecoration(
          label: RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(color: Color(0xFF616161), fontSize: 16), // Fixed: Use Color(0xFF616161) for grey[700]
              children: const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
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
        onChanged: _isEditable ? (value) => setState(() => _selectedGender = value) : null,
        decoration: InputDecoration(
          label: RichText(
            text: TextSpan(
              text: "Gender",
              style: const TextStyle(color: Color(0xFF616161), fontSize: 16), // Fixed: Use Color(0xFF616161) for grey[700]
              children: const [
                TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue.shade100),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final height = size.height;
    final width = size.width;
    return Scaffold(
      resizeToAvoidBottomInset: true, // Added to handle keyboard overflow
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Your Details"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isEditable ? Icons.lock_open : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditable = !_isEditable;
              });
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth * 0.04,
              vertical: constraints.maxHeight * 0.02,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  buildProgressBar(width),
                  buildTextField(
                    label: "Name:",
                    controller: _nameController,
                    readOnly: !_isEditable,
                  ),
                  buildTextField(
                    label: "DOB:",
                    controller: _dobController,
                    readOnly: true,
                    onTap: _selectDate,
                  ),
                  buildTextField(
                    label: "Age:",
                    controller: _ageController,
                    inputType: TextInputType.number,
                    readOnly: true,
                  ),
                  buildTextField(
                    label: "Email:",
                    controller: _emailController,
                    inputType: TextInputType.emailAddress,
                    readOnly: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: TextFormField(
                      controller: _phoneController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Phone Number *',
                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue.shade100),
                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent),
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                  buildDropdownField(),
                  SizedBox(height: height * 0.05),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isEditable ? _goToEventSelection : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: EdgeInsets.symmetric(
                          vertical: height * 0.02,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                      child: const Text(
                        "Next",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget buildProgressBar(double width) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: width * 0.1),
    child: Row(
      children: [
        Expanded(child: Container(height: 2, color: Colors.blue)),
        Container(
          width: width * 0.12,
          height: width * 0.12,
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 22),
        ),
        Expanded(child: Container(height: 2, color: Colors.blue.shade100)),
        Container(
          width: width * 0.08,
          height: width * 0.08,
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            shape: BoxShape.circle,
          ),
        ),
      ],
    ),
  );
}

