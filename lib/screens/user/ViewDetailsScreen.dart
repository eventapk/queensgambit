import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'eventSelection.dart';

class ViewDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;


  @override
  _ViewDetailsScreenState createState() => _ViewDetailsScreenState();
}

class _ViewDetailsScreenState extends State<ViewDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
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

    if (!_isEditable) return;
      context: context,
      initialDate: DateTime.tryParse(_dobController.text) ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
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
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
              ],
            ),
          ),
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
          ),
          enabledBorder: OutlineInputBorder(
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
            .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
            .toList(),
        onChanged: _isEditable ? (value) => setState(() => _selectedGender = value) : null,
        decoration: InputDecoration(
          label: RichText(
            text: TextSpan(
              text: "Gender",
                TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
          enabledBorder: OutlineInputBorder(
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
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
        ],
      ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
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
                        enabledBorder: OutlineInputBorder(
                        ),
                          borderSide: BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                    ),
                  ),
                  buildDropdownField(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isEditable ? _goToEventSelection : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
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