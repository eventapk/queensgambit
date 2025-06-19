import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import 'eventSelection.dart';


class RegistrationScreen extends StatefulWidget {
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _dobController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedGender;
  String? _fullPhoneNumber;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
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
      _formKey.currentState!.save(); // Ensure _fullPhoneNumber gets saved

      final userData = {
        'name': _nameController.text.trim(),
        'age': _ageController.text.trim(),
        'dob': _dobController.text.trim(),
        'email': _emailController.text.trim(),
        'phone_number': _fullPhoneNumber ?? '',
        'gender': _selectedGender ?? '',
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EventSelectionScreen(
            userData: userData,
            isUpdateMode: false, // ✅ Corrected from `null`
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        leading: BackButton(color: Colors.white),
        title: Text('Registration', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          buildStepper(),
          SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    buildTextField(label: "Name:", controller: _nameController),
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
                    ),
                    buildTextField(
                      label: "Email",
                      controller: _emailController,
                      inputType: TextInputType.emailAddress,
                    ),
                    buildPhoneField(),
                    buildDropdownField(),
                    SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _goToEventSelection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text("Next", style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStepper() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Divider(color: Colors.blue[100], thickness: 2, indent: 20, endIndent: 10),
        ),
        CircleAvatar(
          radius: 12,
          backgroundColor: Colors.blueAccent,
          child: Icon(Icons.check, color: Colors.white, size: 16),
        ),
        Expanded(
          child: Divider(color: Colors.blue[100], thickness: 2, indent: 10, endIndent: 20),
        ),
        CircleAvatar(radius: 12, backgroundColor: Colors.grey.shade300),
        Expanded(
          child: Divider(color: Colors.grey.shade300, thickness: 2, indent: 10, endIndent: 20),
        ),
      ],
    );
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
          if (label.toLowerCase().contains("age") &&
              int.tryParse(value.trim()) == null) {
            return "Enter a valid number";
          }
          if (label.toLowerCase().contains("email") &&
              !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value.trim())) {
            return "Please enter a valid email address";
          }
          return null;
        },
        decoration: InputDecoration(
          label: RichText(
            text: TextSpan(
              text: label,
              style: TextStyle(color: Colors.grey[700], fontSize: 16),
              children: [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                )
              ],
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent),
            borderRadius: BorderRadius.circular(8),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue[100]!),
            borderRadius: BorderRadius.circular(8),
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
        validator: (value) =>
        value == null || value.isEmpty ? "Please select gender" : null,
        items: ['Female', 'Male', 'Others']
            .map((gender) =>
            DropdownMenuItem(value: gender, child: Text(gender)))
            .toList(),
        onChanged: (value) => setState(() => _selectedGender = value),
        decoration: InputDecoration(
          label: RichText(
            text: TextSpan(
              text: "Gender",
              style: TextStyle(color: Colors.grey[700], fontSize: 16),
              children: [
                TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent),
            borderRadius: BorderRadius.circular(8),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue[100]!),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget buildPhoneField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: IntlPhoneField(
        controller: _phoneController,
        decoration: InputDecoration(
          labelText: 'Phone Number *',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue[100]!),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        initialCountryCode: 'IN',
        onChanged: (phone) {
          _fullPhoneNumber = phone.completeNumber;
        },
        onSaved: (phone) {
          _fullPhoneNumber = phone?.completeNumber;
        },
        validator: (phone) {
          if (phone == null || phone.number.isEmpty) {
            return 'Please enter your phone number';
          }
          if (phone.countryCode == '+91' &&
              !RegExp(r'^\d{10}$').hasMatch(phone.number)) {
            return 'Enter a valid 10-digit Indian phone number';
          }
          return null;
        },
      ),
    );
  }
}
