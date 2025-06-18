import 'package:flutter/material.dart';
import 'package:queens_gambit/screens/eventSelection.dart';
class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> userData = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Registration")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField("Name"),
              _buildTextField("Age", keyboardType: TextInputType.number),
              _buildTextField("DOB"),
              _buildTextField("Email", keyboardType: TextInputType.emailAddress),
              _buildTextField("Phone number", keyboardType: TextInputType.phone),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: "Gender"),
                items: ['Male', 'Female', 'Other']
                    .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
                    .toList(),
                onChanged: (value) {
                  userData['gender'] = value!;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventSelectionScreen(userData: userData),
                      ),
                    );
                  }
                },
                child: Text("Next"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextFormField _buildTextField(String label, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      keyboardType: keyboardType,
      validator: (value) => value!.isEmpty ? "Enter $label" : null,
      onSaved: (value) => userData[label.toLowerCase().replaceAll(" ", "_")] = value!,
    );
  }
}
