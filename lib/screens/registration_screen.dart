import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/password_strength_checker.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  String _role = 'student';
  String? _semester;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  PasswordStrength _passwordStrength = PasswordStrength.Weak;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() {
        _passwordStrength = PasswordStrengthChecker.checkStrength(_passwordController.text);
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        await Provider.of<AuthService>(context, listen: false).register(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _fullNameController.text.trim(),
          role: _role,
          semester: _role == 'student' ? _semester : null,
          phoneNumber: _role == 'student' ? _phoneNumberController.text.trim() : null,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please log in.')),
        );
        Navigator.pop(context);
      } catch (e) {
        setState(() {
          _errorMessage = "Failed to register. The email may already be in use.";
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8.0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextFormField(
                          controller: _fullNameController,
                          labelText: 'Full Name',
                          icon: Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                          controller: _emailController,
                          labelText: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 16),
                      _buildPasswordFormField(),
                      const SizedBox(height: 8),
                      _buildPasswordStrengthIndicator(),
                      const SizedBox(height: 16),
                      _buildRoleDropdown(),
                      if (_role == 'student') ...[
                        const SizedBox(height: 16),
                        _buildSemesterDropdown(),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                            controller: _phoneNumberController,
                            labelText: 'Phone Number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone),
                      ],
                      const SizedBox(height: 24),
                      if (_errorMessage != null)
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 10),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0)),
                          ),
                          child: const Text('Register', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Already have an account? Login',
                          style: TextStyle(color: Colors.blue.shade800),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
      ),
      keyboardType: keyboardType,
      validator: (value) =>
      (value == null || value.isEmpty) ? 'This field cannot be empty' : null,
    );
  }

  Widget _buildPasswordFormField() {
    return TextFormField(
      controller: _passwordController,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        suffixIcon: IconButton(
          icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
      ),
      obscureText: !_isPasswordVisible,
      validator: (value) {
        if (value == null || value.length < 8) {
          return 'Password must be at least 8 characters';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: (_passwordStrength.index + 1) / 3,
          backgroundColor: Colors.grey.shade300,
          color: PasswordStrengthChecker.getStrengthColor(_passwordStrength),
          minHeight: 6,
        ),
        const SizedBox(height: 4),
        Text(
          'Password Strength: ${PasswordStrengthChecker.getStrengthText(_passwordStrength)}',
          style: TextStyle(
            color: PasswordStrengthChecker.getStrengthColor(_passwordStrength),
            fontSize: 12,
          ),
        )
      ],
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Role',
        prefixIcon: const Icon(Icons.person_pin_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
      ),
      value: _role,
      items: ['student', 'teacher', 'admin']
          .map((role) => DropdownMenuItem(
        value: role,
        child: Text(role[0].toUpperCase() + role.substring(1)),
      ))
          .toList(),
      onChanged: (value) => setState(() {
        _role = value!;
        _semester = null;
      }),
      validator: (value) => (value == null) ? 'Please select a role' : null,
    );
  }

  Widget _buildSemesterDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Semester',
        prefixIcon: const Icon(Icons.school_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
      ),
      value: _semester,
      items: ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th']
          .map((sem) => DropdownMenuItem(value: sem, child: Text(sem)))
          .toList(),
      onChanged: (value) => setState(() => _semester = value),
      validator: (value) =>
      (value == null) ? 'Please select a semester' : null,
    );
  }
}