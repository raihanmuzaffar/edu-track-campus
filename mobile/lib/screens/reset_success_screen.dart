import 'package:flutter/material.dart';

class ResetSuccessScreen extends StatelessWidget {
  const ResetSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ilustrasi Balon (Placeholder)
              const Icon(Icons.celebration, size: 120, color: Color(0xFFD97736)),
              const SizedBox(height: 40),
              
              const Text(
                'Password Reset',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF145A4A)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your password has been reset successfully. Now login with your new password.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              
              const SizedBox(height: 50),
              
              // Tombol Login
              ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
                child: const Text('LOGIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}