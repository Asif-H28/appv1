import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';

class StudentFeePaymentPage extends StatefulWidget {
  const StudentFeePaymentPage({Key? key}) : super(key: key);

  @override
  _StudentFeePaymentPageState createState() => _StudentFeePaymentPageState();
}

class _StudentFeePaymentPageState extends State<StudentFeePaymentPage> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _feeData;

  @override
  void initState() {
    super.initState();
    _fetchFeeStatus();
  }

  Future<void> _fetchFeeStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email') ?? '';
      final phone = prefs.getString('phone') ?? '';

      if (email.isEmpty && phone.isEmpty) {
        setState(() {
          _errorMessage = 'Student email and phone number not found.';
          _isLoading = false;
        });
        return;
      }

      final url = Uri.parse(
        '${ApiConstants.apiBaseUrl}/tuition-applications/status',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'contactNumber': phone}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _feeData = data['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'No fee payment found for your account.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch fee details. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  String _buildUpiUrl({
    required String upiId,
    required double amount,
    String note = 'Fee Payment',
  }) {
    final params = {
      'pa': upiId,
      'pn': 'SchoolSync',
      'am': amount.toStringAsFixed(2),
      'cu': 'INR',
      'tn': note,
    };
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return 'upi://pay?$query';
  }

  Future<void> _processPayment() async {
    if (_feeData == null) return;

    final upiId = _feeData!['upiId']?.toString();
    final feeAmountStr = _feeData!['feeAmount']?.toString();

    if (upiId == null || upiId.isEmpty || feeAmountStr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid payment details. Cannot process payment.'),
        ),
      );
      return;
    }

    final feeAmount = double.tryParse(feeAmountStr) ?? 0.0;
    if (feeAmount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid fee amount.')));
      return;
    }

    final feeTitle = _feeData!['feeTitle']?.toString() ?? 'Fee Payment';
    final upiUrlStr = _buildUpiUrl(
      upiId: upiId,
      amount: feeAmount,
      note: feeTitle,
    );
    final upiUrl = Uri.parse(upiUrlStr);

    try {
      final launched = await launchUrl(
        upiUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No UPI app found or could not launch.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No UPI app found on this device.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Fee Payment',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF4F46E5), // Indigo
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : _errorMessage != null
          ? _buildErrorView()
          : _buildFeeDetailsView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
            ),
            const SizedBox(height: 24),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _fetchFeeStatus,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeDetailsView() {
    if (_feeData == null) return const SizedBox.shrink();

    final studentName = _feeData!['studentName']?.toString() ?? 'Unknown Student';
    final feeAmount = _feeData!['feeAmount']?.toString() ?? '0';

    return Stack(
      children: [
        // Background banner
        Container(
          height: 120,
          decoration: const BoxDecoration(
            color: Color(0xFF4F46E5),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F46E5).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF4F46E5)),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Payment Summary',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                      ),
                      _buildInfoRow(Icons.person_outline_rounded, 'Student Name', studentName),
                      _buildInfoRow(Icons.class_outlined, 'Class', _feeData!['classOrGrade']?.toString() ?? 'N/A'),
                      _buildInfoRow(Icons.menu_book_rounded, 'Board/Syllabus', _feeData!['boardOrSyllabus']?.toString() ?? 'N/A'),
                      _buildInfoRow(Icons.school_outlined, 'Tutor Name', _feeData!['tutorName']?.toString() ?? 'N/A'),
                      const Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 24),
                        child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                      ),
                      
                      // Amount Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            '₹$feeAmount',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 28,
                              color: Color(0xFF059669), // Emerald Green
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Pay Now Button (Gradient)
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Proceed to Pay',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Secure payment footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_rounded, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    '100% Secure UPI Payments',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: const Color(0xFF6B7280)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
