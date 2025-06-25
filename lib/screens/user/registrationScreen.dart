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
      helpText: '',
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
    ScaffoldMessenger.of(context).clearSnackBars(); // ✅ Fix: clear old SnackBars first

    final formValid = _formKey.currentState!.validate();
    final genderValid = _selectedGender != null && _selectedGender!.isNotEmpty;
    final phoneValid = _fullPhoneNumber != null && _fullPhoneNumber!.trim().isNotEmpty;

    if (formValid && genderValid && phoneValid) {
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
          builder: (context) => EventSelectionScreen(
            userData: userData,
            isUpdateMode: false,
          ),
        ),
      );
    } else {
      if (!genderValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select gender')),
        );
      } else if (!phoneValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a valid phone number')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              'assets/images/adminheadlogo.png',
              height: height * 0.05,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: height * 0.005),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: height * 0.02),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.disabled,
                child: Column(
                  children: [
                    Text(
                      'Registration',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: height * 0.025,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    buildProgressBar(width),
                    SizedBox(height: height * 0.02),
                    buildTextField(label: "Name", controller: _nameController, width: width),
                    buildTextField(label: "DOB", controller: _dobController, width: width, readOnly: true, onTap: _selectDate),
                    buildTextField(label: "Age", controller: _ageController, width: width, inputType: TextInputType.number, readOnly: true),
                    buildTextField(label: "Email", controller: _emailController, width: width, inputType: TextInputType.emailAddress),
                    buildPhoneField(width),
                    buildDropdownField(width),
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
                  backgroundColor: Color(0xFF0090FF),
                  padding: EdgeInsets.symmetric(vertical: height * 0.02),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    required double width,
    TextInputType inputType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: width * 0.04),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        readOnly: readOnly,
        onTap: onTap,
        cursorColor: Color(0xFF0090FF),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "Please enter your ${label.replaceAll(':', '')}";
          }
          if (label.toLowerCase().contains("name") && !RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
            return "Only alphabetic characters are allowed in ${label.replaceAll(':', '')}";
          }
          if (label.toLowerCase().contains("age") && int.tryParse(value.trim()) == null) {
            return "Enter a valid number";
          }
          if (label.toLowerCase().contains("email")) {
            final trimmedValue = value.trim();
            if (!RegExp(r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]+$').hasMatch(trimmedValue)) {
              return "Please enter a valid email format";
            }
          }
          return null;
        },
        decoration: InputDecoration(
          label: RichText(
            text: TextSpan(
              text: label,
              style: TextStyle(color: Colors.grey[700], fontSize: width * 0.04),
              children: [TextSpan(text: ' *', style: TextStyle(color: Colors.red))],
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF0090FF)),
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

  Widget buildPhoneField(double width) {
    return Padding(
      padding: EdgeInsets.only(bottom: width * 0.04),
      child: IntlPhoneField(
        controller: _phoneController,
        decoration: InputDecoration(
          helperText: '',
          counterText: '',
          labelText: 'Phone Number *',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue[100]!),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF0090FF)),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        initialCountryCode: 'IN',
        onChanged: (phone) => _fullPhoneNumber = phone.completeNumber,
        onSaved: (phone) => _fullPhoneNumber = phone?.completeNumber,
        validator: (phone) {
          if (phone == null || phone.number.isEmpty) {
            return 'Please enter your phone number';
          }
          if (phone.countryCode == '+91' && !RegExp(r'^\d{10}$').hasMatch(phone.number)) {
            return 'Enter a valid 10-digit Indian phone number';
          }
          return null;
        },
      ),
    );
  }

  Widget buildDropdownField(double width) {
    return Padding(
      padding: EdgeInsets.only(bottom: width * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4, bottom: 4),
            child: RichText(
              text: TextSpan(
                text: "Gender",
                style: TextStyle(color: Colors.grey[700], fontSize: width * 0.04),
                children: [TextSpan(text: ' *', style: TextStyle(color: Colors.red))],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _isGenderDropdownOpen = !_isGenderDropdownOpen),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: width * 0.035),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue[100]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    _selectedGender ?? "Select Gender",
                    style: TextStyle(fontSize: width * 0.04, color: _selectedGender == null ? Colors.grey[600] : Colors.black),
                  ),
                  Spacer(),
                  Icon(_isGenderDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.blueAccent),
                ],
              ),
            ),
          ),
          if (_isGenderDropdownOpen) ...[
            SizedBox(height: width * 0.02),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Column(
                children: ['Female', 'Male', 'Others'].map((gender) {
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedGender = gender;
                      _isGenderDropdownOpen = false;
                    }),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: width * 0.03),
                      decoration: BoxDecoration(
                        color: _selectedGender == gender ? Color(0xFF0090FF) : Colors.transparent,
                        borderRadius: gender == 'Female'
                            ? BorderRadius.vertical(top: Radius.circular(8))
                            : gender == 'Others'
                            ? BorderRadius.vertical(bottom: Radius.circular(8))
                            : null,
                      ),
                      child: Text(
                        gender,
                        style: TextStyle(
                          fontSize: width * 0.04,
                          color: _selectedGender == gender ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildProgressBar(double width) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.0),
      child: Row(
        children: [
          Expanded(child: Container(height: 2, color: Colors.blue)),
          Container(
            width: width * 0.09,
            height: width * 0.09,
            decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
            child: Icon(Icons.check, color: Colors.white, size: width * 0.06),
          ),
          Expanded(child: Container(height: 2, color: Colors.blue[100])),
          Container(
            width: width * 0.065,
            height: width * 0.065,
            decoration: BoxDecoration(color: Colors.blue[100], shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}