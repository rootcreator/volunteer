import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _skillController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _loading = false;
  String _error = '';

  String _selectedRole = 'volunteer';
  final List<String> _roles = ['volunteer', 'admin'];
  final List<String> _skills = [];

  void _signup() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        _selectedRole,
        _skills,
      );
      Navigator.pop(context); // Go back to login
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              items: _roles.map((role) {
                return DropdownMenuItem(value: role, child: Text(role.toUpperCase()));
              }).toList(),
              onChanged: (val) => setState(() => _selectedRole = val!),
              decoration: const InputDecoration(labelText: 'Select Role'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _skillController,
              decoration: InputDecoration(
                labelText: 'Add Skill',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (_skillController.text.trim().isNotEmpty) {
                      setState(() {
                        _skills.add(_skillController.text.trim());
                        _skillController.clear();
                      });
                    }
                  },
                ),
              ),
            ),
            Wrap(
              spacing: 6.0,
              children: _skills
                  .map((skill) => Chip(
                        label: Text(skill),
                        onDeleted: () => setState(() => _skills.remove(skill)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            if (_loading) const CircularProgressIndicator(),
            if (_error.isNotEmpty) Text(_error, style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _signup, child: const Text('Create Account')),
          ],
        ),
      ),
    );
  }
}
