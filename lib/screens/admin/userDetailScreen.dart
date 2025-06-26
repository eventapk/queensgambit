import 'package:flutter/material.dart';

class UserDetailScreen extends StatelessWidget {
  final String name;
  final String event;
  final String phone;
  final String email;
  final String? age;
  final String dob;
  final String gender;
  final String status;
  final String eventDate;

  const UserDetailScreen({
    Key? key,
    required this.name,
    required this.event,
    required this.phone,
    required this.email,
    this.age,
    required this.dob,
    required this.gender,
    required this.status,
    required this.eventDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'User Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: screenWidth > 500 ? 500 : double.infinity),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'USER DETAILS',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Personal Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildInfoRow('Name:', name),
                _buildInfoRow('Date of Birth:', dob),
                _buildInfoRow('Age:', age ?? 'N/A'),
                _buildInfoRow('Email ID:', email),
                _buildInfoRow('Phone No:', phone),
                _buildInfoRow('Gender:', gender),
                _buildInfoRow('Status:', status, isStatus: true),
                const SizedBox(height: 30),
                const Text(
                  'Event Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildInfoRow('Event Name:', event),
                _buildInfoRow('Event Date:', eventDate),
                _buildInfoRow('Contact No:', phone),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: TextStyle(
                fontSize: 16,
                color: isStatus ? _getStatusColor(status) : Colors.black,
                fontWeight: isStatus ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'admitted':
      case 'completed':
        return Colors.green;
      case 'approved':
      case 'registered':
        return Colors.blue;
      case 'waiting':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}