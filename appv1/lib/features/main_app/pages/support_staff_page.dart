import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../../core/services/api_service.dart';

class SupportStaffPage extends StatefulWidget {
  const SupportStaffPage({Key? key}) : super(key: key);

  @override
  _SupportStaffPageState createState() => _SupportStaffPageState();
}

class _SupportStaffPageState extends State<SupportStaffPage> {
  bool _isLoading = false;
  List<dynamic> _staffList = [];

  @override
  void initState() {
    super.initState();
    _fetchStaffList();
  }

  Future<void> _fetchStaffList() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.get('/support-staff/list');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (data is List) {
            _staffList = data;
          } else if (data['staff'] != null) {
            _staffList = data['staff'];
          } else if (data['data'] != null) {
            _staffList = data['data'];
          } else {
            _staffList = [];
          }
        });
      } else {
        _showSnackBar('Failed to load support staff', isError: true);
      }
    } catch (e) {
      _showSnackBar('Network error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _inviteStaff(String email) async {
    if (email.trim().isEmpty) return;
    
    try {
      final response = await ApiService.post(
        '/support-staff/invite',
        body: jsonEncode({'email': email.trim()}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('Invitation sent successfully to $email!');
        _fetchStaffList(); // Refresh list to show newly invited staff (if backend returns them)
      } else {
        final data = jsonDecode(response.body);
        final msg = data['message'] ?? data['error'] ?? 'Failed to send invitation';
        _showSnackBar(msg, isError: true);
      }
    } catch (e) {
      _showSnackBar('Network error: $e', isError: true);
    }
  }

  void _showInviteDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Invite Support Staff', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the email address of the staff member. They will receive a link to join your organization.',
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.teal, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final email = emailController.text;
                Navigator.pop(context);
                if (email.isNotEmpty) {
                  _inviteStaff(email);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Send Invite'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Support Staff',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : _staffList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.group_add_rounded, size: 64, color: Colors.teal[300]),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'No Support Staff Found',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Invite staff to help manage support tickets.',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  // Proper bottom padding so FAB does not overlap the last item
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 100),
                  itemCount: _staffList.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final staff = _staffList[index];
                    final email = staff['email'] ?? 'No email';
                    final status = staff['status'] ?? 'Active';
                    final name = staff['name'] ?? 'Support Agent';

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_outline, color: Colors.teal),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            email,
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: status.toString().toLowerCase() == 'pending' 
                                ? Colors.orange.withOpacity(0.1) 
                                : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status.toString().toUpperCase(),
                            style: TextStyle(
                              color: status.toString().toLowerCase() == 'pending' 
                                  ? Colors.orange 
                                  : Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showInviteDialog,
        backgroundColor: Colors.teal,
        elevation: 4,
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: const Text(
          'Invite Staff',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
    );
  }
}
