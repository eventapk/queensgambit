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
  bool _isGenderDropdownOpen = false;
  bool _showGenderError = false;
  bool _showPhoneError = false;

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
    _ageController.text = age.toString();
  }

  void _goToEventSelection() {
    final isValidForm = _formKey.currentState!.validate();
    final isPhoneValid = _fullPhoneNumber != null && _phoneController.text.length == 10;
    final isGenderValid = _selectedGender != null;

    setState(() {
      _showPhoneError = !isPhoneValid;
      _showGenderError = !isGenderValid;
    });

    if (isValidForm && isPhoneValid && isGenderValid) {
      _formKey.currentState!.save();
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
          builder: (_) => EventSelectionScreen(userData: userData, isUpdateMode: false),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields correctly')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset('assets/images/adminheadlogo.png', height: height * 0.05),
          ],
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: height * 0.005),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: height * 0.015),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      'Registration',
                      style: TextStyle(
                        fontSize: height * 0.025,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    buildProgressBar(width),
                    SizedBox(height: height * 0.02),
                    buildTextField('Name', _nameController, width, validateLettersOnly: true),
                    buildTextField('DOB', _dobController, width, readOnly: true, onTap: _selectDate),
                    buildTextField('Age', _ageController, width, readOnly: true),
                    buildTextField('Email', _emailController, width, inputType: TextInputType.emailAddress),
                    buildPhoneField(width),
                    buildGenderDropdown(width),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(width * 0.05),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _goToEventSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0090FF),
                  padding: EdgeInsets.symmetric(vertical: height * 0.018),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  "Next",
                  style: TextStyle(fontSize: width * 0.045, color: Colors.white),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller, double width,
      {TextInputType inputType = TextInputType.text,
        bool readOnly = false,
        VoidCallback? onTap,
        bool validateLettersOnly = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: width * 0.04),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        readOnly: readOnly,
        onTap: onTap,
        style: TextStyle(fontSize: width * 0.04),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Enter $label';
          if (label == 'Email' &&
              !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value.trim())) {
            return 'Enter a valid email';
          }
          if (validateLettersOnly && !RegExp(r'^[a-zA-Z ]+$').hasMatch(value.trim())) {
            return 'Only letters allowed in $label';
          }
          return null;
        },
        decoration: InputDecoration(
          label: RichText(
            text: TextSpan(
              text: label,
              style: TextStyle(color: Colors.black, fontSize: width * 0.04),
              children: [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red, fontSize: width * 0.04),
                ),
              ],
            ),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget buildPhoneField(double width) {
    return Padding(
      padding: EdgeInsets.only(bottom: width * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntlPhoneField(
            controller: _phoneController,
            initialCountryCode: 'IN',
            decoration: InputDecoration(
              counterText: "",
              label: RichText(
                text: TextSpan(
                  text: 'Phone Number',
                  style: TextStyle(color: Colors.black, fontSize: width * 0.04),
                  children: [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red, fontSize: width * 0.04),
                    ),
                  ],
                ),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (phone) {
              _fullPhoneNumber = phone.completeNumber;
              if (phone.number.length == 10) {
                setState(() => _showPhoneError = false);
              }
            },
          ),
          if (_showPhoneError)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 4),
              child: Text(
                'Enter valid 10-digit phone number',
                style: TextStyle(color: Colors.red, fontSize: width * 0.035),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildGenderDropdown(double width) {
    return Padding(
      padding: EdgeInsets.only(bottom: width * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: 'Gender',
              style: TextStyle(color: Colors.black, fontSize: width * 0.04),
              children: [
                TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
          SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() => _isGenderDropdownOpen = !_isGenderDropdownOpen),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: width * 0.035),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    _selectedGender ?? "Select Gender",
                    style: TextStyle(fontSize: width * 0.04),
                  ),
                  Spacer(),
                  Icon(_isGenderDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          if (_isGenderDropdownOpen)
            Container(
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: ['Female', 'Male', 'Others'].map((gender) {
                  return ListTile(
                    title: Text(gender, style: TextStyle(fontSize: width * 0.04)),
                    onTap: () {
                      setState(() {
                        _selectedGender = gender;
                        _isGenderDropdownOpen = false;
                        _showGenderError = false;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          if (_showGenderError)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 4),
              child: Text(
                'Select gender',
                style: TextStyle(color: Colors.red, fontSize: width * 0.035),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildProgressBar(double width) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: width * 0.04),
      child: Row(
        children: [
          Expanded(child: Container(height: 2, color: Colors.blue)),
          Container(
            width: width * 0.09,
            height: width * 0.09,
            decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
            child: Icon(Icons.check, color: Colors.white, size: width * 0.06),
          ),
          Expanded(child: Container(height: 2, color: Colors.blue[100]!)),
          Container(
            width: width * 0.065,
            height: width * 0.065,
            decoration: const BoxDecoration(color: Color(0xFFE0E0E0), shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}