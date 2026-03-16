import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../main_app/main_app_screen.dart';
import '../widgets/custom_textfield.dart';

class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _orgController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _allFieldsValid = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_checkFormValid);
    _orgController.addListener(_checkFormValid);
    _passwordController.addListener(_checkFormValid);
  }

  void _checkFormValid() {
    final emailValid =
        _emailController.text.isNotEmpty && isValidEmail(_emailController.text);
    final orgValid =
        _orgController.text.isNotEmpty && isValidOrgName(_orgController.text);
    final passValid =
        _passwordController.text.isNotEmpty &&
        isValidPassword(_passwordController.text);

    setState(() {
      _allFieldsValid = emailValid && orgValid && passValid;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: 60),
                  Icon(Icons.sync_alt, size: 80, color: AppColors.primary),
                  SizedBox(height: 24),
                  Text(
                    'SchoolSync',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Start or create with your organization',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 60),

                  // EMAIL
                  CustomTextField(
                    controller: _emailController,
                    label: 'Your Email',
                    icon: Icons.email_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Enter your email';
                      if (!isValidEmail(value)) return 'Invalid email format';
                      return null;
                    },
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 20),

                  // ORGANIZATION
                  CustomTextField(
                    controller: _orgController,
                    label: 'Organization Name',
                    icon: Icons.business_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Enter organization name';
                      if (!isValidOrgName(value))
                        return 'Minimum 2 characters required';
                      return null;
                    },
                  ),
                  SizedBox(height: 20),

                  // PASSWORD with EYE
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Create Password',
                    icon: Icons.lock_outlined,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Enter password';
                      if (!isValidPassword(value))
                        return 'Password must be 6+ characters';
                      return null;
                    },
                  ),

                  SizedBox(height: 40),

                  // BUTTON - DISABLED until ALL 3 fields valid
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _allFieldsValid
                            ? AppColors.primary
                            : AppColors.textSecondary.withOpacity(0.3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: _allFieldsValid ? 4 : 0,
                      ),
                      onPressed: _isLoading || !_allFieldsValid
                          ? null
                          : _handleCreate,
                      child: _isLoading
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: 32),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Login coming soon!')),
                      );
                    },
                    child: Text(
                      'Already have an account? Sign In',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleCreate() async {
    if (_formKey.currentState!.validate() && _allFieldsValid) {
      setState(() => _isLoading = true);

      // TODO: Node.js API integration here
      // await ApiService().createAccount(_emailController.text, _orgController.text, _passwordController.text);

      await Future.delayed(Duration(seconds: 2)); // Simulate API

      // Save login data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userEmail', _emailController.text);
      await prefs.setString('userOrg', _orgController.text);

      setState(() => _isLoading = false);

      // Go to Main App
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainAppScreen(
            role: 'user', // Default role
            email: _emailController.text,
            org: _orgController.text,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _orgController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
